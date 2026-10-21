package com.stellar.erp;

import java.util.Optional;

import org.springframework.core.annotation.AnnotatedElementUtils;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.RequirePermission;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.system.AuthSessions;
import com.stellar.erp.system.UserPermissionService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * 認証 + 権限（00-common 03 §3・§4・§6）。
 *
 * <ul>
 *   <li>Sa-Token のトークンセッションから userId / tenantId / companyId を取り、{@link TenantContext}（→ 事務内
 *   {@code app.tenant_id}）と {@link LoginContext}（→ {@code app.company_id}）を設定。リクエスト終了時に元へ戻す。</li>
 *   <li>有効なセッションなし → 401 / {@code code=2001} / {@code MSG-COM-020}。</li>
 *   <li>handler の {@link RequirePermission}（メソッド優先、なければクラス）のコードを、セッションの会社での
 *   付与（{@code sys_user_role.company_id}）に持たない → 403 / {@code code=3001} / {@code MSG-COM-030}。</li>
 * </ul>
 *
 * <p>{@code erp.auth.trust-preset-context=true}（テストのみ）のときは、トークンがなくても既に設定済みの
 * LoginContext を受け入れる（既存の MockMvc テスト用）。本番既定は false。</p>
 */
@Component
public class AuthInterceptor implements HandlerInterceptor {

    static final int UNAUTHENTICATED = 2001;
    static final String MSG_UNAUTHENTICATED = "MSG-COM-020";
    static final int FORBIDDEN = 3001;
    static final String MSG_FORBIDDEN = "MSG-COM-030";
    private static final String RESTORE = AuthInterceptor.class.getName() + ".restore";

    private record Previous(LoginContext.LoginUser login, Long tenant) {
    }

    private final UserPermissionService permissions;
    private final boolean trustPresetContext;

    public AuthInterceptor(UserPermissionService permissions,
                           TrustPresetContextPolicy trustPolicy) {
        this.permissions = permissions;
        this.trustPresetContext = trustPolicy.enabled();
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        LoginContext.LoginUser user = resolve(request);
        if (handler instanceof HandlerMethod hm) {
            RequirePermission rp = AnnotatedElementUtils.findMergedAnnotation(hm.getMethod(), RequirePermission.class);
            if (rp == null) {
                rp = AnnotatedElementUtils.findMergedAnnotation(hm.getBeanType(), RequirePermission.class);
            }
            if (rp != null && !permissions.permissionCodes(user.userId(), user.companyId()).contains(rp.value())) {
                throw new BizException(FORBIDDEN, MSG_FORBIDDEN, "您没有执行该操作的权限，请联系管理员。");
            }
        }
        return true;
    }

    private LoginContext.LoginUser resolve(HttpServletRequest request) {
        Optional<AuthSessions.SessionUser> session = AuthSessions.current();
        if (session.isPresent()) {
            AuthSessions.SessionUser s = session.get();
            request.setAttribute(RESTORE, new Previous(LoginContext.current().orElse(null),
                    TenantContext.current().isPresent() ? TenantContext.current().getAsLong() : null));
            LoginContext.LoginUser user = new LoginContext.LoginUser(s.userId(), s.companyId());
            TenantContext.set(s.tenantId());
            LoginContext.set(user);
            return user;
        }
        if (trustPresetContext && LoginContext.current().isPresent()) {
            return LoginContext.current().get();
        }
        throw new BizException(UNAUTHENTICATED, MSG_UNAUTHENTICATED, "登录已过期，请重新登录。");
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        if (request.getAttribute(RESTORE) instanceof Previous p) {
            if (p.login() == null) {
                LoginContext.clear();
            } else {
                LoginContext.set(p.login());
            }
            if (p.tenant() == null) {
                TenantContext.clear();
            } else {
                TenantContext.set(p.tenant());
            }
        }
    }
}
