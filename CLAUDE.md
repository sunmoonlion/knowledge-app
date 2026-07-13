# knowledge-app — AI 协作上下文

本文件只提供仓库级入口，不维护独立于其他 AI 工具的项目事实。

## 开始任务前

1. 阅读根 `README.md`，并核对任务明确指定的权威资料。
2. 核对目标子仓代码、README、OpenAPI/migration、provider adapter、测试和当前 Git 状态。
3. 涉及 MoocManus、Artifact、Retrieval/Citation、Identity 或前端迁移时，以 k8s 仓库的 v5 总体方案、实施计划、ADR、contracts 和 evidence 为准。

## 工作边界

- Knowledge 拥有 Dataset/Provider binding、Ingestion、Retrieval 和 Citation 相关领域事实，不接管 Info 来源或 Research Run 状态。
- 接口事实来自代码/OpenAPI/schema 和 contract tests；`docs/history/` 只用于审计。
- 任何时刻只推进实施计划中一个已激活任务；不得以 RAGFlow smoke 代替跨仓 Retrieval/Citation 契约。
- 不输出或提交 token、cookie、client secret、signed URL、真实凭据或完整敏感响应。
- 安装、网络构建和 Git push 由项目负责人执行；本地提交和验证必须可追溯。

## 文档规则

项目状态只写入任务明确指定的权威计划、ADR、contract、evidence 或代码相邻的必要文档。不要创建任何按 AI 工具命名的平行文档树。
