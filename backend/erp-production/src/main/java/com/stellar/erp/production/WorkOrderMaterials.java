package com.stellar.erp.production;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;

import org.springframework.stereotype.Component;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;
import com.stellar.erp.common.BizException;
import com.stellar.erp.production.internal.ProductionRepository;
import com.stellar.erp.production.internal.ProductionRepository.MaterialLineUom;
import com.stellar.erp.production.internal.UomConverter;

/**
 * 工单材料明細の BOM 展開と単位整合（CHK-PRD-002-10 / 60022）。登録・下达・提出で共用。
 *
 * <p>全材料行は {@code uom_code / required_qty} に物料の基本単位で保存し、BOM 原単位・原数量は
 * {@code bom_uom_code / bom_qty}（手工行は NULL）。呼出し側トランザクション内で実行し、60022 時は全体ロールバック。</p>
 */
@Component
class WorkOrderMaterials {

    private final ProductionRepository repo;
    private final UomConverter uoms;

    WorkOrderMaterials(ProductionRepository repo, UomConverter uoms) {
        this.repo = repo;
        this.uoms = uoms;
    }

    /**
     * BOM を展開して材料行を INSERT。
     * BOM 単位で CALC-WO-01（{@code component_qty × order_qty ÷ base_qty}、4 桁四捨五入）と
     * CALC-WO-02（{@code ÷ (1 − loss_rate)}、4 桁切上）を計算し、CALC-WO-10 で required / total をそれぞれ基本単位へ換算
     * （同一単位も含め全行を基本単位 decimal_places へ CEILING）。{@code bom_qty} は換算前の総必要量。
     */
    void expand(long company, long userId, long workOrderId, BigDecimal orderQty, BomQueryService.EffectiveBom bom,
                LocalDate baseDate) {
        for (BomQueryService.Line l : bom.lines()) {
            String baseUom = repo.findBaseUom(company, l.componentMaterialId())
                    .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "物料不存在：" + l.componentCode()));
            BigDecimal bomRequired = l.componentQty().multiply(orderQty).divide(bom.baseQty(), 4, RoundingMode.HALF_UP);
            BigDecimal lossRate = l.lossRate() != null ? l.lossRate() : BigDecimal.ZERO;
            BigDecimal bomQty = bomRequired.divide(BigDecimal.ONE.subtract(lossRate), 4, RoundingMode.CEILING);
            BigDecimal required = uoms.toBase(company, l.uomCode(), baseUom, bomRequired, baseDate);
            BigDecimal total = uoms.toBase(company, l.uomCode(), baseUom, bomQty, baseDate);
            repo.insertMaterialLine(new ProductionRepository.MaterialLineInsert(
                    IdWorker.getId(), company, userId, workOrderId, l.lineNo(), l.id(),
                    l.operationSeq(), l.componentMaterialId(), l.componentCode(), l.componentName(), baseUom,
                    required, lossRate, total.subtract(required), total, l.isKeyPart(), l.substituteGroup(),
                    l.uomCode(), bomQty));
        }
    }

    /**
     * 既存材料行の再チェック（提出・下达）：{@code uom_code} が物料の現在の基本単位であること、
     * BOM 由来行は {@code bom_uom_code → 基本単位} の換算が基準日で有効であること。
     * 数量は書き換えない（AC-PRD-13「既存明細の件数・数量・ID は変わらない」を優先。02 §6.4 2a の再換算・格納とは差異あり）。
     */
    void checkAll(long company, long workOrderId, LocalDate baseDate) {
        for (MaterialLineUom l : repo.listMaterialLineUoms(company, workOrderId)) {
            if (l.baseUom() == null || !l.baseUom().equals(l.uomCode())) {
                throw new BizException(ProductionErrorCode.UOM_MISMATCH, ProductionErrorCode.MSG_UOM_MISMATCH,
                        "BOM の単位と物料の基本単位が一致しません。（行 " + l.lineNo() + "）");
            }
            // 手工行（bom_uom_code NULL）も基本単位が有効な mdm_uom 行を持つか確認（停用・未登録は 60022）
            uoms.check(company, l.bomUomCode() != null ? l.bomUomCode() : l.baseUom(), l.baseUom(), baseDate);
        }
    }
}
