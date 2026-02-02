#!/bin/bash
# ============================================================================
# Build e Push de Imagens para Registry Local K3D
# ============================================================================
# Este script faz build das imagens Docker e push para o registry local
# Registry: localhost:5050 (fora do cluster) / k3d-nexo-registry:5000 (dentro)
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Diretório base
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$LOCAL_DIR")"

# Configurações
CLUSTER_NAME="nexo-local"
# Registry local - acessível em localhost:5050 de fora do cluster
REGISTRY="localhost:5050"
# Nome do registry dentro do cluster K3D
REGISTRY_INTERNAL="k3d-nexo-registry:5000"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================================================
# Verificar Registry
# ============================================================================
check_registry() {
    log_info "Verificando registry local..."
    
    if ! curl -s http://localhost:5050/v2/ > /dev/null 2>&1; then
        log_error "Registry local não está acessível em localhost:5050"
        log_info "Verifique se o cluster K3D está rodando com o registry"
        log_info "Execute: make destroy && make setup"
        exit 1
    fi
    
    log_success "Registry local acessível"
}

# ============================================================================
# Push para Registry Local
# ============================================================================
push_to_registry() {
    local image=$1
    log_info "Fazendo push de $image para registry local..."
    
    docker push "$image"
    log_success "$image pushed para registry local"
}

# ============================================================================
# Build nexo-auth (Keycloak com temas)
# ============================================================================
build_nexo_auth() {
    log_info "Building nexo-auth (Keycloak com temas customizados)..."
    
    cd "$PROJECT_ROOT"
    
    docker build \
        -t ${REGISTRY}/nexo-auth:local \
        -f apps/nexo-auth/Dockerfile \
        .
    
    log_success "nexo-auth built: ${REGISTRY}/nexo-auth:local"
}

# ============================================================================
# Build nexo-be (NestJS Backend)
# ============================================================================
build_nexo_be() {
    log_info "Building nexo-be (NestJS Backend)..."
    
    cd "$PROJECT_ROOT"
    
    docker build \
        -t ${REGISTRY}/nexo-be:local \
        -f apps/nexo-be/Dockerfile \
        .
    
    log_success "nexo-be built: ${REGISTRY}/nexo-be:local"
}

# ============================================================================
# Build nexo-fe (Next.js Frontend)
# ============================================================================
build_nexo_fe() {
    log_info "Building nexo-fe (Next.js Frontend)..."
    
    cd "$PROJECT_ROOT"
    
    docker build \
        -t ${REGISTRY}/nexo-fe:local \
        -f apps/nexo-fe/Dockerfile \
        .
    
    log_success "nexo-fe built: ${REGISTRY}/nexo-fe:local"
}

# ============================================================================
# Menu Principal
# ============================================================================
show_usage() {
    echo "Uso: $0 [opção]"
    echo ""
    echo "Opções:"
    echo "  auth      Build e push nexo-auth (Keycloak)"
    echo "  be        Build e push nexo-be (NestJS)"
    echo "  fe        Build e push nexo-fe (Next.js)"
    echo "  all       Build e push todas as imagens"
    echo "  help      Mostra esta ajuda"
    echo ""
    echo "Registry local: localhost:5050"
    echo "Dentro do cluster: k3d-nexo-registry:5000"
    echo ""
}

case "${1:-all}" in
    auth)
        check_registry
        build_nexo_auth
        push_to_registry "${REGISTRY}/nexo-auth:local"
        ;;
    be)
        check_registry
        build_nexo_be
        push_to_registry "${REGISTRY}/nexo-be:local"
        ;;
    fe)
        check_registry
        build_nexo_fe
        push_to_registry "${REGISTRY}/nexo-fe:local"
        ;;
    all)
        check_registry
        build_nexo_auth
        push_to_registry "${REGISTRY}/nexo-auth:local"
        build_nexo_be
        push_to_registry "${REGISTRY}/nexo-be:local"
        build_nexo_fe
        push_to_registry "${REGISTRY}/nexo-fe:local"
        log_success "Todas as imagens foram buildadas e pushed para o registry local!"
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        log_error "Opção inválida: $1"
        show_usage
        exit 1
        ;;
esac

echo ""
log_info "Para aplicar as mudanças no cluster, execute:"
echo "  kubectl rollout restart deployment -n nexo-develop"
echo ""
log_info "Para listar imagens no registry local:"
echo "  curl http://localhost:5050/v2/_catalog"
