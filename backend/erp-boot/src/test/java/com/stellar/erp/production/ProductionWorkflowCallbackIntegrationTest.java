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
import java.util.concurrent.TimeUnit;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
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
 * E32 購読（{@link ProductionWorkflowCallback}／{@link ProductionWorkflowEventListener}）：
 * 工单・超産の状態遷移、approverUserId、業務検証失敗の FAILED 記録、Modulith listener、冪等・並行・租户隔離。
 */
@DbIntegrationTest
class ProductionWorkflowCallbackIntegrationTest {

    static final long TENANT = 317L, TENANT2 = 318L, CO = 83L, CREATOR = 7901L, APPROVER = 7902L;
    static final long WO = 987101, WO_T2 = 987102, OPA = 987201, LINE = 987041;

    @Autowired PostgreSQLContainer pg;
    @Autowired ProductionWorkflowCallback callback;
    @Autowired ApplicationEventPublisher events;
    @Autowired org.springframework.transaction.PlatformTransactionManager tm;
    @Autowired ProductionWorkflowEventListener listener;

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
        insertWorkOrder(TENANT, WO, 0, true);
        insertWorkOrder(TENANT2, WO_T2, 500, true);
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

    void insertWorkOrder(long tenant, long id, long off, boolean withOp) {
        owner.update("""
            INSERT INTO prd_work_order (id, tenant_id, company_id, work_order_no, material_id, material_code, material_name,
                uom_code, factory_id, order_qty, planned_start_date, planned_end_date, order_status, over_receipt_rate,
                created_by, submitted_at)
            VALUES (?, ?, 83, ?, ?, '9870000011', 'W 成品', 'PCE', ?, 10, DATE '2026-11-01', DATE '2026-11-30', 20, 0.05, ?, now())
            """, id, tenant, "WO-W-" + id, 987011 + off, 987021 + off, CREATOR);
        if (withOp) {
            owner.update("""
                INSERT INTO prd_work_order_operation (id, tenant_id, company_id, work_order_id, operation_seq, operation_code,
                    operation_name, work_center_id, work_center_code, work_center_name, planned_qty, planned_start_date, planned_end_date)
                VALUES (?, ?, 83, ?, 10, 'OP10', '組立', ?, 'WC83', '組立', 10, DATE '2026-11-01', DATE '2026-11-30')
                """, id + 1000, tenant, id, 987081 + off);
        }
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

    static WorkflowProcessCompleted e32(UUID id, long tenant, String type, long businessId, String result,
                                        Long approver, String comment) {
        return new WorkflowProcessCompleted(id, tenant, CO, "pi-" + businessId, type, businessId, "NO-" + businessId,
                result, OffsetDateTime.parse("2026-10-21T15:00:00+08:00"), approver, comment);
    }

    static WorkflowProcessCompleted wo(String result) {
        return e32(UUID.randomUUID(), TENANT, WorkOrderApprovalService.BUSINESS_TYPE, WO, result, APPROVER, null);
    }

    static WorkflowProcessCompleted opa(String result) {
        return e32(UUID.randomUUID(), TENANT, OverproductionApprovalService.BUSINESS_TYPE, OPA, result, APPROVER, null);
    }

    Map<String, Object> woRow(long id) {
        return owner.queryForMap("SELECT order_status, version, approved_by, approved_at FROM prd_work_order WHERE id = ?", id);
    }

    Map<String, Object> opaRow() {
        return owner.queryForMap(
                "SELECT approval_status, version, approved_by, reject_reason FROM prd_overproduction_approval WHERE id = ?", OPA);
    }

    BigDecimal lineAllowed() {
        return owner.queryForObject("SELECT allowed_qty FROM sal_sales_order_line WHERE id = ?", BigDecimal.class, LINE);
    }

    Map<String, Object> consume(UUID eventId) {
        List<Map<String, Object>> rows = owner.queryForList(
                "SELECT consume_status, error_message, retry_count FROM sys_event_consume_log WHERE event_id = ?", eventId);
        return rows.isEmpty() ? null : rows.get(0);
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
        assertThat(num(r.get("approved_by"))).isEqualTo((int) APPROVER);
        assertThat(num(consume(ev.eventId()).get("consume_status"))).isEqualTo(1);
        assertThat(callback.onProcessCompleted(ev)).isEqualTo(Outcome.DUPLICATE_EVENT);
        assertThat(callback.onProcessCompleted(wo("APPROVED"))).isEqualTo(Outcome.ALREADY_APPLIED);
        assertThat(num(woRow(WO).get("version"))).isEqualTo(1);
        assertThatThrownBy(() -> callback.onProcessCompleted(wo("REJECTED")))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(4002));
    }

    @Test
    void workOrderRejectedAndTerminatedReturnToDraft() {
        assertThat(callback.onProcessCompleted(wo("REJECTED"))).isEqualTo(Outcome.APPLIED);
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(10);
        assertThat(callback.onProcessCompleted(wo("REJECTED"))).isEqualTo(Outcome.ALREADY_APPLIED);
        owner.update("UPDATE prd_work_order SET order_status = 20 WHERE id = ?", WO);
        assertThat(callback.onProcessCompleted(wo("TERMINATED"))).isEqualTo(Outcome.APPLIED);
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(10);
    }

    @Test
    void workOrderUnknownResultOrWrongStateIs4002() {
        assertThatThrownBy(() -> callback.onProcessCompleted(wo("WITHDRAWN")))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(4002));
        owner.update("UPDATE prd_work_order SET order_status = 30 WHERE id = ?", WO);
        assertThatThrownBy(() -> callback.onProcessCompleted(wo("TERMINATED")))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(4002));
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(30);
    }

    // ------------------------------------------------------------------ 1) approverUserId

    @Test
    void missingApproverUserIdIsRejected() {
        WorkflowProcessCompleted ev = e32(UUID.randomUUID(), TENANT, WorkOrderApprovalService.BUSINESS_TYPE, WO,
                "APPROVED", null, null);
        assertThatThrownBy(() -> callback.onProcessCompleted(ev))
                .satisfies(t -> {
                    assertThat(bizCode(t)).isEqualTo(1001);
                    assertThat(((BizException) t).getMsgId()).isEqualTo("MSG-COM-040");
                });
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(20);
        assertThat(consume(ev.eventId())).isNull();
    }

    @Test
    void approverSameAsSubmitterIs60005() {
        WorkflowProcessCompleted ev = e32(UUID.randomUUID(), TENANT, WorkOrderApprovalService.BUSINESS_TYPE, WO,
                "APPROVED", CREATOR, null);
        assertThatThrownBy(() -> callback.onProcessCompleted(ev))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(60005));
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(20);
        assertThat(num(consume(ev.eventId()).get("consume_status"))).isZero();
        // 超産も申請者＝承認者 → 60005
        WorkflowProcessCompleted opaEv = e32(UUID.randomUUID(), TENANT, OverproductionApprovalService.BUSINESS_TYPE, OPA,
                "APPROVED", CREATOR, null);
        assertThatThrownBy(() -> callback.onProcessCompleted(opaEv))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(60005));
        assertThat(num(opaRow().get("approval_status"))).isEqualTo(20);
        assertThat(lineAllowed()).isEqualByComparingTo("105");
    }

    // ------------------------------------------------------------------ 2) 業務検証失敗 → FAILED、再送も失敗

    @Test
    void businessValidationFailureLeavesDocumentAndRecordsFailedConsume() {
        owner.update("DELETE FROM prd_work_order_operation WHERE work_order_id = ?", WO);
        UUID eventId = UUID.randomUUID();
        WorkflowProcessCompleted ev = e32(eventId, TENANT, WorkOrderApprovalService.BUSINESS_TYPE, WO, "APPROVED",
                APPROVER, null);
        assertThatThrownBy(() -> callback.onProcessCompleted(ev))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(60021));
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(20);
        assertThat(num(woRow(WO).get("version"))).isZero();
        Map<String, Object> log = consume(eventId);
        assertThat(log).isNotNull();
        assertThat(num(log.get("consume_status"))).isEqualTo(0);
        assertThat(log.get("error_message")).isNotNull();
        assertThat((String) log.get("error_message")).contains("工艺");
        // 同一 eventId 再送：工序はまだ無い → 再び 60021、伝票不変、consume_status は 0 のまま（INSERT せず UPDATE）
        assertThatThrownBy(() -> callback.onProcessCompleted(ev))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(60021));
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(20);
        assertThat(num(woRow(WO).get("version"))).isZero();
        assertThat(num(consume(eventId).get("consume_status"))).isEqualTo(0);
        assertThat(consume(eventId).get("error_message")).isNotNull();
        assertThat(num(consume(eventId).get("retry_count"))).isGreaterThanOrEqualTo(1);
        assertThat(owner.queryForObject(
                "SELECT count(*) FROM sys_event_consume_log WHERE event_id = ?", Integer.class, eventId)).isEqualTo(1);
        // 直したうえで同一 eventId を再送 → 0→1 UPDATE（新行を INSERT しない）
        owner.update("""
            INSERT INTO prd_work_order_operation (id, tenant_id, company_id, work_order_id, operation_seq, operation_code,
                operation_name, work_center_id, work_center_code, work_center_name, planned_qty, planned_start_date, planned_end_date)
            VALUES (?, 317, 83, ?, 10, 'OP10', '組立', 987081, 'WC83', '組立', 10, DATE '2026-11-01', DATE '2026-11-30')
            """, WO + 1000, WO);
        assertThat(callback.onProcessCompleted(ev)).isEqualTo(Outcome.APPLIED);
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(25);
        assertThat(num(consume(eventId).get("consume_status"))).isEqualTo(1);
        assertThat(consume(eventId).get("error_message")).isNull();
        assertThat(owner.queryForObject(
                "SELECT count(*) FROM sys_event_consume_log WHERE event_id = ?", Integer.class, eventId)).isEqualTo(1);
    }

    // ------------------------------------------------------------------ 3) 超産 REJECTED comment → reject_reason

    @Test
    void overproductionRejectedWritesCommentToRejectReason() {
        assertThat(callback.onProcessCompleted(
                e32(UUID.randomUUID(), TENANT, OverproductionApprovalService.BUSINESS_TYPE, OPA, "REJECTED", APPROVER,
                        "  数量过大  "))).isEqualTo(Outcome.APPLIED);
        assertThat(num(opaRow().get("approval_status"))).isEqualTo(40);
        assertThat(opaRow().get("reject_reason")).isEqualTo("数量过大");
        assertThat(lineAllowed()).isEqualByComparingTo("105");
        owner.update("UPDATE prd_overproduction_approval SET approval_status = 20, reject_reason = NULL, version = 0 WHERE id = ?",
                OPA);
        assertThat(callback.onProcessCompleted(
                e32(UUID.randomUUID(), TENANT, OverproductionApprovalService.BUSINESS_TYPE, OPA, "REJECTED", APPROVER,
                        "   "))).isEqualTo(Outcome.APPLIED);
        assertThat(opaRow().get("reject_reason")).isNull();
        owner.update("UPDATE prd_overproduction_approval SET approval_status = 20, version = 0 WHERE id = ?", OPA);
        assertThat(callback.onProcessCompleted(
                e32(UUID.randomUUID(), TENANT, OverproductionApprovalService.BUSINESS_TYPE, OPA, "REJECTED", APPROVER,
                        null))).isEqualTo(Outcome.APPLIED);
        assertThat(opaRow().get("reject_reason")).isNull();
    }

    @Test
    void overproductionApprovedGoesTo30AndAddsAllowedQty() {
        assertThat(callback.onProcessCompleted(opa("APPROVED"))).isEqualTo(Outcome.APPLIED);
        assertThat(num(opaRow().get("approval_status"))).isEqualTo(30);
        assertThat(lineAllowed()).isEqualByComparingTo("112");
        WorkflowProcessCompleted again = opa("APPROVED");
        assertThat(callback.onProcessCompleted(again)).isEqualTo(Outcome.ALREADY_APPLIED);
        assertThat(callback.onProcessCompleted(again)).isEqualTo(Outcome.DUPLICATE_EVENT);
        assertThat(lineAllowed()).isEqualByComparingTo("112");
    }

    @Test
    void overproductionTerminatedIs90WithoutAllowedQtyChange() {
        assertThat(callback.onProcessCompleted(opa("TERMINATED"))).isEqualTo(Outcome.APPLIED);
        assertThat(num(opaRow().get("approval_status"))).isEqualTo(90);
        assertThat(lineAllowed()).isEqualByComparingTo("105");
    }

    // ------------------------------------------------------------------ 4) Modulith listener

    @Test
    void modulithListenerReceivesE32AndApplies() throws Exception {
        WorkflowProcessCompleted ev = wo("APPROVED");
        // 1) Modulith リスナー Bean 経由（ApplicationModuleListener → onProcessCompleted）
        assertThat(listener).isNotNull();
        listener.onProcessCompleted(ev);
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(25);
        assertThat(num(woRow(WO).get("approved_by"))).isEqualTo((int) APPROVER);
        assertThat(num(consume(ev.eventId()).get("consume_status"))).isEqualTo(1);
        // 2) ApplicationEventPublisher：業務 TX 内 publish → コミット後に @TransactionalEventListener が発火
        owner.update("UPDATE prd_work_order SET order_status = 20, version = 0, approved_by = NULL, approved_at = NULL WHERE id = ?", WO);
        owner.update("DELETE FROM sys_event_consume_log WHERE event_id = ?", ev.eventId());
        WorkflowProcessCompleted ev2 = wo("APPROVED");
        var tx = new org.springframework.transaction.support.TransactionTemplate(tm);
        tx.executeWithoutResult(st -> {
            TenantContext.set(TENANT);
            events.publishEvent(ev2);
        });
        long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5);
        while (System.nanoTime() < deadline && num(woRow(WO).get("order_status")) != 25) {
            Thread.sleep(50);
        }
        assertThat(num(woRow(WO).get("order_status")))
                .as("ApplicationModuleListener should apply after TX commit via ApplicationEventPublisher")
                .isEqualTo(25);
        assertThat(num(consume(ev2.eventId()).get("consume_status"))).isEqualTo(1);
    }

    // ------------------------------------------------------------------ 並行・租户

    @Test
    void concurrentConflictingResultsApplyExactlyOnce() throws Exception {
        List<Object> results = race(wo("APPROVED"), wo("TERMINATED"), wo("APPROVED"), wo("REJECTED"));
        long applied = results.stream().filter(o -> o == Outcome.APPLIED).count();
        assertThat(applied).as("%s", results).isEqualTo(1);
        assertThat(num(woRow(WO).get("version"))).isEqualTo(1);
        assertThat(num(woRow(WO).get("order_status"))).isIn(10, 25);
    }

    @Test
    void concurrentSameEventIsConsumedOnce() throws Exception {
        UUID id = UUID.randomUUID();
        WorkflowProcessCompleted ev = e32(id, TENANT, OverproductionApprovalService.BUSINESS_TYPE, OPA, "APPROVED",
                APPROVER, null);
        List<Object> results = race(ev, ev, ev, ev);
        assertThat(results.stream().filter(o -> o == Outcome.APPLIED).count()).as("%s", results).isEqualTo(1);
        assertThat(results).as("%s", results).allMatch(o -> o == Outcome.APPLIED || o == Outcome.DUPLICATE_EVENT
                || o == Outcome.ALREADY_APPLIED);
        assertThat(lineAllowed()).isEqualByComparingTo("112");
        assertThat(num(opaRow().get("version"))).isEqualTo(1);
        assertThat(num(consume(id).get("consume_status"))).isEqualTo(1);
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

    @Test
    void tenantIsolation() {
        assertThatThrownBy(() -> callback.onProcessCompleted(
                e32(UUID.randomUUID(), TENANT, WorkOrderApprovalService.BUSINESS_TYPE, WO_T2, "APPROVED", APPROVER, null)))
                .satisfies(t -> assertThat(bizCode(t)).isEqualTo(4001));
        assertThat(num(woRow(WO_T2).get("order_status"))).isEqualTo(20);
        UUID shared = UUID.randomUUID();
        assertThat(callback.onProcessCompleted(
                e32(shared, TENANT2, WorkOrderApprovalService.BUSINESS_TYPE, WO_T2, "APPROVED", APPROVER, null)))
                .isEqualTo(Outcome.APPLIED);
        assertThat(callback.onProcessCompleted(
                e32(shared, TENANT, WorkOrderApprovalService.BUSINESS_TYPE, WO, "REJECTED", APPROVER, null)))
                .isEqualTo(Outcome.APPLIED);
        assertThat(num(woRow(WO_T2).get("order_status"))).isEqualTo(25);
        assertThat(num(woRow(WO).get("order_status"))).isEqualTo(10);
        assertThat(TenantContext.current()).isEmpty();
        assertThat(LoginContext.current()).isEmpty();
    }
}
