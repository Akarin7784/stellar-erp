package com.stellar.erp.production.web;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.Result;
import com.stellar.erp.production.OverproductionApprovalService;
import com.stellar.erp.production.OverproductionApproved;
import com.stellar.erp.production.OverproductionRequestCommand;
import com.stellar.erp.production.OverproductionRequested;
import com.stellar.erp.production.WorkOrderStateCommand;

import jakarta.validation.Valid;

/**
 * 超产申请 / 承認 API（90 §3.19.1、G2-18 6.）。
 *
 * <p>91 の API 一覧にパスが未定義のため、91 の命名慣例（{@code /api/production/<複数形リソース>}、状態操作は
 * {@code POST /{id}/<動詞>}）に合わせた暫定パス。会社・租户は LoginContext から取り、body の {@code companyId} は無視する。
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

    /** 承認 → 30（受注行・工单の allowed_qty を +request_qty）。body は {@code {"version": n}}。 */
    @PostMapping("/{id}/approve")
    public Result<OverproductionApproved> approve(@PathVariable long id, @Valid @RequestBody WorkOrderStateCommand body) {
        return Result.ok(service.approve(id, body.version()));
    }
}
