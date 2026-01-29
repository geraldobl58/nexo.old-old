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
CLUSTER_NAME="nexo-develop"
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
# Setup do Cluster K3D
# ============================================================================

create_cluster() {
    log_info "Criando cluster K3D '$CLUSTER_NAME'..."
    
    # Criar diretório de storage para K3D
    mkdir -p /tmp/k3d-nexo-storage
    
    # Verificar se cluster já existe
    if k3d cluster list | grep -q "$CLUSTER_NAME"; then
        log_warn "Cluster '$CLUSTER_NAME' já existe"
        read -p "Deseja recriar? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            k3d cluster delete "$CLUSTER_NAME"
        else
            log_info "Usando cluster existente"
            return 0
        fi
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
    kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s
    
    # Criar NodePort service para acesso local
    kubectl apply -f "$LOCAL_DIR/argocd/nodeport.yaml"
    
    # Instalar ArgoCD Image Updater
    log_info "Instalando ArgoCD Image Updater..."
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
    
    # Aguardar Image Updater ficar pronto
    log_info "Aguardando Image Updater ficar pronto..."
    kubectl wait --for=condition=Available deployment/argocd-image-updater -n argocd --timeout=120s
    
    # Obter senha inicial
    local argocd_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    log_success "ArgoCD + Image Updater instalados!"
    echo ""
    echo "  📍 URL: http://localhost:30080"
    echo "  👤 User: admin"
    echo "  🔑 Password: $argocd_password"
    echo "  🔄 Image Updater: Monitorando DockerHub a cada 2min"
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
# Configurar Secret do Registry
# ============================================================================

setup_registry_secret() {
    log_info "Configurando secret do registry..."
    
    # Para ambiente local, usamos o registry local do K3D
    # Em produção, seria o GHCR
    
    kubectl create secret docker-registry ghcr-registry \
        --docker-server=ghcr.io \
        --docker-username=geraldobl58 \
        --docker-password="${GITHUB_TOKEN:-dummy}" \
        --namespace=nexo-develop \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Secret do registry configurado"
}

# ============================================================================
# Aplicar Applications do ArgoCD
# ============================================================================

apply_argocd_apps() {
    log_info "Aplicando Applications do ArgoCD..."
    
    # Aplicar projetos
    kubectl apply -f "$LOCAL_DIR/argocd/projects/"
    
    # Aplicar applications
    kubectl apply -f "$LOCAL_DIR/argocd/apps/"
    
    log_success "Applications do ArgoCD aplicadas"
}

# ============================================================================
# Mostrar resumo
# ============================================================================

show_summary() {
    echo ""
    echo "============================================================================"
    echo -e "${GREEN}✅ Ambiente local K3D configurado com sucesso!${NC}"
    echo "============================================================================"
    echo ""
    echo "� Fluxo GitOps Automatizado:"
    echo ""
    echo "   Código → Commit → Push → GitHub Actions → DockerHub → Image Updater → K3D"
    echo ""
    echo "   O Image Updater verifica novas imagens a cada 2 minutos!"
    echo ""
    echo "📋 Serviços disponíveis:"
    echo ""
    echo "  | Serviço       | URL                      | Credenciais            |"
    echo "  |---------------|--------------------------|------------------------|"
    echo "  | ArgoCD        | http://localhost:30080   | admin / (ver acima)    |"
    echo "  | Grafana       | http://localhost:30030   | admin / (ver acima)    |"
    echo "  | Prometheus    | http://localhost:30090   | -                      |"
    echo "  | Alertmanager  | http://localhost:30093   | -                      |"
    echo ""
    echo "📋 Comandos úteis:"
    echo ""
    echo "  make status                            # Ver status geral"
    echo "  make image-updater                     # Ver logs do Image Updater"
    echo "  make pods                              # Ver pods"
    echo "  make logs-be                           # Logs do backend"
    echo "  make destroy                           # Destruir ambiente"
    echo ""
    echo "📋 Desenvolvimento:"
    echo ""
    echo "  git add . && git commit -m 'feat: X' && git push"
    echo ""
    echo "  Só isso! O CI/CD faz build e deploy automático 🎉"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo ""
    echo "============================================================================"
    echo "🚀 Nexo Platform - Setup Ambiente Local K3D"
    echo "============================================================================"
    echo ""
    
    check_dependencies
    create_cluster
    create_namespaces
    install_ingress
    install_argocd
    install_observability
    setup_registry_secret
    apply_argocd_apps
    show_summary
}

main "$@"
