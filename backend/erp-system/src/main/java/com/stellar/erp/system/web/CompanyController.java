package com.stellar.erp.system.web;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.stellar.erp.common.RequirePermission;
import com.stellar.erp.common.Result;
import com.stellar.erp.system.company.CompanyService;
import com.stellar.erp.system.company.UnifiedSocialCreditCode;

/** 公司 API（01-system 91 #47a / 03 §7 #12a）。 */
@RestController
@RequestMapping("/api/system/companies")
public class CompanyController {

    /**
     * リクエスト（03 §4.4 SCR-SYS-012 公司タブ）。{@code companyId}/{@code tenantId} は受け付けない
     * （未知のプロパティとして無視。租户はログインコンテキスト、company_id は新 id）。
     */
    public record CreateCompanyRequest(String companyCode, String companyName, String unifiedSocialCreditCode,
                                       Integer taxPayerType, Integer fiscalYearStartMonth, String baseCurrencyCode,
                                       String address, String provinceCode, String cityCode) {
    }

    public record FieldError(String field, String message) {
    }

    public record FieldErrors(List<FieldError> fieldErrors) {
    }

    private record Violation(String field, String message, String msgId) {
    }

    private static final Pattern ALNUM = Pattern.compile("[A-Za-z0-9]+");
    private static final Pattern CURRENCY = Pattern.compile("[A-Z]{3}");
    /** MSG-COM-088「「{0}」的格式不正确。」（00-common 05 v1.3）。 */
    static final String MSG_FORMAT = "MSG-COM-088";

    private final CompanyService service;

    public CompanyController(CompanyService service) {
        this.service = service;
    }

    @PostMapping
    @RequirePermission("system:company:create")
    public ResponseEntity<Result<?>> create(@RequestBody(required = false) CreateCompanyRequest req) {
        CreateCompanyRequest r = req != null ? req
                : new CreateCompanyRequest(null, null, null, null, null, null, null, null, null);
        int taxPayerType = r.taxPayerType() == null ? 1 : r.taxPayerType();
        int fiscalMonth = r.fiscalYearStartMonth() == null ? 1 : r.fiscalYearStartMonth();
        String currency = r.baseCurrencyCode() == null ? "CNY" : r.baseCurrencyCode();
        List<Violation> vs = validate(r, taxPayerType, fiscalMonth, currency);
        if (!vs.isEmpty()) {
            Violation first = vs.get(0);
            return ResponseEntity.badRequest().body(new Result<>(1001, first.message(),
                    new FieldErrors(vs.stream().map(v -> new FieldError(v.field(), v.message())).toList()), first.msgId()));
        }
        CompanyService.CompanyCreated created = service.create(new CompanyService.CreateCompanyCommand(
                r.companyCode(), r.companyName(), r.unifiedSocialCreditCode(), taxPayerType, fiscalMonth, currency,
                r.address(), r.provinceCode(), r.cityCode()));
        return ResponseEntity.status(HttpStatus.CREATED).body(Result.ok(created));
    }

    /** 入力チェック（03 §4.4 項目 1〜8、CHK-SYS-014-01）。各項目は最初の違反のみ、項目順に全違反を返す。 */
    private static List<Violation> validate(CreateCompanyRequest r, int taxPayerType, int fiscalMonth, String currency) {
        List<Violation> vs = new ArrayList<>();
        text(vs, "companyCode", "公司代码", r.companyCode(), true, 32, ALNUM, "「公司代码」只能输入半角英数字。", "MSG-COM-087");
        text(vs, "companyName", "公司名称", r.companyName(), true, 200, null, null, null);
        // CHK-SYS-014-01：18 桁＋GB 32100-2015 校验位。必須 040、桁数超過 041、それ以外の形式・校验位違反は 088
        String uscc = r.unifiedSocialCreditCode();
        if (uscc == null || uscc.isBlank()) {
            vs.add(new Violation("unifiedSocialCreditCode", "请输入必填项「统一社会信用代码」。", "MSG-COM-040"));
        } else if (uscc.length() > 18) {
            vs.add(new Violation("unifiedSocialCreditCode", "「统一社会信用代码」不能超过 18 个字符。", "MSG-COM-041"));
        } else if (!UnifiedSocialCreditCode.isValid(uscc)) {
            vs.add(new Violation("unifiedSocialCreditCode", "「统一社会信用代码」的格式不正确。", MSG_FORMAT));
        }
        // CHK-SYS-014-04：1/2 → MSG-COM-049（03:181）
        if (taxPayerType != 1 && taxPayerType != 2) {
            vs.add(new Violation("taxPayerType", "所选数据不存在或已失效，请重新选择。", "MSG-COM-049"));
        }
        // CHK-SYS-014-05：1〜12 → MSG-COM-089
        if (fiscalMonth < 1 || fiscalMonth > 12) {
            vs.add(new Violation("fiscalYearStartMonth", "「会计年度起始月」必须在 1 到 12 之间。", "MSG-COM-089"));
        }
        // CHK-SYS-014-06：ISO 4217 英大文字 3 桁 → MSG-COM-088
        if (!CURRENCY.matcher(currency).matches()) {
            vs.add(new Violation("baseCurrencyCode", "「记账本位币」的格式不正确。", MSG_FORMAT));
        }
        text(vs, "address", "注册地址", r.address(), false, 300, null, null, null);
        text(vs, "provinceCode", "省级行政区划代码", r.provinceCode(), false, 6, null, null, null);
        text(vs, "cityCode", "市级行政区划代码", r.cityCode(), false, 6, null, null, null);
        return vs;
    }

    private static void text(List<Violation> vs, String field, String label, String value, boolean required, int max,
                             Pattern format, String formatMessage, String formatMsgId) {
        if (value == null || value.isBlank()) {
            if (required) {
                vs.add(new Violation(field, "请输入必填项「" + label + "」。", "MSG-COM-040"));
            }
            return;
        }
        if (value.length() > max) {
            vs.add(new Violation(field, "「" + label + "」不能超过 " + max + " 个字符。", "MSG-COM-041"));
            return;
        }
        if (format != null && !format.matcher(value).matches()) {
            vs.add(new Violation(field, formatMessage, formatMsgId));
        }
    }
}
