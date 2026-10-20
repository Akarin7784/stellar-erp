package com.stellar.erp.system.web;

import com.stellar.erp.common.Result;
import java.time.OffsetDateTime;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 系统管理模块连通性探针。
 */
@RestController
@RequestMapping("/api/v1/system")
public class SystemPingController {

    @GetMapping("/ping")
    public Result<Map<String, Object>> ping() {
        return Result.ok(Map.of(
                "module", "erp-system",
                "status", "UP",
                "time", OffsetDateTime.now().toString()
        ));
    }
}
