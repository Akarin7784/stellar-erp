package com.stellar.erp;

import java.util.List;

import org.springframework.boot.context.event.ApplicationEnvironmentPreparedEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.util.StringUtils;

/**
 * prod profile 下校验必需的环境变量，缺失时在创建任何 Bean 之前启动失败。
 * Spring 对无法解析的占位符默认保留原文（如 "${DB_PASSWORD}"），不会自行报错，因此需要显式校验。
 */
public class RequiredEnvironmentCheck implements ApplicationListener<ApplicationEnvironmentPreparedEvent> {

    static final List<String> PROD_REQUIRED = List.of("DB_URL", "DB_USER", "DB_PASSWORD");

    @Override
    public void onApplicationEvent(ApplicationEnvironmentPreparedEvent event) {
        verify(event.getEnvironment());
    }

    static void verify(Environment env) {
        if (!env.acceptsProfiles(Profiles.of("prod"))) {
            return;
        }
        List<String> missing = PROD_REQUIRED.stream()
                .filter(key -> !StringUtils.hasText(env.getProperty(key)))
                .toList();
        if (!missing.isEmpty()) {
            throw new IllegalStateException("prod profile 缺少必需的环境变量: " + String.join(", ", missing));
        }
    }
}
