package com.stellar.erp.production;

import java.sql.SQLException;
import java.util.Optional;

import com.stellar.erp.common.BizException;

/**
 * 生产域相关的 DB 约束错误 → 业务码翻译（兜底，服务层 / G2-18 函数应先行拦截）。
 *
 * <p>{@code ck_sal_sol_completed_qty}（23514，受注行 {@code completed_qty ≤ allowed_qty}）→ 60040 / MSG-PRD-040 / HTTP 422，
 * 与 {@code ck_prd_opa_request_qty} → 60103 的做法相同：只按 SQLSTATE + 约束名精确匹配，其他约束原样抛出。</p>
 */
public final class ProductionDbErrors {

    static final String CK_SAL_SOL_COMPLETED_QTY = "ck_sal_sol_completed_qty";

    private ProductionDbErrors() {
    }

    /** 23514 且约束为 {@code ck_sal_sol_completed_qty}。 */
    public static boolean isCompletedQtyViolation(Throwable e) {
        for (Throwable t = e; t != null; t = t.getCause()) {
            if (t instanceof SQLException sql && "23514".equals(sql.getSQLState())
                    && String.valueOf(sql.getMessage()).contains("\"" + CK_SAL_SOL_COMPLETED_QTY + "\"")) {
                return true;
            }
        }
        return false;
    }

    /** 可翻译时返回业务异常，否则为空（调用方原样处理）。 */
    public static Optional<BizException> translate(Throwable e) {
        return isCompletedQtyViolation(e) ? Optional.of(completedQtyExceeded()) : Optional.empty();
    }

    public static BizException completedQtyExceeded() {
        return new BizException(ProductionErrorCode.COMPLETION_LIMIT_EXCEEDED,
                ProductionErrorCode.MSG_COMPLETION_LIMIT_EXCEEDED, "完工数量超过许容上限。");
    }
}
