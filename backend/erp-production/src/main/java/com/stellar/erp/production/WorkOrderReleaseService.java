package com.stellar.erp.production;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.stellar.erp.common.BizException;
import com.stellar.erp.common.LoginContext;
import com.stellar.erp.production.SalesOrderLineLookup.SalesOrderLine;
import com.stellar.erp.production.internal.ProductionRepository;
import com.stellar.erp.production.internal.ProductionRepository.WorkOrderForRelease;

/**
 * 工单下达（PRC-PRD-002-04，02-work-order §6.4 / T-05 25→30 / 91 §3.2）の最小切片。
 *
 * <ol>
 *   <li>锁序（04 §11.1）：MTO 先 {@code FOR UPDATE} 受注行，再 {@code FOR UPDATE} 工单（单张工单，id 升序天然满足）。</li>
 *   <li>前提：{@code order_status = 25}（否则 4002 / MSG-COM-034）、{@code version} 一致（否则 4003 / MSG-COM-033）、
 *       非保留（否则 60047 / MSG-PRD-047）、MTO 品目一致（60056）。</li>
 *   <li>标准成本快照：下达日所在月的已发布版（status=40）{@code total_unit_cost}；无版本则 NULL 并返回警告 MSG-FIN-117。</li>
 *   <li>{@code order_status=30}、{@code released_by/at}；MTO 从受注行快照 {@code allowed_qty}。</li>
 * </ol>
 *
 * <p>未实装（后续）：引当依頼・E21 Outbox、引当不足警告 60045、日程再計算、監査ログ、Idempotency-Key、
 * 一括下达、権限 production:work-order:release。</p>
 */
@Service
public class WorkOrderReleaseService {

    static final short STATUS_APPROVED = 25;
    static final short STATUS_RELEASED = 30;
    /** 下达日：服务器时刻按 Asia/Shanghai（00-common 01:101，与 fin_publish_standard_cost 的「当月」口径一致）。 */
    static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Shanghai");

    private final ProductionRepository repo;
    private final SalesOrderLineLookup salesOrderLines;
    private final BomQueryService boms;
    private final WorkOrderMaterials materials;
    private Clock clock = Clock.system(BUSINESS_ZONE);

    @Autowired
    WorkOrderReleaseService(ProductionRepository repo, SalesOrderLineLookup salesOrderLines, BomQueryService boms,
                            WorkOrderMaterials materials) {
        this.repo = repo;
        this.salesOrderLines = salesOrderLines;
        this.boms = boms;
        this.materials = materials;
    }

    WorkOrderReleaseService(ProductionRepository repo, SalesOrderLineLookup salesOrderLines, BomQueryService boms,
                            WorkOrderMaterials materials, Clock clock) {
        this(repo, salesOrderLines, boms, materials);
        this.clock = clock;
    }

    @Transactional
    public WorkOrderReleased release(long workOrderId, WorkOrderReleaseCommand cmd) {
        LoginContext.LoginUser login = LoginContext.require();
        long company = login.companyId();
        LocalDate today = LocalDate.now(clock);
        LocalDate releaseDate = cmd != null && cmd.releaseDate() != null ? cmd.releaseDate() : today;
        if (releaseDate.isBefore(today)) {
            throw new BizException(ProductionErrorCode.WO_RELEASE_DATE_PAST, ProductionErrorCode.MSG_WO_RELEASE_DATE_PAST,
                    "下达日不能早于今天。");
        }

        // 不加锁预读：只为取得 sales_order_line_id，以便按锁序（04 §11.1）先锁受注行、再锁工单。
        // 若这里就对工单 FOR UPDATE，会变成「工单→受注行」的逆序加锁，与完工上报等路径形成死锁。
        // 预读结果不参与任何判定：加锁后重新读取，并校验受注行关联未被改动（见下方 Objects.equals）。
        WorkOrderForRelease peek = repo.findWorkOrderForRelease(company, workOrderId)
                .orElseThrow(WorkOrderReleaseService::notFound);

        // 1) 受注行 → 2) 工单
        SalesOrderLine line = null;
        if (peek.salesOrderLineId() != null) {
            line = salesOrderLines.lockForUpdate(company, peek.salesOrderLineId())
                    .orElseThrow(() -> new BizException(ProductionErrorCode.NOT_FOUND, "受注行不存在"));
            if (line.allowedQty() == null || line.allowedQty().signum() < 0) {
                // 受注确认时未快照 allowed_qty（或负值）：不拷到工单。业务数据未就绪 → 422 / 60101 / MSG-PRD-106
                // （lead 2026-10-21 决定；5000 仅用于配置缺失）
                throw new BizException(ProductionErrorCode.OPA_INVALID, ProductionErrorCode.MSG_OPA_ALLOWED_UNAVAILABLE,
                        "超产允许数量不可用或对应的销售订单行已不存在，无法执行此操作");
            }
        }
        WorkOrderForRelease wo = repo.lockWorkOrderForRelease(company, workOrderId)
                .orElseThrow(WorkOrderReleaseService::notFound);
        if (!java.util.Objects.equals(wo.salesOrderLineId(), peek.salesOrderLineId())) {
            // 加锁前后受注行关联被改：按状态不整合处理
            throw stateConflict();
        }

        if (wo.orderStatus() != STATUS_APPROVED) {
            throw stateConflict();
        }
        if (cmd == null || cmd.version() == null || cmd.version() != wo.version()) {
            throw versionConflict();
        }
        if (wo.hold()) {
            throw new BizException(ProductionErrorCode.WO_ON_HOLD, ProductionErrorCode.MSG_WO_ON_HOLD,
                    "保留中の工单は下达・報工・入庫できません。");
        }
        if (line != null && line.materialId() != wo.materialId()) {
            throw new BizException(ProductionErrorCode.WO_MATERIAL_MISMATCH,
                    ProductionErrorCode.MSG_WO_MATERIAL_MISMATCH, "工单品目与销售订单行品目不一致。");
        }

        // 材料行 0 件なら有効 BOM を展開（状態遷移と同一トランザクション、Lead 2026-10-21 決定）。
        // 既に材料行がある工单は再展開せず BOM も見ないが、単位整合（60022）は全行を再チェックする。有効 BOM なし → 422 / 60020 で全体ロールバック
        // （状態 25 のまま、材料行なし、E21 なし）。工单は FOR UPDATE 済みのため並行下达でも展開は 1 回だけ。
        if (repo.countWorkOrderMaterials(company, wo.id()) == 0) {
            BomQueryService.EffectiveBom bom = boms.find(company, wo.materialId(), wo.factoryId(), bomBaseDate(wo, today))
                    .orElseThrow(() -> new BizException(ProductionErrorCode.BOM_NOT_FOUND,
                            ProductionErrorCode.MSG_BOM_NOT_FOUND, "有効な BOM がありません。BOM を登録・承認してください。"));
            materials.expand(company, login.userId(), wo.id(), wo.orderQty(), bom, bomBaseDate(wo, today));
        } else {
            materials.checkAll(company, wo.id(), bomBaseDate(wo, today));
        }

        Optional<BigDecimal> cost = repo.findEffectiveStandardCost(company, wo.materialId(),
                releaseDate.withDayOfMonth(1));
        BigDecimal standardCost = cost.orElse(null);

        int updated = repo.markReleased(company, wo.id(), cmd.version(), login.userId(), standardCost,
                line != null ? line.allowedQty() : null, line != null);
        if (updated != 1) {
            throw versionConflict();
        }

        List<WorkOrderReleased.Warning> warnings = standardCost == null
                ? List.of(new WorkOrderReleased.Warning(ProductionErrorCode.WARN_STANDARD_COST_MISSING,
                        ProductionErrorCode.MSG_WARN_STANDARD_COST_MISSING, "未设定标准成本，本期不进行成本差异分析。"))
                : List.of();
        return new WorkOrderReleased(wo.id(), wo.workOrderNo(), STATUS_RELEASED, releaseDate, standardCost,
                wo.version() + 1, warnings);
    }

    /**
     * BOM 基準日（02 §6.1 第 3 項・§6.4 2a、AC-PRD-12）：{@code planned_start_date}、未入力なら会社タイムゾーン
     * （現時点では Asia/Shanghai）の当日。基準日ルールの変更はここだけで行う。
     */
    static LocalDate bomBaseDate(WorkOrderForRelease wo, LocalDate today) {
        return wo.plannedStartDate() != null ? wo.plannedStartDate() : today;
    }

    private static BizException notFound() {
        return new BizException(ProductionErrorCode.NOT_FOUND, "工单不存在");
    }

    private static BizException versionConflict() {
        return new BizException(ProductionErrorCode.VERSION_CONFLICT, ProductionErrorCode.MSG_VERSION_CONFLICT,
                "数据已被其他用户更新，请重新获取最新信息后再操作。");
    }

    private static BizException stateConflict() {
        return new BizException(ProductionErrorCode.STATE_CONFLICT, ProductionErrorCode.MSG_STATE_CONFLICT,
                "该记录当前状态不允许此操作。");
    }
}
