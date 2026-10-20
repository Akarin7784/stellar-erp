-- pg_trgm：名称模糊检索（gin_trgm_ops）。由 owner（Flyway）创建；erp_app 无需 CREATE。
-- 依据：docs/design/00-common/04-common-db-spec.md §1、docs/design/02-mdm/90-db-design.md §5 / §9.1
CREATE EXTENSION IF NOT EXISTS pg_trgm;
