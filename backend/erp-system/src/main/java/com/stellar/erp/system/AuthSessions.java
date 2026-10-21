package com.stellar.erp.system;

import java.util.Optional;

import cn.dev33.satoken.session.SaSession;
import cn.dev33.satoken.stp.StpUtil;

/**
 * Sa-Token セッション（01-system 01-auth-login PRC-SYS-001-02 第 7 項：{@code loginId=userId}、
 * {@code tenantId}/{@code companyId} をセッションに格納）。
 *
 * <p>多端末で会社が異なり得るため、アカウントセッションではなく<b>トークンセッション</b>に保存する。
 * 会社切替＝新しい companyId でのセッション作成（権限は毎リクエスト session の companyId で再計算）。</p>
 */
public final class AuthSessions {

    public static final String TENANT_ID = "tenantId";
    public static final String COMPANY_ID = "companyId";

    /** 現在リクエストのログイン情報。 */
    public record SessionUser(long userId, long tenantId, long companyId) {
    }

    private AuthSessions() {
    }

    /** ログイン成立時に呼ぶ：トークン発行 + tenantId/companyId 格納。発行したトークン値を返す。 */
    public static String open(long userId, long tenantId, long companyId) {
        StpUtil.login(userId);
        SaSession s = StpUtil.getTokenSession();
        s.set(TENANT_ID, tenantId);
        s.set(COMPANY_ID, companyId);
        return StpUtil.getTokenValue();
    }

    /** 有効なトークンがあり、セッションに tenantId/companyId が揃っていればその内容。 */
    public static Optional<SessionUser> current() {
        if (!StpUtil.isLogin()) {
            return Optional.empty();
        }
        SaSession s = StpUtil.getTokenSession();
        Object tenant = s.get(TENANT_ID);
        Object company = s.get(COMPANY_ID);
        if (tenant == null || company == null) {
            return Optional.empty();
        }
        return Optional.of(new SessionUser(StpUtil.getLoginIdAsLong(), Long.parseLong(tenant.toString()),
                Long.parseLong(company.toString())));
    }

    /** 当該トークンのみ失効（BR-07）。トークンなし・無効・期限切れでも例外にしない（冪等）。 */
    public static void logoutCurrentToken() {
        String token = StpUtil.getTokenValue();
        if (token != null && !token.isBlank()) {
            StpUtil.logoutByTokenValue(token);
        }
    }
}
