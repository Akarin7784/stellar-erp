package com.stellar.erp;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.RequirePermission;
import com.stellar.erp.common.Result;

/** テスト専用：{@link RequirePermission} の検証用エンドポイント（test classpath のみ）。 */
@RestController
@RequestMapping("/api/test/permission-probe")
@RequirePermission("test:probe:class")
class PermissionProbeController {

    @GetMapping("/method")
    @RequirePermission("test:probe:view")
    Result<String> method() {
        return Result.ok("ok");
    }

    @GetMapping("/class")
    Result<String> classLevel() {
        return Result.ok("ok");
    }
}
