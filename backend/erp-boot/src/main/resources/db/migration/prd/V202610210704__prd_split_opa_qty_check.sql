-- 06-production：拆分 prd_overproduction_approval 的数量 CHECK（docs/design/06-production/90-db-design.md §3.19.1）
-- 拆成两条后，违反时可按约束名区分：ck_prd_opa_request_qty → 60103（申请增量须 > 0），ck_prd_opa_allowed_qty → 快照不得为负。
-- 已合迁移 V202610210702 不改，在此 DROP + ADD。
ALTER TABLE prd_overproduction_approval
    DROP CONSTRAINT ck_prd_opa_qty,
    ADD CONSTRAINT ck_prd_opa_request_qty CHECK (request_qty > 0),
    ADD CONSTRAINT ck_prd_opa_allowed_qty CHECK (current_allowed_qty >= 0);
