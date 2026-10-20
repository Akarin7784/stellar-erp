package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
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
    WorkOrderReleaseService service = new WorkOrderReleaseService(repo, lines, CLOCK);

    @BeforeEach
    void login() {
        LoginContext.set(new LoginContext.LoginUser(USER, CO));
    }

    @AfterEach
    void clear() {
        LoginContext.clear();
    }

    WorkOrderForRelease wo(Long line, short status, boolean hold, int version) {
        return new WorkOrderForRelease(WO, "WO2611010001", MAT, line, status, hold, version);
    }

    void stubWo(WorkOrderForRelease w) {
        when(repo.findWorkOrderForRelease(CO, WO)).thenReturn(Optional.of(w));
        when(repo.lockWorkOrderForRelease(CO, WO)).thenReturn(Optional.of(w));
        when(repo.markReleased(anyLong(), anyLong(), anyLong(), any(), any(), anyBoolean())).thenReturn(1);
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
        order.verify(repo).markReleased(CO, WO, USER, new BigDecimal("778.2"), new BigDecimal("105"), true);
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

        verify(repo).markReleased(eq(CO), eq(WO), eq(USER), isNull(), isNull(), eq(false));
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
        verify(repo, never()).markReleased(anyLong(), anyLong(), anyLong(), any(), any(), anyBoolean());
    }

    @Test
    void staleVersionIs4003() {
        stubWo(wo(null, (short) 25, false, 2));
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(1)))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(4003));
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
    void mtoMaterialMismatchIs60056() {
        stubWo(wo(LINE, (short) 25, false, 0));
        when(lines.lockForUpdate(CO, LINE)).thenReturn(Optional.of(
                new SalesOrderLine(LINE, 1L, "SO1", MAT + 1, null, BigDecimal.TEN)));
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(60056));
    }

    @Test
    void unknownWorkOrderIs4001() {
        when(repo.findWorkOrderForRelease(CO, WO)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.release(WO, new WorkOrderReleaseCommand(0)))
                .isInstanceOfSatisfying(BizException.class, e -> assertThat(e.getCode()).isEqualTo(4001));
    }
}
