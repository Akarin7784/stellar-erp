package com.stellar.erp.production.web;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.PageResult;
import com.stellar.erp.common.Result;
import com.stellar.erp.production.OverproductionApprovalService;
import com.stellar.erp.production.OverproductionApprovalView;
import com.stellar.erp.production.OverproductionApproved;
import com.stellar.erp.production.OverproductionRejectCommand;
import com.stellar.erp.production.OverproductionRequestCommand;
import com.stellar.erp.production.OverproductionRequested;
import com.stellar.erp.production.WorkOrderStateCommand;

import jakarta.validation.Valid;

/**
 * 超产申请 / 承認 API（90 §3.19.1、G2-18 6.）。
 *
 * <p>91 #39a〜39g・§3.14。会社・租户は LoginContext から取り、body の {@code companyId} は無視する。
 * TODO 権限チェックは認証落地後に接入。</p>
 */
@RestController
@RequestMapping("/api/production/overproduction-approvals")
public class OverproductionApprovalController {

    private final OverproductionApprovalService service;

    public OverproductionApprovalController(OverproductionApprovalService service) {
        this.service = service;
    }

    /** 申請保存（10）。成功 201。数量不正は 422 / 60103。 */
    @PostMapping
    public ResponseEntity<Result<OverproductionRequested>> create(@RequestBody OverproductionRequestCommand body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(Result.ok(service.request(body)));
    }

    /** 詳細。 */
    @GetMapping("/{id}")
    public Result<OverproductionApprovalView> get(@PathVariable long id) {
        return Result.ok(service.get(id));
    }

    /** 一覧（当前公司のみ。salesOrderLineId / workOrderId / approvalStatus で絞込、page/size は 91 §3.14）。 */
    @GetMapping
    public Result<PageResult<OverproductionApprovalView>> list(@RequestParam(required = false) Long salesOrderLineId,
            @RequestParam(required = false) Long workOrderId, @RequestParam(required = false) Short approvalStatus,
            @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int size) {
        return Result.ok(service.list(salesOrderLineId, workOrderId, approvalStatus, page, size));
    }

    /** 提出 10→20。body は {@code {"version": n}}。 */
    @PostMapping("/{id}/submit")
    public Result<OverproductionApprovalView> submit(@PathVariable long id, @Valid @RequestBody WorkOrderStateCommand body) {
        return Result.ok(service.submit(id, body.version()));
    }

    /** 却下 20→40。body は {@code {"version": n, "rejectReason": "理由"}}。 */
    @PostMapping("/{id}/reject")
    public Result<OverproductionApprovalView> reject(@PathVariable long id, @Valid @RequestBody OverproductionRejectCommand body) {
        return Result.ok(service.reject(id, body.version(), body.rejectReason()));
    }

    /** 取消 10/20→90。 */
    @PostMapping("/{id}/cancel")
    public Result<OverproductionApprovalView> cancel(@PathVariable long id, @Valid @RequestBody WorkOrderStateCommand body) {
        return Result.ok(service.cancel(id, body.version()));
    }

    /** 承認 20→30（受注行・工单の allowed_qty を +request_qty）。body は {@code {"version": n}}。 */
    @PostMapping("/{id}/approve")
    public Result<OverproductionApproved> approve(@PathVariable long id, @Valid @RequestBody WorkOrderStateCommand body) {
        return Result.ok(service.approve(id, body.version()));
    }
}
