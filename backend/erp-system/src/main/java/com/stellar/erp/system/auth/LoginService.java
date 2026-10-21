package com.stellar.erp.system.auth;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;
import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.system.AuthSessions;

import cn.dev33.satoken.secure.BCrypt;
import cn.dev33.satoken.stp.StpUtil;

/**
 * ログイン（01-auth-login PRC-SYS-001-02、01/91 #2）。
 *
 * <ul>
 *   <li>{@code tenantCode} は大文字小文字を区別しない（保存は大文字）→ {@code upper} してから
 *       {@code sys_auth_find_login_user} を呼ぶ。{@code username} は完全一致。</li>
 *   <li>企業代码不存在・租户無効/期限切れ・ユーザ不存在・パスワード不一致は同一の 2002 / MSG-COM-021。
 *       0 行時もダミー BCrypt 照合で応答時間を揃える（BR-14）。</li>
 *   <li>1 行取得後は {@code app.tenant_id}/{@code app.company_id} を設定し RLS 範囲内で更新・ログ記録。</li>
 *   <li>失敗 5 回で 30 分ロック（BR-04）。ロック中は 2003 / MSG-COM-023（残り分数）。</li>
 * </ul>
 */
@Service
public class LoginService {

    /** 账号停用/离职（MSG-SYS-001）の業務コード（SYS 帯、docs #77 で確定）。 */
    public static final int ACCOUNT_DISABLED = 10900;

    static final int MAX_FAILS = 5;
    static final Duration LOCK = Duration.ofMinutes(30);
    /** 0 行時の照合用（cost 10、実ハッシュと同等の計算時間）。 */
    private static final String DUMMY_HASH = BCrypt.hashpw("stellar-dummy-password", BCrypt.gensalt(10));

    public record LoginCommand(String tenantCode, String username, String password, String ip, String userAgent) {
    }

    public record LoginResult(String token, String tokenName, int expiresIn, boolean passwordResetRequired,
                              AuthMeService.UserInfo userInfo, List<AuthMeService.RoleInfo> roles,
                              List<String> permissions, List<AuthMeService.MenuInfo> menus) {
    }

    record Found(long tenantId, long userId, long companyId, String passwordHash, int status, int accountStatus,
                 OffsetDateTime lockUntil, int loginFailCount, boolean passwordResetRequired,
                 OffsetDateTime passwordExpireAt, int version) {
    }

    private final JdbcClient jdbc;
    private final TransactionTemplate tx;
    private final AuthMeService me;
    private final ObjectProvider<UserUpdateHook> hook;

    public LoginService(JdbcClient jdbc, PlatformTransactionManager tm, AuthMeService me,
                        ObjectProvider<UserUpdateHook> hook) {
        this.jdbc = jdbc;
        this.tx = new TransactionTemplate(tm);
        this.me = me;
        this.hook = hook;
    }

    static BizException badCredentials() {
        return new BizException(2002, "MSG-COM-021", "企业代码、用户名或密码错误。");
    }

    public LoginResult login(LoginCommand cmd) {
        String tenantCode = cmd.tenantCode().toUpperCase(Locale.ROOT);
        Optional<Found> found = tx.execute(s -> jdbc.sql("SELECT * FROM sys_auth_find_login_user(:tc, :u)")
                .param("tc", tenantCode).param("u", cmd.username())
                .query((rs, i) -> new Found(rs.getLong("tenant_id"), rs.getLong("user_id"), rs.getLong("company_id"),
                        rs.getString("password_hash"), rs.getInt("status"), rs.getInt("account_status"),
                        rs.getObject("lock_until", OffsetDateTime.class), rs.getInt("login_fail_count"),
                        rs.getBoolean("password_reset_required"),
                        rs.getObject("password_expire_at", OffsetDateTime.class), rs.getInt("version")))
                .optional());
        if (found.isEmpty()) {
            BCrypt.checkpw(cmd.password(), DUMMY_HASH);
            throw badCredentials();
        }
        Found u = found.get();
        Optional<LoginContext.LoginUser> prevLogin = LoginContext.current();
        var prevTenant = TenantContext.current();
        TenantContext.set(u.tenantId());
        LoginContext.set(new LoginContext.LoginUser(u.userId(), u.companyId()));
        try {
            Outcome outcome = tx.execute(s -> authenticateWithRetry(u, cmd));
            if (outcome.failure() != null) {
                // ログインログは独立トランザクション（ユーザ更新のコミット後）
                tx.executeWithoutResult(s -> log(u, cmd, false, outcome.reason(), null));
                throw outcome.failure();
            }
            String token = AuthSessions.open(u.userId(), u.tenantId(), u.companyId());
            tx.executeWithoutResult(s -> log(u, cmd, true, null, token));
            AuthMeService.Me m = me.me();
            boolean resetRequired = u.passwordResetRequired() || u.accountStatus() == 4
                    || (u.passwordExpireAt() != null && u.passwordExpireAt().isBefore(OffsetDateTime.now()));
            return new LoginResult(token, StpUtil.getTokenName(), (int) StpUtil.getTokenTimeout(token), resetRequired,
                    m.userInfo(), m.roles(), m.permissions(), m.menus());
        } finally {
            if (prevTenant.isPresent()) {
                TenantContext.set(prevTenant.getAsLong());
            } else {
                TenantContext.clear();
            }
            prevLogin.ifPresentOrElse(LoginContext::set, LoginContext::clear);
        }
    }

    /** テスト用フック：sys_user 更新直前に呼ばれる（楽観排他競合の再現用）。本番では Bean なし。 */
    public interface UserUpdateHook {
        void beforeUserUpdate(long userId);
    }

    record Outcome(BizException failure, String reason) {
        static final Outcome OK = new Outcome(null, null);
        static final Outcome CONFLICT = new Outcome(null, "CONFLICT");
    }

    static BizException staleVersion() {
        return new BizException(4003, "MSG-COM-033", "数据已被其他用户更新，请重新获取最新信息后再操作。");
    }

    /**
     * 状態判定・照合・sys_user 更新（{@code WHERE id AND version} の楽観排他）。競合時は最新行を再読込して
     * 1 回だけ再試行し、なお競合なら 4003 / MSG-COM-033（01-auth-login 6.3 No.7、03 §楽観排他）。
     */
    private Outcome authenticateWithRetry(Found u, LoginCommand cmd) {
        Found cur = u;
        for (int attempt = 0; attempt < 2; attempt++) {
            Outcome o = attempt(cur, cmd);
            if (o != Outcome.CONFLICT) {
                return o;
            }
            Optional<Found> again = reread(cur);
            if (again.isEmpty()) {
                // 競合中にユーザが削除された：存在しないユーザと同じ 2002（BR-14）
                return new Outcome(badCredentials(), "MSG-COM-021");
            }
            cur = again.get();
        }
        return new Outcome(staleVersion(), "MSG-COM-033");
    }

    private Optional<Found> reread(Found u) {
        return jdbc.sql("""
                        SELECT tenant_id, id, company_id, password_hash, status, account_status, lock_until,
                               login_fail_count, password_reset_required, password_expire_at, version
                          FROM sys_user WHERE id = :id AND deleted = FALSE
                        """)
                .param("id", u.userId())
                .query((rs, i) -> new Found(rs.getLong(1), rs.getLong(2), rs.getLong(3), rs.getString(4), rs.getInt(5),
                        rs.getInt(6), rs.getObject(7, OffsetDateTime.class), rs.getInt(8), rs.getBoolean(9),
                        rs.getObject(10, OffsetDateTime.class), rs.getInt(11)))
                .optional();
    }

    private Outcome attempt(Found u, LoginCommand cmd) {
        if (u.status() != 1 || u.accountStatus() == 3) {
            return new Outcome(new BizException(ACCOUNT_DISABLED, "MSG-SYS-001", "该账号已停用或已离职，请联系管理员。"), "MSG-SYS-001");
        }
        OffsetDateTime now = OffsetDateTime.now();
        int fails = u.loginFailCount();
        int accountStatus = u.accountStatus();
        if (accountStatus == 2) {
            if (u.lockUntil() == null || u.lockUntil().isAfter(now)) {
                return new Outcome(locked(u.lockUntil(), now), "MSG-COM-023");
            }
            // ロック期限到来：解除状態に戻す（以下の更新に含める）
            fails = 0;
            accountStatus = 1;
        }
        boolean ok = BCrypt.checkpw(cmd.password(), u.passwordHash());
        int nextFails = ok ? 0 : fails + 1;
        boolean lock = !ok && nextFails >= MAX_FAILS;
        int nextStatus = lock ? 2 : accountStatus;
        OffsetDateTime lockUntil = lock ? now.plus(LOCK) : (nextStatus == 2 ? u.lockUntil() : null);
        UserUpdateHook h = hook.getIfAvailable();
        if (h != null) {
            h.beforeUserUpdate(u.userId());
        }
        int rows = jdbc.sql("""
                        UPDATE sys_user
                           SET login_fail_count = :fails, account_status = :status, lock_until = :until,
                               last_login_at = CASE WHEN :ok THEN now() ELSE last_login_at END,
                               last_login_ip = CASE WHEN :ok THEN CAST(:ip AS VARCHAR) ELSE last_login_ip END,
                               version = version + 1, updated_at = now()
                         WHERE id = :id AND version = :version
                        """)
                .param("fails", nextFails).param("status", nextStatus).param("until", lockUntil)
                .param("ok", ok).param("ip", cmd.ip()).param("id", u.userId()).param("version", u.version())
                .update();
        if (rows == 0) {
            return Outcome.CONFLICT;
        }
        return ok ? Outcome.OK : new Outcome(badCredentials(), "MSG-COM-021");
    }

    /** sys_login_log.session_id：トークン（資格情報）は保存せず、SHA-256 の 16 進全体（64 字、切り詰めなし）を保存。 */
    static String sessionDigest(String token) {
        try {
            byte[] d = java.security.MessageDigest.getInstance("SHA-256")
                    .digest(token.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(d);
        } catch (java.security.NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    static BizException locked(OffsetDateTime until, OffsetDateTime now) {
        String minutes = until == null ? "-" : Long.toString(Math.max(1, (Duration.between(now, until).toSeconds() + 59) / 60));
        return new BizException(2003, "MSG-COM-023", "账号已被锁定，请于 " + minutes + " 分钟后重试或联系管理员。");
    }

    private void log(Found u, LoginCommand cmd, boolean ok, String reason, String token) {
        jdbc.sql("""
                        INSERT INTO sys_login_log (id, company_id, user_id, username, login_type, login_result, fail_reason,
                                                   ip_address, user_agent, session_id)
                        VALUES (:id, :company, :user, :username, 1, :result, :reason, :ip, :ua, :sid)
                        """)
                .param("id", IdWorker.getId()).param("company", u.companyId()).param("user", u.userId())
                .param("username", cmd.username()).param("result", ok ? 1 : 0).param("reason", reason)
                .param("ip", cmd.ip())
                .param("ua", cmd.userAgent() == null ? null : cmd.userAgent().substring(0, Math.min(500, cmd.userAgent().length())))
                .param("sid", token == null ? null : sessionDigest(token))
                .update();
    }
}
