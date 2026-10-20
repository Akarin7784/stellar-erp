package com.stellar.erp;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.Result;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 全局异常处理：把异常统一转换为 {@link Result}，并按
 * {@code docs/design/00-common/03-common-api-spec.md} §6.2 设置 HTTP 状态码。
 *
 * <p>响应体与业务码保持不变，只修正 HTTP 状态（此前业务异常一律返回 200）。</p>
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BizException.class)
    public ResponseEntity<Result<Void>> handleBiz(BizException ex) {
        return ResponseEntity.status(httpStatusOf(ex.getCode()))
                .body(Result.fail(ex.getCode(), ex.getMessage(), ex.getMsgId()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Result<Void>> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(error -> error.getField() + " " + error.getDefaultMessage())
                .orElse("参数校验失败");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Result.fail(400, message));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Result<Void>> handleUnknown(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Result.fail(500, "服务器内部错误"));
    }

    /**
     * 业务码到 HTTP 状态的映射（API 规格 §6.1、§6.2、§9）。
     *
     * <p>兼容旧写法：直接用 HTTP 数字作业务码（如 {@code new BizException("...")} 默认的 400）时，按原值返回。</p>
     */
    static HttpStatus httpStatusOf(int code) {
        if (code >= 1000 && code <= 1999) {
            return HttpStatus.BAD_REQUEST;
        }
        if (code >= 2000 && code <= 2999) {
            return HttpStatus.UNAUTHORIZED;
        }
        if (code >= 3000 && code <= 3999) {
            return HttpStatus.FORBIDDEN;
        }
        if (code == 4001) {
            return HttpStatus.NOT_FOUND;
        }
        if (code == 4002 || code == 4003 || code == 4005) {
            return HttpStatus.CONFLICT;
        }
        if (code >= 4000 && code <= 4999) {
            return HttpStatus.UNPROCESSABLE_CONTENT;
        }
        if (code == 5001) {
            return HttpStatus.SERVICE_UNAVAILABLE;
        }
        if (code == 5002) {
            return HttpStatus.TOO_MANY_REQUESTS;
        }
        if (code >= 5000 && code <= 5999) {
            return HttpStatus.INTERNAL_SERVER_ERROR;
        }
        if (code >= 10000 && code <= 99999) {
            return HttpStatus.UNPROCESSABLE_CONTENT;
        }
        HttpStatus legacy = HttpStatus.resolve(code);
        if (legacy != null && legacy.isError()) {
            return legacy;
        }
        return HttpStatus.INTERNAL_SERVER_ERROR;
    }
}
