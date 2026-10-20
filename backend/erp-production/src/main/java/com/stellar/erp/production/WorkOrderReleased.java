package com.stellar.erp.production;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * 下达结果（91 §3.2 レスポンス：200 + {@code data.warnings[]}）。
 *
 * @param standardCost NULL＝标准成本未设定（差异分析以 standard_cost IS NULL 判定跳过）
 */
public record WorkOrderReleased(long id, String workOrderNo, short orderStatus, LocalDate releaseDate,
                                BigDecimal standardCost, int version, List<Warning> warnings) {

    /** 警告（成功响应中携带）。 */
    public record Warning(int code, String msgId, String message) {
    }
}
