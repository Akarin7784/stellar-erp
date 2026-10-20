-- btree_gist：供 07 财务 fin_standard_cost 已发布版本期间不重叠的 EXCLUDE 约束（tenant_id/company_id/material_id WITH = + daterange WITH &&）使用。
CREATE EXTENSION IF NOT EXISTS btree_gist;
