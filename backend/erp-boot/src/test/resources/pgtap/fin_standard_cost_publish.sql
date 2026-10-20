-- pgTAP：07-finance §6.12 fin_standard_cost / fin_publish_standard_cost（AC-FIN-09c 期间、AC-FIN-09 快照保护）
-- 业务用例全部在 SET ROLE erp_app 下执行；owner 只负责准备两租户的测试物料。
BEGIN;
SELECT plan(23);

-- 准备（owner，显式 tenant_id）：租户 101 / 202 各一个物料
INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf, status)
VALUES (991001, 101, 1, '9FSC', 'pgTAP fsc', '/9FSC/', 1, TRUE, 1),
       (991002, 202, 1, '9FSC', 'pgTAP fsc', '/9FSC/', 1, TRUE, 1);
INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id,
                          spec, base_uom_code, valuation_method, standard_cost, status)
VALUES (991001, 101, 1, '9FSC000001', 'fsc mat 101', 10, 991001, 'spec', 'PCE', 20, NULL, 1),
       (991002, 202, 1, '9FSC000001', 'fsc mat 202', 10, 991002, 'spec', 'PCE', 20, NULL, 1);
-- 租户 202 的已发布版（跨租户可见性用；owner 也受发布保护触发器约束，暂停触发器写入）
SET LOCAL session_replication_role = replica;
INSERT INTO fin_standard_cost (id, tenant_id, company_id, material_id, material_code, cost_version, period_from,
                               cost_method, material_unit_cost, total_unit_cost, status)
VALUES (992001, 202, 1, 991002, '9FSC000001', '2026A', DATE '2026-01-01', 2, 1, 1, 40);
SET LOCAL session_replication_role = origin;

SET ROLE erp_app;
SELECT set_config('app.tenant_id', '101', true);

-- 版 A：2026-01 起，无截止（778.20 = 659.95 + 53.75 + 64.50 + 0）
INSERT INTO fin_standard_cost (id, company_id, material_id, material_code, cost_version, period_from, cost_method,
                               material_unit_cost, labor_unit_cost, overhead_unit_cost, outsourcing_unit_cost, total_unit_cost)
VALUES (991101, 1, 991001, '9FSC000001', '2026A', DATE '2026-01-01', 2, 659.95, 53.75, 64.50, 0, 778.20);

SELECT lives_ok($$SELECT fin_publish_standard_cost(991101, 7)$$, 'F1 首发 A（无已发布版）成功');
SELECT results_eq(
    $$SELECT status, period_to, published_by FROM fin_standard_cost WHERE id = 991101$$,
    $$VALUES (40::smallint, NULL::date, 7::bigint)$$,
    'F2 A 已发布、无截止、published_by 记录');
SELECT is((SELECT standard_cost FROM mdm_material WHERE id = 991001), 778.200000::numeric(18,6),
          'F3 首发后 mdm_material.standard_cost = A 合计');

-- 版 B：2026-03 起
INSERT INTO fin_standard_cost (id, company_id, material_id, material_code, cost_version, period_from, cost_method,
                               material_unit_cost, total_unit_cost)
VALUES (991102, 1, 991001, '9FSC000001', '2026B', DATE '2026-03-01', 2, 800, 800);
SELECT lives_ok($$SELECT fin_publish_standard_cost(991102, 7)$$, 'F4 发布 B（2026-03 起）成功');
SELECT is((SELECT period_to FROM fin_standard_cost WHERE id = 991101), DATE '2026-02-01',
          'F5 A 自动截止到 2026-02');
SELECT results_eq(
    $$SELECT status, period_to FROM fin_standard_cost WHERE id = 991102$$,
    $$VALUES (40::smallint, NULL::date)$$,
    'F6 B 已发布、无截止');
SELECT is((SELECT standard_cost FROM mdm_material WHERE id = 991001), 800.000000::numeric(18,6),
          'F7 mdm_material.standard_cost 更新为 B');

-- 版 C：2026-02 起，不晚于当前有效版 B → 70134
INSERT INTO fin_standard_cost (id, company_id, material_id, material_code, cost_version, period_from, cost_method,
                               material_unit_cost, total_unit_cost)
VALUES (991103, 1, 991001, '9FSC000001', '2026C', DATE '2026-02-01', 2, 900, 900);
SELECT throws_ok($$SELECT fin_publish_standard_cost(991103, 7)$$, 'P0001', '70134',
                 'F8 C（2026-02）不晚于 B → 70134');
SELECT is((SELECT status FROM fin_standard_cost WHERE id = 991103), 10::smallint, 'F9 C 仍为草稿');
SELECT is((SELECT period_to FROM fin_standard_cost WHERE id = 991101), DATE '2026-02-01', 'F10 被拒后 A 截止不变');

SELECT throws_ok($$SELECT fin_publish_standard_cost(991102, 7)$$, 'P0001', '70135',
                 'F11 已发布版再次发布 → 70135');

-- 发布保护触发器：erp_app 不能绕过发布函数
SELECT throws_ok($$UPDATE fin_standard_cost SET status = 40 WHERE id = 991103$$, 'P0001', '70135',
                 'F12a erp_app 直接 UPDATE status=40 被拒');
SELECT throws_ok(
    $$INSERT INTO fin_standard_cost (id, company_id, material_id, material_code, cost_version, period_from, cost_method,
                                     material_unit_cost, total_unit_cost, status)
      VALUES (991106, 1, 991001, '9FSC000001', '2026Z', DATE '2027-01-01', 2, 1, 1, 40)$$,
    'P0001', '70135', 'F12b erp_app 直接 INSERT status=40 被拒');
SELECT throws_ok($$UPDATE fin_standard_cost SET remark = 'x' WHERE id = 991102$$, 'P0001', '70135',
                 'F12c erp_app 修改已发布行被拒');
SELECT ok(NOT has_table_privilege('erp_app', 'fin_standard_cost', 'UPDATE')
          AND NOT has_column_privilege('erp_app', 'fin_standard_cost', 'published_at', 'UPDATE')
          AND NOT has_column_privilege('erp_app', 'fin_standard_cost', 'published_by', 'UPDATE')
          AND has_column_privilege('erp_app', 'fin_standard_cost', 'material_unit_cost', 'UPDATE'),
          'F12d erp_app 无表级 UPDATE、无 published_* 列 UPDATE、可改草稿业务列');

-- EXCLUDE：owner 暂停触发器后直接插入与 B（2026-03~无期限）重叠的已发布版
RESET ROLE;
SET LOCAL session_replication_role = replica;
SELECT throws_ok(
    $$INSERT INTO fin_standard_cost (id, tenant_id, company_id, material_id, material_code, cost_version, period_from, cost_method,
                                     material_unit_cost, total_unit_cost, status)
      VALUES (991104, 101, 1, 991001, '9FSC000001', '2026X', DATE '2026-05-01', 2, 1, 1, 40)$$,
    '23P01', NULL, 'F12 重叠的已发布版被 ex_fin_standard_cost_period 拒绝');
SET LOCAL session_replication_role = origin;
SET ROLE erp_app;

-- 非月初日期被 CHECK 拒绝
SELECT throws_ok(
    $$INSERT INTO fin_standard_cost (id, company_id, material_id, material_code, cost_version, period_from, cost_method,
                                     material_unit_cost, total_unit_cost)
      VALUES (991105, 1, 991001, '9FSC000001', '2026Y', DATE '2026-06-15', 2, 1, 1)$$,
    '23514', NULL, 'F13 period_from 非月初被 ck_fin_standard_cost_period 拒绝');

-- 跨租户不可见
SELECT is((SELECT count(*) FROM fin_standard_cost WHERE id = 992001 OR tenant_id = 202), 0::bigint,
          'F14 租户 101 看不到租户 202 的标准成本');

-- erp_app 不能直接改快照列
SELECT throws_ok($$UPDATE mdm_material SET standard_cost = 1 WHERE id = 991001$$, '42501', NULL,
                 'F15 erp_app 直接 UPDATE mdm_material.standard_cost 被拒');

-- 生效期间与当月：未来月发布不改快照，当月发布会改（新物料，避免与上面 A/B 的固定期间耦合）
RESET ROLE;
INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id,
                          spec, base_uom_code, valuation_method, standard_cost, status)
VALUES (991003, 101, 1, '9FSC000002', 'fsc mat month', 10, 991001, 'spec', 'PCE', 20, 5.000000, 1);
SET ROLE erp_app;
SELECT set_config('app.tenant_id', '101', true);
INSERT INTO fin_standard_cost (id, company_id, material_id, material_code, cost_version, period_from, cost_method,
                               material_unit_cost, total_unit_cost)
VALUES (991201, 1, 991003, '9FSC000002', 'CUR', date_trunc('month', current_date)::date, 2, 10, 10),
       (991202, 1, 991003, '9FSC000002', 'FUT', (date_trunc('month', current_date) + interval '2 month')::date, 2, 20, 20);
SELECT fin_publish_standard_cost(991201, 7);
SELECT is((SELECT standard_cost FROM mdm_material WHERE id = 991003), 10.000000::numeric(18,6),
          'F17 当月生效版发布 → standard_cost 更新');
SELECT lives_ok($$SELECT fin_publish_standard_cost(991202, 7)$$, 'F18 erp_app 经发布函数发布未来版成功');
SELECT is((SELECT standard_cost FROM mdm_material WHERE id = 991003), 10.000000::numeric(18,6),
          'F19 未来月生效版发布 → standard_cost 不变');

RESET ROLE;

SELECT ok(
    EXISTS (SELECT 1 FROM pg_proc p JOIN pg_roles r ON r.oid = p.proowner
             WHERE p.proname = 'fin_publish_standard_cost' AND p.prosecdef
               AND r.rolname = 'erp_cost_publisher'
               AND p.proconfig @> ARRAY['search_path=public, pg_temp']),
    'F16 fin_publish_standard_cost：owner erp_cost_publisher、SECURITY DEFINER、search_path 固定');

SELECT * FROM finish();
ROLLBACK;
