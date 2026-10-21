package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.common.WorkflowProcessCompleted;
import com.stellar.erp.production.ProductionWorkflowCallback.Outcome;
import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;

/**
 * E32 購読（{@link ProductionWorkflowCallback}）：工单 承認 20→25・却下／強制終了 20→10（AC-PRD-20）、
 * 超産申請 承認 20→30（allowed_qty +request_qty）・却下 →40・強制終了 →90（AC-PRD-21）、冪等・並行・租户隔離。
 */
@DbIntegrationTest
class ProductionWorkflowCallbackIntegrationTest {

    static final long TENANT = 317L, TENANT2 = 318L, CO = 83L, CREATOR = 7901L;
    static final long WO = 987101, WO_T2 = 987102, OPA = 987201, LINE = 987041;

    @Autowired PostgreSQLContainer pg;
    @Autowired ProductionWorkflowCallback callback;

    static JdbcTemplate owner;

    @BeforeEach
    void seed() {
        if (owner == null) {
            owner = OwnerJdbc.of(pg);
        }
        cleanup();
        for (long t : new long[] {TENANT, TENANT2}) {
            long off = t == TENANT ? 0 : 500;
            owner.execute(String.format("""
                INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf)
                  VALUES (%2$d, %1$d, 83, 'W1', 'W', '/W1/', 1, TRUE);
                INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status)
                  VALUES (%3$d, %1$d, 83, '9870000011', 'W 成品', 10, %2$d, 's', 'PCE', 20, 1);
                INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name) VALUES (%4$d, %1$d, 83, 'F83', '工厂83');
                INSERT INTO prd_work_center (id, tenant_id, company_id, work_center_code, work_center_name, factory_id)
                  VALUES (%5$d, %1$d, 83, 'WC83', '組立', %4$d);
                """, t, 987001 + off, 987011 + off, 987021 + off, 987081 + off));
        }
        insertWorkOrder(TENANT, WO, 0);
        insertWorkOrder(TENANT2, WO_T2, 500);
        owner.execute("""
            INSERT INTO mdm_customer (id, tenant_id, company_id, customer_code, customer_name, customer_type, tax_no, owner_user_id, payment_term_code, settlement_method_code)
              VALUES (987031, 317, 83, 'C987031', 'W 客户', 10, '91320000000000000X', 1, 'NET30', 'TT');
            INSERT INTO sal_sales_order (id, tenant_id, company_id, sales_order_no, order_date, customer_id, customer_code, customer_name,
                                         delivery_address, sales_department_id, owner_user_id, payment_term_code, delivery_date, warehouse_id, order_status)
              VALUES (987031, 317, 83, 'SO-W-83', DATE '2026-10-01', 987031, 'C987031', 'W', 'addr', 1, 1, 'NET30', DATE '2026-11-30', 1, 25);
            INSERT INTO sal_sales_order_line (id, tenant_id, company_id, sales_order_id, line_no, material_id, material_code, material_name,
                                              ordered_qty, uom_code, base_uom_code, base_qty, unit_price, tax_code, tax_rate, delivery_date, warehouse_id,
                                              completion_over_rate, allowed_qty, completed_qty)
              VALUES (987041, 317, 83, 987031, 10, 987011, '9870000011', 'W', 100, 'PCE', 'PCE', 100, 1, 'VAT13-OUT', 13, DATE '2026-11-30', 1, 0.05, 105, 0);
            INSERT INTO sys_param (id, tenant_id, company_id, param_key, param_name, param_group, param_value, value_type)
              VALUES (987091, 317, 83, 'prd.overproduction_max_rate', '超产申请上限率', 'prd', '0.5000', 3);
            INSERT INTO prd_overproduction_approval (id, tenant_id, company_id, approval_no, sales_order_line_id, work_order_id, material_id,
                                                      request_qty, approval_status, sales_order_id, current_allowed_qty, requested_by, requested_at)
              VALUES (987201, 317, 83, 'OPA-W-1', 987041, NULL, 987011, 7, 20, 987031, 105, 7901, now());
            """);
    }

    void insertWorkOrder(long tenant, long id, long off) {
        owner.update("""
            INSERT INTO prd_work_order (id, tenant_id, company_id, work_order_no, material_id, material_code, material_name,
                uom_code, factory_id, order_qty, planned_start_date, planned_end_date, order_status, over_receipt_rate,
                created_by, submitted_at)
            VALUES (?, ?, 83, ?, ?, '9870000011', 'W 成品', 'PCE', ?, 10, DATE '2026-11-01', DATE '2026-11-30', 20, 0.05, ?, now())
            """, id, tenant, "WO-W-" + id, 987011 + off, 987021 + off, CREATOR);
        owner.update("""
            INSERT INTO prd_work_order_operation (id, tenant_id, company_id, work_order_id, operation_seq, operation_code,
                operation_name, work_center_id, work_center_code, work_center_name, planned_qty, planned_start_date, planned_end_date)
            VALUES (?, ?, 83, ?, 10, 'OP10', '組立', ?, 'WC83', '組立', 10, DATE '2026-11-01', DATE '2026-11-30')
            """, id + 1000, tenant, id, 987081 + off);
    }

    @AfterEach
    void tearDown() {
        cleanup();
        LoginContext.clear();
        TenantContext.clear();
    }

    @AfterAll
    static void close() {
        if (owner != null) {
            ((SingleConnectionDataSource) owner.getDataSource()).destroy();
            owner = null;
        }
    }

    void cleanup() {
        owner.execute("""
            DELETE FROM sys_event_consume_log WHERE tenant_id IN (317, 318);
            DELETE FROM prd_overproduction_approval WHERE tenant_id IN (317, 318);
            DELETE FROM prd_work_order_operation WHERE tenant_id IN (317, 318);
            DELETE FROM prd_work_order WHERE tenant_id IN (317, 318);
            DELETE FROM prd_work_center WHERE tenant_id IN (317, 318);
            DELETE FROM sys_param WHERE tenant_id IN (317, 318);
            DELETE FROM sal_sales_order_line WHERE tenant_id IN (317, 318);
            DELETE FROM sal_sales_order WHERE tenant_id IN (317, 318);
            DELETE FROM mdm_customer WHERE tenant_id IN (317, 318);
            DELETE FROM mdm_factory WHERE tenant_id IN (317, 318);
            DELETE FROM mdm_material WHERE tenant_id IN (317, 318);
            DELETE FROM mdm_material_category WHERE tenant_id IN (317, 318);
            """);
    }

    static WorkflowProcessCompleted e32(UUID id, long tenant, String type, long businessId, String result) {
        return new WorkflowProcessCompleted(id, tenant, CO, "pi-" + businessId, type, businessId, "NO-" + businessId,
                result, OffsetDateTime.parse("2026-10-21T15:00:00+08:00"));
    }

    static WorkflowProcessCompleted wo(String result) {
        return e32(UUID.randomUUID(), TENANT, WorkOrderApprovalService.BUSINESS_TYPE, WO, result);
    }

    static WorkflowProcessCompleted opa(String result) {
        return e32(UUID.randomUUID(), TENANT, OverproductionApprovalService.BUSINESS_TYPE, OPA, result);
    }

    Map<String, Object> woRow(long id) {
        return owner.queryForMap("SELECT order_status, version, approved_by, approved_at FROM prd_work_order WHERE id = ?", id);
    }

    Map<String, Object> opaRow() {
        return owner.queryForMap("SELECT approval_status, version, approved_by FROM prd_overproduction_approval WHERE id = ?", OPA);
    }

    BigDecimal lineAllowed() {
        return owner.queryForObject("SELECT allowed_qty FROM sal_sales_order_line WHERE id = ?", BigDecimal.class, LINE);
    }

    long consumed() {
        return owner.queryForObject("SELECT count(*) FROM sys_event_consume_log WHERE tenant_id IN (317, 318)", Long.class);
    }

    static int num(Object o) {
        return ((Number) o).intValue();
    }

    static int bizCode(Throwable t) {
        return ((BizException) t).getCode();
    }

    // ------------------------------------------------------------------ 工单（AC-PRD-20）

    @Test
    void workOrderApprovedGoesTo25AndReplayIsIdempotent() {
        WorkflowProcessCompleted ev = wo("APPROVED");
        assertThat(callback.onProcessCompleted(ev)).isEqualTo(Outcome.APPLIED);
        Map<String, Object> r = woRow(WO);
        assertThat(num(r.get("order_status"))).isEqualTo(25);
        assertThat(num(r.get("version"))).isEqualTo(1);
        assertThat(r.get("approved_at")).isNotNull();
        assertThat(num(r.get("approved_by"))).isZero();   // E32 に承認者なし → system(0)（待定）
        // 同一イベント再受信 → 重複排除。別イベントでも同一結果なら状態確認でスキップ。いずれも version 不変
        assertThat(callback.onProcessCompleted(ev)).isEqualTo(Outcome.DUPLICATE_EVENT);
        assertThat(callback.onProcessCompleted(wo("APPROVED"))).isEqualTo(Outcome.ALREADY_APPLIED);
        assertThat(num(woRow(WO).get("version"))).isEqualTo(1);
        // 承認済に却下が届くのは状態不正 4002（消費記録もロールバック）
        assertThatThrownBy(() -> callback.onProcessCompleted(wo("REJECTED")))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(4002));
        assertThat(consumed()).isEqualTo(2);
    }

    @Test
    void workOrderRejectedAndTerminatedReturnToDraft() {
        assertThat(callback.onProcessCompleted(wo("REJECTED"))).isEqualTo(Outcome.APPLIED);
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(10);
        assertThat(num(woRow(WO).get("version"))).isEqualTo(1);
        assertThat(callback.onProcessCompleted(wo("REJECTED"))).isEqualTo(Outcome.ALREADY_APPLIED);
        // 再提出（10→20）後の強制終了も 10（90 にしない）
        owner.update("UPDATE prd_work_order SET order_status = 20 WHERE id = ?", WO);
        assertThat(callback.onProcessCompleted(wo("TERMINATED"))).isEqualTo(Outcome.APPLIED);
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(10);
        assertThat(num(woRow(WO).get("version"))).isEqualTo(2);
    }

    @Test
    void workOrderUnknownResultOrWrongStateIs4002() {
        assertThatThrownBy(() -> callback.onProcessCompleted(wo("WITHDRAWN")))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(4002));
        owner.update("UPDATE prd_work_order SET order_status = 30 WHERE id = ?", WO);
        assertThatThrownBy(() -> callback.onProcessCompleted(wo("TERMINATED")))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(4002));
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(30);
        assertThat(consumed()).isZero();
    }

    // ------------------------------------------------------------------ 超産申請（AC-PRD-21）

    @Test
    void overproductionApprovedGoesTo30AndAddsAllowedQty() {
        assertThat(callback.onProcessCompleted(opa("APPROVED"))).isEqualTo(Outcome.APPLIED);
        assertThat(num(opaRow().get("approval_status"))).isEqualTo(30);
        assertThat(num(opaRow().get("version"))).isEqualTo(1);
        assertThat(lineAllowed()).isEqualByComparingTo("112");
        WorkflowProcessCompleted again = opa("APPROVED");
        assertThat(callback.onProcessCompleted(again)).isEqualTo(Outcome.ALREADY_APPLIED);
        assertThat(callback.onProcessCompleted(again)).isEqualTo(Outcome.DUPLICATE_EVENT);
        assertThat(lineAllowed()).isEqualByComparingTo("112");
        assertThat(num(opaRow().get("version"))).isEqualTo(1);
        assertThatThrownBy(() -> callback.onProcessCompleted(opa("TERMINATED")))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(60101));
    }

    @Test
    void overproductionRejectedIs40AndTerminatedIs90WithoutAllowedQtyChange() {
        assertThat(callback.onProcessCompleted(opa("REJECTED"))).isEqualTo(Outcome.APPLIED);
        assertThat(num(opaRow().get("approval_status"))).isEqualTo(40);
        assertThat(lineAllowed()).isEqualByComparingTo("105");
        owner.update("UPDATE prd_overproduction_approval SET approval_status = 20 WHERE id = ?", OPA);
        assertThat(callback.onProcessCompleted(opa("TERMINATED"))).isEqualTo(Outcome.APPLIED);
        assertThat(num(opaRow().get("approval_status"))).isEqualTo(90);
        assertThat(lineAllowed()).isEqualByComparingTo("105");
        assertThatThrownBy(() -> callback.onProcessCompleted(opa("APPROVED")))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(60101));
        assertThat(lineAllowed()).isEqualByComparingTo("105");
    }

    // ------------------------------------------------------------------ 並行（version）

    @Test
    void concurrentConflictingResultsApplyExactlyOnce() throws Exception {
        List<Object> results = race(wo("APPROVED"), wo("TERMINATED"), wo("APPROVED"), wo("REJECTED"));
        long applied = results.stream().filter(o -> o == Outcome.APPLIED).count();
        assertThat(applied).as("%s", results).isEqualTo(1);
        Map<String, Object> r = woRow(WO);
        assertThat(num(r.get("version"))).isEqualTo(1);
        int status = num(r.get("order_status"));
        assertThat(status).isIn(10, 25);
        // 負けた側は 4002（別遷移）または ALREADY_APPLIED（同一遷移）。version 競合 4003 にはならない（行ロックで直列化）
        assertThat(results).allMatch(o -> o == Outcome.APPLIED || o == Outcome.ALREADY_APPLIED || Integer.valueOf(4002).equals(o));
    }

    @Test
    void concurrentSameEventIsConsumedOnce() throws Exception {
        UUID id = UUID.randomUUID();
        WorkflowProcessCompleted ev = e32(id, TENANT, OverproductionApprovalService.BUSINESS_TYPE, OPA, "APPROVED");
        List<Object> results = race(ev, ev, ev, ev);
        assertThat(results.stream().filter(o -> o == Outcome.APPLIED).count()).as("%s", results).isEqualTo(1);
        assertThat(results).filteredOn(o -> o != Outcome.APPLIED).containsOnly(Outcome.DUPLICATE_EVENT);
        assertThat(lineAllowed()).isEqualByComparingTo("112");
        assertThat(num(opaRow().get("version"))).isEqualTo(1);
    }

    List<Object> race(WorkflowProcessCompleted... events) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(events.length);
        CountDownLatch start = new CountDownLatch(1);
        try {
            List<Future<Object>> fs = new ArrayList<>();
            for (WorkflowProcessCompleted ev : events) {
                fs.add(pool.submit(() -> {
                    start.await();
                    try {
                        return callback.onProcessCompleted(ev);
                    } catch (BizException ex) {
                        return ex.getCode();
                    }
                }));
            }
            start.countDown();
            List<Object> out = new ArrayList<>();
            for (Future<Object> f : fs) {
                out.add(f.get());
            }
            return out;
        } finally {
            pool.shutdownNow();
        }
    }

    // ------------------------------------------------------------------ 租户隔離

    @Test
    void tenantIsolation() {
        // テナント 317 のイベントでテナント 318 の工单 id を指す → 見えない（4001）、318 側は不変、消費記録も残らない
        assertThatThrownBy(() -> callback.onProcessCompleted(
                e32(UUID.randomUUID(), TENANT, WorkOrderApprovalService.BUSINESS_TYPE, WO_T2, "APPROVED")))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(4001));
        assertThat(num(woRow(WO_T2).get("order_status"))).isEqualTo(20);
        assertThat(consumed()).isZero();
        // 同じ eventId でもテナントが違えば別イベント（uk は tenant_id 先頭）
        UUID shared = UUID.randomUUID();
        assertThat(callback.onProcessCompleted(e32(shared, TENANT2, WorkOrderApprovalService.BUSINESS_TYPE, WO_T2, "APPROVED")))
                .isEqualTo(Outcome.APPLIED);
        assertThat(callback.onProcessCompleted(e32(shared, TENANT, WorkOrderApprovalService.BUSINESS_TYPE, WO, "REJECTED")))
                .isEqualTo(Outcome.APPLIED);
        assertThat(num(woRow(WO_T2).get("order_status"))).isEqualTo(25);
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(10);
        // 呼出し元のコンテキストは復元される
        assertThat(TenantContext.current()).isEmpty();
        assertThat(LoginContext.current()).isEmpty();
    }
}
