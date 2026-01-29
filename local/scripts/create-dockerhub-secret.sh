#!/bin/bash
# ============================================================================
# NEXO PLATFORM - Create DockerHub Secret
# ============================================================================
# Cria o ImagePullSecret para o DockerHub em todos os namespaces necessários.
#
# Uso:
#   ./create-dockerhub-secret.sh
#   ./create-dockerhub-secret.sh --username myuser --token mytoken
#
# Se não passar argumentos, será solicitado interativamente.
# ============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       NEXO - DockerHub Secret Configuration                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--username) DOCKERHUB_USERNAME="$2"; shift ;;
        -t|--token) DOCKERHUB_TOKEN="$2"; shift ;;
        -h|--help) 
            echo "Uso: $0 [-u|--username USERNAME] [-t|--token TOKEN]"
            echo ""
            echo "Opções:"
            echo "  -u, --username    DockerHub username"
            echo "  -t, --token       DockerHub access token"
            echo "  -h, --help        Mostra esta ajuda"
            exit 0
            ;;
        *) echo "Argumento desconhecido: $1"; exit 1 ;;
    esac
    shift
done

# Solicitar credenciais se não foram passadas
if [ -z "$DOCKERHUB_USERNAME" ]; then
    read -p "DockerHub Username: " DOCKERHUB_USERNAME
fi

if [ -z "$DOCKERHUB_TOKEN" ]; then
    read -sp "DockerHub Token (Access Token): " DOCKERHUB_TOKEN
    echo ""
fi

# Validar inputs
if [ -z "$DOCKERHUB_USERNAME" ] || [ -z "$DOCKERHUB_TOKEN" ]; then
    echo -e "${RED}❌ Erro: Username e Token são obrigatórios${NC}"
    exit 1
fi

# Namespaces onde o secret será criado
NAMESPACES=(
    "nexo-develop"
    "nexo-qa"
    "nexo-staging"
    "nexo-prod"
    "default"
    "argocd"
)

SECRET_NAME="dockerhub-secret"

echo -e "${YELLOW}📋 Configuração:${NC}"
echo -e "   Username: ${GREEN}$DOCKERHUB_USERNAME${NC}"
echo -e "   Secret Name: ${GREEN}$SECRET_NAME${NC}"
echo -e "   Namespaces: ${GREEN}${NAMESPACES[*]}${NC}"
echo ""

# Criar secret em cada namespace
for NS in "${NAMESPACES[@]}"; do
    echo -e "${BLUE}▶ Processando namespace: $NS${NC}"
    
    # Criar namespace se não existir
    if ! kubectl get namespace "$NS" &>/dev/null; then
        echo -e "  ${YELLOW}Creating namespace $NS...${NC}"
        kubectl create namespace "$NS" 2>/dev/null || true
    fi
    
    # Deletar secret existente (se houver)
    kubectl delete secret "$SECRET_NAME" -n "$NS" 2>/dev/null || true
    
    # Criar novo secret
    kubectl create secret docker-registry "$SECRET_NAME" \
        --docker-server=https://index.docker.io/v1/ \
        --docker-username="$DOCKERHUB_USERNAME" \
        --docker-password="$DOCKERHUB_TOKEN" \
        --docker-email="${DOCKERHUB_USERNAME}@users.noreply.dockerhub.com" \
        -n "$NS"
    
    echo -e "  ${GREEN}✅ Secret criado em $NS${NC}"
done

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            ✅ Secrets criados com sucesso!                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📝 Próximos passos:${NC}"
echo -e "   1. Os Helm charts já estão configurados para usar 'dockerhub-secret'"
echo -e "   2. Deploy via ArgoCD irá usar o secret automaticamente"
echo -e "   3. Verifique com: kubectl get secret $SECRET_NAME -n nexo-develop"
echo ""

# Verificar se os secrets foram criados
echo -e "${BLUE}📋 Verificação:${NC}"
for NS in "${NAMESPACES[@]}"; do
    if kubectl get secret "$SECRET_NAME" -n "$NS" &>/dev/null; then
        echo -e "   ${GREEN}✓${NC} $NS: $SECRET_NAME"
    else
        echo -e "   ${RED}✗${NC} $NS: secret não encontrado"
    fi
done
