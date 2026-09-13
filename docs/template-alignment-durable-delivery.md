# Knowledge 模板对齐：可靠投递开发候选

## 2026-09-13 暂停集成

所有者改为暂停并同步现有成果，本次父仓固定后端 `e79a71272dbcf487e2a0def6dd65a954d3ca0ed8`。
后续 B7u 固定完整回归 418 passed / 0 skipped；累计证据与未完项见 k8s
`sunmoonai/docs/v5-backlog-disposition-luna.md` 和 `v5-backlog-joint-runtime-identity-luna.md`。
下文“本地/尚未推送”保留为各包当时历史；源码同步不是正式镜像发布或业务身份切换。

## 2026-09-13 B7j 回执进展（本地，未发布）

最终固定检查点 `knowledge-backend@5df4f1759cd64bd0a3ca2c4cae8f68102ebe681d`，模板
`a91eb3e284ae91d4bc6b82fe567c4163cfa728f0` 和 Info 修订后全量通过再串行本仓：
**415 passed / 0 skipped，72.09 秒**，Ruff/Pyright 通过。只将 gauge 下降用例改为
移除隔离合成回执，不假定域 Outbox 可直接删除，归档保护不动。
以下保留首轮候选历史，最终门禁以本段为准。

模板 `tpl-backend@a37835132217d8458a7440532f07d437a4684e3b` 固定全量 255 项、
Info 500 项通过后才同步本仓。Knowledge
`knowledge-backend@1597b453fb11901277fb93c8316e796228572d41` 完整
**415 passed / 0 skipped，72.03 秒**，Ruff/Pyright 通过。
共享观测器增加精确已提交 Inbox 数量/最大记录时间，保留 gauge 和无回执策略，
非有限回执使采集失败。两文件增量及四个新测试文件同步，不新增业务表或身份。
差异分类：原摄入/解析/轮询 handler、consumer 和租约领域扩展保留；无配置新增差异、
临时兼容或公共增量违规漂移，不声明全仓相同。
真实 prefork 暂停/父进程 pong/恢复、重复消费和回滚通过；测试只替换隔离存储与
合成 handler，既有真实 PG/解析故障与契约套件仍执行。回执不是业务成功量、per-worker
健康或真实 Provider/部署验收，监控接线仍未来 N4-OPS-01。
六文件固定证据见 k8s `sunmoonai/docs/v5-backlog-worker-progress-luna.md`；
父仓 gitlink 不暂存、master 不改、不推送，等待最终统一集成。

## 2026-09-13 B7i 本地增量（尚未发布）

模板固定 `tpl-backend@ed157e41f11e5e20e6b77812890cb55d382b58f4` 全量 243 项、
Info 全量 488 项通过后才同步本仓。Knowledge 固定
`knowledge-backend@937f09f90a357fa142d24d7c3883da5dfb133597` 的 Ruff/Pyright
通过，完整 **403 passed / 0 skipped，62.55 秒**。
五个新增 Scheduler 活动/CLI/测试/说明文件逐字同步，bootstrap 只加观察类选择。
差异分类：Knowledge 摄入/解析/轮询、handler 与调度清单保留；配置无新增差异，
使用原 schedule 路径；无临时兼容层或公共增量违规漂移，不宣称全仓相同。

真实本仓 Beat 发布及暂停/恢复/重启、既有真实 PG 故障/Provider 恢复与契约回归通过。
观察的是 Linux 本机循环和发送调用，不是 Worker 业务完成或真实 Provider 部署验收；
无镜像/部署/迁移/身份修改。监控安装/采集/告警送达由未来 N4-OPS-01 接收，未实施。
本地提交与证据见 k8s `sunmoonai/docs/v5-backlog-scheduler-activity-luna.md`；
父仓 gitlink 不暂存、不推送，master 和云端留待最终统一集成。

## 2026-09-13 B7h 本地增量（尚未发布）

模板 `c66654a591b186ac814cadb907defc421e94aba6` → Knowledge
`b786a2ca54e891330d642cd5c7984270c9848e94`，严格在 Info 完整门禁通过后实施。
新增 `GET /api/internal/v1/delivery/metrics`，仅签名服务身份及 `delivery:observe`
授权可访问；使用既有只读 collector/API 池，进程内单次准入，失败无旧值/假零。
公共 endpoint、24 项 HTTP 测试、观测说明三文件 SHA-256 与模板一致；路由和响应头
只加相同增量，保留 Knowledge 摄入/检索 Internal 路由、实际 handler、RAGFlow 与
单次轮询策略。Knowledge 既有 Internal 能力不在休眠清单，本包不改该清单。

差异分类：领域扩展保留；Knowledge 身份/audience 配置保留，不默认加主体 scope；
无新增兼容层；本包公共三文件无违规漂移。前端、迁移、部署与依赖未变。首轮
Ruff/Pyright 通过，完整回归 359 passed / 0 skipped（50.17 秒），固定提交复验回执
见 k8s `sunmoonai/docs/v5-backlog-metrics-http-luna.md`；本节是增量而非全量重比。
父仓 gitlink、master、远端和云端不更新，最后统一集成；没有实际采集器/告警上线。

Info 复验发现的恢复期预算泄漏先在模板确定性复现、修正，再严格串行同步。
Knowledge 最终本地检查点 `ffc88f94d2dcfec728eef43a668f8c8756453e84`，只追加
两份共享测试的故障注入范围修正（与模板相同），固定提交 Ruff/Pyright 通过，
360 passed / 0 skipped（50.81 秒）。正式 2 秒超时与运行代码未改，359 项为首轮历史。

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

## 2026-09-13 B7b：API schema readiness 增量对齐

模板 `tpl-backend@ed8d5dc`、Info 固定提交先过门禁；Knowledge 固定
`knowledge-backend@40edfc2` 完整 **262 passed / 0 skipped**（27.84 秒），Ruff/Pyright 通过。
共 4 文件：schema_readiness、测试、说明与模板逐字相同，API 只增加相同检查逻辑。
包名/领域路由保留，期望 revision 取自身迁移链，不复制模板版本；无新增配置、临时兼容
或违规漂移。本次增量对齐不是全仓重验。新增 19 项真实隔离 PG 迁移/降级/再升级、
SELECT 权限、阻塞超时与恢复等测试；旧解析调度/授权/契约回归保留。

三个 ready 别名在协作式预算内检查依赖和精确 revision，live 保持无依赖；不自动迁移。
未改摄入协议/前端/迁移/契约，也未操作业务库/Provider。业务 API principal、KIND、
真实身份及联合发布/回滚未验收，不能把本包探针源码等同于 B5/B6 可直接混滚部署。

## 2026-09-13 B7d：只读投递观测增量对齐

模板 `tpl-backend@1f8941f`、Info `info-backend@9ea1c5e` 固定提交依次过门禁后接入。
Knowledge 固定 `knowledge-backend@d16fb6c` 最后两次全量 **286 passed / 0 skipped**
（30.91 / 31.00 秒），Ruff/Pyright 通过；5 个新文件与模板逐字相同，新增 24 项。
领域 topic 使用原 handler 注册，不动摄入授权、解析游标、Provider、迁移或跨 App DTO。
本包无配置差异、临时兼容或违规漂移；领域扩展保留，增量对齐不冒充全仓重验。

首轮重放观测用例出现一次 publishable=0 而预期 1，单独复跑、150 次重放场景、100 次
原用例及两次完整复跑未复现；没有修改代码或放宽断言，根因仍未确定，留 B7 活性复核。
只读指标不代表 Worker/Scheduler 正常；scrape/告警/业务权限和正式部署均未验收。
测试为隔离 PostgreSQL 与共享契约，未接触业务库、真实 RAGFlow 或 Secret。

## 2026-09-13 B7e：Worker 消费配置检查增量

模板固定 `tpl-backend@5369862` 全量 167 项、Info `info-backend@7755da2` 全量 411 项
先通过后接入。Knowledge 固定 `knowledge-backend@7b11608` Ruff/Pyright 通过；环境
修复后连续两轮原始完整套件 **322 passed / 0 skipped**（44.71 / 44.50 秒）。
新增 CLI、35 项单元、1 项真实 RabbitMQ/本仓 prefork Worker 测试及说明，四文件与模板
逐字同步；另同步旧观测锁超时测试的 monkeypatch 作用域修正，生产 2 秒预算不改。

首轮常规套件在旧重放观测及上传响应丢失恢复处失败，曾暂停串行推进。后捕获隔离 DB
时钟倒退约 1.876 秒，核实 WSL Hyper-V 隐式校时与 timesyncd 同开；经批准关闭重复
校时后原断言不变、常规套件连续通过，才推进 Investment。不是放宽断言或跳过旧测试。
详细环境证据与最终复跑回执见 k8s 的 v5-backlog-worker-readiness-luna.md。

本增量无配置差异、临时兼容或违规漂移；领域任务注册/摄入/Provider/迁移/契约均保留。
历史 bundle/release 未修改，实例探针需下次联合新镜像发布接线；不据本包声明 KIND、
真实身份/业务环境、消费完成进展、Scheduler 活性或部署回滚已验收。


## 2026-09-13 B7f：显式投递状态与时钟回退

模板本地固定 `tpl-backend@1c5173b` 先过 176 项完整门禁，再串行 Info→Knowledge→Investment。
本仓本地固定 `knowledge-backend@94512d5` 全量 **335 passed / 0 skipped**，Ruff/Pyright 通过。
公共四生产文件、9 项故障回归及说明六文件与模板 SHA-256 一致。
新增四项复用原上传/解析响应丢失、轮询时限及重放观测场景的故障回归；Provider/摄入领域代码未改。
没有新增配置差异、临时兼容或违规漂移；这是增量对齐，不重新声称全仓相同。

释放使用负无穷而不删除 epoch 行，立即入队/重放/对账不添加墙钟门槛；真正预约与退避保留。
原失败断言未改，先在旧代码确定性复现再验证修复；详细记录在 k8s 的
v5-backlog-clock-regression-luna.md。没有改系统校时、迁移/前端/契约/Secret/镜像或业务部署。
本轮按所有者要求只保存本地 Luna 候选，父仓 gitlink 暂未更新，未合并 master 或推送同步；
待剩余处置完成后统一集成。真实身份/KIND/发布回滚与运行监控不因本次通过而自动销账。
