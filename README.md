# knowledge-app

Knowledge 领域的架构 v2 实例父仓。活跃源码固定为两个 Next.js 前端与一个统一
FastAPI Backend；Admin/Web 只是应用层入口，不再各自拥有 Backend。

## 活跃子模块

| 子模块 | 技术栈 | 职责 |
| --- | --- | --- |
| `knowledge-admin-frontend` | Next.js + React | 数据集、摄取、Provider 绑定与治理操作 |
| `knowledge-web-frontend` | Next.js + React | 用户侧知识检索与引用体验 |
| `knowledge-backend` | FastAPI + Python 3.12 | `application/admin`、`application/web`、`application/internal` 共用的领域与基础设施 |

Knowledge 拥有 Dataset、Provider binding、Ingestion、Retrieval 与 Citation 事实；
不接管 Info 来源或 Investment Run 状态。

## 架构边界

- `.gitmodules` 是活跃源码拓扑的机器可读权威，必须且只能包含上述三项。
- 根目录不保存旧 worker 副本、NodeBull worker、模板初始化器或 K8s scaffold。
  Worker 入口由 `knowledge-backend` 提供，部署声明由 `k8s` 仓库维护。
- `docs/INSTANCE_FOUNDATION_ALIGNED.json` 与 `docs/P0-009-DOMAIN-RECOVERY.md`
  是迁移前历史证据，不代表当前拓扑。
- RAGFlow、文档转换与 ONLYOFFICE 属于 Knowledge 领域外部能力/适配器，是否部署
  由 K8s 阶段计划决定，不应复制成父仓 Backend。
- 当前 KIND 中的旧 v1 Deployment 在 R5/R7 门禁前可继续存在；源码收口不等于
  流量切换或数据迁移。

## 协作与验证

推送顺序必须是“子仓先提交并推送，父仓再提交 gitlink”。首次克隆或更新：

```bash
git clone --recurse-submodules --branch architecture-v2 \
  https://github.com/sunmoonlion/knowledge-app.git

git pull --ff-only
git submodule sync --recursive
git submodule update --init --recursive
```

后端质量门禁在 `knowledge-backend/app` 执行：

```bash
uv sync --frozen
uv run ruff check .
uv run pyright
uv run pytest -q
```

前端的安装、类型检查、lint、测试与构建命令以各子模块 README 和
`package.json` 为准。跨仓迁移、契约、镜像与运行时状态以 `k8s` 仓库的
architecture-v2 权威文档为准。
