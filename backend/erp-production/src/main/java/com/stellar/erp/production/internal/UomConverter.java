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
 *   <li>同一単位 → 整合（換算なし）。ただし丸めは下記と同じく基本単位の decimal_places へ CEILING（例外なし、
 *       蓝色大肥鱼 2026-10-21 最終決定）。</li>
 *   <li>異なる単位 → 両方が同じ {@code mdm_uom.conversion_group}、かつ基準日 {@code d} に有効な換算率がちょうど 1 件。
 *       有効＝{@code deleted=FALSE AND status=1 AND valid_from <= d AND (valid_to IS NULL OR d <= valid_to)}（valid_to 含む）。
 *       {@code conversion_rate} は「1 from = n to」（CALC-WO-10）。{@code from=BOM 単位・to=基本単位} の行を使い（×rate）、
 *       正方向が 0 件で逆方向行のみ 1 件なら ÷rate。正方向（または逆方向のみの場合の逆方向）が 0 件・複数件なら 60022。</li>
 *   <li>全材料行の数量は基本単位の {@code mdm_uom.decimal_places} 桁へ CEILING（rounding_mode は無視）。
 *       基本単位が {@code mdm_uom} に未登録なら精度不明として 60022。</li>
 * </ul>
 * tenant は RLS、company は登录上下文の値で明示条件。
 */
@Component
public class UomConverter {

    record Uom(String group, int decimalPlaces) {
    }

    record Rate(BigDecimal rate, boolean forward) {
    }

    /**
     * 停用単位（status != 1）は論理削除と同じ扱いで 60022（蓝色大肥鱼 2026-10-21）。
     * 既存行の再チェック（submit/release）でも適用する（案 a、蓝色大肥鱼 2026-10-21 決定）。条件はこの一箇所に集約している。
     */
    static final String ACTIVE_UOM_FILTER = " AND status = 1";

    private final JdbcClient jdbc;

    public UomConverter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /** {@code qty}（{@code fromUom}）を基本単位へ換算し、基本単位の精度へ CEILING。不整合は 422 / 60022。 */
    public BigDecimal toBase(long company, String fromUom, String baseUom, BigDecimal qty, LocalDate d) {
        int scale = uom(company, baseUom).orElseThrow(() -> mismatch(fromUom, baseUom)).decimalPlaces();
        if (fromUom.equals(baseUom)) {
            return qty.setScale(scale, RoundingMode.CEILING);
        }
        Rate rate = rate(company, fromUom, baseUom, d);
        return rate.forward()
                ? qty.multiply(rate.rate()).setScale(scale, RoundingMode.CEILING)
                : qty.divide(rate.rate(), scale, RoundingMode.CEILING);
    }

    /** 整合チェックのみ（換算はしない）。 */
    public void check(long company, String fromUom, String baseUom, LocalDate d) {
        if (fromUom.equals(baseUom)) {
            // toBase と同じく、同一単位でも基本単位が有効な mdm_uom 行を持たなければ 60022
            uom(company, baseUom).orElseThrow(() -> mismatch(fromUom, baseUom));
            return;
        }
        rate(company, fromUom, baseUom, d);
    }

    /** 適用する換算率（正方向優先、逆方向は正方向 0 件のときのみ）。 */
    Rate rate(long company, String fromUom, String baseUom, LocalDate d) {
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
        return pick(rates).orElseThrow(() -> mismatch(fromUom, baseUom));
    }

    /** 正方向がちょうど 1 件ならそれ、正方向 0 件かつ逆方向ちょうど 1 件ならそれ、それ以外（0 件・複数件）は空。 */
    static Optional<Rate> pick(List<Rate> rates) {
        List<Rate> forward = rates.stream().filter(Rate::forward).toList();
        if (forward.size() == 1) {
            return Optional.of(forward.get(0));
        }
        if (!forward.isEmpty()) {
            return Optional.empty();
        }
        List<Rate> reverse = rates.stream().filter(r -> !r.forward()).toList();
        return reverse.size() == 1 ? Optional.of(reverse.get(0)) : Optional.empty();
    }

    Optional<Uom> uom(long company, String code) {
        return jdbc.sql("""
                        SELECT conversion_group, decimal_places FROM mdm_uom
                         WHERE company_id = :c AND uom_code = :u AND deleted = FALSE
                        """ + ACTIVE_UOM_FILTER)
                .param("c", company).param("u", code)
                .query((rs, i) -> new Uom(rs.getString(1), rs.getInt(2)))
                .optional();
    }

    static BizException mismatch(String from, String base) {
        return new BizException(ProductionErrorCode.UOM_MISMATCH, ProductionErrorCode.MSG_UOM_MISMATCH,
                "BOM の単位と物料の基本単位が一致しません。（" + from + " → " + base + "）");
    }
}
