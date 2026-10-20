package com.stellar.erp.support;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;
import org.testcontainers.postgresql.PostgreSQLContainer;

/** 以 owner（容器超级用户）身份连接，仅用于测试准备数据 / 安装测试扩展。会绕过 RLS，切勿用于断言隔离。 */
public final class OwnerJdbc {

    private OwnerJdbc() {
    }

    public static JdbcTemplate of(PostgreSQLContainer pg) {
        SingleConnectionDataSource ds = new SingleConnectionDataSource(pg.getJdbcUrl(), pg.getUsername(), pg.getPassword(), true);
        return new JdbcTemplate(ds);
    }
}
