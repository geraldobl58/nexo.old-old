#!/bin/bash
# ============================================================================
# Nexo Platform - Setup Ambiente Local K3D
# ============================================================================
# Este script cria um ambiente Kubernetes local completo que espelha produção
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório base
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$LOCAL_DIR")"

# Configurações
CLUSTER_NAME="nexo-local"
K3D_CONFIG="$LOCAL_DIR/k3d/config.yaml"

# ============================================================================
# Funções de utilidade
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Verificando dependências..."
    
    local missing=()
    
    if ! command -v docker &> /dev/null; then
        missing+=("docker")
    fi
    
    if ! command -v k3d &> /dev/null; then
        missing+=("k3d")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing+=("kubectl")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing+=("helm")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Dependências faltando: ${missing[*]}"
        echo ""
        echo "Instale com:"
        echo "  brew install k3d kubectl helm"
        echo ""
        exit 1
    fi
    
    log_success "Todas as dependências instaladas"
}

# ============================================================================
# Configurar SSD Externo para Volumes Docker
# ============================================================================

setup_ssd_volumes() {
    log_info "Verificando configuração de SSD externo..."
    
    local SSD_PATH="/Volumes/Backup/DockerSSD"
    local NEXO_PATH="$SSD_PATH/nexo"
    local NEXO_DEV_PATH="$SSD_PATH/nexo-dev"
    
    # Verificar se o SSD está montado
    if [ ! -d "$SSD_PATH" ]; then
        log_warn "SSD não encontrado em $SSD_PATH"
        echo ""
        echo "  Os volumes Docker serão criados no disco interno."
        echo "  Para usar o SSD externo:"
        echo "    1. Conecte o SSD em /Volumes/Backup/DockerSSD"
        echo "    2. Execute este script novamente"
        echo ""
        read -p "Continuar sem SSD? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Setup cancelado. Conecte o SSD e tente novamente."
            exit 1
        fi
        return 0
    fi
    
    log_success "SSD encontrado em $SSD_PATH"
    
    # Criar estrutura de diretórios
    log_info "Criando estrutura de diretórios no SSD..."
    
    # Nexo (produção)
    mkdir -p "$NEXO_PATH/postgres"
    mkdir -p "$NEXO_PATH/keycloak"
    
    # Nexo Dev
    mkdir -p "$NEXO_DEV_PATH/postgres"
    mkdir -p "$NEXO_DEV_PATH/redis"
    mkdir -p "$NEXO_DEV_PATH/keycloak"
    mkdir -p "$NEXO_DEV_PATH/api-uploads"
    mkdir -p "$NEXO_DEV_PATH/prometheus"
    mkdir -p "$NEXO_DEV_PATH/grafana"
    mkdir -p "$NEXO_DEV_PATH/loki"
    
    # Ajustar permissões
    log_info "Ajustando permissões..."
    chmod -R 777 "$NEXO_PATH"/* 2>/dev/null || true
    chmod -R 777 "$NEXO_DEV_PATH"/* 2>/dev/null || true
    
    log_success "Estrutura de volumes SSD configurada!"
    echo ""
    echo "  📁 Volumes mapeados para:"
    echo "    • Produção: $NEXO_PATH"
    echo "    • Dev: $NEXO_DEV_PATH"
    echo ""
    
    # Verificar espaço disponível
    local available_space=$(df -h "$SSD_PATH" | tail -1 | awk '{print $4}')
    log_info "Espaço disponível no SSD: $available_space"
    echo ""
}

# ============================================================================
# Setup do Cluster K3D
# ============================================================================

create_cluster() {
    log_info "Criando cluster K3D '$CLUSTER_NAME'..."
    
    # Criar diretório de storage para K3D
    mkdir -p /tmp/k3d-nexo-storage
    
    # Verificar se cluster já existe
    if k3d cluster list | grep -q "$CLUSTER_NAME"; then
        log_success "Cluster '$CLUSTER_NAME' já existe, continuando..."
        
        # Garantir que o cluster está rodando
        k3d cluster start "$CLUSTER_NAME" 2>/dev/null || true
        
        # Aguardar nodes ficarem prontos
        log_info "Aguardando nodes ficarem prontos..."
        kubectl wait --for=condition=Ready nodes --all --timeout=60s 2>/dev/null || true
        
        return 0
    fi
    
    # Criar cluster
    k3d cluster create --config "$K3D_CONFIG"
    
    # Aguardar nodes ficarem prontos
    log_info "Aguardando nodes ficarem prontos..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    log_success "Cluster '$CLUSTER_NAME' criado com sucesso!"
}

# ============================================================================
# Instalar NGINX Ingress Controller
# ============================================================================

install_ingress() {
    log_info "Instalando NGINX Ingress Controller..."
    
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
    helm repo update
    
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.type=LoadBalancer \
        --set controller.watchIngressWithoutClass=true \
        --set controller.ingressClassResource.default=true \
        --wait
    
    log_success "NGINX Ingress instalado"
}

# ============================================================================
# Criar Namespaces
# ============================================================================

create_namespaces() {
    log_info "Criando namespaces..."
    
    local namespaces=("nexo-develop" "argocd" "monitoring")
    
    for ns in "${namespaces[@]}"; do
        kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
        log_success "Namespace '$ns' criado"
    done
}

# ============================================================================
# Instalar ArgoCD
# ============================================================================

install_argocd() {
    log_info "Instalando ArgoCD..."
    
    # Instalar ArgoCD
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Aguardar pods ficarem prontos
    log_info "Aguardando ArgoCD ficar pronto..."
    sleep 10
    
    # Aguardar deployments principais
    kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s 2>/dev/null || true
    kubectl wait --for=condition=Available deployment/argocd-repo-server -n argocd --timeout=300s 2>/dev/null || true
    kubectl wait --for=condition=Available deployment/argocd-dex-server -n argocd --timeout=300s 2>/dev/null || true
    
    # Reiniciar applicationset controller se estiver com problema
    log_info "Verificando ArgoCD ApplicationSet controller..."
    kubectl rollout restart deployment argocd-applicationset-controller -n argocd 2>/dev/null || true
    sleep 5
    
    # Criar NodePort service para acesso local
    kubectl apply -f "$LOCAL_DIR/argocd/nodeport.yaml"
    
    # Obter senha inicial
    local argocd_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "admin")
    
    log_success "ArgoCD instalado!"
    echo ""
    echo "  📍 URL: http://localhost:30080"
    echo "  👤 User: admin"
    echo "  🔑 Password: $argocd_password"
    echo ""
}

# ============================================================================
# Instalar Stack de Observabilidade
# ============================================================================

install_observability() {
    log_info "Instalando stack de observabilidade..."
    
    # Adicionar repositório Prometheus
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
    helm repo update
    
    # Instalar kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
    helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --values "$LOCAL_DIR/observability/values.yaml" \
        --wait \
        --timeout 10m
    
    # Obter senha do Grafana
    local grafana_password=$(kubectl get secret --namespace monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
    
    log_success "Stack de observabilidade instalada!"
    echo ""
    echo "  📊 Grafana:      http://localhost:30030  (admin / $grafana_password)"
    echo "  📈 Prometheus:   http://localhost:30090"
    echo "  🔔 Alertmanager: http://localhost:30093"
    echo ""
}

# ============================================================================
# Verificar Registry Local
# ============================================================================

verify_local_registry() {
    log_info "Verificando registry local do K3D..."
    
    # Aguardar registry ficar disponível
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:5050/v2/ > /dev/null 2>&1; then
            log_success "Registry local acessível em localhost:5050"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    log_error "Registry local não está acessível. Verifique o cluster K3D."
    return 1
}

# ============================================================================
# Configurar Secret do Registry (GHCR)
# ============================================================================

setup_registry_secret() {
    log_info "Configurando secret do GitHub Container Registry..."
    
    # Verificar se já existe
    if kubectl get secret ghcr-secret -n nexo-develop &>/dev/null; then
        log_success "Secret ghcr-secret já existe"
        return 0
    fi
    
    log_warn "Secret ghcr-secret não encontrado"
    echo ""
    echo "  Para usar imagens do GHCR, você precisa configurar o secret."
    echo "  Execute: ./scripts/setup-ghcr-secret-interactive.sh"
    echo ""
    echo "  Ou configure manualmente com seu GitHub Token:"
    echo "  kubectl create secret docker-registry ghcr-secret \\"
    echo "    --docker-server=ghcr.io \\"
    echo "    --docker-username=SEU_USUARIO \\"
    echo "    --docker-password=SEU_TOKEN \\"
    echo "    -n nexo-develop"
    echo ""
    
    read -p "Deseja configurar agora? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        "$SCRIPT_DIR/setup-ghcr-secret-interactive.sh"
    else
        log_warn "Prosseguindo sem secret. As aplicações podem falhar ao baixar imagens."
    fi
}

# ============================================================================
# Aplicar Applications do ArgoCD
# ============================================================================

apply_argocd_apps() {
    log_info "Aplicando projetos e aplicações do ArgoCD..."
    
    # Aplicar projetos
    kubectl apply -f "$LOCAL_DIR/argocd/projects/" 2>/dev/null || true
    
    # Aplicar apenas o ambiente develop inicialmente
    kubectl apply -f "$LOCAL_DIR/argocd/apps/nexo-develop.yaml" 2>/dev/null || true
    
    log_success "Projetos e aplicações aplicados"
    echo ""
}

# ============================================================================
# Build e Push de Imagens
# ============================================================================

build_images() {
    log_info "Construindo e enviando imagens para o registry local..."
    echo ""
    
    # Obter commit hash curto
    cd "$PROJECT_ROOT"
    local GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
    
    log_info "Tag da imagem: $GIT_COMMIT"
    echo ""
    
    # Build nexo-auth
    log_info "🔨 Building nexo-auth:$GIT_COMMIT..."
    docker build \
        -t localhost:5050/nexo-auth:$GIT_COMMIT \
        -t localhost:5050/nexo-auth:latest \
        -f "$PROJECT_ROOT/apps/nexo-auth/Dockerfile" \
        "$PROJECT_ROOT/apps/nexo-auth" \
        --quiet
    
    docker push localhost:5050/nexo-auth:$GIT_COMMIT --quiet
    docker push localhost:5050/nexo-auth:latest --quiet
    log_success "nexo-auth:$GIT_COMMIT ✓"
    
    # Build nexo-be
    log_info "🔨 Building nexo-be:$GIT_COMMIT..."
    docker build \
        -t localhost:5050/nexo-be:$GIT_COMMIT \
        -t localhost:5050/nexo-be:latest \
        -f "$PROJECT_ROOT/apps/nexo-be/Dockerfile" \
        "$PROJECT_ROOT" \
        --quiet
    
    docker push localhost:5050/nexo-be:$GIT_COMMIT --quiet
    docker push localhost:5050/nexo-be:latest --quiet
    log_success "nexo-be:$GIT_COMMIT ✓"
    
    # Build nexo-fe
    log_info "🔨 Building nexo-fe:$GIT_COMMIT..."
    docker build \
        -t localhost:5050/nexo-fe:$GIT_COMMIT \
        -t localhost:5050/nexo-fe:latest \
        -f "$PROJECT_ROOT/apps/nexo-fe/Dockerfile" \
        "$PROJECT_ROOT" \
        --quiet
    
    docker push localhost:5050/nexo-fe:$GIT_COMMIT --quiet
    docker push localhost:5050/nexo-fe:latest --quiet
    log_success "nexo-fe:$GIT_COMMIT ✓"
    
    echo ""
    log_success "Todas as imagens construídas e enviadas!"
    echo ""
    
    # Listar imagens no registry
    log_info "Imagens disponíveis no registry:"
    curl -s http://localhost:5050/v2/_catalog | grep -o '"repositories":\[[^]]*\]'
    echo ""
}

# ============================================================================
# Sincronizar Aplicações ArgoCD
# ============================================================================

sync_argocd_apps() {
    log_info "Sincronizando aplicações do ArgoCD..."
    echo ""
    
    # Aguardar alguns segundos para ArgoCD detectar as aplicações
    sleep 10
    
    # Forçar sync de todas as aplicações
    for app in $(kubectl get applications -n argocd -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
        log_info "  Syncing $app..."
        kubectl patch application $app -n argocd \
            --type merge \
            -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}' \
            2>/dev/null || true
    done
    
    echo ""
    log_success "Sync iniciado para todas as aplicações"
    echo ""
    
    # Aguardar pods ficarem prontos
    log_info "Aguardando pods do nexo-develop ficarem prontos..."
    sleep 20
    
    local max_wait=60
    local waited=0
    while [ $waited -lt $max_wait ]; do
        local ready_pods=$(kubectl get pods -n nexo-develop --no-headers 2>/dev/null | grep -c "Running" || echo "0")
        if [ "$ready_pods" -ge "3" ]; then
            break
        fi
        sleep 5
        waited=$((waited + 5))
    done
    
    echo ""
}

# ============================================================================
# Mostrar resumo
# ============================================================================

show_summary() {
    echo ""
    echo "============================================================================"
    echo -e "${GREEN}✅ Ambiente Nexo K3D configurado com sucesso!${NC}"
    echo "============================================================================"
    echo ""
    
    # Obter senhas
    local argocd_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "admin")
    local grafana_password=$(kubectl get secret --namespace monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode 2>/dev/null || echo "admin123")
    
    echo "📋 Serviços Disponíveis:"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │ 🔐 ArgoCD                                                       │"
    echo "  │    URL:  http://localhost:30080                                 │"
    echo "  │    User: admin                                                  │"
    echo "  │    Pass: $argocd_password                                       │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │ 📊 Grafana                                                      │"
    echo "  │    URL:  http://localhost:30030                                 │"
    echo "  │    User: admin                                                  │"
    echo "  │    Pass: $grafana_password                                      │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │ 📈 Prometheus:   http://localhost:30090                         │"
    echo "  │ 🔔 Alertmanager: http://localhost:30093                         │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""
    
    echo "🎯 Aplicações Nexo (Develop):"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │ 🎨 Frontend:  http://develop.nexo.local                         │"
    echo "  │ ⚙️  Backend:   http://develop.api.nexo.local                    │"
    echo "  │ 🔐 Keycloak:  http://develop.auth.nexo.local                    │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""
    
    echo "📦 Status dos Pods:"
    echo ""
    kubectl get pods -n nexo-develop 2>/dev/null || echo "  Nenhum pod no namespace nexo-develop ainda"
    echo ""
    
    echo "🐳 Registry Local:"
    echo ""
    echo "  • localhost:5050 (fora do cluster)"
    echo "  • k3d-nexo-registry:5000 (dentro do cluster)"
    echo ""
    
    echo "📋 Comandos Úteis:"
    echo ""
    echo "  make status          # Ver status geral"
    echo "  make pods            # Ver pods"
    echo "  make build-images    # Rebuild imagens"
    echo "  make logs-be         # Logs do backend"
    echo "  make argocd-sync     # Ressincronizar apps"
    echo "  make destroy         # Destruir ambiente"
    echo ""
    
    echo "💡 Adicione ao /etc/hosts:"
    echo ""
    echo "  127.0.0.1 develop.nexo.local develop.api.nexo.local develop.auth.nexo.local"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo ""
    echo "============================================================================"
    echo "🚀 Nexo Platform - Setup Completo K3D + ArgoCD"
    echo "============================================================================"
    echo ""
    
    check_dependencies
    setup_ssd_volumes
    create_cluster
    verify_local_registry
    create_namespaces
    install_ingress
    install_argocd
    install_observability
    setup_registry_secret
    apply_argocd_apps
    sync_argocd_apps
    show_summary
}

main "$@"
