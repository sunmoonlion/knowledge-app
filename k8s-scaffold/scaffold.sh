#!/bin/bash
# k8s 部署目录脚手架
#
# 用法: ./scaffold.sh <APP_NAME> <PORT> [OPTIONS]
#
# 参数:
#   APP_NAME    应用名称（kebab-case，如 report-service、web-frontend）
#   PORT        容器监听端口（如 8000、3000、80）
#
# 选项:
#   --type      应用类型: backend（默认）| node-frontend | static-frontend
#               backend/node-frontend: 有 ConfigMap+Secret envFrom
#               static-frontend: 无 envFrom，无 ConfigMap，资源配额更小
#   --namespace NAMESPACE     目标 namespace（默认 app-platform-dev）
#   --registry REGISTRY       远程集群镜像仓库地址（默认 harbor.sunmoonai.com）
#   --image-project PROJECT   镜像项目名（默认 app-images）
#   --output-dir DIR          输出目录（默认当前目录）
#   --no-configmap            不生成 ConfigMap（static-frontend 自动设置）
#   --no-ingress              不生成 Ingress
#   --no-pvc                  不生成 PVC
#   --with-object-storage     为 Backend 增加独立 S3 ConfigMap/Secret envFrom
#   --with-elasticsearch      为 Backend 增加平台 Elasticsearch 配置、凭据和 CA
#   --with-database           为 Backend 增加 PostgreSQL/Redis 连接 Secret
#   --without-object-storage  显式关闭 Backend 的 S3 接线
#   --without-elasticsearch   显式关闭 Backend 的 Elasticsearch 接线
#   --without-database        显式关闭 Backend 的数据库接线
#   --memory-request MEM      内存请求（覆盖类型默认值）
#   --memory-limit MEM        内存限制
#   --cpu-request CPU         CPU 请求
#   --cpu-limit CPU           CPU 限制
#
# 示例:
#   ./scaffold.sh report-service 8000
#   ./scaffold.sh web-frontend 3000 --type node-frontend
#   ./scaffold.sh admin-frontend 80 --type static-frontend
#   ./scaffold.sh payment-service 8080 --namespace app-platform-prod --output-dir /k8s/my-project/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL_DIR="$SCRIPT_DIR/tpl"

log_info()    { echo -e "\033[0;34m[INFO]\033[0m $*"; }
log_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $*"; }
log_error()   { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; }
log_warn()    { echo -e "\033[1;33m[WARN]\033[0m $*"; }

# ============================================================================
# 参数解析
# ============================================================================

if [[ $# -lt 2 ]]; then
    log_error "用法: $0 <APP_NAME> <PORT> [OPTIONS]"
    echo "  示例: $0 report-service 8000"
    echo "  示例: $0 web-frontend 3000 --type node-frontend"
    echo "  示例: $0 admin-frontend 80 --type static-frontend"
    exit 1
fi

APP_NAME="$1"
PORT="$2"
shift 2

APP_TYPE="backend"
NAMESPACE="app-platform-dev"
REGISTRY="harbor.sunmoonai.com"
KIND_REGISTRY="harbor.sunmoonai.com:30443"
IMAGE_PROJECT="app-images"
OUTPUT_DIR="."
WITH_CONFIGMAP="true"
WITH_INGRESS="true"
WITH_PVC="true"
WITH_OBJECT_STORAGE="auto"
WITH_ELASTICSEARCH="auto"
WITH_DATABASE="auto"
MEMORY_REQUEST=""
MEMORY_LIMIT=""
CPU_REQUEST=""
CPU_LIMIT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --type)           APP_TYPE="$2";          shift 2 ;;
        --namespace)      NAMESPACE="$2";         shift 2 ;;
        --registry)       REGISTRY="$2";          shift 2 ;;
        --image-project)  IMAGE_PROJECT="$2";     shift 2 ;;
        --output-dir)     OUTPUT_DIR="$2";        shift 2 ;;
        --no-configmap)   WITH_CONFIGMAP="false"; shift ;;
        --no-ingress)     WITH_INGRESS="false";   shift ;;
        --no-pvc)         WITH_PVC="false";       shift ;;
        --with-object-storage) WITH_OBJECT_STORAGE="true"; shift ;;
        --with-elasticsearch) WITH_ELASTICSEARCH="true"; shift ;;
        --with-database) WITH_DATABASE="true"; shift ;;
        --without-object-storage) WITH_OBJECT_STORAGE="false"; shift ;;
        --without-elasticsearch) WITH_ELASTICSEARCH="false"; shift ;;
        --without-database) WITH_DATABASE="false"; shift ;;
        --memory-request) MEMORY_REQUEST="$2";    shift 2 ;;
        --memory-limit)   MEMORY_LIMIT="$2";      shift 2 ;;
        --cpu-request)    CPU_REQUEST="$2";       shift 2 ;;
        --cpu-limit)      CPU_LIMIT="$2";         shift 2 ;;
        *) log_error "未知参数: $1"; exit 1 ;;
    esac
done

# ============================================================================
# 根据应用类型设置默认值
# ============================================================================

case "$APP_TYPE" in
    static-frontend)
        [[ "$WITH_OBJECT_STORAGE" == "true" ]] && {
            log_error "static-frontend 不允许接收对象存储长期凭据"
            exit 1
        }
        [[ "$WITH_ELASTICSEARCH" == "true" ]] && {
            log_error "static-frontend 不允许接收 Elasticsearch 长期凭据"
            exit 1
        }
        [[ "$WITH_DATABASE" == "true" ]] && {
            log_error "static-frontend 不允许接收数据库长期凭据"
            exit 1
        }
        WITH_OBJECT_STORAGE="false"
        WITH_ELASTICSEARCH="false"
        WITH_DATABASE="false"
        WITH_CONFIGMAP="false"
        APP_YAML_TPL="app-static.yaml.tpl"
        : "${MEMORY_REQUEST:=64Mi}"
        : "${MEMORY_LIMIT:=128Mi}"
        : "${CPU_REQUEST:=50m}"
        : "${CPU_LIMIT:=200m}"
        ;;
    backend)
        [[ "$WITH_OBJECT_STORAGE" == "auto" ]] && WITH_OBJECT_STORAGE="true"
        [[ "$WITH_ELASTICSEARCH" == "auto" ]] && WITH_ELASTICSEARCH="true"
        [[ "$WITH_DATABASE" == "auto" ]] && WITH_DATABASE="true"
        APP_YAML_TPL="app.yaml.tpl"
        : "${MEMORY_REQUEST:=256Mi}"
        : "${MEMORY_LIMIT:=512Mi}"
        : "${CPU_REQUEST:=100m}"
        : "${CPU_LIMIT:=500m}"
        ;;
    node-frontend|*)
        [[ "$WITH_OBJECT_STORAGE" == "auto" ]] && WITH_OBJECT_STORAGE="false"
        [[ "$WITH_ELASTICSEARCH" == "auto" ]] && WITH_ELASTICSEARCH="false"
        [[ "$WITH_DATABASE" == "auto" ]] && WITH_DATABASE="false"
        APP_YAML_TPL="app.yaml.tpl"
        : "${MEMORY_REQUEST:=256Mi}"
        : "${MEMORY_LIMIT:=512Mi}"
        : "${CPU_REQUEST:=100m}"
        : "${CPU_LIMIT:=500m}"
        ;;
esac

# kebab-case → UPPER_SNAKE_CASE（report-service → REPORT_SERVICE）
APP_NAME_UPPER="$(echo "$APP_NAME" | tr '-' '_' | tr '[:lower:]' '[:upper:]')"
case "$APP_NAME" in
    *-admin-backend) INGRESS_HOST="${APP_NAME%-admin-backend}-admin-api.sunmoonai.com" ;;
    *-admin-frontend) INGRESS_HOST="${APP_NAME%-admin-frontend}-admin.sunmoonai.com" ;;
    *-web-backend) INGRESS_HOST="${APP_NAME%-web-backend}-api.sunmoonai.com" ;;
    *-web-frontend) INGRESS_HOST="${APP_NAME%-web-frontend}.sunmoonai.com" ;;
    *) INGRESS_HOST="${APP_NAME}.sunmoonai.com" ;;
esac

OBJECT_STORAGE_CONFIGMAP_NAME=""
OBJECT_STORAGE_SECRET_NAME=""
if [[ "$WITH_OBJECT_STORAGE" == "true" ]]; then
    if [[ "$APP_TYPE" == "static-frontend" ]]; then
        log_error "static-frontend 不允许接收对象存储长期凭据"
        exit 1
    fi
    OBJECT_STORAGE_CONFIGMAP_NAME="${APP_NAME}-s3"
    OBJECT_STORAGE_SECRET_NAME="${APP_NAME}-s3"
fi

ELASTICSEARCH_CONFIGMAP_NAME=""
ELASTICSEARCH_SECRET_NAME=""
if [[ "$WITH_ELASTICSEARCH" == "true" ]]; then
    if [[ "$APP_TYPE" == "static-frontend" ]]; then
        log_error "static-frontend 不允许接收 Elasticsearch 长期凭据"
        exit 1
    fi
    ELASTICSEARCH_CONFIGMAP_NAME="${APP_NAME}-elasticsearch"
    ELASTICSEARCH_SECRET_NAME="${APP_NAME}-elasticsearch"
fi

POSTGRESQL_SECRET_NAME=""
REDIS_SECRET_NAME=""
MONGODB_SECRET_NAME=""
if [[ "$WITH_DATABASE" == "true" ]]; then
    POSTGRESQL_SECRET_NAME="${APP_NAME}-postgresql-conn"
    REDIS_SECRET_NAME="${APP_NAME}-redis-conn"
    MONGODB_SECRET_NAME="${APP_NAME}-mongodb-conn"
fi

K8S_RESOURCE_DIR="$OUTPUT_DIR/resources/k8s-resource"
DEPLOY_DIR="$OUTPUT_DIR/deploy-$APP_NAME"

log_info "============================================================"
log_info "应用名称   : $APP_NAME  (大写: $APP_NAME_UPPER)"
log_info "端口       : $PORT     类型: $APP_TYPE"
log_info "Namespace  : $NAMESPACE"
log_info "资源配额   : 内存 $MEMORY_REQUEST/$MEMORY_LIMIT  CPU $CPU_REQUEST/$CPU_LIMIT"
log_info "ConfigMap  : $WITH_CONFIGMAP   Ingress: $WITH_INGRESS   PVC: $WITH_PVC"
log_info "Object S3  : $WITH_OBJECT_STORAGE"
log_info "Elasticsearch: $WITH_ELASTICSEARCH"
log_info "Database   : $WITH_DATABASE"
log_info "输出目录   : $OUTPUT_DIR"
log_info "============================================================"

# ============================================================================
# 渲染函数：将 tpl 文件的占位符替换后写入目标路径
# ============================================================================

render_tpl() {
    local tpl_file="$1"
    local out_file="$2"

    if [[ ! -f "$tpl_file" ]]; then
        log_error "模板文件不存在: $tpl_file"
        exit 1
    fi

    mkdir -p "$(dirname "$out_file")"
    # 注意：先替换 __APP_NAME_UPPER__ 再替换 __APP_NAME__，避免重叠匹配
    sed \
        -e "s|__APP_NAME_UPPER__|$APP_NAME_UPPER|g" \
        -e "s|__APP_NAME__|$APP_NAME|g" \
        -e "s|__INGRESS_HOST__|$INGRESS_HOST|g" \
        -e "s|__PORT__|$PORT|g" \
        -e "s|__NAMESPACE__|$NAMESPACE|g" \
        -e "s|__REGISTRY__|$REGISTRY|g" \
        -e "s|__KIND_REGISTRY__|$KIND_REGISTRY|g" \
        -e "s|__IMAGE_PROJECT__|$IMAGE_PROJECT|g" \
        -e "s|__MEMORY_REQUEST__|$MEMORY_REQUEST|g" \
        -e "s|__MEMORY_LIMIT__|$MEMORY_LIMIT|g" \
        -e "s|__CPU_REQUEST__|$CPU_REQUEST|g" \
        -e "s|__CPU_LIMIT__|$CPU_LIMIT|g" \
        -e "s|__OBJECT_STORAGE_CONFIGMAP_NAME__|$OBJECT_STORAGE_CONFIGMAP_NAME|g" \
        -e "s|__OBJECT_STORAGE_SECRET_NAME__|$OBJECT_STORAGE_SECRET_NAME|g" \
        -e "s|__ELASTICSEARCH_CONFIGMAP_NAME__|$ELASTICSEARCH_CONFIGMAP_NAME|g" \
        -e "s|__ELASTICSEARCH_SECRET_NAME__|$ELASTICSEARCH_SECRET_NAME|g" \
        -e "s|__POSTGRESQL_SECRET_NAME__|$POSTGRESQL_SECRET_NAME|g" \
        -e "s|__REDIS_SECRET_NAME__|$REDIS_SECRET_NAME|g" \
        -e "s|__MONGODB_SECRET_NAME__|$MONGODB_SECRET_NAME|g" \
        "$tpl_file" > "$out_file"
}

# ============================================================================
# YAML 模板（resources/k8s-resource/templates/）
# ============================================================================

log_info "生成 YAML 模板..."

render_tpl "$TPL_DIR/$APP_YAML_TPL" \
    "$K8S_RESOURCE_DIR/templates/app/$APP_NAME.yaml"

if [[ "$WITH_CONFIGMAP" == "true" ]]; then
    render_tpl "$TPL_DIR/configmap.yaml.tpl" \
        "$K8S_RESOURCE_DIR/templates/configMap/$APP_NAME-config.yaml"
fi

render_tpl "$TPL_DIR/secret.yaml.tpl" \
    "$K8S_RESOURCE_DIR/templates/secret/$APP_NAME-secret.yaml"

render_tpl "$TPL_DIR/harbor-registry-secret.yaml.tpl" \
    "$K8S_RESOURCE_DIR/templates/secret/harbor-registry-secret.yaml"

if [[ "$WITH_PVC" == "true" ]]; then
    render_tpl "$TPL_DIR/pvc.yaml.tpl" \
        "$K8S_RESOURCE_DIR/templates/pvc/$APP_NAME-pvc.yaml"
fi

render_tpl "$TPL_DIR/namespace.yaml.tpl" \
    "$K8S_RESOURCE_DIR/templates/namespace/$APP_NAME-namespace.yaml"

if [[ "$WITH_INGRESS" == "true" ]]; then
    render_tpl "$TPL_DIR/ingress.yaml.tpl" \
        "$K8S_RESOURCE_DIR/templates/ingress/ingress.yaml"
fi

# ============================================================================
# generate 脚本和配置（resources/k8s-resource/custom-values/）
# ============================================================================

log_info "生成 generate 脚本..."

# generate-app
render_tpl "$TPL_DIR/generate-app.conf.tpl" \
    "$K8S_RESOURCE_DIR/custom-values/app/generate-app/generate-app.conf"
render_tpl "$TPL_DIR/generate-app.sh.tpl" \
    "$K8S_RESOURCE_DIR/custom-values/app/generate-app/generate-app.sh"
chmod +x "$K8S_RESOURCE_DIR/custom-values/app/generate-app/generate-app.sh"

# generate-configmap
if [[ "$WITH_CONFIGMAP" == "true" ]]; then
    CM_DIR="$K8S_RESOURCE_DIR/custom-values/configMap/$APP_NAME-config/generate-$APP_NAME-config"
    render_tpl "$TPL_DIR/generate-configmap.conf.tpl" "$CM_DIR/generate-$APP_NAME-config.conf"
    render_tpl "$TPL_DIR/generate-configmap.sh.tpl"   "$CM_DIR/generate-$APP_NAME-config.sh"
    chmod +x "$CM_DIR/generate-$APP_NAME-config.sh"
fi

# generate-secret (app)
SEC_DIR="$K8S_RESOURCE_DIR/custom-values/secret/$APP_NAME-secret/generate-$APP_NAME-secret"
render_tpl "$TPL_DIR/generate-secret.conf.tpl" "$SEC_DIR/generate-$APP_NAME-secret.conf"
render_tpl "$TPL_DIR/generate-secret.sh.tpl"   "$SEC_DIR/generate-$APP_NAME-secret.sh"
chmod +x "$SEC_DIR/generate-$APP_NAME-secret.sh"

# generate-harbor-registry-secret
HBR_DIR="$K8S_RESOURCE_DIR/custom-values/secret/harbor-registry-secret/generate-harbor-registry-secret"
render_tpl "$TPL_DIR/generate-harbor-secret.conf.tpl" "$HBR_DIR/generate-harbor-registry-secret.conf"
render_tpl "$TPL_DIR/generate-harbor-secret.sh.tpl"   "$HBR_DIR/generate-harbor-registry-secret.sh"
chmod +x "$HBR_DIR/generate-harbor-registry-secret.sh"

# generate-pvc
if [[ "$WITH_PVC" == "true" ]]; then
    PVC_DIR="$K8S_RESOURCE_DIR/custom-values/pvc/$APP_NAME-pvc/generate-$APP_NAME-pvc"
    render_tpl "$TPL_DIR/generate-pvc.conf.tpl" "$PVC_DIR/generate-$APP_NAME-pvc.conf"
    render_tpl "$TPL_DIR/generate-pvc.sh.tpl"   "$PVC_DIR/generate-$APP_NAME-pvc.sh"
    chmod +x "$PVC_DIR/generate-$APP_NAME-pvc.sh"
fi

# generate-namespace
NS_DIR="$K8S_RESOURCE_DIR/custom-values/namespace/$APP_NAME-namespace/generate-$APP_NAME-namespace"
render_tpl "$TPL_DIR/generate-namespace.conf.tpl" "$NS_DIR/generate-$APP_NAME-namespace.conf"
render_tpl "$TPL_DIR/generate-namespace.sh.tpl"   "$NS_DIR/generate-$APP_NAME-namespace.sh"
chmod +x "$NS_DIR/generate-$APP_NAME-namespace.sh"

# generate-ingress
if [[ "$WITH_INGRESS" == "true" ]]; then
    IGR_DIR="$K8S_RESOURCE_DIR/custom-values/ingress/$APP_NAME-ingress/generate-ingress"
    render_tpl "$TPL_DIR/generate-ingress.conf.tpl" "$IGR_DIR/generate-ingress.conf"
    render_tpl "$TPL_DIR/generate-ingress.sh.tpl"   "$IGR_DIR/generate-ingress.sh"
    chmod +x "$IGR_DIR/generate-ingress.sh"
fi

# ============================================================================
# deploy 脚本（deploy-APP_NAME/）
# ============================================================================

log_info "生成 deploy 脚本..."

# main deploy
DAPP_DIR="$DEPLOY_DIR/app/deploy-app"
render_tpl "$TPL_DIR/deploy-app.sh.tpl"   "$DAPP_DIR/deploy-$APP_NAME.sh"
render_tpl "$TPL_DIR/deploy-app.conf.tpl" "$DAPP_DIR/deploy-$APP_NAME.conf"
chmod +x "$DAPP_DIR/deploy-$APP_NAME.sh"

# sub: app-secret
DSEC_DIR="$DEPLOY_DIR/secret/$APP_NAME-secret/deploy-$APP_NAME-secret"
render_tpl "$TPL_DIR/deploy-sub-secret.sh.tpl" "$DSEC_DIR/deploy-$APP_NAME-secret.sh"
render_tpl "$TPL_DIR/deploy-sub.conf.tpl"      "$DSEC_DIR/deploy-$APP_NAME-secret.conf"
chmod +x "$DSEC_DIR/deploy-$APP_NAME-secret.sh"

# sub: harbor-registry-secret
DHBR_DIR="$DEPLOY_DIR/secret/harbor-registry-secret/deploy-harbor-registry-secret"
render_tpl "$TPL_DIR/deploy-sub-harbor.sh.tpl" "$DHBR_DIR/deploy-harbor-registry-secret.sh"
render_tpl "$TPL_DIR/deploy-sub.conf.tpl"      "$DHBR_DIR/deploy-harbor-registry-secret.conf"
chmod +x "$DHBR_DIR/deploy-harbor-registry-secret.sh"

# sub: configmap
if [[ "$WITH_CONFIGMAP" == "true" ]]; then
    DCM_DIR="$DEPLOY_DIR/configMap/$APP_NAME-config/deploy-$APP_NAME-config"
    render_tpl "$TPL_DIR/deploy-sub-configmap.sh.tpl" "$DCM_DIR/deploy-$APP_NAME-config.sh"
    render_tpl "$TPL_DIR/deploy-sub.conf.tpl"         "$DCM_DIR/deploy-$APP_NAME-config.conf"
    chmod +x "$DCM_DIR/deploy-$APP_NAME-config.sh"
fi

# sub: ingress
if [[ "$WITH_INGRESS" == "true" ]]; then
    DIGR_DIR="$DEPLOY_DIR/ingress/$APP_NAME-ingress/deploy-ingress"
    render_tpl "$TPL_DIR/deploy-sub-ingress.sh.tpl" "$DIGR_DIR/deploy-ingress.sh"
    render_tpl "$TPL_DIR/deploy-sub.conf.tpl"       "$DIGR_DIR/deploy-ingress.conf"
    chmod +x "$DIGR_DIR/deploy-ingress.sh"
fi

# ============================================================================
# 完成摘要
# ============================================================================

log_success "============================================================"
log_success "✅ $APP_NAME k8s 部署目录生成完成"
log_success "============================================================"
echo ""
log_warn "⚠️  必须手工填写以下文件后才能部署："
echo ""
N=1
if [[ "$WITH_CONFIGMAP" == "true" ]]; then
    printf "  %2d. templates/configMap/$APP_NAME-config.yaml\n" $N; N=$((N+1))
    echo "       └── 添加实际 key 列表（非敏感配置字段）"
    printf "  %2d. custom-values/configMap/$APP_NAME-config/.../generate-$APP_NAME-config.conf\n" $N; N=$((N+1))
    echo "       └── 填写各 key 的值（服务地址、端口、Casdoor 配置等）"
    printf "  %2d. custom-values/configMap/$APP_NAME-config/.../generate-$APP_NAME-config.sh\n" $N; N=$((N+1))
    echo "       └── 补充 export 变量段（每个 key 一行 export KEY=\"\${KEY:-}\"）"
fi
printf "  %2d. templates/secret/$APP_NAME-secret.yaml\n" $N; N=$((N+1))
echo "       └── 添加实际 key 列表（敏感凭据字段）"
printf "  %2d. custom-values/secret/$APP_NAME-secret/.../generate-$APP_NAME-secret.conf\n" $N; N=$((N+1))
echo "       └── 填写密钥实际值（数据库密码、Redis 密码等）"
printf "  %2d. custom-values/secret/$APP_NAME-secret/.../generate-$APP_NAME-secret.sh\n" $N; N=$((N+1))
echo "       └── 补充 export 变量段"
printf "  %2d. custom-values/secret/harbor-registry-secret/.../generate-harbor-registry-secret.conf\n" $N; N=$((N+1))
echo "       └── 填写 DOCKER_SERVER / DOCKER_USERNAME / DOCKER_PASSWORD"
if [[ "$WITH_INGRESS" == "true" ]]; then
    printf "  %2d. templates/ingress/ingress.yaml\n" $N; N=$((N+1))
    echo "       └── 修改 Host 域名和 PathPrefix"
    printf "  %2d. custom-values/ingress/.../generate-ingress.conf\n" $N; N=$((N+1))
    echo "       └── 填写 UNIFIED_HOST / NODE_IP / SERVICE_NAME 等"
fi
printf "  %2d. deploy-$APP_NAME/app/deploy-app/deploy-$APP_NAME.conf\n" $N
echo "       └── 填写 PROJECT_ID 和 NAMESPACE"
echo ""
log_info "部署命令（在有 kubectl 权限的机器上执行）："
echo "  cd $DEPLOY_DIR/app/deploy-app/"
echo "  ./deploy-$APP_NAME.sh deploy <project_id> $NAMESPACE development"
