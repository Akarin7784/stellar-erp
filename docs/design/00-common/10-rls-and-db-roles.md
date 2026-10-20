# 10 RLS・数据库角色・租户上下文（实现基线）

> 适用：全部含 `tenant_id` 的表。关联：issue #10（租户列统一）、#9（RLS 阶段）、#7（Flowable 独立 schema）。
> 面向：开发、**测试与评审**团队。

## 1. 术语：tenant 与 company

| 列 | 含义 | 用途 |
|---|---|---|
| `tenant_id` | 租户＝部署客户（SaaS 客户 / 私有化实例） | **唯一的 RLS 隔离键**；所有业务表必须持有 |
| `company_id` | 公司＝租户内的法人主体 | 业务键、索引前导列、会计主体；**不进 RLS 策略**，由应用层数据权限控制 |

层级：1 个 tenant ⊇ N 个 company。文档、DDL、代码一律使用 `tenant_id` 这一列名（不使用 `tenant`、`tenant_code`、`org_id` 等别名）。

## 2. 数据库角色

| 角色 | 用途 | 属性 |
|---|---|---|
| owner（dev：`erp`；prod：DBA 指定） | Flyway 执行迁移，所有表的所有者 | 仅用于迁移，应用运行时不使用 |
| `erp_app` | 应用运行账号（`spring.datasource.username`） | 非 owner、`NOSUPERUSER`、`NOBYPASSRLS`；仅 DML 权限 + `public`/`flowable` 的 USAGE；**无 CREATE**（自建表 owner 是自己会使 RLS 失效）。Flowable 表由 Flyway 预建在 schema `flowable`（#7，PR #46） |

- 角色由迁移 `sys/V202610200101__sys_create_app_role.sql` 以 `NOLOGIN` 创建；之后 owner 新建的表通过 `ALTER DEFAULT PRIVILEGES` 自动授权。
- 登录与密码由 Flyway 回调 `db/callback/afterMigrate.sql` 根据占位符 `erp_app_password`（环境变量 `DB_APP_PASSWORD`）设置；为空则保持 `NOLOGIN`。密码不得包含单引号。
- 配置：`spring.datasource.username/password` ← `DB_APP_USER`/`DB_APP_PASSWORD`；`spring.flyway.user/password` ← `DB_USER`/`DB_PASSWORD`（owner）。
- 因为表归 owner 所有且启用了 `FORCE ROW LEVEL SECURITY`，`erp_app` 必然受 RLS 约束。**超级用户和 BYPASSRLS 角色不受 RLS 约束**，不得用于应用连接。

## 3. 租户上下文

1. `com.stellar.erp.common.TenantContext`（ThreadLocal）保存当前租户；首期未设置时为 `0`。
2. `TenantAwareTransactionManager` 在**每个事务开始时**执行 `SELECT set_config('app.tenant_id', ?, true)`（事务级，等价 `SET LOCAL`）。提交/回滚后自动失效，连接池中不会残留租户。
3. 事务之外（自动提交）执行的 SQL **不设置** `app.tenant_id`：访问 RLS 表时 `current_setting('app.tenant_id')` 报错（未设置或为空字符串都无法转换为 bigint），**不会返回全部行**。因此访问业务表的代码必须在 `@Transactional` / `TransactionTemplate` 内。
4. 后续接入登录后，由请求过滤器从会话写入 `TenantContext` 并在请求结束时 `clear()`。

## 4. 表模板（新增含 `tenant_id` 的表必须套用）

```sql
CREATE TABLE xxx_table (
    id         BIGINT NOT NULL,
    tenant_id  BIGINT NOT NULL DEFAULT current_setting('app.tenant_id')::bigint,  -- 不允许 DEFAULT 0
    company_id BIGINT NOT NULL,
    -- ...
    CONSTRAINT pk_xxx_table PRIMARY KEY (id)
);

ALTER TABLE xxx_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE xxx_table FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON xxx_table
    USING      (tenant_id = current_setting('app.tenant_id')::bigint)
    WITH CHECK (tenant_id = current_setting('app.tenant_id')::bigint);
```

- `USING` 限制可见 / 可改 / 可删的行；`WITH CHECK` 拒绝写入或改成其他租户的行。
- `tenant_id` 默认值取当前上下文，**未设置上下文时插入失败（有意为之）**，不再静默写入 0。
- Flyway / owner 执行的种子数据（`V…`、`R__seed_*`）**必须显式写出 `tenant_id`**（owner 无 `app.tenant_id`）。
- 业务表的唯一索引仍以 `company_id` 为前导列（见 04-common-db-spec），如需租户间允许重复的业务键，请在评审中提出。
- **在各领域设计书定稿前，不新增领域业务表**；本 PR 只对现有 `sys_user` 套用模板。

## 5. 测试约定（测试与评审）

| 测试 | 作用 |
|---|---|
| `db.RlsCoverageTest` | CI 守护：`public` 中所有含 `tenant_id` 列的表必须 ENABLE + FORCE RLS 且有策略；应用账号非 owner、非超级用户、无 BYPASSRLS |
| `db.TenantIsolationTest` | 租户 A 不能读 / 改 / 删租户 B 的行；不能写入或改为 B；无上下文查询和插入均失败 |
| `db.PgTapSmokeTest` | pgTAP 冒烟测试（`has_table` / `policies_are` / `has_role`） |

- 标注 `@DbIntegrationTest`（`@Tag("integration")`），由 CI 的 `./mvnw verify` 执行。
- 测试数据库镜像：`backend/erp-boot/src/test/docker/postgres-pgtap/Dockerfile`（`postgres:18.6` + pgTAP），由 Testcontainers `ImageFromDockerfile` 构建。
- `CREATE EXTENSION pgtap` **只在测试中执行**，生产迁移中不包含。
- 准备跨租户数据请用 `support.OwnerJdbc`（owner，会绕过 RLS，只用于准备数据）；断言一律通过应用数据源（`erp_app`）+ `TenantContext.callAs(...)` + 事务执行。
- 应用数据源不使用 `@ServiceConnection`，因为它会让应用以容器超级用户连接，超级用户会绕过 RLS。
