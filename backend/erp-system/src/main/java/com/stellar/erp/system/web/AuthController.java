package com.stellar.erp.system.web;

import java.util.Optional;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.Result;
import com.stellar.erp.system.AuthSessions;
import com.stellar.erp.system.auth.AuthMeService;
import com.stellar.erp.system.auth.LoginService;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 認証 API（01-system 91 #2〜#4）。
 *
 * <p>{@code POST /login}（#2）：企業代码＋账号＋密码（BR-13）。検証コード（2005 / MSG-COM-022）は captcha API 実装時に追加。</p>
 */
@RestController
@RequestMapping("/api/system/auth")
public class AuthController {

    private final AuthMeService me;
    private final LoginService login;

    public AuthController(AuthMeService me, LoginService login) {
        this.me = me;
        this.login = login;
    }

    public record LoginRequest(String tenantCode, String username, String password,
                               String captchaKey, String captcha, Boolean rememberMe) {
    }

    /** 1001 の項目エラー（03 §5.3 {@code data.fieldErrors[]}）。 */
    public record FieldError(String field, String message) {
    }

    /** 1001 の data：違反した全項目（フォーム順 tenantCode → username → password、各項目は最初の違反のみ）。 */
    public record FieldErrors(java.util.List<FieldError> fieldErrors) {
    }

    record Violation(String field, String message, String msgId) {
    }

    static final String MSG_REQUIRED = "MSG-COM-040";
    static final String MSG_TOO_LONG = "MSG-COM-041";
    /** 半角英数以外：共通メッセージに該当 ID がないため msgId なし（BA に ID 採番を依頼中）。 */
    static final String MSG_FORMAT = null;
    private static final java.util.regex.Pattern ALNUM = java.util.regex.Pattern.compile("[A-Za-z0-9]+");

    /**
     * CHK-SYS-001-12 / 01〜03（BR-15）。違反があれば 1001：トップレベルの message / msgId は最初の違反、
     * {@code data.fieldErrors} に全違反。
     */
    static Optional<Result<FieldErrors>> validate(LoginRequest r) {
        if (r == null) {
            r = new LoginRequest(null, null, null, null, null, null);
        }
        java.util.List<Violation> vs = new java.util.ArrayList<>();
        Optional<Violation> t = check("tenantCode", "企业代码", r.tenantCode(), 32);
        if (t.isEmpty() && !ALNUM.matcher(r.tenantCode()).matches()) {
            t = Optional.of(new Violation("tenantCode", "「企业代码」只能为半角英数。", MSG_FORMAT));
        }
        t.ifPresent(vs::add);
        check("username", "账号", r.username(), 64).ifPresent(vs::add);
        check("password", "密码", r.password(), 64).ifPresent(vs::add);
        if (vs.isEmpty()) {
            return Optional.empty();
        }
        Violation first = vs.get(0);
        return Optional.of(new Result<>(1001, first.message(),
                new FieldErrors(vs.stream().map(v -> new FieldError(v.field(), v.message())).toList()), first.msgId()));
    }

    private static Optional<Violation> check(String field, String label, String value, int max) {
        if (value == null || value.isBlank()) {
            return Optional.of(new Violation(field, "请输入必填项「" + label + "」。", MSG_REQUIRED));
        }
        if (value.length() > max) {
            return Optional.of(new Violation(field, "「" + label + "」不能超过 " + max + " 个字符。", MSG_TOO_LONG));
        }
        return Optional.empty();
    }

    /**
     * ログイン（#2）：ログイン不要。パラメータ検証エラー（1001、data.fieldErrors に全違反項目）・業務エラー（2002 / 2003 /
     * 账号停用 ACCOUNT_DISABLED / 楽観排他 1 回リトライ後の 4003 等）は本エンドポイントに限りすべて HTTP 200 + body の code
     * で返す（#71 決定）。他 API の同コードは共通規則どおり（業務エラー 422、4003 は 409）。
     */
    @PostMapping("/login")
    public Result<?> login(@RequestBody(required = false) LoginRequest req, HttpServletRequest http) {
        Optional<Result<FieldErrors>> invalid = validate(req);
        if (invalid.isPresent()) {
            return invalid.get();
        }
        try {
            return Result.ok(login.login(new LoginService.LoginCommand(req.tenantCode(), req.username(),
                    req.password(), http.getRemoteAddr(), http.getHeader("User-Agent"))));
        } catch (BizException e) {
            return Result.fail(e.getCode(), e.getMessage(), e.getMsgId());
        }
    }

    /** ログアウト（#3）：ログイン不要。トークンなし・無効・期限切れでも 200（冪等）。当該トークンのみ失効（BR-07）。 */
    @PostMapping("/logout")
    public Result<Void> logout() {
        AuthSessions.logoutCurrentToken();
        return Result.ok();
    }

    /** ログインユーザ・ロール・権限コード（コードで重複排除）（#4）。 */
    @GetMapping("/me")
    public Result<AuthMeService.Me> me() {
        return Result.ok(me.me());
    }
}
