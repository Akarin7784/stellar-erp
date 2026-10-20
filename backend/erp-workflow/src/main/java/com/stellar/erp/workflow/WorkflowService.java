package com.stellar.erp.workflow;

import org.flowable.engine.RuntimeService;
import org.springframework.stereotype.Service;

/**
 * 工作流门面：对外只暴露稳定方法，内部实现可由 Flowable 替换。
 *
 * <p>当前为骨架实现，用于验证 Flowable 8 与 Spring Boot 4.1 的链路。
 * 里程碑 M2 前需补充：流程部署、任务查询、审批动作、历史归档。</p>
 */
@Service
public class WorkflowService {

    private final RuntimeService runtimeService;

    public WorkflowService(RuntimeService runtimeService) {
        this.runtimeService = runtimeService;
    }

    /** 运行中的流程实例数。 */
    public long runningProcessCount() {
        return runtimeService.createProcessInstanceQuery().count();
    }
}
