package com.stellar.erp.common;

/**
 * 业务异常：由全局异常处理器统一转换为 {@link Result} 响应。
 *
 * <p>约定错误码分段：4xx 客户端问题、5xx 服务端问题、1xxx 业务规则、2xxx 外部依赖。</p>
 */
public class BizException extends RuntimeException {

    private final int code;

    public BizException(int code, String message) {
        super(message);
        this.code = code;
    }

    public BizException(String message) {
        this(400, message);
    }

    public BizException(int code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
    }

    public int getCode() {
        return code;
    }
}
