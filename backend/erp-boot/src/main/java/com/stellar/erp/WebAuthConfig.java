package com.stellar.erp;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * {@link AuthInterceptor} の適用範囲：{@code /api/**}。
 * 除外：ログイン（{@code /api/system/auth/login}、03 §3）とヘルスチェック（{@code /api/v1/system/ping}）。
 */
@Configuration
public class WebAuthConfig implements WebMvcConfigurer {

    private final AuthInterceptor auth;

    public WebAuthConfig(AuthInterceptor auth) {
        this.auth = auth;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(auth)
                .addPathPatterns("/api/**")
                .excludePathPatterns("/api/system/auth/login", "/api/v1/system/ping");
    }
}
