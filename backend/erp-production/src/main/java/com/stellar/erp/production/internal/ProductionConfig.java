package com.stellar.erp.production.internal;

import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.stellar.erp.common.BizException;
import com.stellar.erp.production.ProductionErrorCode;
import com.stellar.erp.production.SalesOrderLineLookup;

@Configuration(proxyBeanMethods = false)
class ProductionConfig {

    /**
     * SAL 域（T2）未合入前的默认实现：MTO（指定了受注行）一律返回 5000，不猜测受注行数据。
     * MTS（不指定受注行）不经过此端口。
     */
    @Bean
    @ConditionalOnMissingBean(SalesOrderLineLookup.class)
    SalesOrderLineLookup unavailableSalesOrderLineLookup() {
        return new SalesOrderLineLookup() {
            @Override
            public java.util.Optional<SalesOrderLine> find(long companyId, long salesOrderLineId) {
                throw unavailable();
            }

            @Override
            public java.util.Optional<SalesOrderLine> lockForUpdate(long companyId, long salesOrderLineId) {
                throw unavailable();
            }

            private BizException unavailable() {
                return new BizException(ProductionErrorCode.CONFIG_MISSING, "受注域（SAL）尚未提供受注行数据");
            }
        };
    }

}
