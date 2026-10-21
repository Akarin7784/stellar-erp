package com.stellar.erp.production.internal;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

import com.stellar.erp.common.BizException;
import com.stellar.erp.production.ProductionErrorCode;

/**
 * 単位整合（CHK-PRD-002-10 / MSG-PRD-022 / 60022、蓝色大肥鱼 2026-10-21 決定）。
 *
 * <ul>
 *   <li>同一単位 → 整合（換算なし）。</li>
 *   <li>異なる単位 → 両方が同じ {@code mdm_uom.conversion_group}、かつ基準日 {@code d} に有効な換算率がちょうど 1 件。
 *       有効＝{@code deleted=FALSE AND status=1 AND valid_from <= d AND (valid_to IS NULL OR d <= valid_to)}（valid_to 含む）。
 *       {@code conversion_rate} は「1 from = n to」。from→base は ×rate、base→from（逆方向行）は ÷rate。
 *       正逆両方向の行が同時に有効な場合も「複数」とみなし 60022。</li>
 *   <li>換算結果は基本単位の {@code mdm_uom.decimal_places} 桁へ CEILING（rounding_mode は無視）。</li>
 * </ul>
 * tenant は RLS、company は登录上下文の値で明示条件。
 */
@Component
public class UomConverter {

    record Uom(String group, int decimalPlaces) {
    }

    record Rate(BigDecimal rate, boolean forward) {
    }

    private final JdbcClient jdbc;

    public UomConverter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /** {@code qty}（{@code fromUom}）を基本単位へ換算。不整合は 422 / 60022。 */
    public BigDecimal toBase(long company, String fromUom, String baseUom, BigDecimal qty, LocalDate d) {
        if (fromUom.equals(baseUom)) {
            return qty;
        }
        BigDecimal rate = rate(company, fromUom, baseUom, d);
        int scale = uom(company, baseUom).orElseThrow(() -> mismatch(fromUom, baseUom)).decimalPlaces();
        return qty.multiply(rate).setScale(scale, RoundingMode.CEILING);
    }

    /** 整合チェックのみ（換算はしない）。 */
    public void check(long company, String fromUom, String baseUom, LocalDate d) {
        if (!fromUom.equals(baseUom)) {
            rate(company, fromUom, baseUom, d);
        }
    }

    /** 1 {@code fromUom} = n {@code baseUom} の n。 */
    BigDecimal rate(long company, String fromUom, String baseUom, LocalDate d) {
        Uom from = uom(company, fromUom).orElseThrow(() -> mismatch(fromUom, baseUom));
        Uom base = uom(company, baseUom).orElseThrow(() -> mismatch(fromUom, baseUom));
        if (!from.group().equals(base.group())) {
            throw mismatch(fromUom, baseUom);
        }
        List<Rate> rates = jdbc.sql("""
                        SELECT conversion_rate, from_uom_code = :from AS forward FROM mdm_uom_conversion
                         WHERE company_id = :c AND conversion_group = :g AND deleted = FALSE AND status = 1
                           AND ((from_uom_code = :from AND to_uom_code = :to) OR (from_uom_code = :to AND to_uom_code = :from))
                           AND valid_from <= :d AND (valid_to IS NULL OR :d <= valid_to)
                        """)
                .param("c", company).param("g", from.group()).param("from", fromUom).param("to", baseUom).param("d", d)
                .query((rs, i) -> new Rate(rs.getBigDecimal(1), rs.getBoolean(2)))
                .list();
        if (rates.size() != 1) {
            throw mismatch(fromUom, baseUom);
        }
        Rate r = rates.get(0);
        return r.forward() ? r.rate() : BigDecimal.ONE.divide(r.rate(), 16, RoundingMode.HALF_UP);
    }

    Optional<Uom> uom(long company, String code) {
        return jdbc.sql("""
                        SELECT conversion_group, decimal_places FROM mdm_uom
                         WHERE company_id = :c AND uom_code = :u AND deleted = FALSE
                        """)
                .param("c", company).param("u", code)
                .query((rs, i) -> new Uom(rs.getString(1), rs.getInt(2)))
                .optional();
    }

    static BizException mismatch(String from, String base) {
        return new BizException(ProductionErrorCode.UOM_MISMATCH, ProductionErrorCode.MSG_UOM_MISMATCH,
                "BOM の単位と物料の基本単位が一致しません。（" + from + " → " + base + "）");
    }
}
