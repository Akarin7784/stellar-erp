package com.stellar.erp.production;

/**
 * 生产域业务码（06-production 91-api-design §9：{@code 60000 + MSG-PRD-NNN}，业务拒否一律 HTTP 422）。
 * 只收录本模块已实装的码，其余按需追加。
 */
public final class ProductionErrorCode {

    private ProductionErrorCode() {
    }

    /**
     * 品目が製造品ではない（CHK-PRD-002-01：{@code prd_material_planning.material_type ∈ {20,30}}）。
     * 93-messages に MSG-PRD-001 はあるが 91 §9 の表に個別行はなく、91 の規則「60000 + MSG-PRD-NNN」で 60001。
     */
    public static final int WO_NOT_MANUFACTURED = 60001;
    public static final String MSG_WO_NOT_MANUFACTURED = "MSG-PRD-001";

    /** 保留中の工单は下达・報工・入庫不可（91 §9）。 */
    public static final int WO_ON_HOLD = 60047;
    public static final String MSG_WO_ON_HOLD = "MSG-PRD-047";

    /** 状態不整合（共通 4002 / HTTP 409 / MSG-COM-034）。 */
    public static final int STATE_CONFLICT = 4002;
    public static final String MSG_STATE_CONFLICT = "MSG-COM-034";

    /** 楽観排他競合（共通 4003 / HTTP 409 / MSG-COM-033）。 */
    public static final int VERSION_CONFLICT = 4003;
    public static final String MSG_VERSION_CONFLICT = "MSG-COM-033";

    /**
     * 警告：標準原価未設定（07-finance 93 MSG-FIN-117、種別 W）。下达は成功し、data.warnings[] に載せる。
     * 07 91 の錯誤碼表に個別行はなく、FIN の慣例（70008↔MSG-FIN-008、70134↔MSG-FIN-134）から 70117。
     */
    public static final int WARN_STANDARD_COST_MISSING = 70117;
    public static final String MSG_WARN_STANDARD_COST_MISSING = "MSG-FIN-117";

    /** 工单品目 ≠ 受注行品目（G2-18，BR-WO-15）。 */
    public static final int WO_MATERIAL_MISMATCH = 60056;
    public static final String MSG_WO_MATERIAL_MISMATCH = "MSG-PRD-056";

    /** 超产申请数量不正（{@code request_qty} ≤ 0 或 NULL）。 */
    public static final int OPA_INVALID_REQUEST_QTY = 60103;
    public static final String MSG_OPA_INVALID_REQUEST_QTY = "MSG-PRD-103";

    /** 设定不备（租户 / 公司上下文 / {@code sys_param.prd.completion_over_rate} 缺失），91 §9 / 93 §1。 */
    public static final int CONFIG_MISSING = 5000;

    /** 资源不存在（共通 4001 / 404）。 */
    public static final int NOT_FOUND = 4001;
}
