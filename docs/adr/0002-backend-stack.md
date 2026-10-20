# ADR-0002：后端技术栈与版本基线

- **状态**：已接受
- **日期**：2026-10-20
- **决策人**：Stellar0502
- **相关**：[技术选型方案](../tech-selection.md)

## 背景

需要为 ERP 后端确定语言、框架、数据访问、认证、API 文档、工作流引擎及构建工具的版本，且所有版本必须可实际构建。

## 决策

| 能力 | 选型 | 版本 |
|---|---|---|
| 运行时 | OpenJDK | 21.0.12 LTS |
| 框架 | Spring Boot | 4.1.1 |
| 模块化 | Spring Modulith | 2.1.1 |
| 数据访问 | MyBatis-Plus（boot4 starter） | 3.5.17 |
| 认证授权 | Sa-Token（boot4 starter） | 1.46.0 |
| API 文档 | springdoc-openapi | 3.1.1 |
| 工作流 | Flowable | 8.0.0（待运行时验证） |
| 数据库迁移 | Flyway | 由 Spring Boot 管理 |
| 构建 | Maven Wrapper | 3.10.0 |

## 理由

1. **版本对齐**：Spring Modulith 2.1.1 的 POM 直接依赖 Spring Boot 4.1.1；springdoc-openapi 3.1.1 基于 Boot 4.1.0 构建。三者形成可验证的版本三角。
2. **Boot 4 starter 齐备**：MyBatis-Plus 与 Sa-Token 均已发布 `spring-boot4-starter`，避免为兼容性降级到 Boot 3.5。
3. **MyBatis-Plus 而非 JPA**：ERP 报表与复杂单据查询多，SQL 可控性优先；分页、多租户、逻辑删除插件开箱即用。
4. **Sa-Token 而非 Spring Security**：菜单/按钮级权限、多端登录、踢人下线为 ERP 刚需，Sa-Token 内置；后续 SSO 可并存 Spring Security OAuth2。
5. **Maven 3.10.0 而非 Maven 4**：Maven 4.0 在核查时仍为 `4.0.0-rc-7`，生产项目不采用 RC。

## 备选方案

| 方案 | 否决理由 |
|---|---|
| Spring Boot 3.5.x | 生态最稳，但 Spring Modulith 2.x 与 springdoc 3.x 已面向 Boot 4，新项目无历史包袱，直接采用当前稳定线 |
| Spring Boot 4.0.8 | 仅作为 Flowable 兼容性兜底 |
| Spring Data JPA | 复杂报表查询不可控 |
| Spring Security 7 | RBAC 开发量大；Phase 2 SSO 时作为协议层引入 |

## 后果

- 必须验证 Flowable 8.0.0 在 Boot 4.1.1 上的运行时行为（M2 前完成）
- Boot 4 生态资料相对 Boot 3 少，需内部沉淀踩坑记录
- 版本升级按季度评估，升级前必须通过完整集成测试
