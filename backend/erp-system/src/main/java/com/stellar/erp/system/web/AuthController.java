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

    /** 1001 の data：最初に不正だった項目名（フォーム順 tenantCode → username → password）。 */
    public record InvalidField(String field) {
    }

    static final String MSG_REQUIRED = "MSG-COM-040";
    static final String MSG_TOO_LONG = "MSG-COM-041";
    /** 半角英数以外：共通メッセージに該当 ID がないため msgId なし（BA に ID 採番を依頼中）。 */
    static final String MSG_FORMAT = null;
    private static final java.util.regex.Pattern ALNUM = java.util.regex.Pattern.compile("[A-Za-z0-9]+");

    /** CHK-SYS-001-12 / 01〜03。フォーム順で最初の違反のみ返す。 */
    static Optional<Result<InvalidField>> validate(LoginRequest r) {
        if (r == null) {
            r = new LoginRequest(null, null, null, null, null, null);
        }
        Optional<Result<InvalidField>> v = check("tenantCode", "企业代码", r.tenantCode(), 32);
        if (v.isEmpty() && !ALNUM.matcher(r.tenantCode()).matches()) {
            v = Optional.of(new Result<>(1001, "「企业代码」只能为半角英数。", new InvalidField("tenantCode"), MSG_FORMAT));
        }
        if (v.isEmpty()) {
            v = check("username", "账号", r.username(), 64);
        }
        if (v.isEmpty()) {
            v = check("password", "密码", r.password(), 64);
        }
        return v;
    }

    private static Optional<Result<InvalidField>> check(String field, String label, String value, int max) {
        if (value == null || value.isBlank()) {
            return Optional.of(new Result<>(1001, "请输入必填项「" + label + "」。", new InvalidField(field), MSG_REQUIRED));
        }
        if (value.length() > max) {
            return Optional.of(new Result<>(1001, "「" + label + "」不能超过 " + max + " 个字符。", new InvalidField(field),
                    MSG_TOO_LONG));
        }
        return Optional.empty();
    }

    /**
     * ログイン（#2）：ログイン不要。パラメータ検証エラー（1001、data.field に最初の不正項目）・業務エラー（2002 / 2003 /
     * 账号停用 ACCOUNT_DISABLED / 楽観排他 1 回リトライ後の 4003 等）は本エンドポイントに限りすべて HTTP 200 + body の code
     * で返す（#71 決定）。他 API の同コードは共通規則どおり（業務エラー 422、4003 は 409）。
     */
    @PostMapping("/login")
    public Result<?> login(@RequestBody(required = false) LoginRequest req, HttpServletRequest http) {
        Optional<Result<InvalidField>> invalid = validate(req);
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
