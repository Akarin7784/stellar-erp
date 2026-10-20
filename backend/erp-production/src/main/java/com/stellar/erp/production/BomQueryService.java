package com.stellar.erp.production;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;

/**
 * 有効 BOM の解決（GET /api/production/boms/effective、91 #9 / 02-work-order §4.5 No.1 / 01 §5 有効版選択）：
 * {@code bom_status = 30} かつ {@code valid_from ≤ 基準日 ≤ COALESCE(valid_to, ∞)}、複数該当は
 * {@code is_default = true} → {@code version_no} 最大。該当なしは 60020 / MSG-PRD-020。
 */
@Service
public class BomQueryService {

    public record EffectiveBom(long id, String bomNo, long materialId, String materialCode, long factoryId,
                               short versionNo, BigDecimal baseQty, String baseUomCode, LocalDate validFrom,
                               LocalDate validTo, boolean isDefault, List<Line> lines) {
    }

    public record Line(int lineNo, long componentMaterialId, String componentCode, String componentName,
                       String uomCode, BigDecimal componentQty, BigDecimal lossRate, BigDecimal requiredQty,
                       Integer operationSeq, boolean isKeyPart, String substituteGroup) {
    }

    private final JdbcClient jdbc;

    public BomQueryService(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public EffectiveBom effective(long materialId, Long factoryId, LocalDate date) {
        long company = LoginContext.require().companyId();
        EffectiveBom header = jdbc.sql("""
                        SELECT id, bom_no, material_id, material_code, factory_id, version_no, base_qty, base_uom_code,
                               valid_from, valid_to, is_default
                          FROM prd_bom
                         WHERE company_id = :c AND material_id = :m AND deleted = FALSE AND bom_status = 30
                           AND valid_from <= :d AND (valid_to IS NULL OR valid_to >= :d)
                           AND (CAST(:f AS BIGINT) IS NULL OR factory_id = :f)
                         ORDER BY is_default DESC, version_no DESC
                         LIMIT 1
                        """)
                .param("c", company).param("m", materialId).param("d", date).param("f", factoryId)
                .query((rs, i) -> new EffectiveBom(rs.getLong(1), rs.getString(2), rs.getLong(3), rs.getString(4),
                        rs.getLong(5), rs.getShort(6), rs.getBigDecimal(7), rs.getString(8),
                        rs.getObject(9, LocalDate.class), rs.getObject(10, LocalDate.class), rs.getBoolean(11), null))
                .optional()
                .orElseThrow(() -> new BizException(ProductionErrorCode.BOM_NOT_FOUND, ProductionErrorCode.MSG_BOM_NOT_FOUND,
                        "有効な BOM がありません。BOM を登録・承認してください。"));
        List<Line> lines = jdbc.sql("""
                        SELECT line_no, component_material_id, component_code, component_name, uom_code, component_qty,
                               loss_rate, required_qty, operation_seq, is_key_part, substitute_group
                          FROM prd_bom_line WHERE company_id = :c AND bom_id = :b AND deleted = FALSE ORDER BY line_no
                        """)
                .param("c", company).param("b", header.id())
                .query((rs, i) -> new Line(rs.getInt(1), rs.getLong(2), rs.getString(3), rs.getString(4), rs.getString(5),
                        rs.getBigDecimal(6), rs.getBigDecimal(7), rs.getBigDecimal(8), rs.getObject(9, Integer.class),
                        rs.getBoolean(10), rs.getString(11)))
                .list();
        return new EffectiveBom(header.id(), header.bomNo(), header.materialId(), header.materialCode(),
                header.factoryId(), header.versionNo(), header.baseQty(), header.baseUomCode(), header.validFrom(),
                header.validTo(), header.isDefault(), lines);
    }
}
