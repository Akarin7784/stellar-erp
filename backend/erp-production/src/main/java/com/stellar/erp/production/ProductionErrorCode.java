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

    /** 起案者と承認者が同一（自己承認不可、CHK-PRD-002-12）。91 の規則 60000 + MSG-PRD-NNN。 */
    public static final int WO_SELF_APPROVAL = 60005;
    public static final String MSG_WO_SELF_APPROVAL = "MSG-PRD-005";

    /** 有効 BOM なし（91 §9 60020）。 */
    public static final int BOM_NOT_FOUND = 60020;
    public static final String MSG_BOM_NOT_FOUND = "MSG-PRD-020";

    /** 単位不整合（CHK-PRD-002-10、93-messages MSG-PRD-022、422。60000 + NNN 規則、蓝色大肥鱼 2026-10-21 決定）。 */
    public static final int UOM_MISMATCH = 60022;
    public static final String MSG_UOM_MISMATCH = "MSG-PRD-022";

    /** 有効工艺なし／工序明細 0 件（CHK-PRD-002-08、93-messages MSG-PRD-021。60000 + NNN 規則）。 */
    public static final int ROUTING_NOT_FOUND = 60021;
    public static final String MSG_ROUTING_NOT_FOUND = "MSG-PRD-021";

    /**
     * 下达日が過去日（Asia/Shanghai 当日より前）。06 91 §3.2 / 93-messages MSG-PRD-104（蓝色大肥鱼 2026-10-21 確定）。
     */
    public static final int WO_RELEASE_DATE_PAST = 60104;
    public static final String MSG_WO_RELEASE_DATE_PAST = "MSG-PRD-104";

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

    /** 完工上限超过（91 §9 / AC-PRD-07：超产路径用尽或 MTS）。DB 兜底 {@code ck_sal_sol_completed_qty}（23514）也映射为此码。 */
    public static final int COMPLETION_LIMIT_EXCEEDED = 60040;
    public static final String MSG_COMPLETION_LIMIT_EXCEEDED = "MSG-PRD-040";

    /** 超产申请数量不正（≤ 0 / NULL、超过受注行基本数量 × prd.overproduction_max_rate、小数位超过基本单位 decimal_places）。 */
    public static final int OPA_INVALID_REQUEST_QTY = 60103;
    public static final String MSG_OPA_INVALID_REQUEST_QTY = "MSG-PRD-103";

    /** 超産承認無効（却下 40／取消 90 の申請に対する承認・操作。91 §4 60101）。 */
    public static final int OPA_INVALID = 60101;
    public static final String MSG_OPA_INVALID = "MSG-PRD-101";

    /** 设定不备（租户 / 公司上下文 / {@code sys_param.prd.completion_over_rate} 缺失），91 §9 / 93 §1。 */
    public static final int CONFIG_MISSING = 5000;

    /** 资源不存在（共通 4001 / 404）。 */
    public static final int NOT_FOUND = 4001;
}
