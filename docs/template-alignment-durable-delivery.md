# Knowledge 模板对齐：可靠投递开发候选

日期：2026-09-11。顺序为模板、Info 验证收口后接入 Knowledge；本文不是正式发布批准。

## 全量源码比较

对 Backend、Admin Frontend、Web Frontend 的 Git 可见文件逐路径计算 SHA-256，
仅自动归一 tpl/Tpl/TPL 身份字符；其它差异逐项分类，不覆盖领域扩展。

| 组件 | 完全一致 | 身份归一后相同 | 其它同路径差异 | Knowledge 独有 | 模板独有 |
| --- | --- | --- | --- | --- | --- |
| Backend | 111 | 8 | 37 | 27 | 3 |
| Admin Frontend | 105 | 11 | 9 | 2 | 0 |
| Web Frontend | 82 | 12 | 7 | 0 | 0 |

可复现清单为工作区接手目录 `knowledge-source-alignment.json`，脚本
`audit-source-alignment.py knowledge`。最终源码以父仓 `development-source-lock.json`
中的干净子仓 commit/tree 为准；清单 HEAD 不能替代未提交候选的内容摘要。

公共 8 文件逐字同模板：`durable_tasks.py`、`messaging/durable_delivery.py`、
`delivery_schema.py`、`repositories/outbox.py`、`tasks/durable_delivery.py`、
`cli/durable_delivery.py`、`delivery_runtime_probe.py`、`test_durable_delivery_db.py`。
领域注册只有 `knowledge.ingest.v1`；没有复制第二个 publisher/死信/消费租约实现。

## 差异分类

| 类别 | 路径组与结论 |
| --- | --- |
| 领域扩展 | knowledge/retrieval DTO、service、ORM、schema、routes、RAGFlow client、服务身份与对应测试；Admin 摄取页、面板、导航、翻译保留。共享认证、日志、审计、HTTP 错误载体不另建一套。GatewayTimeoutError 是现有 504 Provider 错误子类。 |
| 领域扩展 | `ragflow_delivery.py` 和 `provider_receipts` CLI 是外部副作用意图/回执账；不替代 KnowledgeDocument/Version 主档，不把 RAGFlow 当原文真源。handler、worker 注册与不变量测试通过公共扩展点接入。 |
| 领域扩展 | Knowledge 自有 6 条线性迁移，最新 `20260911_0006` 调公共 DDL；不拼接模板的 revision 链，保留历史 UUID 默认迁移。 |
| 配置 | bootstrap 名称、CLAUDE 领域说明、config/env、身份/scope/cookie 测试、数据库/对象存储/检索配置及文档。Provider/源 artifact 权限仍按关系隔离；不复制线上凭据。 |
| 配置 | jsonschema/uv.lock 服务契约测试依赖；pyright 现有重复 app/tasks 范围；前端 server-schema 的全 App 枚举必须保留，不能机械替换成重复 knowledge。 |
| 暂时兼容 | 旧 Celery 任务保留注册但显式拒绝执行；旧裸 RAGFlow 函数签名拒绝执行。旧直接 producer 方法和 ensure_dataset 辅助方法已删除，无可运行旧写路径。 |
| 暂时兼容 | 原 ping producer 的显式 exchange/routing_key、UUIDMixin Python uuid4 与 gen_random_uuid、既有 FastAPI endpoint B008 例外保持；不是第二套领域任务分发。 |
| 暂时兼容 | Redis 驱动额外 ACL SAVE 和前端 TPL_SSR_* 模板脚本接口保留；删除无消费者的 ADMIN_FRONTEND/WEB_FRONTEND/KNOWLEDGE_SSR 影子配置。 |
| 暂时兼容 | 身份测试固定虚拟 tpl audience、少量格式、Web 现有空 Dashboard 节点及通用欢迎文案保留。它们不是生产身份配置，也未以模板同步为由删除领域 UI。 |
| 违规漂移（已修正） | Redis 缺少 resetchannels，Backend rebuild 使用正式 1.0.0，构建/异步说明过时；同步已验收模板/Info 公共修复与开发标签保护。 |
| 验证工具缺陷（已修正） | k8s Calico 门禁仅识别历史 knowledge-r5，错误选择当前 knowledge 的 Provider；增加当前名称识别后全量通过，部署 bundle 与 NetworkPolicy 未改。 |

## 验证范围与诚实边界

- 后端完整 145 passed，无跳过（`knowledge-final-tests.xml`），包含真实 PostgreSQL、
  共享契约向量、原子受理/重试、并发幂等、迁移非空回填及回执恢复；Ruff/format/Pyright 通过。
- Admin 44 单元、10 配对浏览器；Web 48 单元（含共享向量）、7 配对浏览器；
  两端完整 check/build 通过，配对使用后端夹具。
- 真实 Casdoor Admin/Web：匿名 401、登录 200、跨分面 401、缺 CSRF 403、
  退出 204、撤销后 401。TLS 校验开启；浏览器回调交候选进程内 ASGI，使用独立
  测试 DB/Redis。这不是完整部署态前后端 TLS 与领域 UI 验收。
- KIND 测试镜像 `luna-knowledge-delivery:20260911` 清单
  `sha256:76ed4b25317e0df35813e7a4f06755e994fdd55a9ab5190f50fb7f244c693cc8`：
  独立迁移入口、真实 Worker/Beat/RabbitMQ、重复投递 counter/Inbox 均为 1。
  镜像之后只改说明/测试，不改变服务运行代码。
- 完整测试库实际备份恢复至新库，revision `20260911_0006`、counter/outbox/inbox
  为 1/1/1；额外三个明确标记的模拟 Provider 回执（confirmed/unknown/legacy_unknown）
  的 intent/state/receipt 完全一致。初次恢复因扩展注释所有权失败；保留管理员预装扩展，
  用 `--no-comments` 完整重试通过，不提升 App 角色权限。
- 实际 RAGFlow `v0.25.4-sunmoonai.1`：创建/上传响应丢失各只写 1 次，恢复下载
  原文件验证 SHA-256，两个 UUID dataset 已删除。没有调用 parse/embedding；
  解析结果未知、租约迟到和跨代次保护目前由真实 DB + 可控 Provider 故障测试覆盖。
- 独立 Calico v3.28.2：内部/前端到 Backend 放行，无标签拒绝；Knowledge API
  与 Worker 可到 RAGFlow（API 有同步检索职责），Scheduler 拒绝。首次工具误识别
  失败与修正后完整通过诊断均保留；两个临时集群已删除，原有 kind 未改。
- 三个组件正式构建标签拒绝回归通过；独立 Redis 的本地与生成 k8s 客户端命令
  均收回旧 allchannels、保留指定频道。未验证 ACL SAVE 重启持久化；既有 Redis
  CLI 服务端错误传播风险没有在本轮宣称修复。

历史正式 manifest、部署 bundle 和线上数据库保持原状。开发源码锁明确
`formal_release=false`，不能替代正式镜像/部署/数据发布锁。迁移回滚遇到任何 Provider
回执时拒绝丢数据，须使用已验证整库备份恢复，并单独处置回滚窗口内的外部副作用。
跨 App 最终 master/worktree 收口仍需等 Investment 完成。

## 2026-09-13 B7a：公共日志增量对齐

本节不改写以上 2026-09-11 历史证据。模板固定 `tpl-backend@553c36b`，
Knowledge 固定 `knowledge-backend@e99a894`；日志策略、Postgres 包装器、专项测试和说明
逐字相同。Worker 只同步信号注册，保留 knowledge_ingestion 领域任务，此差异属领域扩展。
无新增配置差异、临时兼容或违规漂移；不以本次增量对齐重新宣称全仓对齐。

在模板与 Info 固定提交回归通过后串行同步；静态检查通过，固定提交全量
**243 passed / 0 skipped**（25.04 秒），真实一次性 PG 与共享契约向量。
新增 8 项日志测试；B6b 单次轮询/故障回归保留。不改摄入协议、前端、迁移或服务契约。
本轮没有 KIND、真实身份、发布回滚或业务 Provider 验收。此项只关闭 SQL/HTTP 日志源码
欠账，不代表 M1-203 运行态或 M1-503 全套观测已通过。
