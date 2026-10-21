package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Optional;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InOrder;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.production.SalesOrderLineLookup.SalesOrderLine;
import com.stellar.erp.production.internal.ProductionRepository;
import com.stellar.erp.production.internal.ProductionRepository.WorkOrderForRelease;

class WorkOrderReleaseServiceTest {

    static final long CO = 1L, USER = 9L, WO = 100L, LINE = 200L, MAT = 300L;
    // 2026-10-31T16:30Z = 上海 2026-11-01 00:30 → 期间 2026-11-01（验证按 Asia/Shanghai 取日）
    static final Clock CLOCK = Clock.fixed(Instant.parse("2026-10-31T16:30:00Z"), WorkOrderReleaseService.BUSINESS_ZONE);

    ProductionRepository repo = mock(ProductionRepository.class);
    SalesOrderLineLookup lines = mock(SalesOrderLineLookup.class);
    BomQueryService boms = mock(BomQueryService.class);
    com.stellar.erp.production.internal.UomConverter uoms = mock(com.stellar.erp.production.internal.UomConverter.class);

    @BeforeEach
    void uomIdentity() {
        when(repo.findBaseUom(anyLong(), anyLong())).thenReturn(Optional.of("PCE"));
        when(uoms.toBase(anyLong(), any(), any(), any(), any())).thenAnswer(inv -> inv.getArgument(3));
    }
    WorkOrderReleaseService service = new WorkOrderReleaseService(repo, lines, boms, new WorkOrderMaterials(repo, uoms), CLOCK);

    @BeforeEach
    void login() {
        LoginContext.set(new LoginContext.LoginUser(USER, CO));
    }

    @AfterEach
    void clear() {
        LoginContext.clear();
    }

    WorkOrderForRelease wo(Long line, short status, boolean hold, int version) {
        return new WorkOrderForRelease(WO, "WO2611010001", MAT, line, status, hold, version, FACTORY, PLANNED_START,
                new BigDecimal("10"));
    }

    void stubWo(WorkOrderForRelease w) {
        when(repo.findWorkOrderForRelease(CO, WO)).thenReturn(Optional.of(w));
        when(repo.lockWorkOrderForRelease(CO, WO)).thenReturn(Optional.of(w));
        when(repo.markReleased(anyLong(), anyLong(), anyInt(), anyLong(), any(), any(), anyBoolean())).thenReturn(1);
        when(repo.countWorkOrderMaterials(CO, WO)).thenReturn(1L);   // 既定：材料行あり（展開しない）
    }

    static final long FACTORY = 77;
    static final LocalDate PLANNED_START = LocalDate.of(2026, 11, 20);

    static BomQueryService.EffectiveBom bom(BomQueryService.Line... lines) {
        return new BomQueryService.EffectiveBom(500, "BOM1", MAT, "M", FACTORY, (short) 1, new BigDecimal("2"), "PCE",
                LocalDate.of(2026, 1, 1), null, true, java.util.List.of(lines));
    }

    @Test
    void zeroLinesWithoutBomIs60020AndNothingWritten() {
        stubWo(wo(null, (short) 25, false, 0));
        when(repo.countWorkOrderMaterials(CO, WO)).thenReturn(0L);
        when(boms.find(CO, MAT, FACTORY, PLANNED_START)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(60020);
                    assertThat(e.getMsgId()).isEqualTo("MSG-PRD-020");
                });
        verify(repo, never()).insertMaterialLine(any());
        verify(repo, never()).markReleased(anyLong(), anyLong(), anyInt(), anyLong(), any(), any(), anyBoolean());
    }

    @Test
    void zeroLinesExpandsBomWithCalcWo01And02() {
        stubWo(wo(null, (short) 25, false, 0));
        when(repo.countWorkOrderMaterials(CO, WO)).thenReturn(0L);
        when(repo.findEffectiveStandardCost(anyLong(), anyLong(), any())).thenReturn(Optional.empty());
        // base_qty 2、order_qty 10、component_qty 3、loss 0.005 → required 15.0000、total 15÷0.995=15.0754（切上）
        when(boms.find(CO, MAT, FACTORY, PLANNED_START)).thenReturn(Optional.of(bom(
                new BomQueryService.Line(601, 10, 900, "C1", "部品", "PCE", new BigDecimal("3"), new BigDecimal("0.005"),
                        new BigDecimal("3.0151"), 10, true, null))));
        service.release(WO, new WorkOrderReleaseCommand(0));
        org.mockito.ArgumentCaptor<ProductionRepository.MaterialLineInsert> c =
                org.mockito.ArgumentCaptor.forClass(ProductionRepository.MaterialLineInsert.class);
        InOrder order = inOrder(repo);
        order.verify(repo).lockWorkOrderForRelease(CO, WO);
        order.verify(repo).insertMaterialLine(c.capture());
        order.verify(repo).markReleased(anyLong(), anyLong(), anyInt(), anyLong(), any(), any(), anyBoolean());
        assertThat(c.getValue().requiredQty()).isEqualByComparingTo("15.0000");
        assertThat(c.getValue().totalRequiredQty()).isEqualByComparingTo("15.0754");
        assertThat(c.getValue().lossQty()).isEqualByComparingTo("0.0754");
        assertThat(c.getValue().bomLineId()).isEqualTo(601);
        assertThat(c.getValue().materialId()).isEqualTo(900);
        assertThat(c.getValue().uomCode()).isEqualTo("PCE");
        assertThat(c.getValue().bomUomCode()).isEqualTo("PCE");
        assertThat(c.getValue().bomQty()).isEqualByComparingTo("15.0754");   // 換算前の総必要量
    }

    @Test
    void zeroLinesUomMismatchIs60022AndNotReleased() {
        stubWo(wo(null, (short) 25, false, 0));
        when(repo.countWorkOrderMaterials(CO, WO)).thenReturn(0L);
        when(boms.find(CO, MAT, FACTORY, PLANNED_START)).thenReturn(Optional.of(bom(
                new BomQueryService.Line(601, 10, 900, "C1", "部品", "KGM", BigDecimal.ONE, BigDecimal.ZERO,
                        BigDecimal.ONE, 10, false, null))));
        when(uoms.toBase(CO, "KGM", "PCE", new BigDecimal("5.0000"), PLANNED_START)).thenThrow(
                new BizException(60022, "MSG-PRD-022", "x"));
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(60022));
        verify(repo, never()).insertMaterialLine(any());
        verify(repo, never()).markReleased(anyLong(), anyLong(), anyInt(), anyLong(), any(), any(), anyBoolean());
    }

    @Test
    void existingLinesAreRecheckedAndMismatchIs60022() {
        stubWo(wo(null, (short) 25, false, 0));
        when(repo.listMaterialLineUoms(CO, WO)).thenReturn(java.util.List.of(
                new ProductionRepository.MaterialLineUom(1, 10, 900, "PCE", "BOX", "PCE")));
        org.mockito.Mockito.doThrow(new BizException(60022, "MSG-PRD-022", "x"))
                .when(uoms).check(CO, "BOX", "PCE", PLANNED_START);
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(60022));
        verify(repo, never()).markReleased(anyLong(), anyLong(), anyInt(), anyLong(), any(), any(), anyBoolean());
    }

    @Test
    void existingManualLineWithNonBaseUomIs60022() {
        stubWo(wo(null, (short) 25, false, 0));
        when(repo.listMaterialLineUoms(CO, WO)).thenReturn(java.util.List.of(
                new ProductionRepository.MaterialLineUom(1, 10, 900, "KGM", null, "PCE")));
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(60022));
    }

    @Test
    void existingLinesAreNotReExpandedAndBomNotChecked() {
        stubWo(wo(null, (short) 25, false, 0));
        when(repo.findEffectiveStandardCost(anyLong(), anyLong(), any())).thenReturn(Optional.empty());
        service.release(WO, new WorkOrderReleaseCommand(0));
        verify(boms, never()).find(anyLong(), anyLong(), anyLong(), any());
        verify(repo, never()).insertMaterialLine(any());
    }

    @Test
    void bomBaseDateFallsBackToTodayWhenNoPlannedStart() {
        WorkOrderForRelease w = new WorkOrderForRelease(WO, "WO2611010001", MAT, null, (short) 25, false, 0, FACTORY, null,
                BigDecimal.TEN);
        stubWo(w);
        when(repo.countWorkOrderMaterials(CO, WO)).thenReturn(0L);
        when(boms.find(anyLong(), anyLong(), anyLong(), any())).thenReturn(Optional.empty());
        // CLOCK = 2026-10-31T16:30Z → Asia/Shanghai 2026-11-01
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0, LocalDate.of(2026, 12, 5))))
                .isInstanceOf(BizException.class);
        verify(boms).find(CO, MAT, FACTORY, LocalDate.of(2026, 11, 1));
    }

    @Test
    void mtoAllowedQtyNullIs60101BeforeWorkOrderLock() {
        when(repo.findWorkOrderForRelease(CO, WO)).thenReturn(Optional.of(wo(LINE, (short) 25, false, 0)));
        when(lines.lockForUpdate(CO, LINE)).thenReturn(Optional.of(new SalesOrderLine(LINE, 1L, "SO1", MAT, null, null)));
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(60101);
                    assertThat(e.getMsgId()).isEqualTo("MSG-PRD-106");
                });
        verify(repo, never()).lockWorkOrderForRelease(anyLong(), anyLong());
    }

    @Test
    void mtoNegativeAllowedQtyIs60101BeforeWorkOrderLock() {
        when(repo.findWorkOrderForRelease(CO, WO)).thenReturn(Optional.of(wo(LINE, (short) 25, false, 0)));
        when(lines.lockForUpdate(CO, LINE)).thenReturn(Optional.of(
                new SalesOrderLine(LINE, 1L, "SO1", MAT, null, new BigDecimal("-1"))));
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(60101);
                    assertThat(e.getMsgId()).isEqualTo("MSG-PRD-106");
                });
        verify(repo, never()).lockWorkOrderForRelease(anyLong(), anyLong());
    }

    @Test
    void mtoLocksSalesOrderLineBeforeWorkOrder() {
        stubWo(wo(LINE, (short) 25, false, 3));
        when(lines.lockForUpdate(CO, LINE)).thenReturn(Optional.of(
                new SalesOrderLine(LINE, 1L, "SO1", MAT, null, new BigDecimal("105"))));
        when(repo.findEffectiveStandardCost(CO, MAT, LocalDate.of(2026, 11, 1))).thenReturn(Optional.of(new BigDecimal("778.2")));

        WorkOrderReleased r = service.release(WO, new WorkOrderReleaseCommand(3));

        InOrder order = inOrder(lines, repo);
        order.verify(lines).lockForUpdate(CO, LINE);
        order.verify(repo).lockWorkOrderForRelease(CO, WO);
        order.verify(repo).markReleased(CO, WO, 3, USER, new BigDecimal("778.2"), new BigDecimal("105"), true);
        assertThat(r.orderStatus()).isEqualTo((short) 30);
        assertThat(r.releaseDate()).isEqualTo(LocalDate.of(2026, 11, 1));
        assertThat(r.warnings()).isEmpty();
        assertThat(r.version()).isEqualTo(4);
    }

    @Test
    void noPublishedVersionKeepsNullAndWarnsMsgFin117() {
        stubWo(wo(null, (short) 25, false, 0));
        when(repo.findEffectiveStandardCost(anyLong(), anyLong(), any())).thenReturn(Optional.empty());

        WorkOrderReleased r = service.release(WO, new WorkOrderReleaseCommand(0));

        verify(repo).markReleased(eq(CO), eq(WO), eq(0), eq(USER), isNull(), isNull(), eq(false));
        verify(lines, never()).lockForUpdate(anyLong(), anyLong());
        assertThat(r.standardCost()).isNull();
        assertThat(r.warnings()).singleElement().satisfies(w -> {
            assertThat(w.code()).isEqualTo(70117);
            assertThat(w.msgId()).isEqualTo("MSG-FIN-117");
        });
    }

    @Test
    void notApprovedIs4002() {
        stubWo(wo(null, (short) 10, false, 0));
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(4002);
                    assertThat(e.getMsgId()).isEqualTo("MSG-COM-034");
                });
        verify(repo, never()).markReleased(anyLong(), anyLong(), anyInt(), anyLong(), any(), any(), anyBoolean());
    }

    @Test
    void staleVersionIs4003() {
        stubWo(wo(null, (short) 25, false, 2));
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(1)))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(4003));
    }

    @Test
    void zeroRowsUpdatedIs4003() {
        stubWo(wo(null, (short) 25, false, 0));
        when(repo.markReleased(anyLong(), anyLong(), anyInt(), anyLong(), any(), any(), anyBoolean())).thenReturn(0);
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(4003);
                    assertThat(e.getMsgId()).isEqualTo("MSG-COM-033");
                });
    }

    @Test
    void holdIs60047() {
        stubWo(wo(null, (short) 25, true, 0));
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(60047);
                    assertThat(e.getMsgId()).isEqualTo("MSG-PRD-047");
                });
    }

    @Test
    void mtoLineWithoutAllowedQtySnapshotIs60101() {
        stubWo(wo(LINE, (short) 25, false, 0));
        when(lines.lockForUpdate(CO, LINE)).thenReturn(Optional.of(
                new SalesOrderLine(LINE, 1L, "SO1", MAT, null, null)));
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(60101);
                    assertThat(e.getMsgId()).isEqualTo("MSG-PRD-106");
                });
        verify(repo, never()).lockWorkOrderForRelease(anyLong(), anyLong());
        verify(repo, never()).markReleased(anyLong(), anyLong(), anyInt(), anyLong(), any(), any(), anyBoolean());
    }

    @Test
    void mtoMaterialMismatchIs60056() {
        stubWo(wo(LINE, (short) 25, false, 0));
        when(lines.lockForUpdate(CO, LINE)).thenReturn(Optional.of(
                new SalesOrderLine(LINE, 1L, "SO1", MAT + 1, null, BigDecimal.TEN)));
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(60056));
    }

    @Test
    void pastReleaseDateIs60104BeforeAnyLock() {
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0, LocalDate.of(2026, 10, 31))))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(60104);
                    assertThat(e.getMsgId()).isEqualTo("MSG-PRD-104");
                });
        verify(repo, never()).lockWorkOrderForRelease(anyLong(), anyLong());
    }

    @Test
    void futureReleaseDatePicksCostOfThatMonth() {
        stubWo(wo(null, (short) 25, false, 0));
        when(repo.findEffectiveStandardCost(CO, MAT, LocalDate.of(2027, 1, 1))).thenReturn(Optional.of(new BigDecimal("5")));
        WorkOrderReleased r = service.release(WO, new WorkOrderReleaseCommand(0, LocalDate.of(2027, 1, 20)));
        assertThat(r.releaseDate()).isEqualTo(LocalDate.of(2027, 1, 20));
        assertThat(r.standardCost()).isEqualByComparingTo("5");
        verify(repo, never()).findEffectiveStandardCost(CO, MAT, LocalDate.of(2026, 11, 1));
    }

    @Test
    void todayReleaseDateIsAccepted() {
        stubWo(wo(null, (short) 25, false, 0));
        when(repo.findEffectiveStandardCost(anyLong(), anyLong(), any())).thenReturn(Optional.empty());
        assertThat(service.release(WO, new WorkOrderReleaseCommand(0, LocalDate.of(2026, 11, 1))).releaseDate())
                .isEqualTo(LocalDate.of(2026, 11, 1));
    }

    @Test
    void unknownWorkOrderIs4001() {
        when(repo.findWorkOrderForRelease(CO, WO)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(4001));
    }
}
