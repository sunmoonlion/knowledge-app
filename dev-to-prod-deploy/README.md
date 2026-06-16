# dev-to-prod-deploy — Dev 到 k8s 生产的配置桥梁

## 这个目录是什么

私有仓库（开发阶段）的配置集中在 `app/.env` 和源码里的各种默认值。  
k8s 生产部署所需的配置集中在 k8s 仓库的 `resources/k8s-resource/custom-values/generate-*.conf` 中。

这两套配置**不做自动同步**——字段名尽量对齐，但值各自独立（地址、密码、运行模式都不同）。

本目录是两者之间的**方法论桥梁**：

- 说明每类配置**从开发侧哪里找字段**
- 说明填写 k8s 侧 `generate-*.conf` 时的**注意事项和易错点**
- 不包含实际的 conf 值（conf 手动填写到 k8s 仓库）

## 为什么"一事一议"

每个应用的字段集合、命名习惯、存储需求都不同，无法形成固定的自动映射。  
本目录提供的是**思考框架和检查清单**，具体字段由开发者逐项判断。

## 子目录分工

| 目录 | 对应 k8s 资源 | 说明 |
|------|-------------|------|
| `configmap-conf/` | ConfigMap | 非敏感配置：服务地址、功能开关、业务参数 |
| `secret-conf/` | Secret | 敏感凭据：密码、密钥、token |
| `pvc-conf/` | PersistentVolumeClaim | 存储路径：文件上传、持久化数据目录 |
| `app-conf/` | Deployment + Service | 镜像、副本数、资源限制 |

## 与 k8s 仓库的对应关系

```
knowledge-app/dev-to-prod-deploy/   ←→   k8s/app-platform/<app>/resources/k8s-resource/
├── configmap-conf/           →       custom-values/configMap/.../generate-*.conf
├── secret-conf/              →       custom-values/secret/.../generate-*-secret.conf
├── pvc-conf/                 →       custom-values/pvc/.../generate-*-pvc.conf
└── app-conf/                 →       custom-values/app/generate-app/generate-app.conf
```

## 使用场景

1. **新应用上 k8s 时**：对照各子目录的检查清单，逐项填写 k8s 仓库的 `generate-*.conf`
2. **`app/.env` 新增字段时**：查阅对应子目录，确定新字段进 ConfigMap 还是 Secret，在 k8s 侧补充
3. **字段命名对齐时**：查阅各子目录的命名约定，保证私有仓库和 k8s 侧字段名一致

## 部署组件完整性清单

新应用上 k8s 前，确认以下组件均已就绪（按实际需求勾选）：

- [ ] Namespace
- [ ] ConfigMap（应用非敏感配置）
- [ ] Secret（应用敏感凭据）
- [ ] Secret（harbor-registry-secret，镜像拉取）
- [ ] Deployment + Service（app）
- [ ] Ingress / IngressRoute
- [ ] Middleware（rate-limit 等，按需）
- [ ] PVC（如需持久化存储）
- [ ] Casdoor 侧 Organization / Application / 组织内初始用户（在 **k8s 仓库** `app-platform/auth-app/casdoor/deploy-casdoor` 执行 `post-deploy-setup.sh`，或按该仓库文档手工等价配置）
