# ADR-0001：架构风格采用模块化单体（Spring Modulith）

- **状态**：已接受
- **日期**：2026-10-20
- **决策人**：Stellar0502
- **相关**：[技术选型方案](../tech-selection.md)

## 背景

ERP 系统涉及 8 个业务域，事务链路长、主数据强依赖、审批流密集。团队初期 1~5 人。需要在「传统单体」与「微服务」之间做架构风格选择。

## 决策

采用 **模块化单体**：单个 Spring Boot 应用部署，内部按限界上下文划分为 `erp-system`、`erp-mdm`、`erp-purchase`、`erp-sales`、`erp-inventory`、`erp-production`、`erp-finance`、`erp-workflow`、`erp-integration` 九个模块，使用 **Spring Modulith 2.1.1** 约束模块边界。

具体约束：

1. 每个模块是一个 Maven 子模块，根包为 `com.stellar.erp.{module}`
2. 模块对外只暴露 `api` 子包（接口 + DTO），`internal` 子包禁止被其他模块引用
3. 模块间同步调用仅允许读操作；写操作通过领域事件（`@ApplicationModuleListener`）异步解耦
4. CI 中执行 `ApplicationModules.of(ErpApplication.class).verify()`，违规依赖直接失败
5. 事件外部化预留 `spring-modulith-events-amqp`，Phase 2 切换到 RabbitMQ

## 备选方案

| 方案 | 否决理由 |
|---|---|
| 微服务（Spring Cloud Alibaba） | 1~5 人团队无法承担 9 个服务的运维成本；ERP 核心链路会变成分布式事务 |
| 传统分层单体 | 缺少模块边界机制，1 年内必然腐化为大泥球 |

## 后果

**正面：**
- 本地事务保证采购→入库→应收强一致
- 单进程部署，Docker Compose 即可交付
- 模块边界由框架强制校验，而非口头约定

**负面：**
- 单进程故障影响全部模块（通过多实例 + 健康检查缓解）
- 模块内独立伸缩能力有限

## 演进触发条件

满足任一条件时评估拆分：

- 单模块负载达到整库瓶颈 60% 以上
- 团队规模 > 10 人且发布节奏冲突
- 需要异地多活
- 必须独立交付的团队边界出现
