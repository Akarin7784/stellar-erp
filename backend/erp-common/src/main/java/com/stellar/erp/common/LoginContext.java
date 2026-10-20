package com.stellar.erp.common;

import java.util.Optional;
import java.util.function.Supplier;

/**
 * 当前线程的登录上下文（用户 ID + 公司 ID）。
 *
 * <p>01-system 01-auth-login §6（Sa-Token 会话保存 {@code tenantId}/{@code companyId}/{@code factoryId}）落地前，
 * 由调用方（后续的认证拦截器 / 测试）设置。业务代码只从这里取公司，不接受请求体里的 {@code company_id}。</p>
 *
 * <p>未设置时 {@link #require()} 抛出业务码 5000（设定不备，与租户未设置同口径，06-production 91 §9）。</p>
 */
public final class LoginContext {

    /** 登录用户与所属公司。 */
    public record LoginUser(long userId, long companyId) {
    }

    private static final ThreadLocal<LoginUser> CURRENT = new ThreadLocal<>();

    private LoginContext() {
    }

    public static Optional<LoginUser> current() {
        return Optional.ofNullable(CURRENT.get());
    }

    /** 当前登录用户；未设置时抛出 {@link BizException}（5000）。 */
    public static LoginUser require() {
        LoginUser user = CURRENT.get();
        if (user == null) {
            throw new BizException(5000, "未设置登录上下文（公司/用户）");
        }
        return user;
    }

    public static void set(LoginUser user) {
        CURRENT.set(user);
    }

    public static void clear() {
        CURRENT.remove();
    }

    /** 以指定用户执行，结束后恢复原值。 */
    public static <T> T callAs(LoginUser user, Supplier<T> action) {
        LoginUser previous = CURRENT.get();
        CURRENT.set(user);
        try {
            return action.get();
        } finally {
            if (previous == null) {
                CURRENT.remove();
            } else {
                CURRENT.set(previous);
            }
        }
    }
}
