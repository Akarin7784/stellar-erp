package com.stellar.erp.production.web;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.RequirePermission;
import com.stellar.erp.common.Result;
import com.stellar.erp.production.WorkOrderCreateCommand;
import com.stellar.erp.production.WorkOrderApprovalService;
import com.stellar.erp.production.WorkOrderCreated;
import com.stellar.erp.production.WorkOrderDetail;
import com.stellar.erp.production.WorkOrderQueryService;
import com.stellar.erp.production.WorkOrderStateCommand;
import com.stellar.erp.production.WorkOrderReleaseCommand;
import com.stellar.erp.production.WorkOrderReleaseService;
import com.stellar.erp.production.WorkOrderReleased;
import com.stellar.erp.production.WorkOrderService;

import jakarta.validation.Valid;

/** 工单 API（06-production 91 #26 / 02-work-order §7 No.3）。权限 production:work-order:create 待认证落地后接入。 */
@RestController
@RequestMapping("/api/production/work-orders")
public class WorkOrderController {

    private final WorkOrderService service;
    private final WorkOrderReleaseService releaseService;
    private final WorkOrderApprovalService approvalService;
    private final WorkOrderQueryService queryService;

    public WorkOrderController(WorkOrderService service, WorkOrderReleaseService releaseService,
                               WorkOrderApprovalService approvalService, WorkOrderQueryService queryService) {
        this.service = service;
        this.releaseService = releaseService;
        this.approvalService = approvalService;
        this.queryService = queryService;
    }

    /** 詳細（91 #24 / 02 §7 No.2）。 */
    @GetMapping("/{id}")
    public Result<WorkOrderDetail> get(@PathVariable long id) {
        return Result.ok(queryService.get(id));
    }

    /**
     * 承認 20→25（Lead 2026-10-21 決定）。将来の Flowable E32 コールバックと同じ
     * {@link WorkOrderApprovalService#approve} を呼ぶ。08-workflow 落地後はコールバック専用とし、この API は廃止する。
     * 権限：production:work-order:approve（06/91 #28a）。
     */
    @PostMapping("/{id}/approve")
    @RequirePermission("production:work-order:approve")
    public Result<WorkOrderDetail> approve(@PathVariable long id, @Valid @RequestBody WorkOrderStateCommand body) {
        return Result.ok(approvalService.approve(id, body));
    }

    /** 承認提出 10→20（91 #28 / 02 §7 No.5）。 */
    @PostMapping("/{id}/submit")
    public Result<WorkOrderDetail> submit(@PathVariable long id, @Valid @RequestBody WorkOrderStateCommand body) {
        return Result.ok(approvalService.submit(id, body));
    }


    @PostMapping
    public ResponseEntity<Result<WorkOrderCreated>> create(@Valid @RequestBody WorkOrderCreateCommand body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(Result.ok(service.create(body)));
    }

    /** 下达（91 #29 / §3.2）：200。标准成本未设定时 data.warnings[] 含 MSG-FIN-117。 */
    @PostMapping("/{id}/release")
    public Result<WorkOrderReleased> release(@PathVariable long id, @Valid @RequestBody WorkOrderReleaseCommand body) {
        return Result.ok(releaseService.release(id, body));
    }
}
