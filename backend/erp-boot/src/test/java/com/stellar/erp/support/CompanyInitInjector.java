package com.stellar.erp.support;

import java.util.function.BiConsumer;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

import com.stellar.erp.system.company.CompanyService;

/** テスト用：公司 INSERT 後・sys_init_company 前（同一 TX）に任意処理を差し込む。既定は何もしない。 */
@Component
public class CompanyInitInjector implements CompanyService.BeforeInitHook {

    public static volatile BiConsumer<JdbcClient, Long> action = (j, id) -> { };

    private final JdbcClient jdbc;

    public CompanyInitInjector(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void beforeInit(long tenantId, long companyId) {
        action.accept(jdbc, companyId);
    }

    public static void reset() {
        action = (j, id) -> { };
    }
}
