package com.stellar.erp;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import tools.jackson.databind.module.SimpleModule;
import tools.jackson.databind.ser.std.ToStringSerializer;

/**
 * JSON 全局规则（00-common 03-common-api-spec §8：ID（BIGINT）は文字列、2^53 超のため）。
 *
 * <p>Jackson 3（Spring Boot 4）。{@code Long} / {@code long} はレスポンスで一律文字列化し、DTO 個別の注釈は不要。
 * 逆シリアライズは既定のスカラー強制（{@code MapperFeature.ALLOW_COERCION_OF_SCALARS}）により
 * {@code "123"} と {@code 123} の双方を受け付ける。Boot は {@code JacksonModule} Bean を自動登録する。</p>
 */
@Configuration(proxyBeanMethods = false)
public class JacksonConfig {

    @Bean
    SimpleModule bigintAsStringModule() {
        SimpleModule module = new SimpleModule("bigint-as-string");
        module.addSerializer(Long.class, ToStringSerializer.instance);
        module.addSerializer(Long.TYPE, ToStringSerializer.instance);
        return module;
    }
}
