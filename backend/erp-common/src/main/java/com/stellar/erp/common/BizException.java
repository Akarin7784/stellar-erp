package com.stellar.erp.common;

/**
 * 业务异常：由全局异常处理器统一转换为 {@link Result} 响应。
 *
 * <p>错误码号段见 {@code docs/design/00-common/03-common-api-spec.md} §6.1：1xxx 输入校验、2xxx 认证、
 * 3xxx 权限、4xxx 通用业务状态、5000 系统错误、10000 以上为各域业务码。</p>
 */
public class BizException extends RuntimeException {

    private final int code;

    /** 消息编号（如 {@code MSG-PRD-040}），可空。 */
    private final String msgId;

    public BizException(int code, String message) {
        this(code, null, message);
    }

    public BizException(int code, String msgId, String message) {
        super(message);
        this.code = code;
        this.msgId = msgId;
    }

    public BizException(String message) {
        this(1001, message);
    }

    public BizException(int code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
        this.msgId = null;
    }

    public int getCode() {
        return code;
    }

    public String getMsgId() {
        return msgId;
    }
}
