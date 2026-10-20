package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.testcontainers.postgresql.PostgreSQLContainer;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.common.LoginContext.LoginUser;
import com.stellar.erp.common.TenantContext;
import com.stellar.erp.support.DbIntegrationTest;
import com.stellar.erp.support.OwnerJdbc;

/** 提出→承認→下达の一連、詳細 GET、boms/effective、mdm 選択 API（erp_app + RLS、会社境界）。 */
@DbIntegrationTest
class WorkOrderDetailLookupIntegrationTest {

    static final long TENANT = 305L, CO = 51L, CO2 = 52L, CREATOR = 7201L, APPROVER = 7202L;
    static final long MAT = 995011, COMP = 995012, MAT_CO2 = 995013, FACTORY = 995021, FACTORY_CO2 = 995022;
    static final long WH = 995061;

    @Autowired PostgreSQLContainer pg;
    @Autowired WorkOrderService workOrders;
    @Autowired WorkOrderApprovalService approvals;
    @Autowired WorkOrderReleaseService releases;
    @Autowired WorkOrderQueryService queries;
    @Autowired BomQueryService boms;
    @Autowired WebApplicationContext wac;

    JdbcTemplate owner;

    @BeforeEach
    void seed() {
        owner = OwnerJdbc.of(pg);
        cleanup();
        owner.execute("""
            INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf)
              VALUES (995001, 305, 51, 'E1', 'E', '/E1/', 1, TRUE), (995002, 305, 52, 'E2', 'E', '/E2/', 1, TRUE);
            INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status, completion_over_rate) VALUES
              (995011, 305, 51, '9950000011', 'E 成品', 10, 995001, 's', 'PCE', 20, 1, 0.0300),
              (995012, 305, 51, '9950000012', 'E 部品', 30, 995001, 's', 'PCE', 20, 1, NULL),
              (995013, 305, 52, '9950000013', 'E 他社', 10, 995002, 's', 'PCE', 20, 1, NULL);
            INSERT INTO mdm_uom (id, tenant_id, company_id, uom_code, uom_name, conversion_group) VALUES
              (995071, 305, 51, 'PCE', '个', 'PCS'), (995072, 305, 52, 'PCE', '他社个', 'PCS');
            INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name) VALUES
              (995021, 305, 51, 'F51', '工厂51'), (995022, 305, 52, 'F52', '工厂52');
            INSERT INTO mdm_warehouse (id, tenant_id, company_id, warehouse_code, warehouse_name, warehouse_type, factory_id, status) VALUES
              (995061, 305, 51, 'W51', '成品仓', 30, 995021, 1),
              (995062, 305, 51, 'W51X', '停止仓', 30, 995021, 0),
              (995063, 305, 52, 'W52', '他社仓', 30, 995022, 1);
            INSERT INTO prd_material_planning (id, tenant_id, company_id, material_id, material_code, material_name, factory_id, material_type)
              VALUES (995031, 305, 51, 995011, '9950000011', 'E 成品', 995021, 20);
            INSERT INTO sys_param (id, tenant_id, company_id, param_key, param_name, param_group, param_value, value_type)
              VALUES (995041, 305, 51, 'prd.completion_over_rate', '完工超收容差', 'prd', '0.0500', 3);
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
            DELETE FROM prd_work_order_material WHERE tenant_id = 305;
            DELETE FROM prd_work_order WHERE tenant_id = 305;
            DELETE FROM prd_bom_line WHERE tenant_id = 305;
            DELETE FROM prd_bom WHERE tenant_id = 305;
            DELETE FROM prd_material_planning WHERE tenant_id = 305;
            DELETE FROM sys_param WHERE tenant_id = 305;
            DELETE FROM sys_sequence WHERE tenant_id = 305;
            DELETE FROM fin_standard_cost WHERE tenant_id = 305;
            DELETE FROM mdm_warehouse WHERE tenant_id = 305;
            DELETE FROM mdm_factory WHERE tenant_id = 305;
            DELETE FROM mdm_material WHERE tenant_id = 305;
            DELETE FROM mdm_material_category WHERE tenant_id = 305;
            DELETE FROM mdm_uom WHERE tenant_id = 305;
            """);
    }

    <T> T as(long user, long company, Supplier<T> body) {
        return TenantContext.callAs(TENANT, () -> LoginContext.callAs(new LoginUser(user, company), body));
    }

    long createDraft(boolean withMaterial) {
        WorkOrderCreated c = as(CREATOR, CO, () -> workOrders.create(new WorkOrderCreateCommand(null, FACTORY, MAT,
                new BigDecimal("10"), "PCE", LocalDate.of(2026, 11, 2), LocalDate.of(2026, 11, 9), null, null, WH,
                null, null, "r")));
        if (withMaterial) {
            owner.update("""
                INSERT INTO prd_work_order_material (id, tenant_id, company_id, work_order_id, line_no, material_id,
                    material_code, material_name, uom_code, required_qty, total_required_qty)
                VALUES (?, 305, 51, ?, 1, 995012, '9950000012', 'E 部品', 'PCE', 20, 20)
                """, c.id() + 1_000_000, c.id());
        }
        return c.id();
    }

    @Test
    void submitApproveReleaseLifecycle() {
        long id = createDraft(true);
        WorkOrderDetail s = as(CREATOR, CO, () -> approvals.submit(id, new WorkOrderStateCommand(0, null)));
        assertThat(s.orderStatus()).isEqualTo((short) 20);
        assertThat(s.submittedAt()).isNotNull();

        assertThatThrownBy(() -> as(CREATOR, CO, () -> approvals.approve(id, new WorkOrderStateCommand(1, null))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(60005));

        WorkOrderDetail a = as(APPROVER, CO, () -> approvals.approve(id, new WorkOrderStateCommand(1, null)));
        assertThat(a.orderStatus()).isEqualTo((short) 25);
        assertThat(a.approvedBy()).isEqualTo(APPROVER);
        assertThat(a.version()).isEqualTo(2);

        WorkOrderReleased r = as(APPROVER, CO, () -> releases.release(id, new WorkOrderReleaseCommand(2)));
        assertThat(r.warnings()).singleElement().satisfies(w -> assertThat(w.msgId()).isEqualTo("MSG-FIN-117"));
        assertThat(as(APPROVER, CO, () -> queries.get(id)).orderStatus()).isEqualTo((short) 30);
    }

    @Test
    void submitWithoutMaterialsIs1001AndStaleVersionIs4003() {
        long id = createDraft(false);
        assertThatThrownBy(() -> as(CREATOR, CO, () -> approvals.submit(id, new WorkOrderStateCommand(0, null))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getMsgId()).isEqualTo("MSG-COM-040"));
        long id2 = createDraft(true);
        assertThatThrownBy(() -> as(CREATOR, CO, () -> approvals.submit(id2, new WorkOrderStateCommand(5, null))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(4003));
        assertThatThrownBy(() -> as(APPROVER, CO, () -> approvals.approve(id2, new WorkOrderStateCommand(0, null))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(4002));
    }

    @Test
    void apiDetailHasSnapshotsAndOtherCompanyIs404() throws Exception {
        long id = createDraft(true);
        MockMvc mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(CREATOR, CO));
        mvc.perform(get("/api/production/work-orders/" + id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.orderStatus").value(10))
                .andExpect(jsonPath("$.data.statusName").value("草稿"))
                .andExpect(jsonPath("$.data.overReceiptRate").value(0.03))
                .andExpect(jsonPath("$.data.standardCost").doesNotExist())
                .andExpect(jsonPath("$.data.warehouseId").value(String.valueOf(WH)))
                .andExpect(jsonPath("$.data.materials[0].materialCode").value("9950000012"));
        mvc.perform(post("/api/production/work-orders/" + id + "/submit").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"version\": 0}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.orderStatus").value(20));
        LoginContext.set(new LoginUser(CREATOR, CO2));
        mvc.perform(get("/api/production/work-orders/" + id))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(4001));
    }

    void bom(long id, long company, long material, int version, boolean dflt, int status, String from, String to) {
        owner.update("""
            INSERT INTO prd_bom (id, tenant_id, company_id, bom_no, material_id, material_code, material_name, factory_id,
                version_no, base_uom_code, valid_from, valid_to, is_default, bom_status)
            VALUES (?, 305, ?, ?, ?, 'M', 'M', ?, ?, 'PCE', CAST(? AS DATE), CAST(? AS DATE), ?, ?)
            """, id, company, "BOM-" + id, material, company == CO ? FACTORY : FACTORY_CO2, version, from, to, dflt, status);
    }

    @Test
    void effectiveBomPicksApprovedDefaultInRange() {
        bom(995101, CO, MAT, 1, true, 30, "2026-01-01", null);
        bom(995102, CO, MAT, 2, false, 30, "2026-01-01", null);
        bom(995103, CO, MAT, 3, false, 10, "2026-01-01", null);       // 未承認
        bom(995104, CO, MAT, 4, false, 30, "2027-01-01", null);       // 期間外
        owner.update("""
            INSERT INTO prd_bom_line (id, tenant_id, company_id, bom_id, line_no, component_material_id, component_code,
                component_name, uom_code, component_qty, required_qty)
            VALUES (995111, 305, 51, 995101, 10, 995012, '9950000012', 'E 部品', 'PCE', 2, 2)
            """);
        BomQueryService.EffectiveBom b = as(CREATOR, CO, () -> boms.effective(MAT, FACTORY, LocalDate.of(2026, 11, 1)));
        assertThat(b.id()).isEqualTo(995101);
        assertThat(b.lines()).singleElement().satisfies(l -> assertThat(l.componentMaterialId()).isEqualTo(COMP));

        bom(995105, CO2, MAT_CO2, 1, true, 30, "2026-01-01", null);
        assertThatThrownBy(() -> as(CREATOR, CO, () -> boms.effective(MAT_CO2, FACTORY_CO2, LocalDate.of(2026, 11, 1))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(60020));
        assertThatThrownBy(() -> as(CREATOR, CO, () -> boms.effective(MAT, FACTORY, LocalDate.of(2025, 1, 1))))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getMsgId()).isEqualTo("MSG-PRD-020"));
    }

    @Test
    void apiLookupsAreCompanyScoped() throws Exception {
        bom(995101, CO, MAT, 1, true, 30, "2026-01-01", null);
        MockMvc mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(CREATOR, CO));
        mvc.perform(get("/api/mdm/factories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].factoryCode").value("F51"));
        mvc.perform(get("/api/mdm/warehouses/options").param("factoryId", String.valueOf(FACTORY)))
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].warehouseCode").value("W51"));
        mvc.perform(get("/api/mdm/warehouses/options").param("factoryId", String.valueOf(FACTORY_CO2)))
                .andExpect(status().isNotFound());
        mvc.perform(get("/api/mdm/materials").param("keyword", "部品"))
                .andExpect(jsonPath("$.data.total").value("1"))
                .andExpect(jsonPath("$.data.list[0].id").value(String.valueOf(COMP)))
                .andExpect(jsonPath("$.data.list[0].baseUomCode").value("PCE"))
                .andExpect(jsonPath("$.data.list[0].unitId").value("995071"))
                .andExpect(jsonPath("$.data.list[0].unitName").value("个"));
        mvc.perform(get("/api/mdm/materials").param("pageSize", "1"))
                .andExpect(jsonPath("$.data.total").value("2"))
                .andExpect(jsonPath("$.data.pages").value("2"));
        mvc.perform(get("/api/production/boms/effective").param("materialId", String.valueOf(MAT)).param("date", "2026-11-01")
                        .param("factoryId", String.valueOf(FACTORY)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value("995101"));
        mvc.perform(get("/api/production/boms/effective").param("materialId", String.valueOf(MAT_CO2)).param("date", "2026-11-01")
                        .param("factoryId", String.valueOf(FACTORY_CO2)))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60020));
        mvc.perform(get("/api/production/boms/effective").param("materialId", String.valueOf(MAT)).param("date", "2026-11-01"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(1001));
    }

    @Test
    void apiApproveAndSelfApprovalIs60005() throws Exception {
        long id = createDraft(true);
        as(CREATOR, CO, () -> approvals.submit(id, new WorkOrderStateCommand(0, null)));
        MockMvc mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(CREATOR, CO));
        mvc.perform(post("/api/production/work-orders/" + id + "/approve").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"version\": 1}"))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.code").value(60005))
                .andExpect(jsonPath("$.msgId").value("MSG-PRD-005"));
        assertThat(owner.queryForObject("SELECT order_status FROM prd_work_order WHERE id = ?", Integer.class, id)).isEqualTo(20);

        LoginContext.set(new LoginUser(APPROVER, CO));
        mvc.perform(post("/api/production/work-orders/" + id + "/approve").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"version\": 0}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value(4003));
        mvc.perform(post("/api/production/work-orders/" + id + "/approve").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"version\": 1}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.orderStatus").value(25))
                .andExpect(jsonPath("$.data.approvedBy").value(String.valueOf(APPROVER)))
                .andExpect(jsonPath("$.data.version").value(2));
    }

    /** 2 スレッド同時実行：1 件のみ成功、他方は 4002/4003、version は +1 のみ（#25 と同じ方式）。 */
    void raceOnce(long id, long user, Supplier<WorkOrderDetail> op, int expectStatus) throws Exception {
        int before = owner.queryForObject("SELECT version FROM prd_work_order WHERE id = ?", Integer.class, id);
        CyclicBarrier barrier = new CyclicBarrier(2);
        Callable<WorkOrderDetail> task = () -> {
            barrier.await(10, TimeUnit.SECONDS);
            return as(user, CO, op);
        };
        ExecutorService pool = Executors.newFixedThreadPool(2);
        List<Future<WorkOrderDetail>> futures;
        try {
            futures = List.of(pool.submit(task), pool.submit(task));
            pool.shutdown();
            assertThat(pool.awaitTermination(30, TimeUnit.SECONDS)).isTrue();
        } finally {
            pool.shutdownNow();
        }
        int ok = 0;
        List<Integer> failures = new ArrayList<>();
        for (Future<WorkOrderDetail> f : futures) {
            try {
                f.get();
                ok++;
            } catch (ExecutionException e) {
                assertThat(e.getCause()).isInstanceOf(BizException.class);
                failures.add(((BizException) e.getCause()).getCode());
            }
        }
        assertThat(ok).isEqualTo(1);
        assertThat(failures).singleElement().satisfies(c -> assertThat(c).isIn(4002, 4003));
        assertThat(owner.queryForObject("SELECT order_status FROM prd_work_order WHERE id = ?", Integer.class, id))
                .isEqualTo(expectStatus);
        assertThat(owner.queryForObject("SELECT version FROM prd_work_order WHERE id = ?", Integer.class, id))
                .isEqualTo(before + 1);
    }

    @Test
    void concurrentSubmitOnlyOneWins() throws Exception {
        long id = createDraft(true);
        raceOnce(id, CREATOR, () -> approvals.submit(id, new WorkOrderStateCommand(0, null)), 20);
    }

    @Test
    void concurrentApproveOnlyOneWins() throws Exception {
        long id = createDraft(true);
        as(CREATOR, CO, () -> approvals.submit(id, new WorkOrderStateCommand(0, null)));
        raceOnce(id, APPROVER, () -> approvals.approve(id, new WorkOrderStateCommand(1, null)), 25);
    }

    /** 03-common-api-spec §8：BIGINT ID はレスポンスで文字列、リクエストは文字列・数値の双方を受理。 */
    @Test
    void apiBigintIdsAreJsonStringsAndStringIdsAreAccepted() throws Exception {
        MockMvc mvc = MockMvcBuilders.webAppContextSetup(wac).build();
        TenantContext.set(TENANT);
        LoginContext.set(new LoginUser(CREATOR, CO));
        String body = mvc.perform(post("/api/production/work-orders").contentType(MediaType.APPLICATION_JSON).content("""
                {"factoryId": "%d", "materialId": "%d", "warehouseId": %d, "orderQty": "10", "uomCode": "PCE",
                 "plannedStartDate": "2026-11-02", "plannedEndDate": "2026-11-09"}
                """.formatted(FACTORY, MAT, WH)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").isString())
                .andReturn().getResponse().getContentAsString();
        String id = com.jayway.jsonpath.JsonPath.read(body, "$.data.id");
        mvc.perform(get("/api/production/work-orders/" + id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(id))
                .andExpect(jsonPath("$.data.materialId").value(String.valueOf(MAT)))
                .andExpect(jsonPath("$.data.factoryId").value(String.valueOf(FACTORY)))
                .andExpect(jsonPath("$.data.warehouseId").value(String.valueOf(WH)))
                .andExpect(jsonPath("$.data.departmentId").doesNotExist())
                .andExpect(jsonPath("$.data.orderStatus").isNumber())
                .andExpect(jsonPath("$.data.version").isNumber());
        mvc.perform(get("/api/mdm/factories"))
                .andExpect(jsonPath("$.data[0].id").value(String.valueOf(FACTORY)));
        mvc.perform(get("/api/mdm/warehouses/options").param("factoryId", String.valueOf(FACTORY)))
                .andExpect(jsonPath("$.data[0].id").value(String.valueOf(WH)))
                .andExpect(jsonPath("$.data[0].factoryId").value(String.valueOf(FACTORY)));
        mvc.perform(get("/api/mdm/materials").param("keyword", "部品"))
                .andExpect(jsonPath("$.data.list[0].id").isString())
                .andExpect(jsonPath("$.data.list[0].unitId").isString());
    }
}
