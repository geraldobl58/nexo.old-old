#!/bin/bash
# ============================================================================
# Build e Import de Imagens Customizadas para K3D
# ============================================================================
# Este script faz build das imagens Docker customizadas e importa para o K3D
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
REGISTRY="nexo-local"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

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
# Import para K3D
# ============================================================================
import_to_k3d() {
    local image=$1
    log_info "Importando $image para cluster K3D..."
    
    if k3d cluster list | grep -q "$CLUSTER_NAME"; then
        k3d image import "$image" -c "$CLUSTER_NAME"
        log_success "$image importada para K3D"
    else
        log_error "Cluster $CLUSTER_NAME não encontrado!"
        exit 1
    fi
}

# ============================================================================
# Menu Principal
# ============================================================================
show_usage() {
    echo "Uso: $0 [opção]"
    echo ""
    echo "Opções:"
    echo "  auth      Build e import nexo-auth (Keycloak)"
    echo "  be        Build e import nexo-be (NestJS)"
    echo "  fe        Build e import nexo-fe (Next.js)"
    echo "  all       Build e import todas as imagens"
    echo "  help      Mostra esta ajuda"
    echo ""
}

case "${1:-all}" in
    auth)
        build_nexo_auth
        import_to_k3d "${REGISTRY}/nexo-auth:local"
        ;;
    be)
        log_warn "nexo-be build ainda não implementado"
        ;;
    fe)
        log_warn "nexo-fe build ainda não implementado"
        ;;
    all)
        build_nexo_auth
        import_to_k3d "${REGISTRY}/nexo-auth:local"
        log_success "Todas as imagens foram buildadas e importadas!"
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
echo "  kubectl rollout restart deployment/nexo-auth-develop -n nexo-develop"
