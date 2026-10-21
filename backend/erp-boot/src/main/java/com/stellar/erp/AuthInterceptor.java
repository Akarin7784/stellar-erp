package com.stellar.erp;

import org.springframework.core.annotation.AnnotatedElementUtils;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.RequirePermission;
import com.stellar.erp.system.UserPermissionService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * 认证 + 权限拦截（00-common 03 §3・§4・§6）。
 *
 * <ul>
 *   <li>未登录（{@link LoginContext} 未设置）→ 401 / {@code code=2001} / {@code MSG-COM-020}。</li>
 *   <li>handler 带 {@link RequirePermission} 且当前用户无该权限码 → 403 / {@code code=3001} / {@code MSG-COM-030}。</li>
 * </ul>
 *
 * <p>TODO：Sa-Token 登录（01-system 01-auth-login）落地后，在此之前由 token 解析出用户 / 公司 / 租户并设置
 * {@link LoginContext} / TenantContext。目前只有测试会设置上下文。</p>
 */
@Component
public class AuthInterceptor implements HandlerInterceptor {

    static final int UNAUTHENTICATED = 2001;
    static final String MSG_UNAUTHENTICATED = "MSG-COM-020";
    static final int FORBIDDEN = 3001;
    static final String MSG_FORBIDDEN = "MSG-COM-030";

    private final UserPermissionService permissions;

    public AuthInterceptor(UserPermissionService permissions) {
        this.permissions = permissions;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        LoginContext.LoginUser user = LoginContext.current().orElseThrow(() ->
                new BizException(UNAUTHENTICATED, MSG_UNAUTHENTICATED, "登录已过期，请重新登录。"));
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
}
