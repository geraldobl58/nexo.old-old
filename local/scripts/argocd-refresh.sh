#!/bin/bash
# ============================================================================
# NEXO PLATFORM - Refresh ArgoCD Applications
# ============================================================================
# Força o refresh das aplicações ArgoCD para resolver problemas de sincronização
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       NEXO - ArgoCD Refresh & Sync                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se kubectl está configurado
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Erro: kubectl não está configurado ou cluster não está acessível${NC}"
    exit 1
fi

# Verificar se ArgoCD está instalado
if ! kubectl get namespace argocd &>/dev/null; then
    echo -e "${RED}❌ Erro: Namespace argocd não encontrado${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Aplicações ArgoCD encontradas:${NC}"
kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status 2>/dev/null || echo "Nenhuma aplicação encontrada"
echo ""

# Função para fazer refresh de uma aplicação
refresh_app() {
    local app_name=$1
    echo -e "${BLUE}▶ Refreshing: $app_name${NC}"
    
    # Patch para forçar refresh
    kubectl patch application "$app_name" -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' 2>/dev/null || true
    
    echo -e "  ${GREEN}✓${NC} Refresh triggered"
}

# Listar e fazer refresh de todas as aplicações
APPS=$(kubectl get applications -n argocd -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

if [ -z "$APPS" ]; then
    echo -e "${YELLOW}⚠️ Nenhuma aplicação ArgoCD encontrada${NC}"
    exit 0
fi

for app in $APPS; do
    refresh_app "$app"
done

echo ""
echo -e "${GREEN}✅ Refresh completed para todas as aplicações${NC}"
echo ""

# Mostrar status atualizado
echo -e "${YELLOW}📋 Status atualizado:${NC}"
sleep 3
kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status

echo ""
echo -e "${BLUE}ℹ️ Dica: Para sync manual, use:${NC}"
echo "   kubectl patch application <app-name> -n argocd --type merge -p '{\"operation\":{\"initiatedBy\":{\"username\":\"admin\"},\"sync\":{}}}'"
