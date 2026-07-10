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
| `source_document_version_id` | uuid | 否 | 上游文档版本 |
| `status` | string | 否 | `accepted/running/succeeded/failed` |
| `limit` | int | 否 | 默认 50 |
| `offset` | int | 否 | 默认 0 |

### GET /api/knowledge/ingestions/{ingestion_id}
查询单个 ingestion job。

### POST /api/knowledge/ingestions/{ingestion_id}/status
更新 ingestion job 状态。后续接 RAGFlow/worker 后由 knowledge-app 内部任务调用。

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
