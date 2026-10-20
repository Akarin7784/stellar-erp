package com.stellar.erp.production.web;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.Result;
import com.stellar.erp.production.WorkOrderCreateCommand;
import com.stellar.erp.production.WorkOrderCreated;
import com.stellar.erp.production.WorkOrderService;

import jakarta.validation.Valid;

/** 工单 API（06-production 91 #26 / 02-work-order §7 No.3）。权限 production:work-order:create 待认证落地后接入。 */
@RestController
@RequestMapping("/api/production/work-orders")
public class WorkOrderController {

    private final WorkOrderService service;

    public WorkOrderController(WorkOrderService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<Result<WorkOrderCreated>> create(@Valid @RequestBody WorkOrderCreateCommand body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(Result.ok(service.create(body)));
    }
}
