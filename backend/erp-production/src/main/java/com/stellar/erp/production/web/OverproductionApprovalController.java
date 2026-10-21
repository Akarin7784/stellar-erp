package com.stellar.erp.production.web;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.PageResult;
import com.stellar.erp.common.RequirePermission;
import com.stellar.erp.common.Result;
import com.stellar.erp.production.OverproductionApprovalService;
import com.stellar.erp.production.OverproductionApprovalView;
import com.stellar.erp.production.OverproductionApproved;
import com.stellar.erp.production.OverproductionRejectCommand;
import com.stellar.erp.production.OverproductionRequestCommand;
import com.stellar.erp.production.OverproductionRequested;
import com.stellar.erp.production.OverproductionUpdateCommand;
import com.stellar.erp.production.SalesOrderLineOption;
import com.stellar.erp.production.WorkOrderStateCommand;

import jakarta.validation.Valid;

/**
 * 超产申请 / 承認 API（90 §3.19.1、G2-18 6.）。
 *
 * <p>91 #39a〜39g・§3.14。会社・租户は LoginContext から取り、body の {@code companyId} は無視する。
 * 権限は 91 #39a〜39g の権限コード（{@link RequirePermission}、AuthInterceptor が検証）。</p>
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
    @RequirePermission("production:overproduction-approval:create")
    public ResponseEntity<Result<OverproductionRequested>> create(@RequestBody OverproductionRequestCommand body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(Result.ok(service.request(body)));
    }

    /** 詳細。 */
    @GetMapping("/{id}")
    @RequirePermission("production:overproduction-approval:view")
    public Result<OverproductionApprovalView> get(@PathVariable long id) {
        return Result.ok(service.get(id));
    }

    /** 一覧（当前公司のみ。salesOrderLineId / workOrderId / approvalStatus で絞込、page/size は 91 §3.14）。 */
    @GetMapping
    @RequirePermission("production:overproduction-approval:view")
    public Result<PageResult<OverproductionApprovalView>> list(@RequestParam(required = false) Long salesOrderLineId,
            @RequestParam(required = false) Long workOrderId, @RequestParam(required = false) Short approvalStatus,
            @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int size) {
        return Result.ok(service.list(salesOrderLineId, workOrderId, approvalStatus, page, size));
    }

    /** 提出 10→20。body は {@code {"version": n}}。 */
    @PostMapping("/{id}/submit")
    @RequirePermission("production:overproduction-approval:submit")
    public Result<OverproductionApprovalView> submit(@PathVariable long id, @Valid @RequestBody WorkOrderStateCommand body) {
        return Result.ok(service.submit(id, body.version()));
    }

    /** 却下 20→40。body は {@code {"version": n, "rejectReason": "理由"}}。 */
    @PostMapping("/{id}/reject")
    @RequirePermission("production:overproduction-approval:approve")
    public ResponseEntity<Result<?>> reject(@PathVariable long id, @RequestBody OverproductionRejectCommand body) {
        java.util.List<Violation> vs = new java.util.ArrayList<>();
        if (body == null || body.version() == null) {
            vs.add(new Violation("version", "请输入必填项「version」。", MSG_REQUIRED));
        }
        String reason = body == null ? null : body.rejectReason();
        if (reason == null || reason.isBlank()) {
            vs.add(new Violation("rejectReason", "请输入必填项「却下理由」。", MSG_REQUIRED));
        } else if (reason.length() > REJECT_REASON_MAX) {
            vs.add(new Violation("rejectReason", "「却下理由」不能超过 " + REJECT_REASON_MAX + " 个字符。", MSG_TOO_LONG));
        }
        if (!vs.isEmpty()) {
            Violation first = vs.get(0);
            return ResponseEntity.badRequest().body(new Result<>(1001, first.message(),
                    new FieldErrors(vs.stream().map(v -> new FieldError(v.field(), v.message())).toList()), first.msgId()));
        }
        return ResponseEntity.ok(Result.ok(service.reject(id, body.version(), reason)));
    }

    static final String MSG_REQUIRED = "MSG-COM-040";
    static final String MSG_TOO_LONG = "MSG-COM-041";
    static final int REJECT_REASON_MAX = 500;

    /** 1001 の項目エラー（03 §5.3 {@code data.fieldErrors[]}）。 */
    public record FieldError(String field, String message) {
    }

    public record FieldErrors(java.util.List<FieldError> fieldErrors) {
    }

    record Violation(String field, String message, String msgId) {
    }

    /** 草稿修正 #39h（状態 10 のみ。requestQty・workOrderId・remark）。10 以外は 422 / 60101、version 不一致は 409 / 4003。 */
    @PutMapping("/{id}")
    @RequirePermission("production:overproduction-approval:create")
    public ResponseEntity<Result<?>> update(@PathVariable long id, @RequestBody OverproductionUpdateCommand body) {
        if (body != null && body.remark() != null && body.remark().length() > REMARK_MAX) {
            String msg = "「备注」不能超过 " + REMARK_MAX + " 个字符。";
            return ResponseEntity.badRequest().body(new Result<>(1001, msg,
                    new FieldErrors(java.util.List.of(new FieldError("remark", msg))), MSG_TOO_LONG));
        }
        return ResponseEntity.ok(Result.ok(service.update(id, body)));
    }

    static final int REMARK_MAX = 500;

    /**
     * 超产申请用 受注行ピッカー（当前会社のみ、page/size は 91 §3.14 と同じ）。
     * {@code salesOrderNo}：受注番号の部分一致、{@code material}：品目コード／品名の部分一致。
     */
    @GetMapping("/sales-order-lines")
    @RequirePermission("production:overproduction-approval:create")
    public ResponseEntity<Result<?>> salesOrderLines(@RequestParam(required = false) String salesOrderNo,
            @RequestParam(required = false) String material,
            @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int size) {
        // page/size は丸めずに 400 / 1001 + fieldErrors（size 上限 200）
        java.util.List<Violation> vs = new java.util.ArrayList<>();
        if (page < 1) {
            vs.add(new Violation("page", "「page」必须大于 0。", MSG_GREATER_THAN));
        }
        if (size < 1) {
            vs.add(new Violation("size", "「size」必须大于 0。", MSG_GREATER_THAN));
        } else if (size > PAGE_SIZE_MAX) {
            vs.add(new Violation("size", "「size」不能大于「" + PAGE_SIZE_MAX + "」。", MSG_NOT_GREATER_THAN));
        }
        if (!vs.isEmpty()) {
            Violation first = vs.get(0);
            return ResponseEntity.badRequest().body(new Result<>(1001, first.message(),
                    new FieldErrors(vs.stream().map(v -> new FieldError(v.field(), v.message())).toList()), first.msgId()));
        }
        return ResponseEntity.ok(Result.ok(service.searchSalesOrderLines(salesOrderNo, material, page, size)));
    }

    static final int PAGE_SIZE_MAX = 200;
    /** MSG-COM-044「「{0}」必须大于 {1}。」／MSG-COM-045「「{0}」不能大于「{1}」。」（00-common 05）。 */
    static final String MSG_GREATER_THAN = "MSG-COM-044";
    static final String MSG_NOT_GREATER_THAN = "MSG-COM-045";

    /** 取消 10/20→90。 */
    @PostMapping("/{id}/cancel")
    @RequirePermission("production:overproduction-approval:cancel")
    public Result<OverproductionApprovalView> cancel(@PathVariable long id, @Valid @RequestBody WorkOrderStateCommand body) {
        return Result.ok(service.cancel(id, body.version()));
    }

    /** 承認 20→30（受注行・工单の allowed_qty を +request_qty）。body は {@code {"version": n}}。 */
    @PostMapping("/{id}/approve")
    @RequirePermission("production:overproduction-approval:approve")
    public Result<OverproductionApproved> approve(@PathVariable long id, @Valid @RequestBody WorkOrderStateCommand body) {
        return Result.ok(service.approve(id, body.version()));
    }
}
