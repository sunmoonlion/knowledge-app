# API 契约（API CONTRACT）

> 接口定义的唯一真实来源，从后端代码中提取后在此记录。
> 每次新增接口时更新。

---

## 约定

- Base URL：`{{API_BASE_URL}}`，e.g. `http://localhost:8000`
- 认证：{{e.g. `Authorization: Bearer <token>` / HTTP-only Cookie `session_id`}}
- 响应格式：`{ "code": 0, "message": "ok", "data": {...} }`
- 错误响应：`{ "code": <非0>, "message": "<错误描述>" }`

---

## 认证模块

> 根据实际认证方案填写。以下为 OIDC BFF 模式的示例，可替换为其他方案。

### GET /auth/login
发起登录（跳转 OIDC 授权页 / 返回登录表单等，视方案而定）。

**响应**：{{302 → 授权页 / 200 + 登录表单}}

---

### GET /auth/callback
认证回调，处理 code 换 token。（仅 OIDC 模式需要）

**Query 参数**：`code` string 必填

**响应**：302 → `/dashboard`（成功）或 400（失败）

---

### GET /auth/logout
退出登录，清除 session / token。

**响应**：302 → `/login`

---

### GET /auth/me
获取当前登录用户信息。

**响应**：
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "avatar": "string"
}
```

---

## {{业务模块}}

## Knowledge Ingestion

### POST /api/knowledge/ingestions
提交上游业务系统的已治理文档版本，创建或幂等返回 ingestion job。

处理模式：

- 未配置 `RAGFLOW_API_BASE` 或 `RAGFLOW_API_KEY` 时，worker 使用 mock 模式，
  仅验证状态机与队列链路。
- 配置 RAGFlow 后，worker 会拉取 artifact、确保 Dataset、上传 Document、
  触发解析并轮询解析状态，成功后写入 `ragflow_document_id`。

**请求体**：

```json
{
  "source_app": "info-app",
  "source_document_id": "uuid",
  "source_document_version_id": "uuid",
  "source_artifact_refs": [
    {
      "artifact_type": "text",
      "bucket": "development-info-originals",
      "object_key": "path/to/text.txt",
      "content_type": "text/plain",
      "sha256": "..."
    }
  ],
  "title": "string",
  "canonical_url": "https://example.com/news/1",
  "source_name": "string",
  "content_hash": "string",
  "metadata": {
    "copyright_status": "licensed",
    "trust_level": "official"
  },
  "target_dataset": "default",
  "profile_key": "markdown",
  "idempotency_key": "info-app:version:dataset"
}
```

**响应**：`202 Accepted`，返回 `KnowledgeIngestionRead`。

### GET /api/knowledge/ingestions
查询 ingestion job。

**Query 参数**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `source_app` | string | 否 | 上游应用，例如 `info-app` |
| `source_document_id` | uuid | 否 | 上游文档 |
| `source_document_version_id` | uuid | 否 | 上游文档版本 |
| `target_dataset` | string | 否 | 目标知识库 Dataset |
| `status` | string | 否 | `accepted/running/succeeded/failed/ragflow_config_error/ragflow_parse_failed/artifact_unreadable/external_api_error` |
| `ragflow_document_id` | string | 否 | RAGFlow Document ID |
| `idempotency_key` | string | 否 | 幂等键 |
| `created_from` | datetime | 否 | 创建时间下限 |
| `created_to` | datetime | 否 | 创建时间上限 |
| `limit` | int | 否 | 默认 50 |
| `offset` | int | 否 | 默认 0 |

### GET /api/knowledge/ingestions/{ingestion_id}
查询单个 ingestion job。

### GET /api/knowledge/ragflow/config-check
检查当前 RAGFlow 配置是否满足真实解析条件。接口不会返回 API key。

**响应字段**：

```json
{
  "enabled": true,
  "reachable": true,
  "has_default_embedding": false,
  "ready": false,
  "issues": ["RAGFlow tenant has no default embedding model"],
  "details": {
    "api_base_configured": true,
    "api_key_configured": true,
    "dataset_list_accessible": true,
    "tenant_id": "string",
    "tenant_name": "string",
    "embd_id": "",
    "tenant_embd_id": null,
    "llm_id": "string"
  }
}
```

### POST /api/knowledge/ingestions/{ingestion_id}/status
更新 ingestion job 状态。通常由 knowledge-app 内部任务调用；外部系统不应直接
绕过 ingestion worker 写状态。

**请求体**：

```json
{
  "status": "succeeded",
  "last_error": null,
  "metadata": {
    "chunk_count": 12
  },
  "knowledge_document_id": "knowledge-doc-id",
  "ragflow_document_id": "ragflow-doc-id"
}
```

### POST /api/knowledge/ingestions/{ingestion_id}/dispatch
手动投递或本地同步执行 ingestion job。适用于 `accepted/running` 等非终态任务的 smoke test。

### POST /api/knowledge/ingestions/{ingestion_id}/retry
把终态失败任务重置为 `accepted` 并重新投递。`succeeded` 不允许 retry。
`ragflow_config_error` 默认阻止 retry，需要先修配置；必要时可 `force=true`。

**请求体**：

```json
{
  "force": false,
  "reason": "after fixing ragflow default embedding"
}
```

**状态语义**：

| status | 含义 |
|--------|------|
| `accepted` | 已接收，等待 worker |
| `running` | worker 执行中 |
| `succeeded` | 入库完成 |
| `failed` | 未分类失败 |
| `ragflow_config_error` | RAGFlow 配置错误，例如默认 embedding 缺失 |
| `ragflow_parse_failed` | RAGFlow 已接收文档但解析失败或超时 |
| `artifact_unreadable` | 上游 artifact 无法读取或没有可读正文 |
| `external_api_error` | RAGFlow/S3/HTTP 等外部依赖错误 |

---

## 错误码

| code | HTTP 状态码 | 含义 |
|------|------------|------|
| 0 | 200 | 成功 |
| 400 | 400 | 请求参数错误 |
| 401 | 401 | 未登录 |
| 403 | 403 | 无权限 |
| 404 | 404 | 资源不存在 |
| 500 | 500 | 服务器内部错误 |
