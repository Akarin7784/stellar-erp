-- prd_work_order.order_status 去掉 95（驳回）：工单驳回回到 10 草稿，不设终态 95（#114 §待定 4，蓝色大肥鱼 2026-10-21 决定）。
-- 其余取值 10/20/25/30/35/40/90 不变。prd_work_order_change.change_status、委外、销售订单的 95 不在本次范围。
-- 已确认迁移、种子、pgTAP fixture、后端测试数据中无 order_status = 95 的工单行；若存在则重建约束时校验失败（不做硬删）。
ALTER TABLE prd_work_order DROP CONSTRAINT ck_prd_work_order_status;
ALTER TABLE prd_work_order ADD CONSTRAINT ck_prd_work_order_status CHECK (order_status IN (10,20,25,30,35,40,90));

COMMENT ON COLUMN prd_work_order.order_status IS '10:草稿 20:待审批 25:已批准 30:已下达 35:生产中 40:完工（以 closed_at 结案、终态） 90:取消';
