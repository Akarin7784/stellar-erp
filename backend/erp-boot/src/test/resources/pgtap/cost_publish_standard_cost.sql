-- pgTAP 骨架：AC1-9 标准成本发布（mdm_material.standard_cost）。
-- 已定方案（蓝色大肥鱼 2026-10-20 定稿）：
--   * NOLOGIN 角色 erp_cost_publisher 持有 SECURITY DEFINER 函数 fin_publish_standard_cost（固定 search_path，函数内先 set_config 租户）；
--   * 触发器只放行 current_user = 'erp_cost_publisher' 的 standard_cost 更新；不使用 app.cost_publish 标记；
--   * erp_app 对 mdm_material 无表级 UPDATE，按列授权且不含 standard_cost；该表不吃 ALTER DEFAULT PRIVILEGES。
--   * erp_cost_publisher 不是表 owner：需要 UPDATE (standard_cost)，以及 WHERE 引用列（id, tenant_id, company_id）的列级 SELECT、
--     fin_standard_cost 的 SELECT；FORCE RLS 对其同样生效。
-- 状态：mdm（T1）与 07-finance 迁移未合，全部 skip。表合入后去掉 skip 并按下列用例实现。
BEGIN;
SELECT plan(10);
SELECT skip('T1 mdm_material 触发器 / 07-finance fin_publish_standard_cost 未合入', 10);
-- C1 正例：以 erp_app 调用 fin_publish_standard_cost → 函数内执行真实
--      UPDATE mdm_material SET standard_cost = ... WHERE id = ? AND tenant_id = ? AND company_id = ?，
--      断言 standard_cost 已变更（results_eq）
-- C2 erp_app 直接 UPDATE mdm_material SET standard_cost = ... WHERE id = ? → throws_ok '42501'
-- C3 erp_app 先 set_config('app.cost_publish','on',true) 再直接 UPDATE standard_cost → 仍 throws_ok '42501'
-- C4 ok(NOT has_table_privilege('erp_app','mdm_material','UPDATE'))：无表级 UPDATE
-- C5 ok(NOT has_column_privilege('erp_app','mdm_material','standard_cost','UPDATE'))
-- C6 has_column_privilege('erp_app','mdm_material','material_name','UPDATE') 为真（其他列照常可改）
-- C7 erp_cost_publisher：rolcanlogin = false，且是 fin_publish_standard_cost 的 owner、prosecdef = true、proconfig 含 search_path
-- C8 has_column_privilege('erp_cost_publisher','mdm_material','standard_cost','UPDATE')
-- C9 has_column_privilege('erp_cost_publisher','mdm_material', 'id' / 'tenant_id' / 'company_id','SELECT') 均为真
-- C10 has_table_privilege('erp_cost_publisher','fin_standard_cost','SELECT') 为真
SELECT * FROM finish();
ROLLBACK;
