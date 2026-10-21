package com.stellar.erp;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * {@link AuthInterceptor} の適用範囲：{@code /api/**}。
 * 除外（Lead 2026-10-21 決定、この 3 件のみ）：ログイン・ログアウト（{@code /api/system/auth/login}・{@code /logout}）とヘルスチェック（{@code /api/v1/system/ping}）。
 */
@Configuration
public class WebAuthConfig implements WebMvcConfigurer {

    private final AuthInterceptor auth;
    private final SaTokenContextInterceptor saContext;

    public WebAuthConfig(AuthInterceptor auth, SaTokenContextInterceptor saContext) {
        this.auth = auth;
        this.saContext = saContext;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(saContext).addPathPatterns("/**").order(0);
        registry.addInterceptor(auth).order(1)
                .addPathPatterns("/api/**")
                .excludePathPatterns("/api/system/auth/login", "/api/system/auth/logout", "/api/v1/system/ping");
    }
}
