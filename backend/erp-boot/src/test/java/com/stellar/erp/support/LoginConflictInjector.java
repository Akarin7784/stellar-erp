package com.stellar.erp.support;

import java.util.function.LongConsumer;

import org.springframework.stereotype.Component;

import com.stellar.erp.system.auth.LoginService;

/** テスト用：ログイン時の sys_user 更新直前に任意処理（別接続での競合更新）を差し込む。既定は何もしない。 */
@Component
public class LoginConflictInjector implements LoginService.UserUpdateHook {

    public static volatile LongConsumer action = id -> { };

    @Override
    public void beforeUserUpdate(long userId) {
        action.accept(userId);
    }

    public static void reset() {
        action = id -> { };
    }
}
