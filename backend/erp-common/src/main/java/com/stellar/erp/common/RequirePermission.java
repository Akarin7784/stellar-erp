package com.stellar.erp.common;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 接口所需权限码（00-common 03 §4：权限必须在服务端校验）。
 *
 * <p>由 erp-boot 的 {@code AuthInterceptor} 校验：当前用户的权限码（sys_user_role → sys_role → sys_role_permission）
 * 不含 {@link #value()} 时返回 403 / 3001 / MSG-COM-030。方法上的注解优先于类上的注解。</p>
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
public @interface RequirePermission {

    /** 权限码，例 {@code production:overproduction-approval:view}。 */
    String value();
}
