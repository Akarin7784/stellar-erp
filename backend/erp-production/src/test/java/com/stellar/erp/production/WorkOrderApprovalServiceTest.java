package com.stellar.erp.production;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.production.internal.ProductionRepository;
import com.stellar.erp.production.internal.ProductionRepository.WorkOrderForApproval;

class WorkOrderApprovalServiceTest {

    static final long CO = 1, USER = 9, CREATOR = 8, WO = 100;

    ProductionRepository repo = mock(ProductionRepository.class);
    WorkOrderQueryService query = mock(WorkOrderQueryService.class);
    WorkOrderApprovalService service = new WorkOrderApprovalService(repo, query);

    @BeforeEach
    void login() {
        LoginContext.set(new LoginContext.LoginUser(USER, CO));
    }

    @AfterEach
    void clear() {
        LoginContext.clear();
    }

    void stub(int status, int version, long createdBy) {
        when(repo.lockWorkOrderForApproval(CO, WO))
                .thenReturn(Optional.of(new WorkOrderForApproval(WO, (short) status, version, createdBy)));
    }

    static int code(Throwable e) {
        return ((BizException) e).getCode();
    }

    @Test
    void submitFromDraft() {
        stub(10, 2, CREATOR);
        when(repo.countWorkOrderMaterials(CO, WO)).thenReturn(1L);
        when(repo.markSubmitted(CO, WO, 2, USER)).thenReturn(1);
        service.submit(WO, new WorkOrderStateCommand(2, null));
        verify(repo).markSubmitted(CO, WO, 2, USER);
    }

    @Test
    void submitWithoutMaterialLinesIs1001() {
        stub(10, 0, CREATOR);
        when(repo.countWorkOrderMaterials(CO, WO)).thenReturn(0L);
        assertThatThrownBy(() -> service.submit(WO, new WorkOrderStateCommand(0, null)))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(1001);
                    assertThat(e.getMsgId()).isEqualTo("MSG-COM-040");
                });
        verify(repo, never()).markSubmitted(anyLong(), anyLong(), anyInt(), anyLong());
    }

    @Test
    void submitFromWrongStatusIs4002() {
        stub(25, 0, CREATOR);
        assertThatThrownBy(() -> service.submit(WO, new WorkOrderStateCommand(0, null)))
                .satisfies(e -> assertThat(code(e)).isEqualTo(4002));
    }

    @Test
    void staleVersionIs4003() {
        stub(10, 3, CREATOR);
        assertThatThrownBy(() -> service.submit(WO, new WorkOrderStateCommand(2, null)))
                .satisfies(e -> assertThat(code(e)).isEqualTo(4003));
    }

    @Test
    void approveFromPending() {
        stub(20, 1, CREATOR);
        when(repo.markApproved(CO, WO, 1, USER)).thenReturn(1);
        service.approve(WO, new WorkOrderStateCommand(1, null));
        verify(repo).markApproved(CO, WO, 1, USER);
    }

    @Test
    void selfApprovalIs60005() {
        stub(20, 1, USER);
        assertThatThrownBy(() -> service.approve(WO, new WorkOrderStateCommand(1, null)))
                .isInstanceOfSatisfying(BizException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(60005);
                    assertThat(e.getMsgId()).isEqualTo("MSG-PRD-005");
                });
        verify(repo, never()).markApproved(anyLong(), anyLong(), anyInt(), anyLong());
    }

    @Test
    void approveFromDraftIs4002() {
        stub(10, 0, CREATOR);
        assertThatThrownBy(() -> service.approve(WO, new WorkOrderStateCommand(0, null)))
                .satisfies(e -> assertThat(code(e)).isEqualTo(4002));
    }

    @Test
    void unknownIs4001() {
        when(repo.lockWorkOrderForApproval(CO, WO)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.approve(WO, new WorkOrderStateCommand(0, null)))
                .satisfies(e -> assertThat(code(e)).isEqualTo(4001));
    }

    @Test
    void zeroRowsUpdatedIs4003() {
        stub(20, 1, CREATOR);
        when(repo.markApproved(CO, WO, 1, USER)).thenReturn(0);
        assertThatThrownBy(() -> service.approve(WO, new WorkOrderStateCommand(1, null)))
                .satisfies(e -> assertThat(code(e)).isEqualTo(4003));
    }
}
