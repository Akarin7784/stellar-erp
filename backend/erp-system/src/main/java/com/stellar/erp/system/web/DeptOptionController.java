package com.stellar.erp.system.web;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.Result;
import com.stellar.erp.system.dept.DeptOptionService;

/** 部門選択用一覧。権限は認証落地後に接入。 */
@RestController
@RequestMapping("/api/system")
public class DeptOptionController {

    private final DeptOptionService service;

    public DeptOptionController(DeptOptionService service) {
        this.service = service;
    }

    @GetMapping("/depts/options")
    public Result<List<DeptOptionService.DeptOptionDto>> options() {
        return Result.ok(service.options());
    }
}
