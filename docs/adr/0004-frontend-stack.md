# ADR-0004：前端技术栈采用 Vue 3 + TypeScript + Element Plus

- **状态**：已接受
- **日期**：2026-10-20
- **决策人**：Stellar0502
- **相关**：[技术选型方案](../tech-selection.md)

## 背景

ERP 前端是中后台密集型应用：大量表格、表单、树、详情页、报表看板。团队规模小，需要开箱即用的组件与低学习成本。

## 决策

| 能力 | 选型 | 版本 |
|---|---|---|
| 框架 | Vue | 3.5.44 |
| 语言 | TypeScript | 7.0.2（待验证） |
| 构建 | Vite | 8.3.4 |
| UI 组件 | Element Plus | 2.14.7 |
| 路由 | Vue Router | 5.4.0 |
| 状态 | Pinia | 4.1.0 |
| HTTP | Axios | 1.20.0 |
| 图表 | ECharts | 6.1.0 |
| 单元测试 | Vitest | 5.0.5 |
| 包管理 | pnpm | 12.8.1 |

## 理由

1. **Element Plus 组件完整度**：表格（虚拟滚动、合并单元格）、表单校验、树形选择、穿梭框等 ERP 高频组件内置，开发效率远高于自研。
2. **模板语法贴近后端开发者直觉**，小团队全栈开发时切换成本低。
3. **按需引入**：`unplugin-vue-components` + ElementPlusResolver 自动按需加载，构建体积可控。
4. **ECharts 6**：报表看板生态最完整，支持大数据量渲染。

## 备选方案

| 方案 | 否决理由 |
|---|---|
| React 19 + Ant Design | 团队前端能力偏弱时 Hooks 心智负担高；无强约束的技术理由否决，仅团队匹配度低 |
| Vue 2 + Element UI | 已停止维护 |
| 低代码平台 | 无法满足复杂单据与审批流定制 |

## 风险与兜底

- **TypeScript 7** 为原生编译器实现，`vue-tsc` 3.3.13 兼容性需 `pnpm build` 验证；不兼容则降级 TS 5.9/6.x
- **Vite 8** 的 unplugin 生态需验证；不兼容则降级 Vite 7
- **ESLint 10** 使用 flat config，团队需按 v10 规范编写配置

## 后果

- 前端构建链路的验证纳入 CI（`pnpm build` + `pnpm lint`）
- 组件库深度定制（主题、业务组件）需要额外 2~3 周
- 若未来桌面端需求增加，可选 Tauri 复用同一 Vue 代码库
