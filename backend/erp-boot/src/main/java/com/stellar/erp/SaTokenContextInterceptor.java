package com.stellar.erp;

import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import cn.dev33.satoken.servlet.util.SaTokenContextJakartaServletUtil;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Sa-Token のリクエストコンテキストを MVC 層で確実に用意する（Starter の Servlet フィルタが無い環境、例：MockMvc でも
 * {@code StpUtil} が使えるように）。{@link AuthInterceptor} とログアウトより前に適用し、リクエスト終了時に破棄する。
 */
@Component
public class SaTokenContextInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        SaTokenContextJakartaServletUtil.setContext(request, response);
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        SaTokenContextJakartaServletUtil.clearContext();
    }
}
