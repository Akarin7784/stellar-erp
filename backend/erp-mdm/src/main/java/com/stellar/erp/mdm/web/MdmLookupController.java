package com.stellar.erp.mdm.web;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.PageResult;
import com.stellar.erp.common.Result;
import com.stellar.erp.mdm.MdmLookupService;

/** 02-mdm 91 #1 / #55 / #138。権限（mdm:*:view）は認証落地後に接入。 */
@RestController
@RequestMapping("/api/mdm")
public class MdmLookupController {

    private final MdmLookupService service;

    public MdmLookupController(MdmLookupService service) {
        this.service = service;
    }

    @GetMapping("/factories")
    public Result<List<MdmLookupService.FactoryDto>> factories(@RequestParam(required = false) String resource) {
        return Result.ok(service.factories(resource));
    }

    @GetMapping("/warehouses/options")
    public Result<List<MdmLookupService.WarehouseOptionDto>> warehouseOptions(@RequestParam(required = false) Long factoryId) {
        return Result.ok(service.warehouseOptions(factoryId));
    }

    @GetMapping("/materials")
    public Result<PageResult<MdmLookupService.MaterialListDto>> materials(@RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") int pageNum, @RequestParam(defaultValue = "20") int pageSize) {
        return Result.ok(service.materials(keyword, pageNum, pageSize));
    }
}
