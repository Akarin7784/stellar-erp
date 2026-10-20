package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.function.Supplier;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.LoginContext.LoginUser;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.production.SalesOrderLineLookup.SalesOrderLine;
import com.stellar.erp.production.internal.ProductionRepository;
import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;

/**
 * 任务 C：工单登録（over_receipt_rate チェーン快照）+ 超产申请（60103）。
 * 应用数据源为 erp_app（NOBYPASSRLS），数据由 owner 以显式 tenant_id 准备。
 * SAL（T2）未迁移，受注行经 {@link SalesOrderLineLookup} 端口以 Mock 提供。
 */
@DbIntegrationTest
class ProductionCoreIntegrationTest {

    static final long TENANT = 303L;
    static final long COMPANY = 31L;
    static final long OTHER_COMPANY = 32L;
    static final long USER = 7001L;

    static final long CAT_NULL = 993001, CAT_RATE = 993002;
    static final long MAT_NULL = 993011, MAT_RATE = 993012, MAT_ZERO = 993013, MAT_CAT = 993014, MAT_OTHER_CO = 993015;
    static final long FACTORY = 993021;
    static final long SO = 993031, SO_LINE = 993032;

    @Autowired PostgreSQLContainer pg;
    @Autowired WorkOrderService workOrders;
    @Autowired OverproductionApprovalService approvals;
    @Autowired ProductionRepository repo;
    @Autowired TransactionTemplate tx;
    @Autowired WebApplicationContext wac;

    @MockitoBean SalesOrderLineLookup salesOrderLines;

    JdbcTemplate owner;

    @BeforeEach
    void seed() {
        owner = OwnerJdbc.of(pg);
        cleanup();
        owner.execute("""
            INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf, completion_over_rate) VALUES
              (993001, 303, 31, 'C1', '无率分类', '/C1/', 1, TRUE, NULL),
              (993002, 303, 31, 'C2', '分类率',   '/C2/', 1, TRUE, 0.0200);
            INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status, completion_over_rate) VALUES
              (993011, 303, 31, '9930000011', 'M 全 NULL',  10, 993001, 's1', 'PCE', 20, 1, NULL),
              (993012, 303, 31, '9930000012', 'M 物料率',   10, 993002, 's2', 'PCE', 20, 1, 0.0300),
              (993013, 303, 31, '9930000013', 'M 显式 0',   10, 993002, 's3', 'PCE', 20, 1, 0),
              (993014, 303, 31, '9930000014', 'M 继承分类', 10, 993002, 's4', 'PCE', 20, 1, NULL),
              (993015, 303, 32, '9930000015', 'M 其他公司', 10, 993001, 's5', 'PCE', 20, 1, 0.0400);
            INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name) VALUES (993021, 303, 31, 'F31', '工厂31');
            INSERT INTO sys_param (id, tenant_id, company_id, param_key, param_name, param_group, param_value, value_type) VALUES
              (993041, 303, 31, 'prd.completion_over_rate', '完工超收容差', 'prd', '0.0500', 3);
            """);
    }

    @AfterEach
    void tearDown() {
        cleanup();
        LoginContext.clear();
        TenantContext.clear();
    }

    void cleanup() {
        owner.execute("""
            DELETE FROM prd_overproduction_approval WHERE tenant_id = 303;
            DELETE FROM prd_work_order WHERE tenant_id = 303;
            DELETE FROM sys_sequence WHERE tenant_id = 303;
            DELETE FROM sys_param WHERE tenant_id = 303;
            DELETE FROM mdm_factory WHERE tenant_id = 303;
            DELETE FROM mdm_material WHERE tenant_id = 303;
            DELETE FROM mdm_material_category WHERE tenant_id = 303;
            """);
    }

    <T> T asUser(Supplier<T> body) {
        return TenantContext.callAs(TENANT, () -> LoginContext.callAs(new LoginUser(USER, COMPANY), body));
    }

    static WorkOrderCreateCommand cmd(long materialId, Long salesOrderLineId) {
        return new WorkOrderCreateCommand(null, FACTORY, materialId, new BigDecimal("120.0000"), "PCE",
                LocalDate.of(2026, 11, 12), LocalDate.of(2026, 11, 17), null, null, null, salesOrderLineId, null, null);
    }

    Map<String, Object> row(long id) {
        return owner.queryForMap("SELECT * FROM prd_work_order WHERE id = ?", id);
    }

    // ---------------------------------------------------------------- 工单登録

    @Test
    void createSnapshotsRateAndDefaults() {
        WorkOrderCreated created = asUser(() -> workOrders.create(cmd(MAT_RATE, null)));

        Map<String, Object> r = row(created.id());
        assertThat((BigDecimal) r.get("over_receipt_rate")).isEqualByComparingTo("0.03");
        assertThat(r.get("company_id")).isEqualTo(COMPANY);
        assertThat(r.get("tenant_id")).isEqualTo(TENANT);
        assertThat(r.get("order_status")).isEqualTo(10);
        assertThat(r.get("standard_cost")).isNull();
        assertThat(r.get("source_type")).isEqualTo(20);
        assertThat(r.get("material_code")).isEqualTo("9930000012");
        assertThat(r.get("created_by")).isEqualTo(USER);
        assertThat(created.workOrderNo()).matches("WO\\d{6}0001");
        assertThat(created.standardCost()).isNull();

        WorkOrderCreated second = asUser(() -> workOrders.create(cmd(MAT_RATE, null)));
        assertThat(second.workOrderNo()).endsWith("0002");
    }

    @Test
    void explicitZeroOnMaterialIsKept() {
        WorkOrderCreated c = asUser(() -> workOrders.create(cmd(MAT_ZERO, null)));
        assertThat((BigDecimal) row(c.id()).get("over_receipt_rate")).isEqualByComparingTo("0");
    }

    @Test
    void materialNullInheritsCategory() {
        WorkOrderCreated c = asUser(() -> workOrders.create(cmd(MAT_CAT, null)));
        assertThat((BigDecimal) row(c.id()).get("over_receipt_rate")).isEqualByComparingTo("0.02");
    }

    @Test
    void allNullUsesCompanyParam() {
        owner.update("UPDATE sys_param SET param_value = '0.0700' WHERE id = 993041");
        WorkOrderCreated c = asUser(() -> workOrders.create(cmd(MAT_NULL, null)));
        assertThat((BigDecimal) row(c.id()).get("over_receipt_rate")).isEqualByComparingTo("0.07");
    }

    @Test
    void companyParamFallsBackToTenantLevelCompanyZero() {
        owner.execute("""
            DELETE FROM sys_param WHERE id = 993041;
            INSERT INTO sys_param (id, tenant_id, company_id, param_key, param_name, param_group, param_value, value_type)
              VALUES (993042, 303, 0, 'prd.completion_over_rate', '完工超收容差', 'prd', '0.0600', 3);
            """);
        WorkOrderCreated c = asUser(() -> workOrders.create(cmd(MAT_NULL, null)));
        assertThat((BigDecimal) row(c.id()).get("over_receipt_rate")).isEqualByComparingTo("0.06");
    }

    @Test
    void missingCompanyParamIs5000AndNothingInserted() {
        owner.update("DELETE FROM sys_param WHERE tenant_id = 303");
        assertThatThrownBy(() -> asUser(() -> workOrders.create(cmd(MAT_NULL, null))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(5000));
        assertThat(owner.queryForObject("SELECT count(*) FROM prd_work_order WHERE tenant_id = 303", Long.class)).isZero();
    }

    @Test
    void salesOrderLineRateWinsAndIsSnapshot() {
        when(salesOrderLines.find(eq(COMPANY), eq(SO_LINE))).thenReturn(Optional.of(
                new SalesOrderLine(SO_LINE, SO, "SO2610200001", MAT_RATE, new BigDecimal("0.0100"), new BigDecimal("121"))));
        WorkOrderCreated c = asUser(() -> workOrders.create(cmd(MAT_RATE, SO_LINE)));
        Map<String, Object> r = row(c.id());
        assertThat((BigDecimal) r.get("over_receipt_rate")).isEqualByComparingTo("0.01");
        assertThat(r.get("sales_order_line_id")).isEqualTo(SO_LINE);
        assertThat(r.get("sales_order_id")).isEqualTo(SO);
        assertThat((BigDecimal) r.get("allowed_qty")).isEqualByComparingTo("121");
        assertThat(r.get("source_type")).isEqualTo(30);
    }

    @Test
    void salesOrderLineNullRateInheritsMaterial() {
        when(salesOrderLines.find(eq(COMPANY), eq(SO_LINE))).thenReturn(Optional.of(
                new SalesOrderLine(SO_LINE, SO, "SO1", MAT_RATE, null, new BigDecimal("123"))));
        WorkOrderCreated c = asUser(() -> workOrders.create(cmd(MAT_RATE, SO_LINE)));
        assertThat((BigDecimal) row(c.id()).get("over_receipt_rate")).isEqualByComparingTo("0.03");
    }

    @Test
    void materialMismatchWithSalesOrderLineIs60056() {
        when(salesOrderLines.find(eq(COMPANY), eq(SO_LINE))).thenReturn(Optional.of(
                new SalesOrderLine(SO_LINE, SO, "SO1", MAT_NULL, null, new BigDecimal("1"))));
        assertThatThrownBy(() -> asUser(() -> workOrders.create(cmd(MAT_RATE, SO_LINE))))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(60056);
                    assertThat(e.getMsgId()).isEqualTo("MSG-PRD-056");
                });
    }

    @Test
    void materialOfOtherCompanyIsNotFound() {
        assertThatThrownBy(() -> asUser(() -> workOrders.create(cmd(MAT_OTHER_CO, null))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(4001));
    }

    @Test
    void missingLoginContextIs5000() {
        assertThatThrownBy(() -> TenantContext.callAs(TENANT, () -> workOrders.create(cmd(MAT_RATE, null))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(5000));
    }

    @Test
    void apiIgnoresCompanyIdInBodyAndReturns201() throws Exception {
        MockMvc mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(USER, COMPANY));
        mvc.perform(post("/api/production/work-orders").contentType(MediaType.APPLICATION_JSON).content("""
                {"companyId": 32, "company_id": 32, "factoryId": %d, "materialId": %d, "orderQty": "10",
                 "uomCode": "PCE", "plannedStartDate": "2026-11-12", "plannedEndDate": "2026-11-17",
                 "standardCost": "999.000000"}
                """.formatted(FACTORY, MAT_RATE)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.orderStatus").value(10))
                .andExpect(jsonPath("$.data.standardCost").doesNotExist());
        assertThat(owner.queryForObject(
                "SELECT count(*) FROM prd_work_order WHERE tenant_id = 303 AND company_id = 31 AND standard_cost IS NULL",
                Long.class)).isEqualTo(1L);
        assertThat(owner.queryForObject("SELECT count(*) FROM prd_work_order WHERE company_id = 32", Long.class)).isZero();
    }

    @Test
    void apiMaterialMismatchIs422() throws Exception {
        when(salesOrderLines.find(anyLong(), anyLong())).thenReturn(Optional.of(
                new SalesOrderLine(SO_LINE, SO, "SO1", MAT_NULL, null, new BigDecimal("1"))));
        MockMvc mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(USER, COMPANY));
        mvc.perform(post("/api/production/work-orders").contentType(MediaType.APPLICATION_JSON).content("""
                {"factoryId": %d, "materialId": %d, "orderQty": "10", "uomCode": "PCE",
                 "plannedStartDate": "2026-11-12", "plannedEndDate": "2026-11-17", "salesOrderLineId": %d}
                """.formatted(FACTORY, MAT_RATE, SO_LINE)))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60056))
                .andExpect(jsonPath("$.msgId").value("MSG-PRD-056"));
    }

    // ---------------------------------------------------------------- 超产申请

    void stubLine() {
        when(salesOrderLines.find(eq(COMPANY), eq(SO_LINE))).thenReturn(Optional.of(
                new SalesOrderLine(SO_LINE, SO, "SO1", MAT_RATE, null, new BigDecimal("105"))));
    }

    long approvalCount() {
        return owner.queryForObject("SELECT count(*) FROM prd_overproduction_approval WHERE tenant_id = 303", Long.class);
    }

    @ParameterizedTest
    @NullSource
    @ValueSource(strings = {"0", "-5"})
    void invalidRequestQtyIs60103AndNothingInserted(BigDecimal qty) {
        stubLine();
        assertThatThrownBy(() -> asUser(() -> approvals.request(new OverproductionRequestCommand(SO_LINE, null, qty, null))))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(60103);
                    assertThat(e.getMsgId()).isEqualTo("MSG-PRD-103");
                });
        assertThat(approvalCount()).isZero();
        assertThat(owner.queryForObject("SELECT count(*) FROM sys_sequence WHERE tenant_id = 303", Long.class)).isZero();
    }

    @Test
    void validRequestIsSaved() {
        stubLine();
        OverproductionRequested r = asUser(() -> approvals.request(
                new OverproductionRequestCommand(SO_LINE, null, new BigDecimal("3"), "追加")));
        assertThat(r.approvalNo()).matches("OPA\\d{6}0001");
        Map<String, Object> row = owner.queryForMap("SELECT * FROM prd_overproduction_approval WHERE id = ?", r.id());
        assertThat(row.get("company_id")).isEqualTo(COMPANY);
        assertThat((BigDecimal) row.get("request_qty")).isEqualByComparingTo("3");
        assertThat((BigDecimal) row.get("current_allowed_qty")).isEqualByComparingTo("105");
        assertThat(row.get("approval_status")).isEqualTo(10);
        assertThat(row.get("requested_by")).isEqualTo(USER);
        assertThat(row.get("material_id")).isEqualTo(MAT_RATE);
    }

    @Test
    void dbNotNullViolationOnRequestQtyIsRecognised() {
        // 兜底：绕过服务层直接写 NULL，DB 返回 23502；服务层的识别逻辑会把它转换为 60103（不会成为 500）
        assertThatThrownBy(() -> asUser(() -> tx.execute(s -> {
            repo.insertApproval(new ProductionRepository.ApprovalInsert(993099L, COMPANY, USER, "OPA-X", SO, SO_LINE,
                    null, MAT_RATE, null, new BigDecimal("105"), (short) 10, OffsetDateTime.now(), null));
            return null;
        }))).isInstanceOfSatisfying(DataIntegrityViolationException.class,
                e -> assertThat(OverproductionApprovalService.isRequestQtyViolation(e)).isTrue());
    }
}
