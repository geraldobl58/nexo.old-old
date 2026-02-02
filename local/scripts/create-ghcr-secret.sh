#!/bin/bash
# ============================================================================
# Create GHCR (GitHub Container Registry) Secret
# ============================================================================
# Este script cria o secret para autenticação no GHCR em todos os namespaces
# Requisito: Você precisa de um GitHub Personal Access Token (PAT) com:
#   - read:packages (para pull de imagens)
#   - write:packages (opcional, para push)
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Namespaces onde o secret será criado
NAMESPACES="nexo-develop nexo-qa nexo-staging nexo-prod"

# Nome do secret
SECRET_NAME="ghcr-secret"

# Registry
REGISTRY="ghcr.io"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     🔐 Setup GHCR Secret                                        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar variáveis de ambiente
if [ -z "$GITHUB_USERNAME" ]; then
    echo -e "${YELLOW}GITHUB_USERNAME não definido.${NC}"
    read -p "Digite seu username do GitHub: " GITHUB_USERNAME
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${YELLOW}GITHUB_TOKEN não definido.${NC}"
    echo -e "${CYAN}Você precisa de um Personal Access Token (PAT) com permissão read:packages${NC}"
    echo -e "${CYAN}Crie em: https://github.com/settings/tokens/new${NC}"
    read -sp "Digite seu GitHub Personal Access Token: " GITHUB_TOKEN
    echo ""
fi

# Validar inputs
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ Username e Token são obrigatórios${NC}"
    exit 1
fi

echo -e "${CYAN}📦 Criando secret '$SECRET_NAME' nos namespaces...${NC}"
echo ""

for NS in $NAMESPACES; do
    echo -n "  $NS: "
    
    # Criar namespace se não existir
    kubectl create namespace $NS 2>/dev/null || true
    
    # Deletar secret existente se houver
    kubectl delete secret $SECRET_NAME -n $NS 2>/dev/null || true
    
    # Criar novo secret
    kubectl create secret docker-registry $SECRET_NAME \
        --docker-server=$REGISTRY \
        --docker-username=$GITHUB_USERNAME \
        --docker-password=$GITHUB_TOKEN \
        --docker-email=$GITHUB_USERNAME@users.noreply.github.com \
        -n $NS 2>/dev/null
    
    echo -e "${GREEN}✓ Created${NC}"
done

echo ""
echo -e "${GREEN}✅ GHCR secret criado com sucesso!${NC}"
echo ""
echo -e "${CYAN}📝 Para usar o secret nos deployments, adicione nos values files:${NC}"
echo ""
echo "imagePullSecrets:"
echo "  - name: ghcr-secret"
echo ""
echo -e "${CYAN}Ou exporte as variáveis antes de rodar este script:${NC}"
echo "  export GITHUB_USERNAME=seu-usuario"
echo "  export GITHUB_TOKEN=ghp_xxxxxxxxxxxx"
echo "  ./create-ghcr-secret.sh"
