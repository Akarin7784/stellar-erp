package com.stellar.erp.system.web;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.Result;
import com.stellar.erp.system.AuthSessions;
import com.stellar.erp.system.auth.AuthMeService;
import com.stellar.erp.system.auth.LoginService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

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

    public record LoginRequest(
            @NotBlank(message = "请输入必填项「企业代码」。") @Size(max = 32, message = "「企业代码」不能超过 32 个字符。")
            @Pattern(regexp = "[A-Za-z0-9]*", message = "「企业代码」只能为半角英数。") String tenantCode,
            @NotBlank(message = "请输入必填项「账号」。") @Size(max = 64, message = "「账号」不能超过 64 个字符。") String username,
            @NotBlank(message = "请输入必填项「密码」。") @Size(max = 64, message = "「密码」不能超过 64 个字符。") String password,
            String captchaKey, String captcha, Boolean rememberMe) {
    }

    /** ログイン（#2）：ログイン不要。 */
    @PostMapping("/login")
    public Result<LoginService.LoginResult> login(@Valid @RequestBody LoginRequest req, HttpServletRequest http) {
        return Result.ok(login.login(new LoginService.LoginCommand(req.tenantCode(), req.username(), req.password(),
                http.getRemoteAddr(), http.getHeader("User-Agent"))));
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
