#!/bin/bash
# ============================================================================
# Nexo Platform - Destroy Ambiente Local K3D
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CLUSTER_NAME="nexo-develop"

echo ""
echo "============================================================================"
echo -e "${YELLOW}⚠️  ATENÇÃO: Isso vai destruir o ambiente local completo!${NC}"
echo "============================================================================"
echo ""
echo "O seguinte será removido:"
echo "  - Cluster K3D '$CLUSTER_NAME'"
echo "  - Todos os pods, serviços e dados"
echo "  - Registry local"
echo ""

read -p "Tem certeza? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

echo ""
echo -e "${YELLOW}Destruindo cluster...${NC}"

# Deletar cluster
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    k3d cluster delete "$CLUSTER_NAME"
    echo -e "${GREEN}✅ Cluster '$CLUSTER_NAME' removido${NC}"
else
    echo -e "${YELLOW}Cluster '$CLUSTER_NAME' não encontrado${NC}"
fi

# Limpar volumes
if [ -d "/tmp/k3d-nexo-storage" ]; then
    rm -rf /tmp/k3d-nexo-storage
    echo -e "${GREEN}✅ Volumes removidos${NC}"
fi

echo ""
echo -e "${GREEN}✅ Ambiente local destruído com sucesso!${NC}"
echo ""
echo "Para recriar: make local-setup"
echo ""
