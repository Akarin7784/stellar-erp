package com.stellar.erp.db;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.common.TenantContext;
import com.stellar.erp.support.DbIntegrationTest;

/**
 * G2-18 并发用例。pgTAP 单会话无法模拟并发，故用两个线程 / 两个应用连接（erp_app）+ CountDownLatch。
 * 加锁顺序（已定）：先锁受注行，再锁工单；同类行按 id 升序。
 * 不变量：0 <= completed_qty <= allowed_qty；对账视图差异为 0；不出现死锁（SQLSTATE 40P01）。
 */
@DbIntegrationTest
@Disabled("等 T2（销售订单）/ T3（工单）表与 G2-18 存储过程合入")
class G218ConcurrencyTest {

    static final long TENANT = 101L;

    @Autowired JdbcTemplate jdbc;
    @Autowired TransactionTemplate tx;
    @Autowired PostgreSQLContainer pg;

    ExecutorService pool = Executors.newFixedThreadPool(2);

    /** 两个完工同时争抢剩余 allowed_qty：只能一个成功，另一个因 CHECK / 校验失败；completed_qty 不超过 allowed_qty。 */
    @Test
    void twoCompletionsRaceForRemainingAllowedQty() throws Exception {
        // TODO 准备（OwnerJdbc，显式 tenant_id）：受注行 order_qty=100, over_receipt_rate=0.05 → allowed_qty=105, completed_qty=100；
        //      两张工单关联同一受注行。
        CountDownLatch start = new CountDownLatch(1);
        Future<?> a = pool.submit(() -> { await(start); asTenant(() -> null /* TODO 调用报完工过程：工单1 完工 5 */); });
        Future<?> b = pool.submit(() -> { await(start); asTenant(() -> null /* TODO 调用报完工过程：工单2 完工 5 */); });
        start.countDown();
        // TODO 断言：恰好一个成功、一个抛 DataAccessException（非 40P01）；completed_qty == 105；对账视图差异 0
        a.get(30, TimeUnit.SECONDS);
        b.get(30, TimeUnit.SECONDS);
    }

    /** 报完工与受注改量同时进行：无死锁；改量低于已完工时被拒；不变量成立。 */
    @Test
    void completionAndOrderQtyChangeConcurrentlyNoDeadlock() throws Exception {
        // TODO 准备：受注行 order_qty=100, completed_qty=90；工单 1 张。
        // 线程 A：报完工 5（过程内先锁受注行再锁工单）；线程 B：受注变更单把数量改为 92（先锁受注行，再按 id 升序锁关联工单）。
        // 可在过程内插入 pg_sleep 钩子或用第二个 latch 放大交错窗口。
        CountDownLatch start = new CountDownLatch(1);
        Future<?> a = pool.submit(() -> { await(start); asTenant(() -> null /* TODO 报完工 */); });
        Future<?> b = pool.submit(() -> { await(start); asTenant(() -> null /* TODO 受注改量 */); });
        start.countDown();
        // TODO 断言：两者均无 40P01；若 A 先提交则 B 因 92 < 95 被拒；若 B 先提交则 allowed_qty 随之重算且 A 的结果满足 completed_qty <= allowed_qty
        a.get(30, TimeUnit.SECONDS);
        b.get(30, TimeUnit.SECONDS);
    }

    /** 完工退回 / 报废冲销与报完工并发：同一锁内扣减，completed_qty 不为负且对账一致。 */
    @Test
    void reversalAndCompletionConcurrently() {
        // TODO 同上模式
    }

    private <T> T asTenant(java.util.function.Supplier<T> body) {
        return TenantContext.callAs(TENANT, () -> tx.execute(s -> body.get()));
    }

    private static void await(CountDownLatch l) {
        try {
            l.await(10, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
