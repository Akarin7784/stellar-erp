-- 删除 sys/V202610211406 的一次性回填函数 sys_apply_overproduction_menu()（回填已在 V202610211406 执行完毕）。
-- 不改 V202610211406。之后的新租户/新公司由 sys_init_tenant（sys_menu_seed_rows() 594 行）/ sys_init_company 负责。
DROP FUNCTION IF EXISTS public.sys_apply_overproduction_menu();
