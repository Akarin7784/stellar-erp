package com.stellar.erp.system.company;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.system.company.CompanyService.CreateCompanyCommand;

/**
 * 公司登録の監査ログ（PRC-SYS-014-03 手順 4 / 05 PRC-SYS-009-01 4.）。呼出し元トランザクション内で同期 INSERT。
 * company_id は操作したセッション会社、resource_id/resource_no は新会社の id／公司代码、after_data は登録項目（機密項目なし）。
 * 失敗時の例外はそのまま送出し、{@link CompanyService} が 5000 / MSG-SYS-091 に変換してロールバックする。
 */
@Component
public class CompanyAuditWriter {

    private final JdbcClient jdbc;

    public CompanyAuditWriter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    public void write(long tenant, long companyId, CreateCompanyCommand c) {
        LoginContext.LoginUser login = LoginContext.current().orElse(null);
        long userId = login == null ? 0L : login.userId();
        long sessionCompany = login == null ? companyId : login.companyId();
        jdbc.sql("""
                        INSERT INTO sys_audit_log (id, tenant_id, company_id, created_by, user_id, username,
                            operation_type, module_code, resource_code, resource_id, resource_no, after_data, result)
                        VALUES (:id, :tenant, :company, :user, :user,
                                (SELECT u.username FROM sys_user u WHERE u.tenant_id = :tenant AND u.id = :user),
                                'CREATE', 'system', 'company', :rid, :rno,
                                jsonb_build_object('companyCode', CAST(:code AS TEXT), 'companyName', CAST(:name AS TEXT),
                                    'unifiedSocialCreditCode', CAST(:uscc AS TEXT), 'taxPayerType', CAST(:tpt AS INT),
                                    'fiscalYearStartMonth', CAST(:fysm AS INT), 'baseCurrencyCode', CAST(:cur AS TEXT),
                                    'address', CAST(:addr AS TEXT), 'provinceCode', CAST(:prov AS TEXT),
                                    'cityCode', CAST(:city AS TEXT)), 1)
                        """)
                .param("id", IdWorker.getId()).param("tenant", tenant).param("company", sessionCompany)
                .param("user", userId).param("rid", String.valueOf(companyId)).param("rno", c.companyCode())
                .param("code", c.companyCode()).param("name", c.companyName())
                .param("uscc", c.unifiedSocialCreditCode()).param("tpt", c.taxPayerType())
                .param("fysm", c.fiscalYearStartMonth()).param("cur", c.baseCurrencyCode())
                .param("addr", c.address()).param("prov", c.provinceCode()).param("city", c.cityCode())
                .update();
    }
}
