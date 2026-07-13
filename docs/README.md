# knowledge-app 文档入口

状态：当前有效

本目录是 knowledge-app 根仓唯一的工具无关文档入口。当前跨仓架构、任务顺序和 Gate 以 `k8s` 仓库的 MoocManus v5 总体方案、实施计划、ADR、contracts 和 evidence 为准。

## 本仓真相源

1. Knowledge 后端路由/OpenAPI、数据库 migration、领域模型、provider adapter 和自动化测试。
2. Knowledge 前端实际路由、typed client、组件测试和部署配置。
3. k8s 中的 Knowledge desired state、镜像 digest、迁移/回滚证据。
4. `docs/history/` 只保存带日期的历史实施快照，不得作为当前接口或恢复入口。

## 当前历史资料

- [Ingestion Worker/RAGFlow 快照](history/KNOWLEDGE_INGESTION_WORKER_20260711.md)
- [Knowledge API 契约快照](history/KNOWLEDGE_API_CONTRACT_SNAPSHOT_20260711.md)

当前接口以代码/OpenAPI 和 provider/consumer contract tests 为准；跨仓 Artifact、Identity、Retrieval/Citation 契约只在 k8s v5 contracts 中维护。
