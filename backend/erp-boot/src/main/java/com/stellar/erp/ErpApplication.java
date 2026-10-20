package com.stellar.erp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Stellar ERP 启动类。
 *
 * <p>模块化单体：业务模块位于 {@code com.stellar.erp.{module}}，
 * 模块边界由 Spring Modulith 在测试阶段校验。</p>
 */
@SpringBootApplication
public class ErpApplication {

    public static void main(String[] args) {
        SpringApplication.run(ErpApplication.class, args);
    }
}
