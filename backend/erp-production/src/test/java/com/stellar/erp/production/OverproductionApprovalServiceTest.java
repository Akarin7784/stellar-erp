package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.lang.reflect.Proxy;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.concurrent.atomic.AtomicInteger;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;

import com.stellar.erp.common.BizException;

/** request_qty 校验在任何 DB 访问之前（不依赖登录上下文、不调用端口/仓库）。 */
class OverproductionApprovalServiceTest {

    @ParameterizedTest
    @NullSource
    @ValueSource(strings = {"0", "0.0000", "-1", "-0.0001"})
    void invalidRequestQtyIs60103BeforeAnyAccess(BigDecimal qty) {
        AtomicInteger lookups = new AtomicInteger();
        SalesOrderLineLookup lookup = (SalesOrderLineLookup) Proxy.newProxyInstance(
                getClass().getClassLoader(), new Class<?>[] {SalesOrderLineLookup.class}, (p, m, a) -> {
                    lookups.incrementAndGet();
                    throw new AssertionError("should not be called");
                });
        // repo = null：若服务在校验前访问仓库会 NPE，测试即失败
        OverproductionApprovalService service = new OverproductionApprovalService(null, lookup);

        assertThatThrownBy(() -> service.request(new OverproductionRequestCommand(1L, null, qty, null)))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(60103);
                    assertThat(e.getMsgId()).isEqualTo("MSG-PRD-103");
                });
        assertThat(lookups).hasValue(0);
    }

    @Test
    void nullCommandIs60103() {
        OverproductionApprovalService service = new OverproductionApprovalService(null, null);
        assertThatThrownBy(() -> service.request(null))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(60103));
    }

    @Test
    void recognisesNotNullAndCheckViolationsOnRequestQty() {
        assertThat(OverproductionApprovalService.isRequestQtyViolation(new DataIntegrityViolationException("x",
                new SQLException("null value in column \"request_qty\" violates not-null constraint", "23502"))))
                .isTrue();
        assertThat(OverproductionApprovalService.isRequestQtyViolation(new DataIntegrityViolationException("x",
                new SQLException("new row for relation \"prd_overproduction_approval\" violates check constraint \"ck_prd_opa_request_qty\"", "23514")))).isTrue();
        assertThat(OverproductionApprovalService.isRequestQtyViolation(new DataIntegrityViolationException("x",
                new SQLException("null value in column \"material_id\"", "23502")))).isFalse();
    }

    @org.junit.jupiter.params.ParameterizedTest
    @org.junit.jupiter.params.provider.CsvSource(delimiter = '|', value = {
            "23514|violates check constraint \"ck_prd_opa_allowed_qty\"",
            "23514|violates check constraint \"ck_prd_opa_qty\"",
            "23514|violates check constraint \"ck_prd_opa_status\"",
            "23514|violates check constraint \"ck_prd_opa_request_qty_x\"",
            "23505|duplicate key value violates unique constraint \"uk_prd_overproduction_approval_no\"",
            "23502|null value in column \"current_allowed_qty\""
    })
    void otherConstraintViolationsAreNot60103(String state, String message) {
        assertThat(OverproductionApprovalService.isRequestQtyViolation(
                new DataIntegrityViolationException("x", new SQLException(message, state)))).isFalse();
    }

    // ---------------------------------------------------------------- DB 兜底经 request() 转换（插入阶段）

    static final long CO = 1, USER = 9, LINE = 500, SO = 400, MAT = 300;

    private OverproductionApprovalService mockedService(com.stellar.erp.production.internal.ProductionRepository repo) {
        SalesOrderLineLookup lookup = org.mockito.Mockito.mock(SalesOrderLineLookup.class);
        org.mockito.Mockito.when(lookup.find(CO, LINE)).thenReturn(java.util.Optional.of(
                new SalesOrderLineLookup.SalesOrderLine(LINE, SO, "SO1", MAT, null, new BigDecimal("105"))));
        org.mockito.Mockito.when(repo.nextSequence(org.mockito.ArgumentMatchers.eq(CO), org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.anyLong())).thenReturn(1L);
        org.mockito.Mockito.when(repo.findCompanyDecimalParam(CO, "prd.overproduction_max_rate")).thenReturn(BigDecimal.ONE);
        org.mockito.Mockito.when(repo.findOverproductionLimitBasis(CO, LINE)).thenReturn(java.util.Optional.of(
                new com.stellar.erp.production.internal.ProductionRepository.OverproductionLimitBasis(new BigDecimal("100"), 0)));
        return new OverproductionApprovalService(repo, lookup);
    }

    @Test
    void dbRequestQtyCheckViolationDuringRequestIsConvertedTo60103() {
        var repo = org.mockito.Mockito.mock(com.stellar.erp.production.internal.ProductionRepository.class);
        org.mockito.Mockito.doThrow(new DataIntegrityViolationException("x", new SQLException(
                "new row for relation \"prd_overproduction_approval\" violates check constraint \"ck_prd_opa_request_qty\"", "23514")))
                .when(repo).insertApproval(org.mockito.ArgumentMatchers.any());
        OverproductionApprovalService service = mockedService(repo);
        com.stellar.erp.common.LoginContext.set(new com.stellar.erp.common.LoginContext.LoginUser(USER, CO));
        try {
            assertThatThrownBy(() -> service.request(new OverproductionRequestCommand(LINE, null, new BigDecimal("3"), null)))
                    .isInstanceOfSatisfying(BizException.class, e -> {
                        assertThat(e.getCode()).isEqualTo(60103);
                        assertThat(e.getMsgId()).isEqualTo("MSG-PRD-103");
                    });
        } finally {
            com.stellar.erp.common.LoginContext.clear();
        }
    }

    @Test
    void otherDbViolationDuringRequestIsRethrownUnchanged() {
        var repo = org.mockito.Mockito.mock(com.stellar.erp.production.internal.ProductionRepository.class);
        DataIntegrityViolationException original = new DataIntegrityViolationException("x", new SQLException(
                "violates check constraint \"ck_prd_opa_allowed_qty\"", "23514"));
        org.mockito.Mockito.doThrow(original).when(repo).insertApproval(org.mockito.ArgumentMatchers.any());
        OverproductionApprovalService service = mockedService(repo);
        com.stellar.erp.common.LoginContext.set(new com.stellar.erp.common.LoginContext.LoginUser(USER, CO));
        try {
            assertThatThrownBy(() -> service.request(new OverproductionRequestCommand(LINE, null, new BigDecimal("3"), null)))
                    .isSameAs(original);
        } finally {
            com.stellar.erp.common.LoginContext.clear();
        }
    }

    @Test
    void invalidQtyIsCheckedBeforeMissingSalesOrderLineAndLogin() {
        // 受注行未指定 + 未登录 + 数量 0：60103 优先（不是 1001 / 未登录错误）
        OverproductionApprovalService service = new OverproductionApprovalService(null, null);
        assertThatThrownBy(() -> service.request(new OverproductionRequestCommand(null, null, BigDecimal.ZERO, null)))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(60103));
    }

    // ------------------------------------------------------------------ 受注行消失 → 60101 / MSG-PRD-106／状態更新 0 行 → 4003

    static final long APPROVAL = 555L, APPROVER = 8L;

    private static com.stellar.erp.production.internal.ProductionRepository.ApprovalRow approvalRow(short status, int version) {
        return new com.stellar.erp.production.internal.ProductionRepository.ApprovalRow(APPROVAL, "OPA1", LINE, null,
                new BigDecimal("3"), status, version, USER);
    }

    private static void assert60101(Throwable t) {
        assertThat(t).isInstanceOfSatisfying(BizException.class, e -> {
            assertThat(e.getCode()).isEqualTo(60101);
            assertThat(e.getMsgId()).isEqualTo("MSG-PRD-106");
            assertThat(e.getMessage()).isEqualTo("超产允许数量不可用或对应的销售订单行已不存在，无法执行此操作");
        });
    }

    @Test
    void updateWhenSalesOrderLineMissingIs60101() {
        var repo = org.mockito.Mockito.mock(com.stellar.erp.production.internal.ProductionRepository.class);
        SalesOrderLineLookup lookup = org.mockito.Mockito.mock(SalesOrderLineLookup.class);
        org.mockito.Mockito.when(repo.findApproval(CO, APPROVAL, true)).thenReturn(java.util.Optional.of(approvalRow((short) 10, 0)));
        org.mockito.Mockito.when(lookup.find(CO, LINE)).thenReturn(java.util.Optional.empty());
        OverproductionApprovalService service = new OverproductionApprovalService(repo, lookup);
        com.stellar.erp.common.LoginContext.set(new com.stellar.erp.common.LoginContext.LoginUser(USER, CO));
        try {
            assert60101(org.assertj.core.api.Assertions.catchThrowable(() -> service.update(APPROVAL,
                    new OverproductionUpdateCommand(0, null, new BigDecimal("3"), null))));
            org.mockito.Mockito.verify(repo, org.mockito.Mockito.never()).updateDraftApproval(
                    org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.anyInt(),
                    org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any(),
                    org.mockito.ArgumentMatchers.any());
        } finally {
            com.stellar.erp.common.LoginContext.clear();
        }
    }

    @Test
    void approveWhenSalesOrderLineMissingIs60101() {
        var repo = org.mockito.Mockito.mock(com.stellar.erp.production.internal.ProductionRepository.class);
        SalesOrderLineLookup lookup = org.mockito.Mockito.mock(SalesOrderLineLookup.class);
        org.mockito.Mockito.when(repo.findApproval(CO, APPROVAL, false)).thenReturn(java.util.Optional.of(approvalRow((short) 20, 1)));
        org.mockito.Mockito.when(lookup.lockForUpdate(CO, LINE)).thenReturn(java.util.Optional.empty());
        OverproductionApprovalService service = new OverproductionApprovalService(repo, lookup);
        com.stellar.erp.common.LoginContext.set(new com.stellar.erp.common.LoginContext.LoginUser(APPROVER, CO));
        try {
            assert60101(org.assertj.core.api.Assertions.catchThrowable(() -> service.approve(APPROVAL, 1)));
            org.mockito.Mockito.verify(repo, org.mockito.Mockito.never()).addSalesOrderLineAllowedQty(
                    org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.any(),
                    org.mockito.ArgumentMatchers.anyLong());
        } finally {
            com.stellar.erp.common.LoginContext.clear();
        }
    }

    @Test
    void approveStatusUpdateZeroRowsIs4003() {
        var repo = org.mockito.Mockito.mock(com.stellar.erp.production.internal.ProductionRepository.class);
        SalesOrderLineLookup lookup = org.mockito.Mockito.mock(SalesOrderLineLookup.class);
        org.mockito.Mockito.when(repo.findApproval(CO, APPROVAL, false)).thenReturn(java.util.Optional.of(approvalRow((short) 20, 1)));
        org.mockito.Mockito.when(repo.findApproval(CO, APPROVAL, true)).thenReturn(java.util.Optional.of(approvalRow((short) 20, 1)));
        org.mockito.Mockito.when(lookup.lockForUpdate(CO, LINE)).thenReturn(java.util.Optional.of(
                new SalesOrderLineLookup.SalesOrderLine(LINE, SO, "SO1", MAT, null, new BigDecimal("105"))));
        org.mockito.Mockito.when(repo.addSalesOrderLineAllowedQty(CO, LINE, new BigDecimal("3"), APPROVER))
                .thenReturn(java.util.Optional.of(new BigDecimal("108")));
        org.mockito.Mockito.when(repo.markOverproductionApproved(CO, APPROVAL, 1, APPROVER, new BigDecimal("108"))).thenReturn(0);
        OverproductionApprovalService service = new OverproductionApprovalService(repo, lookup);
        com.stellar.erp.common.LoginContext.set(new com.stellar.erp.common.LoginContext.LoginUser(APPROVER, CO));
        try {
            assertThatThrownBy(() -> service.approve(APPROVAL, 1))
                    .isInstanceOfSatisfying(BizException.class, e -> {
                        assertThat(e.getCode()).isEqualTo(4003);
                        assertThat(e.getMsgId()).isEqualTo("MSG-COM-033");
                    });
        } finally {
            com.stellar.erp.common.LoginContext.clear();
        }
    }

    // ------------------------------------------------------------------ 承認時の allowed_qty 異常（工单未快照・UPDATE 0 行）→ 60101 / MSG-PRD-106

    static final long WO = 700L;

    private static com.stellar.erp.production.internal.ProductionRepository woLevelRepo() {
        var repo = org.mockito.Mockito.mock(com.stellar.erp.production.internal.ProductionRepository.class);
        var row = new com.stellar.erp.production.internal.ProductionRepository.ApprovalRow(APPROVAL, "OPA1", LINE, WO,
                new BigDecimal("3"), (short) 20, 1, USER);
        org.mockito.Mockito.when(repo.findApproval(CO, APPROVAL, false)).thenReturn(java.util.Optional.of(row));
        org.mockito.Mockito.when(repo.findApproval(CO, APPROVAL, true)).thenReturn(java.util.Optional.of(row));
        org.mockito.Mockito.when(repo.lockWorkOrderRef(CO, WO)).thenReturn(java.util.Optional.of(
                new com.stellar.erp.production.internal.ProductionRepository.WorkOrderRef(WO, MAT, LINE)));
        return repo;
    }

    private static Throwable approveWith(com.stellar.erp.production.internal.ProductionRepository repo) {
        SalesOrderLineLookup lookup = org.mockito.Mockito.mock(SalesOrderLineLookup.class);
        org.mockito.Mockito.when(lookup.lockForUpdate(CO, LINE)).thenReturn(java.util.Optional.of(
                new SalesOrderLineLookup.SalesOrderLine(LINE, SO, "SO1", MAT, null, new BigDecimal("105"))));
        OverproductionApprovalService service = new OverproductionApprovalService(repo, lookup);
        com.stellar.erp.common.LoginContext.set(new com.stellar.erp.common.LoginContext.LoginUser(APPROVER, CO));
        try {
            return org.assertj.core.api.Assertions.catchThrowable(() -> service.approve(APPROVAL, 1));
        } finally {
            com.stellar.erp.common.LoginContext.clear();
        }
    }

    @Test
    void approveWhenWorkOrderAllowedQtyNullIs106() {
        var repo = woLevelRepo();
        org.mockito.Mockito.when(repo.findWorkOrderLimitState(CO, WO)).thenReturn(java.util.Optional.of(
                new com.stellar.erp.production.internal.ProductionRepository.WorkOrderLimitState((short) 30, null)));
        assert60101(approveWith(repo));
        org.mockito.Mockito.verify(repo, org.mockito.Mockito.never()).addSalesOrderLineAllowedQty(
                org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.anyLong());
    }

    @Test
    void approveWhenLineAllowedQtyUpdateHitsZeroRowsIs106() {
        var repo = woLevelRepo();
        org.mockito.Mockito.when(repo.findWorkOrderLimitState(CO, WO)).thenReturn(java.util.Optional.of(
                new com.stellar.erp.production.internal.ProductionRepository.WorkOrderLimitState((short) 30, new BigDecimal("10"))));
        org.mockito.Mockito.when(repo.addSalesOrderLineAllowedQty(CO, LINE, new BigDecimal("3"), APPROVER))
                .thenReturn(java.util.Optional.empty());
        assert60101(approveWith(repo));
        org.mockito.Mockito.verify(repo, org.mockito.Mockito.never()).addWorkOrderAllowedQty(
                org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.anyLong());
    }

    @Test
    void approveWhenWorkOrderAllowedQtyUpdateHitsZeroRowsIs106() {
        var repo = woLevelRepo();
        org.mockito.Mockito.when(repo.findWorkOrderLimitState(CO, WO)).thenReturn(java.util.Optional.of(
                new com.stellar.erp.production.internal.ProductionRepository.WorkOrderLimitState((short) 30, new BigDecimal("10"))));
        org.mockito.Mockito.when(repo.addSalesOrderLineAllowedQty(CO, LINE, new BigDecimal("3"), APPROVER))
                .thenReturn(java.util.Optional.of(new BigDecimal("108")));
        org.mockito.Mockito.when(repo.addWorkOrderAllowedQty(CO, WO, new BigDecimal("3"), APPROVER)).thenReturn(0);
        assert60101(approveWith(repo));
        org.mockito.Mockito.verify(repo, org.mockito.Mockito.never()).markOverproductionApproved(
                org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.anyInt(),
                org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.any());
    }
}
