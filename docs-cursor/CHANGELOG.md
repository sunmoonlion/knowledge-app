# 变更日志（CHANGELOG）

> 记录项目重大变更，按时间倒序排列。
> 每次 Phase 推进、架构变更、重大决策落地时更新。

---

## [Unreleased]

### Added
- 初始化 `docs-cursor/` 文档体系
- Knowledge ingestion API 已接入部署态 smoke：`POST /api/knowledge/ingestions` 可接收 info-app 标准 payload，并返回 `202 Accepted` / `status=accepted`。

### Changed
- 明确当前 ingestion API 完成的是“接收入库 job”入口闭环；后续 RAGFlow 解析、切片、索引和状态推进仍由 worker 阶段实现。

---

## 格式说明

```
## [版本或日期] — YYYY-MM-DD

### Added     新增功能或文档
### Changed   变更（非破坏性）
### Fixed     修复
### Removed   删除
### Breaking  破坏性变更（影响接口、数据结构、部署方式）
```
