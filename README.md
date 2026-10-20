# Stellar ERP

智能制造 ERP 系统 —— 模块化单体架构，面向私有化部署与快速交付。

[![CI](https://github.com/Stellar0502/stellar-erp/actions/workflows/ci.yml/badge.svg)](https://github.com/Stellar0502/stellar-erp/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 技术栈

| 层 | 技术 | 版本 |
|---|---|---|
| 运行时 | OpenJDK | 21 LTS |
| 框架 | Spring Boot | 4.1.1 |
| 模块化 | Spring Modulith | 2.1.1 |
| 数据访问 | MyBatis-Plus | 3.5.17 |
| 认证 | Sa-Token | 1.46.0 |
| 工作流 | Flowable | 8.0.0 |
| 数据库 | PostgreSQL | 18.6 |
| 缓存 | Redis | 8.8.3 |
| 消息 | RabbitMQ | 4.4.0 |
| 前端 | Vue 3 + TypeScript + Element Plus | 3.5.44 / 6.0.3 / 2.14.7 |
| 构建 | Maven Wrapper + pnpm | 3.10.0 / 12.8.1 |

选型依据、对比矩阵与版本核查结果见 **[docs/tech-selection.md](docs/tech-selection.md)**。

业务与功能的详细设计（日式「詳細設計書」规范、中文正文、真实资料基准）见 **[docs/design/README.md](docs/design/README.md)**：覆盖系统管理、主数据、销售、采购、库存、生产、财务、工作流、集成、报表共 10 个业务域，含機能一覧、画面項目定義、処理詳細、DB 設計、API 設計、帳票・バッチ、メッセージ、権限、テスト観点。

## 目录结构

```
stellar-erp/
├── backend/                    # Maven 多模块后端
│   ├── erp-common/             # 通用返回体、异常、工具
│   ├── erp-system/             # 系统管理（用户/角色/菜单/租户）
│   ├── erp-workflow/           # 工作流（Flowable）
│   ├── erp-boot/               # 启动模块（装配、配置、Modulith 校验）
│   └── pom.xml                 # 父 POM（版本基线）
├── frontend/                   # Vue 3 + Vite 前端
├── docs/
│   ├── tech-selection.md       # 技术选型方案
│   ├── adr/                    # 架构决策记录
│   └── design/                 # 业务详细设计书体系（共通设计/10 业务域/矩阵/真实资料）
├── docker-compose.yml          # 本地依赖：PostgreSQL / Redis / RabbitMQ
└── .github/workflows/ci.yml    # 持续集成
```

## 快速开始

### 1. 启动依赖服务

```bash
docker compose up -d
```

| 服务 | 端口 | 默认凭据 |
|---|---|---|
| PostgreSQL | 5432 | `erp` / `erp_dev_password`，库 `stellar_erp` |
| Redis | 6379 | 无密码（仅本地） |
| RabbitMQ | 5672 / 15672 | `erp` / `erp_dev_password` |

### 2. 启动后端

```bash
cd backend
./mvnw spring-boot:run -pl erp-boot -am
```

- API: http://localhost:8080
- Swagger UI: http://localhost:8080/swagger-ui.html
- 健康检查: http://localhost:8080/actuator/health

### 3. 启动前端

```bash
cd frontend
pnpm install
pnpm dev
```

前端地址: http://localhost:5173 （`/api` 代理到后端 8080）

## 开发约定

- **模块边界**：按 Spring Modulith 约定，模块**根包**下的类型对外暴露，子包（含 `internal`）为内部实现、禁止跨模块引用；CI 中由 `ApplicationModules.verify()` 强制校验
- **数据库迁移**：Flyway 脚本放在各模块 `src/main/resources/db/migration/`，命名 `V{版本}__{描述}.sql`
- **接口规范**：统一返回 `Result<T>`，业务异常抛 `BizException`，由全局异常处理器转换
- **提交规范**：Conventional Commits（`feat:` / `fix:` / `docs:` / `chore:` / `refactor:` / `test:`）

## GitButler 工作流

本仓库使用 [GitButler](https://gitbutler.com) 管理并行分支，主分支为 `main`，工作区分支为 `gitbutler/workspace`。

```bash
but setup          # 首次：把当前仓库接入 GitButler
but status         # 查看工作区（分支 / 提交 / 未提交改动）
but branch new <name>          # 新建并行分支
but commit -m "msg" -b <branch>  # 把改动提交到指定分支
but push           # 推送所有有提交的分支
but pr new         # 创建 Pull Request（需先在 but config forge auth 登录 GitHub）
but undo / redo    # 操作级撤销/重做
but teardown       # 退出 GitButler 模式，回到普通 Git
```

工作流示例：同时推进「技术选型文档」与「工程骨架」两条分支，互不干扰，分别建 PR、分别评审。

## 路线图

| 阶段 | 目标 |
|---|---|
| Phase 1 | 主数据、采购、库存、销售 MVP + 审批流基础 |
| Phase 2 | 财务应收应付、报表看板、SSO、可观测性 |
| Phase 3 | 按需拆分热点模块为独立服务（Spring Cloud Alibaba） |

## 许可

本项目采用 [MIT License](LICENSE) 开源许可。

Copyright (c) 2026 Stellar0502

在遵守 MIT 许可证（保留版权声明与许可声明）的前提下，可自由使用、复制、修改、合并、发布、分发、再许可和/或销售本软件的副本。本软件按「原样」提供，不附带任何明示或暗示的担保。

> 说明：代码与原创文档适用 MIT 许可；文档中引用的国家标准、法律法规、会计准则、公开产品资料等，其权利归原权利人，引用仅用于设计说明，不改变其原有授权。

---

[![](https://img.shields.io/badge/powered_by-dsh-4D6BFE?style=flat-square&logo=deepseek&logoColor=white)](https://github.com/deepseek-ai/deepseek-harness)
