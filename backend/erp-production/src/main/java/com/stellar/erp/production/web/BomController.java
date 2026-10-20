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

    /** {@code ?materialId&date}（02 §4.5）。{@code factoryId} 必須（BOM は工厂別、Lead 2026-10-21 決定）。欠落は 400 / 1001。 */
    @GetMapping("/effective")
    public Result<BomQueryService.EffectiveBom> effective(@RequestParam long materialId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam long factoryId) {
        return Result.ok(service.effective(materialId, factoryId, date));
    }
}
