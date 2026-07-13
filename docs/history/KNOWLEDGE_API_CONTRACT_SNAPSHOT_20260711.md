# API 契约（API CONTRACT）

> 历史接口快照，最后有效日期为 2026-07-11，不是契约唯一真相源。当前接口以 FastAPI 路由/OpenAPI、provider/consumer contract tests 和 k8s 仓库的版本化跨仓契约为准。

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

### GET /{{path}}
{{描述}}

**Query 参数**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `{{field}}` | string | 是 | {{说明}} |

**响应**：
```json
{
  "{{field}}": "{{type}}"
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
