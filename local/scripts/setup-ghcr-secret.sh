#!/bin/bash
# ============================================================================
# Setup GHCR Secret para todos os namespaces
# ============================================================================
# Este script cria o secret para autenticação com GitHub Container Registry
# em todos os namespaces do Nexo Platform.
#
# Uso:
#   ./scripts/setup-ghcr-secret.sh
#
# Pré-requisitos:
#   - GitHub Personal Access Token (PAT) com permissão 'read:packages'
#   - kubectl configurado para o cluster K3D
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

echo ""
echo "============================================"
echo "  🔐 Setup GHCR Secret - Nexo Platform"
echo "============================================"
echo ""

# Namespaces que precisam do secret
NAMESPACES=("nexo-develop" "nexo-qa" "nexo-staging" "nexo-prod")

# Verificar se já existe variável de ambiente
if [ -n "$GHCR_TOKEN" ]; then
    log_info "Usando GHCR_TOKEN do ambiente"
    TOKEN="$GHCR_TOKEN"
elif [ -n "$GITHUB_TOKEN" ]; then
    log_info "Usando GITHUB_TOKEN do ambiente"
    TOKEN="$GITHUB_TOKEN"
else
    echo "Para criar o secret, você precisa de um GitHub Personal Access Token (PAT)"
    echo ""
    echo "Como criar:"
    echo "  1. Vá em: https://github.com/settings/tokens"
    echo "  2. Clique em 'Generate new token (classic)'"
    echo "  3. Selecione os scopes: 'read:packages', 'write:packages'"
    echo "  4. Copie o token gerado"
    echo ""
    read -sp "Cole seu GitHub Personal Access Token: " TOKEN
    echo ""
fi

if [ -z "$TOKEN" ]; then
    log_error "Token não fornecido. Abortando."
    exit 1
fi

# Solicitar username se não estiver no ambiente
if [ -n "$GITHUB_USERNAME" ]; then
    USERNAME="$GITHUB_USERNAME"
else
    read -p "Digite seu GitHub username [geraldobl58]: " USERNAME
    USERNAME=${USERNAME:-geraldobl58}
fi

log_info "Configurando GHCR secret para: $USERNAME"
echo ""

# Criar namespaces se não existirem
for NS in "${NAMESPACES[@]}"; do
    if ! kubectl get namespace "$NS" &>/dev/null; then
        log_info "Criando namespace: $NS"
        kubectl create namespace "$NS"
    fi
done

# Criar/atualizar secret em cada namespace
for NS in "${NAMESPACES[@]}"; do
    log_info "Configurando secret em: $NS"
    
    # Deletar secret existente se houver
    kubectl delete secret ghcr-secret -n "$NS" 2>/dev/null || true
    
    # Criar novo secret
    kubectl create secret docker-registry ghcr-secret \
        --docker-server=ghcr.io \
        --docker-username="$USERNAME" \
        --docker-password="$TOKEN" \
        --docker-email="${USERNAME}@users.noreply.github.com" \
        -n "$NS"
    
    log_success "Secret criado em $NS"
done

echo ""
log_success "🎉 Todos os secrets foram configurados!"
echo ""

# Testar se consegue fazer pull
log_info "Testando autenticação..."
echo "$TOKEN" | docker login ghcr.io -u "$USERNAME" --password-stdin 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "Autenticação com GHCR OK!"
else
    log_warning "Falha na autenticação. Verifique o token."
fi

echo ""
log_info "Para aplicar as mudanças, reinicie os pods:"
echo "  kubectl rollout restart deployment -n nexo-qa"
echo "  kubectl rollout restart deployment -n nexo-staging"
echo "  kubectl rollout restart deployment -n nexo-prod"
echo ""
