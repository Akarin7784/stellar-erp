package com.stellar.erp.system.web;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.Result;
import com.stellar.erp.system.dept.DeptOptionService;

/**
 * 部門選択用一覧。/options 系は全て「ログインのみ必須・権限コード不要」（lead 決定）。
 * データ範囲は現在の会社 + RLS で絞る。403 テストは設けない。
 * 未ログイン時 401 のテストは認証インターセプター実装後に追加する。
 */
@RestController
@RequestMapping("/api/system")
public class DeptOptionController {

    private final DeptOptionService service;

    public DeptOptionController(DeptOptionService service) {
        this.service = service;
    }

    @GetMapping("/departments/options")
    public Result<List<DeptOptionService.DeptOptionDto>> options() {
        return Result.ok(service.options());
    }
}
