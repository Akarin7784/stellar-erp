package com.stellar.erp;

import javax.sql.DataSource;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** 以 TenantAwareTransactionManager 替换 Spring Boot 默认的 JDBC 事务管理器。 */
@Configuration(proxyBeanMethods = false)
class TenantTransactionConfig {

    @Bean
    TenantAwareTransactionManager transactionManager(DataSource dataSource) {
        return new TenantAwareTransactionManager(dataSource);
    }
}
