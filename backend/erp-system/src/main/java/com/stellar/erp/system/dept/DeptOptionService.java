package com.stellar.erp.system.dept;

import java.util.List;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.stellar.erp.common.LoginContext;

/**
 * 部門の選択用一覧（他域の部门選択、例：工单画面 SCR-PRD-009）。
 * tenant は RLS、company は登录上下文で明示条件（company_id パラメータは受け付けない）。
 * 有効（status=1）・未削除（deleted=FALSE）のみ返す。
 *
 * <p>返却項目は 02-mdm 91 §3.8 の選択用 API の方針（ID・コード・名称）に合わせる。
 * 並び順は sys_department のツリー表示順（idx_sys_department_parent：parent_id, sort_no）を参考に
 * sort_no → department_code とする（設計書に本 API の定義なし、暫定）。</p>
 */
@Service
public class DeptOptionService {

    public record DeptOptionDto(long id, String departmentCode, String departmentName) {
    }

    private final JdbcClient jdbc;

    public DeptOptionService(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public List<DeptOptionDto> options() {
        long company = LoginContext.require().companyId();
        return jdbc.sql("""
                        SELECT id, department_code, department_name FROM sys_department
                         WHERE company_id = :c AND deleted = FALSE AND status = 1
                         ORDER BY sort_no, department_code
                        """).param("c", company)
                .query((rs, i) -> new DeptOptionDto(rs.getLong(1), rs.getString(2), rs.getString(3)))
                .list();
    }
}
