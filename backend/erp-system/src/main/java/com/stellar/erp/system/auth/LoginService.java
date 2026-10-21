package com.stellar.erp.system.auth;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

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

    public LoginService(JdbcClient jdbc, PlatformTransactionManager tm, AuthMeService me) {
        this.jdbc = jdbc;
        this.tx = new TransactionTemplate(tm);
        this.me = me;
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
            BizException failure = tx.execute(s -> authenticate(u, cmd));
            if (failure != null) {
                throw failure;
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

    /** 状態判定・照合・失敗回数更新。失敗時は（更新をコミットさせるため）例外を投げずに返す。 */
    private BizException authenticate(Found u, LoginCommand cmd) {
        if (u.status() != 1 || u.accountStatus() == 3) {
            log(u, cmd, false, "MSG-SYS-001", null);
            return new BizException(10001, "MSG-SYS-001", "该账号已停用或已离职，请联系管理员。");
        }
        OffsetDateTime now = OffsetDateTime.now();
        int fails = u.loginFailCount();
        if (u.accountStatus() == 2) {
            if (u.lockUntil() == null || u.lockUntil().isAfter(now)) {
                log(u, cmd, false, "MSG-COM-023", null);
                return locked(u.lockUntil(), now);
            }
            // ロック期限到来：解除状態に戻す
            jdbc.sql("UPDATE sys_user SET account_status = 1, lock_until = NULL, login_fail_count = 0, "
                            + "version = version + 1, updated_at = now() WHERE id = :id")
                    .param("id", u.userId()).update();
            fails = 0;
        }
        if (!BCrypt.checkpw(cmd.password(), u.passwordHash())) {
            int next = fails + 1;
            if (next >= MAX_FAILS) {
                jdbc.sql("UPDATE sys_user SET login_fail_count = :n, account_status = 2, lock_until = :until, "
                                + "version = version + 1, updated_at = now() WHERE id = :id")
                        .param("n", next).param("until", now.plus(LOCK)).param("id", u.userId()).update();
            } else {
                jdbc.sql("UPDATE sys_user SET login_fail_count = :n, version = version + 1, updated_at = now() "
                                + "WHERE id = :id")
                        .param("n", next).param("id", u.userId()).update();
            }
            log(u, cmd, false, "MSG-COM-021", null);
            return badCredentials();
        }
        jdbc.sql("UPDATE sys_user SET login_fail_count = 0, last_login_at = now(), last_login_ip = :ip, "
                        + "version = version + 1, updated_at = now() WHERE id = :id")
                .param("ip", cmd.ip()).param("id", u.userId()).update();
        return null;
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
                .param("sid", token == null ? null : token.substring(0, Math.min(100, token.length())))
                .update();
    }
}
