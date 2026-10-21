package com.stellar.erp.system.company;

import java.sql.SQLException;
import java.util.Set;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;
import com.stellar.erp.common.BizException;
import com.stellar.erp.common.TenantContext;

/**
 * 公司登録（01-system 03 PRC-SYS-014-03 / 91 #47a）。
 *
 * <ol>
 *   <li>{@code sys_company} を INSERT（{@code company_id} = 自行 {@code id}、租户はログインコンテキスト）。</li>
 *   <li>同一トランザクションで {@code sys_init_company(tenant, id)}：{@code sys_param} 既定行と SYSTEM_ADMIN ロール＋全権限。
 *       失敗時は会社登録ごとロールバック。</li>
 *   <li>同一トランザクションで {@code sys_audit_log} に CREATE / system / company を同期 INSERT（手順 4、05 PRC-SYS-009-01 4.）。
 *       INSERT 失敗時は会社登録ごとロールバックし 5000 / MSG-SYS-091。</li>
 *   <li>{@code uk_sys_company_code} / {@code uk_sys_company_credit} の一意違反（23505）のみ 10035 / MSG-SYS-093 / 422。
 *       その他の 23505 は変換しない。</li>
 * </ol>
 */
@Service
public class CompanyService {

    public static final int COMPANY_DUPLICATE = 10035;
    public static final String MSG_COMPANY_DUPLICATE = "MSG-SYS-093";
    static final Set<String> DUPLICATE_CONSTRAINTS = Set.of("uk_sys_company_code", "uk_sys_company_credit");

    /** テスト用フック：INSERT 後・{@code sys_init_company} 呼出し前（同一トランザクション内）。本番では Bean なし。 */
    public interface BeforeInitHook {
        void beforeInit(long tenantId, long companyId);
    }

    public record CreateCompanyCommand(String companyCode, String companyName, String unifiedSocialCreditCode,
                                       Integer taxPayerType, Integer fiscalYearStartMonth, String baseCurrencyCode,
                                       String address, String provinceCode, String cityCode) {
    }

    public record CompanyCreated(long id, String companyCode, String companyName, int version) {
    }

    private final JdbcClient jdbc;
    private final TransactionTemplate tx;
    private final ObjectProvider<BeforeInitHook> hook;
    private final CompanyAuditWriter audit;

    public CompanyService(JdbcClient jdbc, PlatformTransactionManager tm, ObjectProvider<BeforeInitHook> hook,
                          CompanyAuditWriter audit) {
        this.jdbc = jdbc;
        this.audit = audit;
        this.tx = new TransactionTemplate(tm);
        this.hook = hook;
    }

    public CompanyCreated create(CreateCompanyCommand c) {
        long tenant = TenantContext.currentTenantId();
        long id = IdWorker.getId();
        try {
            return tx.execute(s -> {
                jdbc.sql("""
                                INSERT INTO sys_company (id, tenant_id, company_id, company_code, company_name,
                                    unified_social_credit_code, tax_payer_type, fiscal_year_start_month, base_currency_code,
                                    address, province_code, city_code)
                                VALUES (:id, :tenant, :id, :code, :name, :uscc, :tpt, :fysm, :cur, :addr, :prov, :city)
                                """)
                        .param("id", id).param("tenant", tenant).param("code", c.companyCode())
                        .param("name", c.companyName()).param("uscc", c.unifiedSocialCreditCode())
                        .param("tpt", c.taxPayerType()).param("fysm", c.fiscalYearStartMonth())
                        .param("cur", c.baseCurrencyCode()).param("addr", c.address())
                        .param("prov", c.provinceCode()).param("city", c.cityCode())
                        .update();
                BeforeInitHook h = hook.getIfAvailable();
                if (h != null) {
                    h.beforeInit(tenant, id);
                }
                jdbc.sql("SELECT sys_init_company(:tenant, :id)").param("tenant", tenant).param("id", id)
                        .query((rs, i) -> 1).list();
                writeAudit(tenant, id, c);
                return new CompanyCreated(id, c.companyCode(), c.companyName(), 0);
            });
        } catch (DataIntegrityViolationException e) {
            if (isCompanyDuplicate(e)) {
                throw new BizException(COMPANY_DUPLICATE, MSG_COMPANY_DUPLICATE,
                        "公司代码「" + c.companyCode() + "」或统一社会信用代码已存在，请使用其他代码。");
            }
            throw e;
        }
    }

    public static final String MSG_AUDIT_FAILED = "MSG-SYS-091";

    private void writeAudit(long tenant, long companyId, CreateCompanyCommand c) {
        try {
            audit.write(tenant, companyId, c);
        } catch (RuntimeException e) {
            throw new BizException(5000, MSG_AUDIT_FAILED, "审计日志写入失败，操作已中止，请稍后重试或联系管理员。");
        }
    }

    /** 23505 かつ制約名が {@link #DUPLICATE_CONSTRAINTS} のいずれか。 */
    public static boolean isCompanyDuplicate(Throwable e) {
        for (Throwable t = e; t != null; t = t.getCause()) {
            if (t instanceof SQLException sql && "23505".equals(sql.getSQLState())) {
                String msg = String.valueOf(sql.getMessage());
                return DUPLICATE_CONSTRAINTS.stream().anyMatch(n -> msg.contains("\"" + n + "\""));
            }
        }
        return false;
    }
}
