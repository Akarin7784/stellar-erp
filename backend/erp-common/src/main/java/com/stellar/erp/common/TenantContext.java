package com.stellar.erp.common;

import java.util.OptionalLong;
import java.util.function.Supplier;

/**
 * 当前线程的租户上下文。事务开始时由 erp-boot 的 TenantAwareTransactionManager 读取，
 * 以 {@code set_config('app.tenant_id', ?, true)}（等价 SET LOCAL）写入数据库会话，事务结束自动失效。
 *
 * <p>没有默认租户：未设置时 {@link #currentTenantId()} 抛出 {@link IllegalStateException}，
 * 事务管理器也不会写入 app.tenant_id，受 RLS 保护的表在该事务中直接报错（不会静默落到租户 0）。
 * 事务之外（自动提交）执行的 SQL 不会设置 app.tenant_id，受 RLS 保护的表会直接报错，绝不返回全部行。
 */
public final class TenantContext {

    private static final ThreadLocal<Long> CURRENT = new ThreadLocal<>();

    private TenantContext() {
    }

    /** 当前租户；未设置时抛出 {@link IllegalStateException}。 */
    public static long currentTenantId() {
        Long id = CURRENT.get();
        if (id == null) {
            throw new IllegalStateException("未设置租户上下文（TenantContext）");
        }
        return id;
    }

    /** 当前租户（可能未设置）。 */
    public static OptionalLong current() {
        Long id = CURRENT.get();
        return id != null ? OptionalLong.of(id) : OptionalLong.empty();
    }

    public static void set(long tenantId) {
        CURRENT.set(tenantId);
    }

    public static void clear() {
        CURRENT.remove();
    }

    /** 在指定租户下执行，结束后恢复原值。 */
    public static <T> T callAs(long tenantId, Supplier<T> action) {
        Long previous = CURRENT.get();
        CURRENT.set(tenantId);
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

    public static void runAs(long tenantId, Runnable action) {
        callAs(tenantId, () -> {
            action.run();
            return null;
        });
    }
}
