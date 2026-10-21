-- 06-production：allowed_qty 非负 CHECK 补齐（蓝色大肥鱼 2026-10-21 决定；docs/design/06-production/90-db-design.md v1.20）。
-- sal_sales_order_line.allowed_qty（ck_sal_sales_order_line_qty）与 prd_overproduction_approval.current_allowed_qty（ck_prd_opa_allowed_qty）已有 >= 0，
-- 本次补 prd_work_order.allowed_qty 与 prd_overproduction_approval.approved_allowed_qty。NULL 照常通过（NULL＝未快照／未批准）。
-- 已确认迁移、种子、pgTAP fixture、后端测试数据中两列均无负数，直接校验（不用 NOT VALID）。
ALTER TABLE prd_work_order
    ADD CONSTRAINT ck_prd_work_order_allowed_qty CHECK (allowed_qty >= 0);
ALTER TABLE prd_overproduction_approval
    ADD CONSTRAINT ck_prd_opa_approved_allowed_qty CHECK (approved_allowed_qty >= 0);

COMMENT ON CONSTRAINT ck_prd_work_order_allowed_qty ON prd_work_order IS '允许完工上限不得为负（NULL＝未快照，可通过）。DB 层最终防线，服务层先以 422/60101 拒绝';
COMMENT ON CONSTRAINT ck_prd_opa_approved_allowed_qty ON prd_overproduction_approval IS '批准后新上限不得为负（NULL＝未批准，可通过）。DB 层最终防线';
