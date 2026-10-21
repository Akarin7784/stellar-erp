package com.stellar.erp.common;

import java.io.Serializable;

/**
 * 统一响应体。
 *
 * <p>响应体固定为 {@code {code, message, data, msgId}} 4 个键（API 规格 03 §5），不输出派生字段。</p>
 *
 * <p>约定：{@code code == 0} 表示成功，非 0 为业务错误码；HTTP 状态码由全局异常处理器决定。</p>
 *
 * <p>位于 common 模块根包，按 Spring Modulith 约定属于对外暴露类型；
 * 子包（如 {@code internal}）不对外暴露。</p>
 *
 * @param code    业务码，0 = 成功
 * @param message 提示信息
 * @param data    业务数据
 * @param msgId   消息编号（如 {@code MSG-PRD-040}），可空；见 API 规格 §5.1
 */
public record Result<T>(int code, String message, T data, String msgId) implements Serializable {

    public static <T> Result<T> ok(T data) {
        return new Result<>(0, "ok", data, null);
    }

    public static Result<Void> ok() {
        return new Result<>(0, "ok", null, null);
    }

    public static <T> Result<T> fail(int code, String message) {
        return new Result<>(code, message, null, null);
    }

    public static <T> Result<T> fail(int code, String message, String msgId) {
        return new Result<>(code, message, null, msgId);
    }
}
