#!/bin/bash
# ============================================================================
# Setup GHCR Secret - GitHub Container Registry
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "============================================================================"
echo "🔐 Configurar Secret do GitHub Container Registry (GHCR)"
echo "============================================================================"
echo ""

# Verificar se já existe
if kubectl get secret ghcr-secret -n nexo-develop &>/dev/null; then
    echo -e "${GREEN}[OK]${NC} Secret ghcr-secret já existe no namespace nexo-develop"
    echo ""
    read -p "Deseja recriar? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Mantendo secret existente."
        exit 0
    fi
    kubectl delete secret ghcr-secret -n nexo-develop
fi

echo -e "${BLUE}[INFO]${NC} Para criar o secret, você precisa de um Personal Access Token do GitHub"
echo ""
echo "Crie em: https://github.com/settings/tokens"
echo "Permissões necessárias: read:packages"
echo ""

# Ler GitHub username
echo -e "${YELLOW}GitHub Username:${NC}"
read -r GITHUB_USERNAME

# Ler GitHub token
echo -e "${YELLOW}GitHub Personal Access Token (não será exibido):${NC}"
read -rs GITHUB_TOKEN
echo ""

if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}[ERROR]${NC} Username e token são obrigatórios"
    exit 1
fi

# Criar secret
echo ""
echo -e "${BLUE}[INFO]${NC} Criando secret ghcr-secret..."

kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username="$GITHUB_USERNAME" \
    --docker-password="$GITHUB_TOKEN" \
    --docker-email="${GITHUB_USERNAME}@users.noreply.github.com" \
    -n nexo-develop

echo ""
echo -e "${GREEN}[OK]${NC} Secret ghcr-secret criado com sucesso!"
echo ""
echo "Agora você pode fazer deploy das aplicações:"
echo "  cd local && make argocd-sync"
echo ""
