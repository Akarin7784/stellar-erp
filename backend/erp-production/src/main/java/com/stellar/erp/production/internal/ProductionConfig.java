package com.stellar.erp.production.internal;

import org.springframework.context.annotation.Configuration;

/**
 * 生产模块配置。
 *
 * <p>原先 SAL 未合入时注册的「一律返回 5000」的 {@code SalesOrderLineLookup} 默认实现已移除：
 * sal/V202610210705 合入后由 {@link JdbcSalesOrderLineLookup} 直接读正式表。</p>
 */
@Configuration(proxyBeanMethods = false)
class ProductionConfig {
}
