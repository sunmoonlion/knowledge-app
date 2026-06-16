# Casdoor 部署问题全记录

> 记录日期：2026-04-26  
> 适用项目：investment-app / knowledge-app（两者共享同一套 Casdoor 部署方案）

---

## 一、Casdoor 在本项目中的角色

Casdoor 作为 OIDC Provider 部署在 k8s 集群（namespace: `app-platform-dev`），通过 Traefik NodePort 对外暴露：

| 协议 | 外部端口 | 内部服务端口 |
|------|----------|-------------|
| HTTPS | 30443 | 443 |
| HTTP  | 30080 | 80  |

**对外访问地址**：`https://casdoor.sunmoonai.com:30443`  
（`casdoor.sunmoonai.com` 已解析到 `115.190.64.131`）

两个后端均通过 OIDC Authorization Code Flow 与 Casdoor 交互：

| 后端 | 端口 | Casdoor Application | redirect_uri |
|------|------|---------------------|--------------|
| investment-web-backend  | 8000 | app-investment-web  | `http://43.159.148.235:8000/api/auth/callback` |
| investment-admin-backend | 8001 | app-investment-admin | `http://43.159.148.235:8001/api/auth/callback` |

---

## 二、标准部署流程（正确顺序）

```
1. 先决条件检查
      ↓
2. db-access-bootstrap（provision Casdoor DB + 用户）
      ↓
3. deploy-casdoor.sh --cluster C1
      ↓
4. post-deploy-setup（配置 Organizations / Applications）
      ↓
5. 验证（Pod Running → 登录重定向 → 完整 OAuth 流程）
```

### 2.1 先决条件清单

```bash
# 工具
which psql        # postgresql-client: apt install postgresql-client
which redis-cli   # redis-tools: apt install redis-tools
which kubectl
which helm

# DNS（/etc/hosts 需包含）
115.190.64.131  www.sunmoonai.com
115.190.64.131  casdoor.sunmoonai.com
115.190.64.131  llmops.sunmoonai.com

# dbctl 可执行权限
ls -la /home/zym/investment-app/investment-web-backend/db-provisioner/bin/dbctl
# 必须是 -rwxr-xr-x；若不是：
chmod +x /home/zym/investment-app/investment-web-backend/db-provisioner/bin/dbctl

# 所有 .sh 脚本可执行权限（git 默认 100644）
find /home/zym/k8s/sunmoonai/app-platform/auth-app/casdoor -name "*.sh" -exec chmod +x {} \;
```

### 2.2 db-access-bootstrap

```bash
cd /home/zym/k8s/sunmoonai/app-platform/auth-app/casdoor/db-access-bootstrap
./setup-external-db-access.sh
```

关键配置文件：

- `config/common.env`：`DBCTL_BIN` 路径、`NAMESPACE`
- `config/postgresql.external.env`：`DB_HOST`、`PG_ADMIN_PASSWORD`、`APP_DB_USER`、`APP_DB_PASSWORD`

### 2.3 deploy-casdoor.sh

**必须传 `--cluster C1`**，否则脚本默认使用 KIND 集群：

```bash
cd /home/zym/k8s/sunmoonai/app-platform/auth-app/casdoor/deploy-casdoor
./deploy-casdoor.sh --cluster C1
```

### 2.4 post-deploy-setup（已脚本化）

**仓库路径（单一事实来源，不在 knowledge-app 内）**：

- `k8s/sunmoonai/app-platform/auth-app/casdoor/deploy-casdoor/post-deploy-setup.sh`
- `k8s/sunmoonai/app-platform/auth-app/casdoor/deploy-casdoor/post-deploy-setup.conf`

```bash
cd /home/zym/k8s/sunmoonai/app-platform/auth-app/casdoor/deploy-casdoor
bash post-deploy-setup.sh app-platform-dev   # namespace 按环境调整
```

脚本会（幂等）：写入 Pod 内 `/conf/app.conf`（含 `copyrequestbody=true`）、创建 **Organizations / Applications**（由 `.conf` 中 `ORG_*` / `APP_*` 定义）、补齐 **`organization.languages`**（避免 OAuth 页白板）、按 **`ORG_*`** 创建各业务组织下的 **`admin`** 用户（密码同 **`ADMIN_PASSWORD`**）、更新 **built-in/admin** 密码。

从 **knowledge-app `init.sh` 派生的新项目**在 k8s 侧落地后：把 `.conf` 里的组织名、应用名、`redirect_uris`、client_id 改成新项目域名；首次 Casdoor 初始化务必执行上述脚本或等价 SQL（见下文「问题 11 / 12」）。

investment 示例（仍以 `.conf` 为准）：

1. **Organizations**：`investment-web`、`investment-admin`
2. **Applications**：
   - `app-investment-web`：`client_id=cd8328352070e08cd432`，redirect_uri 含业务 API 的 `/api/auth/callback`
   - `app-investment-admin`：`client_id=440db4e5a480c02c370d`，同上

---

## 三、已遇到的问题及根因与修复

### 问题 1：`SQLALCHEMY_DATABASE_URI` vs `DATABASE_URL` 命名不一致

**影响组件**：`investment-admin-backend`、`knowledge-admin-backend`

**根因**：
- `db-access-bootstrap/merge-and-generate-app-env.sh` 向 `.env` 写入 `DATABASE_URL`
- `app/core/config.py` 中 pydantic-settings 字段名为 `sqlalchemy_database_uri`，读取的是 `SQLALCHEMY_DATABASE_URI` 环境变量
- provision 后 `.env` 里从未有 `SQLALCHEMY_DATABASE_URI`，导致后端始终使用默认值连接

**修复（两个项目均需同步）**：

1. `app/core/config.py`：
```python
from pydantic import field_validator
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://..."

    @field_validator("database_url", mode="before")
    @classmethod
    def ensure_asyncpg(cls, v: str) -> str:
        if isinstance(v, str) and v.startswith("postgresql://"):
            return v.replace("postgresql://", "postgresql+asyncpg://", 1)
        return v
```

2. `db-access-bootstrap/merge-and-generate-app-env.sh`：
```bash
# 改为
for key in DATABASE_URL REDIS_HOST REDIS_PORT REDIS_DB REDIS_PASSWORD REDIS_USER; do
```

3. `app/.env`：将 `SQLALCHEMY_DATABASE_URI=...` 替换为 `DATABASE_URL=...`

---

### 问题 2：`uuid-ossp` 扩展创建失败（权限不足）

**影响组件**：`investment-admin-backend`、`knowledge-admin-backend`

**根因**：
- `postgres.py` 的 `init()` 在应用启动时执行 `CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`
- 应用 DB 用户（如 `sunmoonai_dev`）不是 SUPERUSER，无权创建扩展

**修复**：
- 从 `postgres.py` 删除 `CREATE EXTENSION` 语句
- 移入 `setup-external-db-access.sh` 的 `run_postgresql()` 函数，用 `PG_ADMIN_USER` 执行：

```bash
export PGPASSWORD="${PG_ADMIN_PASSWORD}"
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${PG_ADMIN_USER}" -d "${APP_DB_NAME}" \
  -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' >/dev/null
```

---

### 问题 3：所有 `.sh` 脚本和 `dbctl` 无执行权限

**根因**：git 默认将文件存储为 `100644`（无执行位）。clone/pull 后权限丢失。

**修复**：
```bash
# 一次性 chmod
find <repo-root> -name "*.sh" -exec chmod +x {} \;
chmod +x db-provisioner/bin/dbctl

# 持久化到 git（在每个 submodule 目录执行）
git update-index --chmod=+x path/to/script.sh
git update-index --chmod=+x db-provisioner/bin/dbctl
git commit -m "fix: mark shell scripts and dbctl as executable"
```

---

### 问题 4：所有 git submodule 处于 detached HEAD 状态

**根因**：`git submodule update --init` 会将 submodule checkout 到某个具体 commit，不在任何分支上。

**修复**：
```bash
# 进入每个 submodule 目录
cd <submodule>
git checkout master
git merge --ff-only origin/master  # 或 pull
```

---

### 问题 5：`common.env` 中 `DBCTL_BIN` 使用了 Windows 路径

**文件**：`k8s/sunmoonai/app-platform/auth-app/casdoor/db-access-bootstrap/config/common.env`

**根因**：在 Windows 环境下编辑，保存了类似 `C:\Users\...` 的路径。

**修复**：
```
DBCTL_BIN=/home/zym/investment-app/investment-web-backend/db-provisioner/bin/dbctl
```

---

### 问题 6：`postgresql.external.env` 使用了旧 IP 和旧密码

**文件**：同上目录的 `config/postgresql.external.env`

**根因**：配置在旧服务器（`101.126.151.0`）时写入，服务器已迁移。

**修复**：
```
DB_HOST=www.sunmoonai.com
PG_ADMIN_PASSWORD=Po!s1359admin
```

---

### 问题 7：hsy-local-2 节点新 Pod 全部卡在 ContainerCreating

**根因**：
- 节点初建期间为拉取外网镜像，**手动**写入了 `/etc/systemd/system/containerd.service.d/http-proxy.conf`，让 containerd 走本地 Clash（`http://127.0.0.1:7890`）
- Harbor 建好后 Clash 停了，但此文件从未清理，containerd 持续尝试连接死掉的代理端口
- Calico CNI 从 containerd 的 systemd 环境继承代理变量，导致 Pod 网络初始化也失败
- **此文件与 Kind 集群脚本无关**（Kind 脚本用 `docker exec` 只写容器内部文件系统）；也与节点上启用 TUN 模式无关（TUN 停止后自动清理，不留残余配置）
- 本项目所有基础设施脚本（step02/setup-runtime 等）均不会在真实节点上创建 `http-proxy.conf`，出现即说明是手动操作遗留

**诊断命令**：
```bash
# SSH 跳转到节点
ssh -J root@115.190.64.131:1022 root@192.168.3.89 -p 1022

# 查看代理配置
cat /etc/systemd/system/containerd.service.d/http-proxy.conf

# 查看 Pod 卡住的事件
kubectl describe pod <pod-name> -n <namespace>
```

**修复**：
```bash
# 在 hsy-local-2 节点上
rm /etc/systemd/system/containerd.service.d/http-proxy.conf
systemctl daemon-reload
systemctl restart containerd
```

---

### 问题 8：Casdoor Pod 启动后报 `password authentication failed for user "casdoor"`

**根因**：问题 6 中 DB 信息错误，导致 `setup-external-db-access.sh` 从未成功执行，`casdoor` DB 用户和数据库不存在。

**修复**：修正 `postgresql.external.env`（见问题 6）后重新执行：
```bash
./setup-external-db-access.sh
```

然后重启 Pod：
```bash
kubectl rollout restart deployment/casdoor -n app-platform-dev
```

---

### 问题 9：Casdoor Pod 缺少 `/conf/app.conf`（beego 配置）

**根因**：
- Helm chart 将 PVC 挂载到 `/conf`，覆盖了镜像内置的 `app.conf`
- PVC 是空的，Pod 启动时找不到配置文件，或使用空配置

**关键配置项**：beego 需要 `copyrequestbody=true` 才能正确解析 POST body。

**临时修复**（Pod 运行后 exec 写入）：
```bash
kubectl exec -it <casdoor-pod> -n app-platform-dev -- /bin/sh
cat > /conf/app.conf << 'EOF'
appname = casdoor
httpport = 8000
runmode = dev
copyrequestbody = true
EOF
exit

kubectl rollout restart deployment/casdoor -n app-platform-dev
```

**永久修复**：在 Helm values 或 ConfigMap 中预置 `app.conf`，通过 initContainer 或 ConfigMap 挂载写入 `/conf/app.conf`。

---

### 问题 11：OAuth `/login/oauth/authorize` 授权页白板（控制台 `languages.length` / `map` 报错）

**现象**：浏览器打开授权链接后整页空白；控制台类似 `Cannot read properties of null (reading 'length')`（Casdoor 前端对 `organizationObj.languages` 未做空判断）。

**根因**：通过 SQL 或残缺脚本写入的 **Organization** 未设置 **`languages`** 列，数据库为 NULL，接口返回 `languages: null`。

**修复**：

1. **推荐**：重新执行 `post-deploy-setup.sh`（含 `patch_organization_languages`）。
2. **手工 SQL**（按需调整语言列表）：
```sql
UPDATE organization
SET languages = '["en","zh"]'
WHERE owner = 'admin'
  AND (languages IS NULL OR languages = '' OR btrim(languages) = 'null');
```

---

### 问题 12：登录报错「The user: `{organization}/admin` doesn't exist」

**根因**：OAuth 应用绑定某一 **Organization**（如 `investment-admin`）时，只能登录 **该组织下** 的用户。 **`built-in/admin`** 不属于业务组织，会出现 `{org}/admin` 不存在。

**修复**：

1. **推荐**：执行 `post-deploy-setup.sh`，其中 **`ensure_org_admin_users`** 会按 **`ORG_*`** 第三列 `default_application` 幂等创建 **`{组织名}/admin`**（密码与 **`ADMIN_PASSWORD`** 一致）。
2. **手工**：在 Casdoor 控制台对应组织下新建用户，或与脚本同等逻辑的 SQL 插入（需谨慎字段完整性）。

---

### 问题 10：`CASDOOR_ENDPOINT` 端口错误（443 vs 30443）

**影响组件**：`investment-web-backend/app/.env`、`investment-admin-backend/app/.env`

**根因**：Casdoor 通过 Traefik NodePort 30443 暴露，不是标准 443 端口；但配置填写时漏掉端口号。

**修复**：
```bash
# investment-admin-backend/app/.env
CASDOOR_ENDPOINT=https://casdoor.sunmoonai.com:30443

# investment-web-backend/app/.env
CASDOOR_ENDPOINT=https://casdoor.sunmoonai.com:30443
```

同时需要关闭 SSL 验证（自签名证书）：
```bash
# investment-admin-backend
CASDOOR_VERIFY_SSL=false

# investment-web-backend
NODE_TLS_REJECT_UNAUTHORIZED=0
```

---

## 四、验证步骤

### 4.1 Casdoor Pod 健康

```bash
kubectl get pod -n app-platform-dev -l app=casdoor
# 期望：STATUS=Running，READY=1/1
```

### 4.2 后端登录重定向

```bash
# web-backend
curl -v http://43.159.148.235:8000/api/auth/login 2>&1 | grep -E "location|Location"
# 期望：Location: https://casdoor.sunmoonai.com:30443/login/oauth/authorize?...&client_id=cd8328352070e08cd432...

# admin-backend
curl -v http://43.159.148.235:8001/api/auth/login 2>&1 | grep -E "location|Location"
# 期望：Location: https://casdoor.sunmoonai.com:30443/login/oauth/authorize?...&client_id=440db4e5a480c02c370d...
```

### 4.3 Casdoor Admin 配置核查

登录 `https://casdoor.sunmoonai.com:30443`（admin/admin 或项目约定密码），确认：

1. **Organizations** 存在 `investment-web` 和 `investment-admin`
2. **Applications** `app-investment-web` 存在，且：
   - Client ID = `cd8328352070e08cd432`
   - Redirect URI 包含 `http://43.159.148.235:8000/api/auth/callback`
3. **Applications** `app-investment-admin` 存在，且：
   - Client ID = `440db4e5a480c02c370d`
   - Redirect URI 包含 `http://43.159.148.235:8001/api/auth/callback`

### 4.4 完整 OAuth 流程（浏览器）

1. 访问 `http://43.159.148.235:3000`（web frontend）→ 跳转 Casdoor 登录页
2. 登录后跳回 `http://43.159.148.235:8000/api/auth/callback` → 再跳回前端
3. 前端显示已登录状态

---

## 五、待完成事项

- [ ] 验证 Casdoor Applications 配置（Client ID / Redirect URI）是否正确
- [ ] 启动 investment-web-frontend（`npm run dev`，端口 3000）
- [ ] 启动 investment-admin-frontend（`pnpm dev --host`，端口 5173）
- [ ] 完整浏览器 OAuth 流程测试（web + admin 各一次）
- [ ] 将 Casdoor `app.conf` 纳入 Helm ConfigMap（永久修复问题 9）
- [x] `post-deploy-setup` 脚本化（Organizations / Applications / languages 补丁 / 各组织 admin）— 实现见 `auth-app/casdoor/deploy-casdoor/post-deploy-setup.sh`

---

## 六、关键地址速查

| 资源 | 地址 |
|------|------|
| Casdoor UI | `https://casdoor.sunmoonai.com:30443` |
| web-backend | `http://43.159.148.235:8000` |
| admin-backend | `http://43.159.148.235:8001` |
| web-frontend | `http://43.159.148.235:3000` |
| admin-frontend | `http://43.159.148.235:5173` |
| PostgreSQL | `www.sunmoonai.com:30444` |
| Redis | `www.sunmoonai.com:30446` |
| hsy-local-2 SSH | `ssh -J root@115.190.64.131:1022 root@192.168.3.89 -p 1022` |

---

## 七、文件修改清单（本次 session 已完成）

| 文件 | 修改内容 |
|------|----------|
| `investment-admin-backend/app/core/config.py` | 字段名 `sqlalchemy_database_uri` → `database_url`，加 `ensure_asyncpg` validator |
| `investment-admin-backend/app/app/infrastructure/storage/postgres.py` | 删除 `CREATE EXTENSION`，移除 `from sqlalchemy import text` |
| `investment-admin-backend/db-access-bootstrap/setup-external-db-access.sh` | 删除 `SQLALCHEMY_DATABASE_URI` 写入；加 admin 用户 `CREATE EXTENSION "uuid-ossp"` |
| `investment-admin-backend/db-access-bootstrap/merge-and-generate-app-env.sh` | key 从 `SQLALCHEMY_DATABASE_URI` 改为 `DATABASE_URL` |
| `investment-admin-backend/app/.env` | key 替换；`CASDOOR_ENDPOINT` 加端口 `:30443` |
| `investment-web-backend/app/.env` | `CASDOOR_ENDPOINT` 加端口 `:30443` |
| `k8s/.../casdoor/db-access-bootstrap/config/common.env` | 修正 `DBCTL_BIN` 路径（Windows→Linux） |
| `k8s/.../casdoor/db-access-bootstrap/config/postgresql.external.env` | 修正 `DB_HOST`（旧IP→域名）、`PG_ADMIN_PASSWORD` |
| `knowledge-admin-backend/` 对应文件 | 与 `investment-admin-backend/` 同步所有上述修改 |
| `k8s/.../auth-app/casdoor/deploy-casdoor/post-deploy-setup.sh` | `languages` 写入组织、`patch_organization_languages`、`ensure_org_admin_users`、`sql_escape_single`、built-in admin 密码转义 |
| `k8s/.../auth-app/casdoor/deploy-casdoor/post-deploy-setup.conf` | `ADMIN_PASSWORD` 与各组织 `admin`、说明 `ORG_*` 与 `APP_*` 对齐 |

（派生新项目时：**无需**把上述脚本复制进 knowledge-app；在 **k8s 仓库**维护 Casdoor，knowledge-app 侧仅复制业务 submodule 与文档约定。）
