-- pgTAP 骨架：G2-18 受注行完工数量规则（单会话规则部分）。
-- 状态：表未建（等 T2 销售订单 / T3 工单迁移），全部 skip。并发场景见 Java db.G218ConcurrencyTest。
-- 已定列名：sal_order_line.completed_qty / over_receipt_rate（确认时快照）/ allowed_qty；prd_work_order.sales_order_line_id
-- 已定加锁顺序：先锁受注行，再锁工单；同类行按 id 升序。
-- TODO(T2/T3 合并后)：去掉 skip，补充准备数据（两个租户、公司默认率 0.05、物料率、行率），全部 SET ROLE erp_app 后断言。
BEGIN;
SELECT plan(12);
SELECT skip('G2-18：等 T2/T3 表合入', 12);
-- 计划用例（逐条替换 skip）：
-- R1  allowed_qty = order_qty * (1 + over_receipt_rate)
-- R2  率优先级：行 > 物料 > 公司默认 0.05（三条数据各验一次）
-- R3  确认时快照：确认后改物料/公司率，行上 over_receipt_rate 与 allowed_qty 不变
-- R4  CHECK：completed_qty < 0 被拒（23514）
-- R5  CHECK：completed_qty > allowed_qty 被拒（23514）
-- R6  CHECK 边界：completed_qty = allowed_qty 通过
-- R7  超产审批：allowed_qty 提高 且 写入一条审批记录（表名待 T2 定稿）
-- R8  完工退回：在同一事务/锁内扣减 completed_qty，结果不为负
-- R9  报废冲销：冲销函数扣减 completed_qty，对账视图差异为 0
-- R10 受注改量低于已完工数 → 被拒
-- R11 受注改量低于已发货数 → 被拒
-- R12 对账视图：受注行 completed_qty = Σ 工单完工 − Σ 冲销
SELECT * FROM finish();
ROLLBACK;
