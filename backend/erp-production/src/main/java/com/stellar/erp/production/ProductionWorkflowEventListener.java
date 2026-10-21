package com.stellar.erp.production;

import org.springframework.modulith.events.ApplicationModuleListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;

import com.stellar.erp.common.WorkflowProcessCompleted;

/**
 * E32 の Modulith 購読入口。{@link ApplicationModuleListener} は {@code @TransactionalEventListener}
 * ＋ {@code @Async}。業務 TX は {@link ProductionWorkflowCallback} 内で租户設定の後に開くため、
 * ここでは {@link Propagation#NOT_SUPPORTED}（リスナー既定の REQUIRES_NEW だと租户未設定のまま
 * {@code app.tenant_id} を書いて失敗する）。
 */
@Component
public class ProductionWorkflowEventListener {

    private final ProductionWorkflowCallback callback;

    public ProductionWorkflowEventListener(ProductionWorkflowCallback callback) {
        this.callback = callback;
    }

    @ApplicationModuleListener(propagation = Propagation.NOT_SUPPORTED)
    void onProcessCompleted(WorkflowProcessCompleted event) {
        callback.onProcessCompleted(event);
    }
}
