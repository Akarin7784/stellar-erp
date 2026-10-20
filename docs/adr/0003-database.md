# ADR-0003：关系型数据库采用 PostgreSQL

- **状态**：已接受
- **日期**：2026-10-20
- **决策人**：Stellar0502
- **相关**：[技术选型方案](../tech-selection.md)

## 背景

ERP 的数据库需求：强事务、复杂报表（窗口函数/CTE）、单据自定义扩展字段、未来多租户隔离、国内可运维。

## 决策

采用 **PostgreSQL 18.6**（Docker 镜像 `postgres:18.6`）。

配套：

- 连接池：HikariCP（Spring Boot 默认）
- 迁移：Flyway，SQL 脚本按模块分目录（`db/migration/{module}/V{version}__{desc}.sql`）
- 主键：`bigint` 雪花 ID（应用层生成，避免自增锁与分库限制）
- 扩展字段：`jsonb` 列 + GIN 索引
- 多租户预留：所有业务表带 `tenant_id`，Phase 3 启用 RLS

## 备选方案

| 方案 | 否决理由 |
|---|---|
| MySQL 8.4 LTS / 9.7 | JSON 能力弱于 JSONB；声明式分区限制多；无行级安全 |
| Oracle | 许可成本高，私有化部署受限 |
| SQL Server | 许可成本高，Linux 生态弱 |

## 理由

1. **JSONB + GIN 索引**：客户自定义字段无需频繁 DDL，这是 ERP 定制化的核心痛点。
2. **窗口函数与 CTE**：库龄、周转率、期间报表、成本核算高度依赖，PG 优化器更可靠。
3. **RLS 预留多租户**：Phase 3 可在不改业务代码的情况下实现租户隔离。
4. **扩展生态**：`pg_trgm` 满足模糊搜索，后期可接 PostGIS（厂区地理位置）、pgvector（智能补货）。
5. **许可**：PostgreSQL License，无 GPL 传染性顾虑。

## 后果

- 团队若不熟悉 PG，需要 1~2 周学习（索引策略、VACUUM、慢查询分析）
- 国内云厂商 PG 运维经验少于 MySQL，客户现场需提供运维文档
- 切换 MySQL 的成本被隔离在 Flyway 脚本与方言层，业务代码基本无感（MyBatis-Plus 兼容）
