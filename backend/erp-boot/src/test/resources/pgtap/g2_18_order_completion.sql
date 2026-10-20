-- pgTAP：G2-18 受注行累计完工上限（单会话规则）。并发场景见 Java db.G218ConcurrencyTest。
-- 被测对象：db/draft/g2_18_completion.sql（PR #4 定稿 32b4493），在本事务内加载，结尾 ROLLBACK。
-- prd_work_order / prd_overproduction_approval 用 prd/V202610210702 的正式表；T2 受注表还没迁移，用 pgtap-support/g2_18_stub_tables.sql 的桩表；
-- 物料/分类的 completion_over_rate、mdm_uom、sys_param、sys_audit_log 用的是 main 上的正式表。
-- 断言全部在 SET ROLE erp_app（NOBYPASSRLS）下进行，app.tenant_id / app.company_id 用 set_config(...,true)。
-- 业务错误由 g2_18_raise 抛出：SQLSTATE P0001，MESSAGE = 错误码。
-- 「--!include <classpath 路径>」由 PgTapSuiteTest / scripts/local-ci.sh 展开成文件内容。
BEGIN;
SELECT plan(66);

--!include pgtap-support/g2_18_stub_tables.sql
--!include db/draft/g2_18_completion.sql

-- ---------------------------------------------------------------- 准备数据（owner，显式 tenant_id）
INSERT INTO mdm_material_category (id, tenant_id, company_id, category_code, category_name, category_path, category_level, is_leaf, completion_over_rate) VALUES
    (991001, 101, 1, '9G1', 'g218 无率分类', '/9G1/', 1, TRUE, NULL),
    (991002, 101, 1, '9G2', 'g218 分类率',   '/9G2/', 1, TRUE, 0.0200);
INSERT INTO mdm_uom (id, tenant_id, company_id, uom_code, uom_name, conversion_group, is_base_uom, decimal_places) VALUES
    (991001, 101, 1, 'PCE', '个', 'CNT', TRUE, 0),
    (991002, 101, 1, 'KGM', '千克', 'WGT', TRUE, 2);
INSERT INTO mdm_material (id, tenant_id, company_id, material_code, material_name, material_type, category_id, spec, base_uom_code, valuation_method, status, completion_over_rate) VALUES
    (991001, 101, 1, '99G2180001', 'M1 无率',      10, 991001, 's', 'PCE', 20, 1, NULL),
    (991002, 101, 1, '99G2180002', 'M2 另一物料',  10, 991001, 's', 'PCE', 20, 1, NULL),
    (991003, 101, 1, '99G2180003', 'M3 物料率',    10, 991002, 's', 'PCE', 20, 1, 0.0300),
    (991004, 101, 1, '99G2180004', 'M4 继承分类',  10, 991002, 's', 'PCE', 20, 1, NULL),
    (991005, 101, 1, '99G2180005', 'M5 物料显式0', 10, 991002, 's', 'PCE', 20, 1, 0),
    (991006, 101, 1, '99G2180006', 'M6 KGM',       10, 991001, 's', 'KGM', 20, 1, NULL);
INSERT INTO sys_param (id, tenant_id, company_id, param_key, param_name, param_group, param_value, value_type) VALUES
    (991001, 101, 1, 'prd.completion_over_rate', '完工超入库容许率', 'PRD', '0.05', 3);

INSERT INTO sal_sales_order (id, tenant_id, company_id, order_no) VALUES
    (991001, 101, 1, 'SO-G218-1'),
    (991901, 202, 1, 'SO-G218-T202');
INSERT INTO sal_sales_order_line (id, tenant_id, sales_order_id, line_no, material_id, base_qty, shipped_base_qty, over_receipt_rate, allowed_qty, completed_qty) VALUES
    (991011, 101, 991001, 1, 991001, 100, 0,  0.05, 105, 100),  -- L1 报完工
    (991012, 101, 991001, 2, 991001, 100, 0,  0,    100, 0),    -- L2 工单级审批
    (991013, 101, 991001, 3, 991001, 100, 0,  0,    100, 0),    -- L3 整行审批
    (991014, 101, 991001, 4, 991001, 100, 0,  0.05, 115, 115),  -- L4 改量（已批 +10）
    (991015, 101, 991001, 5, 991001, 100, 0,  NULL, NULL, 0),   -- L5 allowed_qty 未快照
    (991016, 101, 991001, 6, 991001, 100, 50, 0.05, 105, 0),    -- L6 已发货 50
    (991017, 101, 991001, 7, 991001, 100, 0,  0,    100, 0),    -- L7 60103
    (991901, 202, 991901, 1, 991001, 100, 0,  0.05, 105, 0);    -- 租户 202
INSERT INTO mdm_factory (id, tenant_id, company_id, factory_code, factory_name) VALUES
    (991001, 101, 1, '9G1', 'g218 工厂'),
    (991901, 202, 1, '9G1', 'g218 工厂 T202');
-- 正式表的 NOT NULL 快照列按物料补齐；order_status 显式给（DEFAULT 是 10，G2-18 需要 30/35）
INSERT INTO prd_work_order (id, tenant_id, company_id, sales_order_line_id, material_id, order_status, order_qty, completed_qty, allowed_qty, over_receipt_rate, work_order_no, material_code, material_name, uom_code, factory_id, planned_start_date, planned_end_date)
SELECT v.*, 0.05, 'WO-G218-' || v.id,  -- over_receipt_rate 显式快照 0.05（NOT NULL、无 DEFAULT）
       m.material_code, m.material_name, m.base_uom_code,
       CASE v.tenant_id WHEN 202 THEN 991901 ELSE 991001 END, DATE '2026-10-01', DATE '2026-10-31'
FROM (VALUES
    (991101, 101, 1, 991011, 991001, 35, 100, 100, 105),
    (991102, 101, 1, 991011, 991001, 30, 1,   0,   0),   -- 正式表 CHECK order_qty > 0，桩表用的 0 改成 1（allowed 仍 0）
    (991103, 101, 1, 991011, 991002, 35, 10,  0,   10),   -- 物料与受注行不一致
    (991201, 101, 1, 991012, 991001, 30, 60,  0,   63),
    (991202, 101, 1, 991012, 991001, 30, 40,  0,   42),
    (991301, 101, 1, 991013, 991001, 30, 60,  0,   63),
    (991302, 101, 1, 991013, 991001, 30, 40,  0,   42),
    (991501, 101, 1, NULL,   991001, 35, 10,  0,   NULL), -- MTS，allowed 未快照 → 用工单快照 rate 0.05
    (991901, 202, 1, 991901, 991001, 35, 100, 0,   105)
) v(id, tenant_id, company_id, sales_order_line_id, material_id, order_status, order_qty, completed_qty, allowed_qty)
JOIN mdm_material m ON m.id = v.material_id;

INSERT INTO prd_overproduction_approval (id, tenant_id, company_id, approval_no, sales_order_line_id, work_order_id, material_id, request_qty, approval_status, sales_order_id, current_allowed_qty, requested_by, requested_at)
SELECT v.*, 991001, 100, 9, now() FROM (VALUES
    (991301, 101, 1, 'OA-L3',     991013, NULL::bigint,   991001, 10,  20),  -- L3 整行
    (991401, 101, 1, 'OA-L4-OK',  991014, NULL,   991001, 10,  30),
    (991402, 101, 1, 'OA-L4-NG',  991014, NULL,   991001, 7,   40),
    (991702, 101, 1, 'OA-L7-0.4', 991017, NULL,   991001, 0.4, 20)
) v;  -- current_allowed_qty 为申请时快照，G2-18 不读，统一给 100
-- 原 991701（request_qty NULL）删掉：正式表 request_qty NOT NULL，插不进去，A16 已删（2026-10-21 定稿，NULL 校验移到服务层）

SET ROLE erp_app;
SELECT set_config('app.tenant_id', '101', true);
SELECT set_config('app.company_id', '1', true);

-- ---------------------------------------------------------------- C 上下文守卫
SELECT set_config('app.tenant_id', '', true);
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 1, 9)$$, 'P0001', '5000', 'C1 缺 app.tenant_id → 5000');
SELECT set_config('app.tenant_id', 'abc', true);
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 1, 9)$$, 'P0001', '5000', 'C2 app.tenant_id 非数值 → 5000');
SELECT set_config('app.tenant_id', '0', true);
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 1, 9)$$, 'P0001', '5000', 'C3 app.tenant_id = 0 → 5000');
SELECT set_config('app.tenant_id', '101', true);
SELECT set_config('app.company_id', '', true);
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 1, 9)$$, 'P0001', '5000', 'C4 缺 app.company_id → 5000');
SELECT set_config('app.company_id', '2', true);
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 1, 9)$$, 'P0001', '4001', 'C5 其他公司的工单 → 4001');
SELECT throws_ok($$SELECT g2_18_raise_allowed_qty(991012, NULL, 10, 'X', 9, 990001)$$, 'P0001', '4001', 'C6 其他公司的受注行审批调高 → 4001');
SELECT set_config('app.company_id', '1', true);

-- ---------------------------------------------------------------- R RLS 跨租户
SELECT is((SELECT count(*) FROM sal_sales_order_line WHERE id = 991901), 0::bigint, 'R1 租户 101 看不到租户 202 的受注行');
SELECT throws_ok($$SELECT g2_18_report_completion(991901, 1, 9)$$, 'P0001', '4001', 'R2 租户 101 对租户 202 的工单报完工 → 4001');
SELECT set_config('app.tenant_id', '202', true);
SELECT is((SELECT count(*) FROM prd_work_order WHERE tenant_id = 101), 0::bigint, 'R3 租户 202 看不到租户 101 的工单');
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 1, 9)$$, 'P0001', '4001', 'R4 租户 202 对租户 101 的工单报完工 → 4001');
SELECT lives_ok($$SELECT g2_18_report_completion(991901, 5, 9)$$, 'R5 租户 202 对自己的工单报完工成功');
SELECT is((SELECT completed_qty FROM sal_sales_order_line WHERE id = 991901), 5::numeric, 'R6 租户 202 受注行 completed_qty = 5');
SELECT set_config('app.tenant_id', '101', true);

-- ---------------------------------------------------------------- K 容许率四级继承
SELECT is(g2_18_resolve_over_receipt_rate(0.1000, 991003), 0.1000::numeric, 'K1 受注行指定优先于物料');
SELECT is(g2_18_resolve_over_receipt_rate(0, 991003), 0::numeric, 'K2 受注行显式 0 不继承');
SELECT is(g2_18_resolve_over_receipt_rate(NULL, 991003), 0.0300::numeric, 'K3 行 NULL → 物料 0.03');
SELECT is(g2_18_resolve_over_receipt_rate(NULL, 991005), 0::numeric, 'K4 物料显式 0 不继承分类 0.02');
SELECT is(g2_18_resolve_over_receipt_rate(NULL, 991004), 0.0200::numeric, 'K5 物料 NULL → 分类 0.02');
SELECT is(g2_18_resolve_over_receipt_rate(NULL, 991001), 0.05::numeric, 'K6 物料/分类 NULL → sys_param 0.05');
SELECT set_config('app.company_id', '3', true);
SELECT throws_ok($$SELECT g2_18_resolve_over_receipt_rate(NULL, 991001)$$, 'P0001', '5000', 'K7 公司 sys_param 缺失 → 5000（不硬编码 0.05）');
SELECT set_config('app.company_id', '1', true);

-- ---------------------------------------------------------------- F 按 decimal_places 向下取整
SELECT is(g2_18_calc_allowed_qty(7, 0.05, 991001), 7::numeric, 'F1 PCE(0 位) 7×1.05=7.35 → 7');
SELECT is(g2_18_calc_allowed_qty(7, 0.05, 991006), 7.35::numeric, 'F2 KGM(2 位) 7×1.05 → 7.35');
SELECT is(g2_18_calc_allowed_qty(7.333, 0.05, 991006), 7.69::numeric, 'F3 KGM 7.333×1.05=7.69965 → 7.69（不四舍五入）');

-- ---------------------------------------------------------------- S 确认快照 / allowed_qty NULL
SELECT throws_ok($$SELECT g2_18_raise_allowed_qty(991015, NULL, 10, 'X', 9, 990002)$$, 'P0001', '5000', 'S1 受注行 allowed_qty 未快照时审批 → 5000');
SELECT is(g2_18_snapshot_on_line_confirm(991015, NULL, 9), 105::numeric, 'S2 确认快照 allowed_qty = floor(100×1.05) = 105');
SELECT is((SELECT ARRAY[over_receipt_rate, allowed_qty] FROM sal_sales_order_line WHERE id = 991015), ARRAY[0.05, 105]::numeric[], 'S3 快照写入 rate 0.05 / allowed 105');

-- ---------------------------------------------------------------- P 报完工（L1：100/105，WO 991101 100/105，+10 同时超行和工单）
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 0, 9)$$, 'P0001', '1003', 'P1 数量 0 → 1003');
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 10, 9)$$, 'P0001', '60100', 'P2 无审批：60100 优先于工单上限 60040');
RESET ROLE;
INSERT INTO prd_overproduction_approval (id, tenant_id, company_id, approval_no, sales_order_line_id, work_order_id, material_id, request_qty, approval_status, sales_order_id, current_allowed_qty, requested_by, requested_at)
VALUES (991102, 101, 1, 'OA-L1-WO2', 991011, 991102, 991001, 10, 30, 991001, 105, 9, now());   -- 只针对 WO 991102
SET ROLE erp_app;
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 10, 9)$$, 'P0001', '60100', 'P3 只有其他工单的已批审批不算本工单 → 60100');
RESET ROLE;
INSERT INTO prd_overproduction_approval (id, tenant_id, company_id, approval_no, sales_order_line_id, work_order_id, material_id, request_qty, approval_status, sales_order_id, current_allowed_qty, requested_by, requested_at)
VALUES (991101, 101, 1, 'OA-L1-WO1', 991011, 991101, 991001, 10, 20, 991001, 105, 9, now());
SET ROLE erp_app;
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 10, 9)$$, 'P0001', '60100', 'P4 审批承認待ち(20) → 60100');
UPDATE prd_overproduction_approval SET approval_status = 10 WHERE id = 991101;
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 10, 9)$$, 'P0001', '60100', 'P5 审批草稿(10) → 60100');
UPDATE prd_overproduction_approval SET approval_status = 40 WHERE id = 991101;
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 10, 9)$$, 'P0001', '60101', 'P6 只有却下(40) → 60101');
UPDATE prd_overproduction_approval SET approval_status = 90 WHERE id = 991101;
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 10, 9)$$, 'P0001', '60101', 'P7 只有取消(90) → 60101');
UPDATE prd_overproduction_approval SET approval_status = 30 WHERE id = 991101;
SELECT throws_ok($$SELECT g2_18_report_completion(991101, 10, 9)$$, 'P0001', '60040', 'P8 已批(30)但额度用尽 → 60040');
SELECT lives_ok($$SELECT g2_18_report_completion(991101, 5, 9)$$, 'P9 恰好到 allowed_qty 105 成功');
SELECT is((SELECT ARRAY[l.completed_qty, w.completed_qty] FROM sal_sales_order_line l, prd_work_order w WHERE l.id = 991011 AND w.id = 991101),
          ARRAY[105, 105]::numeric[], 'P10 受注行与工单 completed_qty 都 = 105');
SELECT throws_ok($$SELECT g2_18_report_completion(991103, 1, 9)$$, 'P0001', '60056', 'P11 工单物料 ≠ 受注行物料 → 60056');
SELECT throws_ok($$SELECT g2_18_report_completion(991501, 11, 9)$$, 'P0001', '60040', 'P12 MTS 超 floor(10×1.05)=10 → 60040');
SELECT lives_ok($$SELECT g2_18_report_completion(991501, 10, 9)$$, 'P13 MTS 恰好 10 成功');
RESET ROLE;
SELECT CASE WHEN (SELECT is_nullable FROM information_schema.columns
                   WHERE table_schema = 'public' AND table_name = 'prd_work_order' AND column_name = 'over_receipt_rate') = 'NO'
    THEN throws_ok($$INSERT INTO prd_work_order (id, tenant_id, company_id, material_id, order_status, order_qty, work_order_no, material_code,
                       material_name, uom_code, factory_id, planned_start_date, planned_end_date, over_receipt_rate)
                     VALUES (991502, 101, 1, 991001, 30, 10, 'WO-G218-991502', '99G2180001', 'M1', 'PCE', 991001, DATE '2026-10-01', DATE '2026-10-31', NULL)$$,
                   '23502', NULL, 'P14 工单 over_receipt_rate 为 NULL → 23502（NOT NULL，工单层不继承）')
    ELSE skip('P14 待 #13 迁移把 prd_work_order.over_receipt_rate 改成 NOT NULL 无 DEFAULT（2026-10-21 定稿）', 1) END;
SET ROLE erp_app;

-- ---------------------------------------------------------------- V 冲销
SELECT throws_ok($$SELECT g2_18_reverse_completion(991101, 200, 9)$$, 'P0001', '60102', 'V1 冲销量 > 已完工 → 60102');
SELECT throws_ok($$SELECT g2_18_reverse_completion(991101, 0, 9)$$, 'P0001', '1003', 'V2 冲销量 0 → 1003');
SELECT lives_ok($$SELECT g2_18_reverse_completion(991101, 5, 9)$$, 'V3 冲销 5 成功');
SELECT is((SELECT ARRAY[l.completed_qty, w.completed_qty] FROM sal_sales_order_line l, prd_work_order w WHERE l.id = 991011 AND w.id = 991101),
          ARRAY[100, 100]::numeric[], 'V4 冲销后受注行与工单都 = 100');

-- ---------------------------------------------------------------- A 超产审批 delta
SELECT lives_ok($$SELECT g2_18_raise_allowed_qty(991012, 991201, 10, 'OA-L2-WO1', 9, 990003)$$, 'A1 工单级 +10 成功');
SELECT is((SELECT ARRAY[(SELECT allowed_qty FROM sal_sales_order_line WHERE id = 991012),
                        (SELECT allowed_qty FROM prd_work_order WHERE id = 991201),
                        (SELECT allowed_qty FROM prd_work_order WHERE id = 991202)]),
          ARRAY[110, 73, 42]::numeric[], 'A2 工单级 +10：受注行 110 / WO1 73 / WO2 42');
SELECT throws_ok($$SELECT g2_18_report_completion(991202, 43, 9)$$, 'P0001', '60040', 'A3 WO2 仍受自身 allowed 42 限制 → 60040');
SELECT lives_ok($$SELECT g2_18_report_completion(991202, 42, 9)$$, 'A4 WO2 完工 42 成功');
SELECT throws_ok($$SELECT g2_18_raise_allowed_qty(991012, 991301, 10, 'OA-X', 9, 990004)$$, 'P0001', '60056', 'A5 工单不属于该受注行 → 60056');
SELECT is((SELECT allowed_qty FROM sal_sales_order_line WHERE id = 991012), 110::numeric, 'A6 60056 时受注行 allowed_qty 不变（110）');
SELECT is(g2_18_approve_overproduction(991301, 9, 990005), 110::numeric, 'A7 整行审批通过返回新 allowed 110');
SELECT is((SELECT ARRAY[(SELECT allowed_qty FROM sal_sales_order_line WHERE id = 991013),
                        (SELECT allowed_qty FROM prd_work_order WHERE id = 991301),
                        (SELECT allowed_qty FROM prd_work_order WHERE id = 991302)]),
          ARRAY[110, 63, 42]::numeric[], 'A8 整行 +10：受注行 110，工单 63/42 不变');
SELECT is((SELECT ARRAY[approval_status, approved_allowed_qty, approved_by] FROM prd_overproduction_approval WHERE id = 991301),
          ARRAY[30, 110, 9]::numeric[], 'A9 审批单 30 / approved_allowed_qty 110 / approved_by');
SELECT is((SELECT count(*) FROM sys_audit_log WHERE id = 990005 AND resource_no = 'OA-L3' AND (after_data->>'delta_qty')::numeric = 10),
          1::bigint, 'A10 写入审计日志（tenant_id 取列默认值）');
SELECT throws_ok($$SELECT g2_18_approve_overproduction(991301, 9, 990006)$$, 'P0001', '4002', 'A11 已批的审批单再次通过 → 4002');
SELECT throws_ok($$SELECT g2_18_raise_allowed_qty(991017, NULL, NULL, 'X', 9, 990007)$$, 'P0001', '60103', 'A12 delta NULL → 60103');
SELECT throws_ok($$SELECT g2_18_raise_allowed_qty(991017, NULL, 0, 'X', 9, 990008)$$, 'P0001', '60103', 'A13 delta 0 → 60103');
SELECT throws_ok($$SELECT g2_18_raise_allowed_qty(991017, NULL, -1, 'X', 9, 990009)$$, 'P0001', '60103', 'A14 delta 负数 → 60103');
SELECT throws_ok($$SELECT g2_18_approve_overproduction(991702, 9, 990010)$$, 'P0001', '60103', 'A15 审批单 request_qty 0.4（PCE 取整为 0）→ 60103');
SELECT is((SELECT ARRAY[(SELECT allowed_qty FROM sal_sales_order_line WHERE id = 991017),
                        (SELECT approval_status FROM prd_overproduction_approval WHERE id = 991702)]),
          ARRAY[100, 20]::numeric[], 'A17 60103 后受注行 100、审批单仍 20');

-- ---------------------------------------------------------------- Q 受注改量
SELECT is(g2_18_check_line_qty_change(991014, 120), 136::numeric, 'Q1 100→120 率 0.05 + 已批 +10（驳回 7 不计）= 136');
SELECT throws_ok($$SELECT g2_18_check_line_qty_change(991014, 90)$$, 'P0001', '30022', 'Q2 新 allowed 94+10=104 < 已完工 115 → 30022');
SELECT is(g2_18_check_line_qty_change(991014, 100), 115::numeric, 'Q3 边界：新 allowed 115 = 已完工 115 通过');
SELECT throws_ok($$SELECT g2_18_check_line_qty_change(991016, 40)$$, 'P0001', '30022', 'Q4 新数量 40 < 已发货 50 → 30022');

-- ---------------------------------------------------------------- D 对账视图 / CHECK 兜底
SELECT is((SELECT ARRAY[line_completed_qty, wo_completed_qty_sum, diff_qty] FROM v_g2_18_line_completion_recon WHERE sales_order_line_id = 991012),
          ARRAY[42, 42, 0]::numeric[], 'D1 对账视图 L2：受注行 42 = 工单合计 42');
SELECT is((SELECT count(*) FROM v_g2_18_line_completion_recon WHERE sales_order_line_id = 991901), 0::bigint, 'D2 视图 security_invoker：看不到租户 202');
SELECT throws_ok($$UPDATE sal_sales_order_line SET completed_qty = 106 WHERE id = 991011$$, '23514', NULL, 'D3 绕过函数直接超 allowed_qty → CHECK 23514');

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
