-- 01-system：sys_menu.menu_name 不得为空串或纯空白（蓝色大肥鱼 2026-10-21 决定；docs/design/01-system/90-db-design.md v1.22）。
-- 已确认 V202610211405 种子、sys_menu_seed_rows()（594 行）、pgTAP fixture 与后端测试数据中无空串或纯空白菜单名，直接校验（不用 NOT VALID）。
-- 后端目前没有写 sys_menu 的维护 API（只有 AuthMeService 读取），本约束为 DB 层防线。
ALTER TABLE sys_menu
    ADD CONSTRAINT ck_sys_menu_menu_name_not_blank CHECK (btrim(menu_name) <> '');

COMMENT ON CONSTRAINT ck_sys_menu_menu_name_not_blank ON sys_menu IS '菜单名称不得为空串或纯空白（btrim 后非空）';
