# Stellar ERP 技术选型方案

| 项目 | 内容 |
|---|---|
| 版本 | v1.0（基线版） |
| 日期 | 2026-10-20 |
| 仓库 | [Stellar0502/stellar-erp](https://github.com/Stellar0502/stellar-erp) |
| 状态 | 已确认，进入工程落地 |
| 决策记录 | [ADR-0001](adr/0001-architecture-style.md) / [ADR-0002](adr/0002-backend-stack.md) / [ADR-0003](adr/0003-database.md) / [ADR-0004](adr/0004-frontend-stack.md) |

> 说明：本文所有版本号均于 2026-10-20 通过 Maven Central、npm registry、Docker Hub 实际查询核实，而非凭记忆填写。核实方式见文末「版本基线清单」。

---

## 1. 背景与目标

### 1.1 业务背景

智能制造场景的 ERP 系统，首期覆盖八大业务域：系统管理、主数据、销售、采购、库存、生产、财务、工作流。典型特征：

- **单据驱动**：采购订单 → 收货 → 入库 → 销售发货 → 出库 → 应收/应付，事务链路长，数据一致性要求高
- **主数据强约束**：物料、客户、供应商、仓库、计量单位，跨模块强依赖
- **审批流密集**：请购、订单、付款、变更单几乎都需要多级审批
- **报表复杂**：期间报表、库龄、周转、成本核算，多表关联 + 窗口函数
- **私有化部署**：客户现场部署为主，数据不出内网

### 1.2 工程目标

| 目标 | 验收标准 |
|---|---|
| 3 个月交付 MVP | 采购 → 入库 → 销售 → 出库 → 应收应付 主链路可用 |
| 小团队可维护 | 1~5 人开发，无需专职运维 |
| 模块边界清晰 | Spring Modulith 校验模块依赖，禁止跨域直接调用 |
| 本地一键启动 | `docker compose up -d` + `mvnw spring-boot:run` + `pnpm dev` |
| 并行开发 | 使用 GitButler 工作区，一人同时推进多条分支不互相阻塞 |
| 可演进 | 预留从模块化单体拆分微服务的路径，不重写业务代码 |

---

## 2. 约束与假设

| 类别 | 约束 / 假设 |
|---|---|
| 团队规模 | 初期 1~5 人，无专职 DBA / 运维 |
| 现有环境 | JDK 21.0.12 LTS、Node 24.21.0、pnpm 12.8.1、Docker 29.8.2、Git 2.56.0（开发机已安装） |
| 运行环境 | 开发 Windows 11，生产 Linux（x86_64），单机或 2~3 节点起步 |
| 网络 | 国内网络环境，依赖拉取优先可用镜像源；GitHub 托管代码 |
| 数据合规 | 私有化部署优先，客户数据不出内网 |
| 多租户 | 首期为单租户私有化，数据结构预留 `tenant_id` 字段 |
| 团队经验 | 熟悉 Java 生态；前端团队规模小，需要中后台组件库开箱即用 |
| 时间预算 | 选型冻结后不再反复，版本升级按季度评估 |

---

## 3. 选型原则

1. **复杂度匹配团队规模**：能用单体解决的不上微服务；架构复杂度必须由业务复杂度兑换。
2. **生态成熟度优先**：库要有活跃维护、完整文档、可查的 issue 历史。
3. **可验证**：每个关键版本必须能在本仓库实际构建成功，不接受「应该兼容」。
4. **可演进**：所有选择都要有明确的退出/替换路径，避免锁定。
5. **总成本最低**：不只是开发成本，还包括部署、运维、升级、招人成本。

---

## 4. 架构风格选型

### 4.1 候选方案对比

| 维度 | 模块化单体（Spring Modulith） | 微服务（Spring Cloud Alibaba） | 传统分层单体 |
|---|---|---|---|
| 事务一致性 | 本地事务，强一致，简单 | 分布式事务（Seata/Saga），复杂 | 本地事务，简单 |
| 部署运维 | 1 个进程，1 套中间件 | 9+ 服务，Nacos/Sentinel/Gateway，运维重 | 1 个进程，最轻 |
| 开发效率 | 高，单仓单进程调试 | 低，跨服务联调成本高 | 高，但模块边界易腐化 |
| 模块边界 | 编译期 + 运行时校验，边界清晰 | 网络边界，天然隔离 | 靠约定，容易变成大泥球 |
| 独立伸缩 | 整进程伸缩 | 按服务伸缩，粒度细 | 整进程伸缩 |
| 团队要求 | 1~10 人合适 | 需要平台/运维投入，10 人以上 | 1~5 人合适 |
| 演进成本 | 可平滑拆出热点模块 | 已拆，但过度设计成本高 | 拆分需重构 |
| 首期总成本 | **低** | 高 | 低 |

### 4.2 结论：模块化单体（Spring Modulith）

**理由：**

1. ERP 的核心难点是**业务一致性与主数据治理**，不是高并发。采购入库、库存扣减、应收生成必须在同一事务内完成，微服务会把这些变成分布式事务，复杂度爆炸而收益极低。
2. 团队 1~5 人，微服务的运维成本（Nacos 集群、链路追踪、配置中心、服务治理）会吃掉一半以上的开发时间。
3. Spring Modulith 提供**编译期依赖校验 + 运行时事件解耦**，既有单体的事务简单性，又有微服务的边界纪律性：
   - `ApplicationModules.verify()` 在 CI 中阻止跨模块违规依赖
   - 模块间异步通信用 `@ApplicationModuleListener`（基于 Spring 事件，可换 RabbitMQ 实现）
   - 模块根包下的类型即对外 API；子包（`internal` 等）为内部实现，跨模块引用由 CI 拦截
4. 拆分路径明确：当某个模块出现独立伸缩需求（如报表、库存扣减）时，将其提取为独立服务，通过 `@ApplicationModuleListener` 已解耦的边界迁移事件，业务代码基本不改。

**触发拆分微服务的条件（预先约定）：**

- 单个模块的 QPS 或数据量达到整库瓶颈的 60% 以上
- 团队规模 > 10 人，模块间发布节奏冲突明显
- 需要独立多活/异地部署
- 出现必须跨团队独立交付的边界

### 4.3 模块划分（限界上下文）

| 模块 | 职责 | 核心实体 | 依赖 |
|---|---|---|---|
| `erp-system` | 用户、角色、菜单、权限、租户、字典、审计日志 | User / Role / Menu / Tenant | common |
| `erp-mdm` | 主数据：物料、客户、供应商、仓库、计量单位、价格表 | Material / Customer / Supplier / Warehouse | common, system |
| `erp-purchase` | 请购、采购订单、收货、对账 | PurchaseOrder / Receipt | mdm, inventory |
| `erp-sales` | 报价、销售订单、发货、退货 | SalesOrder / Shipment | mdm, inventory |
| `erp-inventory` | 库存事务、批次、盘点、调拨、库龄 | StockTxn / Batch / StockBalance | mdm |
| `erp-production` | BOM、工艺路线、工单、报工 | Bom / Routing / WorkOrder | mdm, inventory |
| `erp-finance` | 应收、应付、总账、成本核算 | Receivable / Payable / Voucher | mdm, sales, purchase |
| `erp-workflow` | 流程定义、任务、审批历史 | ProcessInstance / Task | system |
| `erp-integration` | 外部系统对接（MES/WMS/财务软件） | IntegrationConfig | common |

> 模块间只允许引用对方**根包**下的公开类型（接口 + DTO）；跨模块写操作通过领域事件异步处理，读操作允许同步查询。

---

## 5. 后端选型

### 5.1 语言与运行时：Java 21 LTS

| 维度 | Java 21 LTS | Go | Node.js / TypeScript |
|---|---|---|---|
| 本机现状 | ✅ 已安装 21.0.12 | 未安装 | 24.21.0 已安装 |
| ERP 生态 | 极成熟（Spring 全家桶） | 一般，企业应用框架少 | 一般，中后台框架弱于 Java |
| 复杂业务建模 | 强（DDD、事务、ORM） | 中（需自建大量基础设施） | 中 |
| 长事务/一致性 | 强 | 中 | 中 |
| 并发模型 | 虚拟线程（JDK 21）足以支撑 ERP | goroutine 优秀 | 单线程事件循环 |
| 招聘/交接 | 国内 ERP 人才储备最多 | 偏基础设施 | 偏互联网 |
| 结论 | **✅ 选定** | ❌ | ❌ |

JDK 21 的虚拟线程让传统「一请求一线程 + 阻塞 JDBC」模型重新具备高并发能力，ERP 不需要响应式复杂度。

### 5.2 应用框架：Spring Boot 4.1.1

| 维度 | Spring Boot 4.1.1 | NestJS 11 | Go + Gin |
|---|---|---|---|
| 版本状态 | 2026-10 最新稳定线（4.2.0-M2 为里程碑） | 稳定 | 稳定 |
| 生态完整度 | 极高（Security/Data/Batch/Actuator/Modulith） | 良好 | 需自行拼装 |
| 事务/ORM 能力 | 强 | 中 | 弱 |
| 学习曲线 | 中 | 中 | 中 |
| 团队匹配度 | **高** | 低 | 低 |
| 结论 | **✅ 选定** | ❌ | ❌ |

**为什么是 4.1.1 而不是 4.0.8 / 3.5.x：**

- Spring Modulith 2.1.1 的 POM 直接依赖 `spring-boot-autoconfigure 4.1.1`（已核实），版本完全对齐
- springdoc-openapi 3.1.1 基于 Spring Boot 4.1.0 构建（已核实）
- Sa-Token 1.46.0、MyBatis-Plus 3.5.17 均提供 `spring-boot4-starter`
- 4.0.x 是上一稳定线，仅作为 Flowable 兼容性兜底

### 5.3 模块化框架：Spring Modulith 2.1.1

- 与 Boot 4.1.1 严格对齐（已验证 POM 依赖）
- 提供：模块依赖校验、事件外部化（`spring-modulith-events`）、文档生成（`spring-modulith-docs`）、可观测性
- 落地约束：业务代码按模块分包；对外类型放模块根包（如 `com.stellar.erp.common.Result`），其余放子包（`internal`、`web` 等），跨模块访问子包类型会被 `verify()` 拦截

### 5.4 数据访问：MyBatis-Plus 3.5.17

| 维度 | MyBatis-Plus 3.5.17（boot4 starter） | Spring Data JPA 4.x |
|---|---|---|
| SQL 可控性 | 高，复杂报表 SQL 直接写 | 低，复杂查询易失控 |
| 分页/多租户/逻辑删除 | 内置插件，开箱即用 | 需自行实现 |
| 简单 CRUD 效率 | 高（BaseMapper） | 高 |
| 学习成本 | 低（国内团队熟悉） | 中（需理解 JPA 生命周期） |
| 报表/窗口函数 | 强 | 弱 |
| 结论 | **✅ 选定** | 备选 |

补充：
- 简单写操作 + 乐观锁用 MyBatis-Plus
- 复杂读模型（报表、看板）用 `JdbcClient` 直写 SQL，不套 ORM
- 数据库迁移：**Flyway**（SQL 优先、版本管理简单；Liquibase 的 XML 抽象对单纯 SQL 团队是负资产）

### 5.5 认证授权：Sa-Token 1.46.0

| 维度 | Sa-Token 1.46.0（boot4 starter） | Spring Security 7 |
|---|---|---|
| RBAC 菜单/按钮权限 | 内置注解 + 拦截器，简单直接 | 需自行封装 |
| 多端登录/踢人/续签 | 内置 | 需自行实现 |
| 学习曲线 | 低 | 高 |
| OAuth2/SSO | 需扩展 | 原生支持 |
| 结论 | **✅ 首期选定** | Phase 2 接入 SSO 时并存 |

设计要点：
- 登录态 JWT（无状态）+ Redis（可主动下线），兼顾横向扩展与强制登出
- 权限模型：用户 → 角色 → 菜单/按钮权限；数据权限（部门/本人）通过 MyBatis-Plus 插件实现
- Phase 2 对接企业 SSO 时，Sa-Token 负责会话，Spring Security OAuth2 负责协议，两者可共存

### 5.6 API 文档：springdoc-openapi 3.1.1

- 基线 Spring Boot 4.1.0（已核实），与 Boot 4.1.1 兼容
- Swagger UI 自动生成，接口分组按模块划分
- 生产环境通过 `springdoc.api-docs.enabled=false` 关闭

### 5.7 工作流引擎：Flowable 8.0.0

| 维度 | Flowable 8.0.0 | Camunda 8 | 自研状态机 |
|---|---|---|---|
| 部署形态 | 内嵌（JAR + 同库） | 外部 Zeebe 集群 | 内嵌 |
| 许可 | Apache 2.0 | 商业许可（Community 功能受限） | 自研 |
| BPMN 2.0 支持 | 完整 | 完整 | 无 |
| 运维成本 | 低 | 高 | 中 |
| ERP 审批流适配 | 好（会签、驳回、加签、动态表单） | 好 | 需自建 |
| 与 Boot 4 兼容 | 基于 Spring Boot 4.0 构建，**需运行时验证** | 独立进程，无此问题 | 无 |
| 结论 | **✅ 选定（需验证）** | ❌（许可+运维） | 备选（极简审批） |

风险与兜底：
- Flowable 8.0.0 官方基线为 Spring Boot 4.0（其父 POM 注释明确提到 Boot 4.0 的 Artemis 版本问题）
- 验证节点：里程碑 M2（第 6 周）前完成「启动上下文 + 部署一条 BPMN + 完成审批任务」集成测试
- 兜底方案：Spring Boot 降级到 4.0.8 + Spring Modulith 2.0.x（同为 Boot 4.0 基线），业务代码无需改动

### 5.8 基础库

| 能力 | 选型 | 说明 |
|---|---|---|
| 参数校验 | Jakarta Validation（Boot 管理） | `@Valid` + 全局异常处理 |
| 对象映射 | MapStruct 1.6.x | 编译期生成，无反射开销；版本由落地时核实 |
| 简化样板 | Lombok（Boot 管理版本） | 配合 MyBatis-Plus 实体 |
| 工具库 | Hutool 5.8.x | 国内常用，减少样板代码；注意仅用于工具方法 |
| 日志 | SLF4J + Logback（Boot 管理） | 生产 JSON 格式，接入 Loki/ELK |
| 测试 | JUnit 5 + Mockito + Testcontainers | 集成测试用 Testcontainers 起 PostgreSQL |
| 构建 | Maven Wrapper（Maven 3.10.0） | Maven 4.0 仍为 RC，不选 |

---

## 6. 数据与中间件

### 6.1 关系型数据库：PostgreSQL 18.6

| 维度 | PostgreSQL 18.6 | MySQL 8.4 LTS / 9.7 |
|---|---|---|
| JSONB | 原生，可索引 | JSON 功能较弱 |
| 窗口函数/CTE | 完整，报表友好 | 8.0+ 支持，优化器弱于 PG |
| 分区表 | 声明式分区成熟 | 分区限制较多 |
| 行级安全（RLS） | 原生，多租户预留 | 无 |
| 扩展性 | pg_trgm / PostGIS / pgvector | 插件生态弱 |
| 国内运维熟悉度 | 中 | 高 |
| 许可 | PostgreSQL License | GPLv2（MySQL） |
| 结论 | **✅ 选定** | 备选（团队只有 MySQL 经验时） |

选择理由：
- 单据的扩展字段（客户自定义属性）用 JSONB 存储并可建 GIN 索引，避免频繁加列
- 期间报表、库龄、周转率强依赖窗口函数与 CTE，PG 优化器更可靠
- 预留 `tenant_id` + RLS 实现多租户隔离，不改表结构
- 版本策略：锁定 18.6（Docker 镜像已核实存在），跟随小版本升级

### 6.2 缓存：Redis 8.8.3

用途：登录态、字典/权限缓存、分布式锁（Phase 2 引入 Redisson）、接口限流。
策略：Cache-Aside；缓存 key 统一前缀 `erp:{module}:{biz}:{id}`；禁止缓存强一致业务数据。

### 6.3 消息队列：RabbitMQ 4.4.0

| 维度 | RabbitMQ 4.4.0 | Kafka 4.x | RocketMQ 5.x |
|---|---|---|---|
| ERP 场景匹配 | 高（延迟队列、死信、优先级） | 中（流处理强） | 中 |
| 运维成本 | 低 | 中 | 中 |
| 国内生态 | 好 | 好 | 好（阿里系） |
| 结论 | **✅ 首期选定** | Phase 3 数据管道 | 备选 |

用途：模块间异步事件外部化（Modulith events → RabbitMQ）、外部系统集成重试。

### 6.4 对象存储

- 首期：本地文件系统（附件、导入导出文件），通过 `StorageService` 接口抽象
- 生产：S3 兼容存储（MinIO，镜像 `quay.io/minio/minio` —— 注意 Docker Hub 官方镜像已下架，已核实 `minio/minio` 404）

### 6.5 全文检索

- 首期：PostgreSQL `pg_trgm` + `to_tsvector`，满足物料/客户模糊搜索
- 数据量 > 500 万行或需要分词时，再引入 OpenSearch

---

## 7. 前端选型

### 7.1 框架：Vue 3.5.44 + TypeScript 6.0.3 + Vite 8.3.4 + Element Plus 2.14.7

| 维度 | Vue 3 + Element Plus | React 19 + Ant Design |
|---|---|---|
| 中后台组件完整度 | 高（表格/表单/树/穿梭框齐全） | 高 |
| 学习曲线 | 低（模板语法贴近后端开发者直觉） | 中（Hooks 心智负担） |
| 国内生态/文档 | 最好 | 好 |
| 团队匹配 | **高** | 中 |
| 结论 | **✅ 选定** | 备选 |

### 7.2 配套库

| 能力 | 选型 | 版本 |
|---|---|---|
| 语言 | TypeScript | 6.0.3 ✅ 已验证（7.0.2 与 vue-tsc 3.3.13 不兼容） |
| 构建 | Vite | 8.3.4 |
| 路由 | Vue Router | 5.4.0 |
| 状态管理 | Pinia | 4.1.0 |
| UI 组件 | Element Plus | 2.14.7 |
| 图标 | @element-plus/icons-vue | 2.3.2 |
| HTTP | Axios | 1.20.0 |
| 图表 | ECharts | 6.1.0 |
| 日期 | Day.js | 1.11.23 |
| 样式 | Sass | 1.105.2 |
| 按需引入 | unplugin-auto-import / unplugin-vue-components | 21.1.0 / 32.1.0 |
| 单元测试 | Vitest | 5.0.5 |
| 类型检查 | vue-tsc | 3.3.13 |
| Lint | ESLint / Prettier | 10.13.0 / 3.9.10 |
| 包管理 | pnpm | 12.8.1 |

### 7.3 前端风险与兜底

- **TypeScript 7**（原生 Go 编译器）已实测：`vue-tsc` 3.3.13 报 `ERR_PACKAGE_PATH_NOT_EXPORTED: typescript/lib/tsc`，**不兼容**。已按兜底方案降级 **TypeScript 6.0.3**，`pnpm build` 通过；同时移除 TS 6 已废弃的 `baseUrl`（改用 `paths` 相对解析）
- **Vite 8** 插件生态（unplugin 系列）需验证；兜底 Vite 7
- **ESLint 10** 为 flat config，配置模板按 v10 规范编写
- 验证方式：`pnpm install && pnpm build` 在 CI 与本地均通过

---

## 8. 部署与运维

| 能力 | 选型 | 说明 |
|---|---|---|
| 容器化 | Docker 29.8.2 + Docker Compose | 开发与中小客户交付；生产可选 K8s |
| 反向代理 | Nginx | `nginx:stable` 镜像 |
| CI/CD | GitHub Actions | JDK 21 + Maven Wrapper + pnpm 12，缓存依赖 |
| 可观测性 | Spring Boot Actuator + Micrometer | Phase 2 接 Prometheus + Grafana + Loki |
| 健康检查 | `/actuator/health` + Compose healthcheck | 数据库/Redis/RabbitMQ 就绪依赖 |
| 备份 | `pg_dump` 每日全量 + WAL 归档 | Phase 2 落地 |
| 配置管理 | Spring Profile + 环境变量 | 敏感信息不入库，走部署环境注入 |

---

## 9. 版本基线清单

> 核查渠道：`repo.maven.apache.org`（Maven）、`registry.npmmirror.com`（npm）、`hub.docker.com`（镜像）。
> 核查时间：2026-10-20。

| 组件 | 版本 | 核查结果 | 状态 |
|---|---|---|---|
| JDK | 21.0.12 LTS | 本机已安装 | ✅ 可用 |
| Maven | 3.10.0 | Maven Central 最新稳定版 | ✅ 可用 |
| Spring Boot | 4.1.1 | 4.1.1 稳定（4.2.0-M2 里程碑） | ✅ 可用 |
| Spring Modulith | 2.1.1 | POM 依赖 Boot 4.1.1 | ✅ 对齐 |
| MyBatis-Plus | 3.5.17 | `mybatis-plus-spring-boot4-starter` 存在 | ✅ 可用 |
| Sa-Token | 1.46.0 | `sa-token-spring-boot4-starter` 存在 | ✅ 可用 |
| springdoc-openapi | 3.1.1 | POM 基于 Boot 4.1.0 | ✅ 可用 |
| Flowable | 8.0.0 | 基线 Boot 4.0，需运行时验证 | ⚠️ 待验证 |
| PostgreSQL | 18.6 | Docker Hub 镜像存在 | ✅ 可用 |
| Redis | 8.8.3 | Docker Hub 镜像存在 | ✅ 可用 |
| RabbitMQ | 4.4.0 | Docker Hub 镜像存在 | ✅ 可用 |
| MySQL（备选） | 8.4.11 LTS / 9.7.2 | Docker Hub 镜像存在 | 备选 |
| Node.js | 24.21.0 | 本机已安装 | ✅ 可用 |
| pnpm | 12.8.1 | 本机已安装 | ✅ 可用 |
| Vue | 3.5.44 | npm 最新 | ✅ 可用 |
| TypeScript | 6.0.3 | 7.0.2 为 npm 最新，但与 vue-tsc 不兼容；降级 6.0.3 | ✅ 构建通过 |
| Vite | 8.3.4 | npm 最新；`manualChunks` 对象写法已移除 | ✅ 构建通过 |
| Element Plus | 2.14.7 | npm 最新 | ✅ 可用 |
| Pinia | 4.1.0 | npm 最新 | ✅ 可用 |
| Vue Router | 5.4.0 | npm 最新 | ✅ 可用 |
| Axios | 1.20.0 | npm 最新 | ✅ 可用 |
| ECharts | 6.1.0 | npm 最新 | ✅ 可用 |
| Docker | 29.8.2 | 本机已安装 | ✅ 可用 |

---

## 10. 风险与验证计划

| # | 风险 | 影响 | 验证方式 | 兜底方案 |
|---|---|---|---|---|
| R1 | Flowable 8.0.0 在 Boot 4.1.1 运行时异常 | 工作流模块不可用 | M2 前：启动上下文 + 部署 BPMN + 完成审批任务 | Boot 降 4.0.8 + Modulith 2.0.x |
| R2 | TypeScript 7 与 vue-tsc / ESLint 不兼容 | 前端无法构建 | **已验证**：TS 7.0.2 下 `vue-tsc` 读取 `typescript/lib/tsc` 被 exports 拦截；降级 TS 6.0.3 后通过 | 已落地 TS 6.0.3 |
| R3 | Vite 8 插件生态（unplugin）兼容性 | 前端构建失败 | **已验证**：unplugin 插件正常；Vite 8 不再接受 `manualChunks` 对象写法，已改用默认分包 | 构建通过 |
| R4 | MyBatis-Plus boot4 starter 兼容问题 | 数据访问层 | 集成测试（Testcontainers PostgreSQL） | 原生 MyBatis + mybatis-spring-boot-starter 4.0 |
| R5 | Sa-Token boot4 starter 兼容问题 | 登录鉴权 | 登录接口集成测试 | Spring Security 7 |
| R6 | Spring Boot 4 资料少于 3.x | 排障成本 | 建立内部踩坑记录 | 无（接受） |
| R7 | MinIO 官方 Docker Hub 镜像下架 | 对象存储不可用 | 使用 `quay.io/minio/minio` | 本地文件系统 |

> **验证记录（2026-10-20）**：后端 `mvnw verify` 通过（5 个模块，含 Spring Modulith 模块结构校验，`ApplicationModules.verify()` 无违规）；前端 `pnpm build` 通过（1697 个模块）。Flowable 当前仅完成编译级验证（依赖解析 + 编译通过），**运行时验证（R1）待 Docker 环境可用后在 M2 前补做**。

---

## 11. 演进路线

| 阶段 | 时间 | 内容 |
|---|---|---|
| Phase 1 | 0~3 月 | 模块化单体 + PostgreSQL + Redis；系统管理/主数据/采购/库存/销售 MVP；CI + Compose |
| Phase 2 | 3~6 月 | Flowable 审批流、RabbitMQ 事件、报表（ECharts）、对象存储、可观测性、SSO |
| Phase 3 | 6~12 月 | 按需拆分：报表/库存扣减独立服务；Spring Cloud Alibaba 2025.1.0.0 + Nacos + Gateway；多租户 RLS |

---

## 12. 备选组合

| 条件变化 | 切换方案 |
|---|---|
| 团队 > 10 人、多产品线独立交付 | 微服务：Spring Cloud Alibaba 2025.1.0.0 + Nacos + Gateway + Sentinel |
| 团队只有 MySQL 运维能力 | PostgreSQL → MySQL 8.4 LTS（仅替换 Flyway 脚本与方言） |
| 前端团队 React 强 | Vue → React 19 + Ant Design |
| 极简交付、无 Java 团队 | Spring Boot → Go 单体（需重估，不建议中途更换） |
| 审批流极简（仅 2~3 个固定流程） | Flowable → 自研状态机 + 审批记录表 |

---

## 附录 A：评估维度与权重

| 维度 | 权重 | 说明 |
|---|---|---|
| 业务匹配度 | 25% | 是否解决 ERP 核心问题（事务、报表、审批） |
| 生态成熟度 | 20% | 文档、社区、维护频率、版本节奏 |
| 团队匹配度 | 20% | 学习曲线、招聘难度、交接成本 |
| 运维成本 | 15% | 部署复杂度、中间件数量、故障排查 |
| 性能与扩展 | 10% | 当前与 3 年后的负载 |
| 许可与合规 | 10% | 商业许可风险、数据合规 |

---

*本文档随代码评审更新；版本升级需新增 ADR 并更新第 9 节。*
