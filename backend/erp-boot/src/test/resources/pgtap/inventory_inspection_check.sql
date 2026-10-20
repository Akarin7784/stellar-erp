-- pgTAP 骨架：inventory 入库待检 CHECK（inv_stock_txn_line）。
-- 已定方案：明细冗余 txn_type（NOT NULL，无外键，触发器校验与表头一致）；inspection_flag NOT NULL；
--   CHECK (txn_type NOT IN (<入库待检类型>) OR NOT inspection_flag OR stock_status = 10)
-- 入库待检类型清单（采购收货/委外收货/完工入库/销售退货入库）编码以业务分析 inventory 文档 PR 定稿为准。
-- 状态：inventory 迁移未合，全部 skip。TODO：表合入后填入编码，SET ROLE erp_app 后断言。
BEGIN;
SELECT plan(9);
SELECT skip('inventory 迁移未合入', 9);
-- I1 正例：入库待检类型 + inspection_flag=true + stock_status=10 → 通过（每种入库类型各一条）
-- I2 反例：入库待检类型 + inspection_flag=true + stock_status<>10 → 23514
-- I3 inspection_flag=false 的入库明细不受限
-- I4 出库明细（inspection_flag=true、stock_status 任意）不被误拦
-- I5 状态转移明细不被误拦
-- I6 明细 txn_type 与表头不一致 → 触发器报错
-- I7 txn_type 为 NULL → 23502（否则 NOT IN 得 NULL，CHECK 放行）
-- I8 inspection_flag 为 NULL → 23502
-- I9 col_not_null 目录断言：txn_type、inspection_flag
SELECT * FROM finish();
ROLLBACK;
