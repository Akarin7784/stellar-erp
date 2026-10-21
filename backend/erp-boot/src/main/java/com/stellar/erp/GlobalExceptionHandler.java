package com.stellar.erp;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.Result;
import com.stellar.erp.production.ProductionDbErrors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

/**
 * 全局异常处理：把异常统一转换为 {@link Result}，并按
 * {@code docs/design/00-common/03-common-api-spec.md} §6.2 设置 HTTP 状态码。
 *
 * <p>响应体与业务码保持不变，只修正 HTTP 状态（此前业务异常一律返回 200）。</p>
 */
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(BizException.class)
    public ResponseEntity<Result<Void>> handleBiz(BizException ex) {
        return ResponseEntity.status(httpStatusOf(ex.getCode()))
                .body(Result.fail(ex.getCode(), ex.getMessage(), ex.getMsgId()));
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(MethodArgumentNotValidException ex,
            HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(error -> error.getField() + " " + error.getDefaultMessage())
                .orElse("参数校验失败");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).headers(headers).body(Result.fail(1001, message));
    }

    /**
     * Spring MVC 自身的异常（405 方法不支持、400 请求体无法解析、404 路径不存在等）
     * 保留框架给出的 HTTP 状态，响应体统一为 {@link Result}，业务码按 {@link #codeOf(int)} 归入规格号段。
     */
    @Override
    protected ResponseEntity<Object> handleExceptionInternal(Exception ex, Object body, HttpHeaders headers,
            HttpStatusCode statusCode, WebRequest request) {
        if (statusCode.is5xxServerError()) {
            log.error("MVC 处理异常", ex);
        } else {
            log.debug("MVC 请求异常: {}", ex.getMessage());
        }
        String message = HttpStatus.resolve(statusCode.value()) != null
                ? HttpStatus.valueOf(statusCode.value()).getReasonPhrase()
                : "请求错误";
        return ResponseEntity.status(statusCode).headers(headers)
                .body(Result.fail(codeOf(statusCode.value()), message));
    }

    /**
     * DB 约束兜底：已知业务约束翻译为业务码（如 {@code ck_sal_sol_completed_qty} → 60040 / 422），
     * 其余仍按未处理异常返回 5000，不泄露约束细节。
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Result<Void>> handleDataIntegrity(DataIntegrityViolationException ex) {
        return ProductionDbErrors.translate(ex).map(this::handleBiz).orElseGet(() -> handleUnknown(ex));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Result<Void>> handleUnknown(Exception ex) {
        log.error("未处理异常", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Result.fail(5000, "服务器内部错误"));
    }

    /** 框架层 HTTP 状态到规格业务码（API 规格 §6.1）。 */
    static int codeOf(int httpStatus) {
        return switch (httpStatus) {
            case 401 -> 2001;
            case 403 -> 3001;
            case 404 -> 4001;
            case 503 -> 5001;
            case 429 -> 5002;
            default -> httpStatus >= 500 ? 5000 : 1001;
        };
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
        // 認証帯：2001（未認証/期限切れ）のみ 401。2002 ログイン失敗・2003 ロック・2004 パスワード期限切れ・
        // 2005 検証コード等はログイン画面で処理する業務結果として HTTP 200 + body の code（#71 決定）
        if (code == 2001) {
            return HttpStatus.UNAUTHORIZED;
        }
        if (code >= 2000 && code <= 2999) {
            return HttpStatus.OK;
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
