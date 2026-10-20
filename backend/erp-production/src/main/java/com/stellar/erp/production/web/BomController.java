package com.stellar.erp.production.web;

import java.time.LocalDate;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.Result;
import com.stellar.erp.production.BomQueryService;

/** BOM API（91 #9）。 */
@RestController
@RequestMapping("/api/production/boms")
public class BomController {

    private final BomQueryService service;

    public BomController(BomQueryService service) {
        this.service = service;
    }

    /** {@code ?materialId&date}（02 §4.5）。{@code factoryId} は任意（BOM は工厂別のため追加、設計書未記載）。 */
    @GetMapping("/effective")
    public Result<BomQueryService.EffectiveBom> effective(@RequestParam long materialId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) Long factoryId) {
        return Result.ok(service.effective(materialId, factoryId, date));
    }
}
