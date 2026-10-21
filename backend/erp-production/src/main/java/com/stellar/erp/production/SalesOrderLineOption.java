package com.stellar.erp.production;

import java.math.BigDecimal;

/**
 * 超产申请画面の受注行ピッカー 1 行（当前会社のみ。ID は全局 Jackson 設定で文字列）。
 *
 * @param baseQty    受注行基本数量（基本単位）
 * @param allowedQty 受注行の現在の許容完工上限（基本単位）
 */
public record SalesOrderLineOption(long salesOrderLineId, long salesOrderId, String salesOrderNo, int lineNo,
                                   long materialId, String materialCode, String materialName, String baseUomCode,
                                   BigDecimal baseQty, BigDecimal allowedQty, BigDecimal completedQty) {
}
