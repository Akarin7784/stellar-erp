package com.stellar.erp.system.web;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.Result;
import com.stellar.erp.system.AuthSessions;
import com.stellar.erp.system.auth.AuthMeService;

/**
 * 認証 API（01-system 91 #2〜#4）。
 *
 * <p>{@code POST /login}（#2）は sys_user の正式迁移（01/90 §sys_user：password_hash・account_status・lock_until・
 * login_fail_count・company 所属等）とログイン時のテナント特定方法が未確定のため未実装。</p>
 */
@RestController
@RequestMapping("/api/system/auth")
public class AuthController {

    private final AuthMeService me;

    public AuthController(AuthMeService me) {
        this.me = me;
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
