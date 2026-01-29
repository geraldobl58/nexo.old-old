#!/bin/bash
# ============================================================================
# Nexo Platform - Status do Ambiente Local K3D
# ============================================================================

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CLUSTER_NAME="nexo-develop"

echo ""
echo "============================================================================"
echo "📊 Nexo Platform - Status do Ambiente Local"
echo "============================================================================"
echo ""

# Verificar cluster
echo -e "${BLUE}[K3D Cluster]${NC}"
if k3d cluster list 2>/dev/null | grep -q "$CLUSTER_NAME"; then
    echo -e "  Status: ${GREEN}Running${NC}"
    k3d cluster list | grep "$CLUSTER_NAME"
else
    echo -e "  Status: ${RED}Not Running${NC}"
    echo ""
    echo "  Execute: make local-setup"
    exit 0
fi

echo ""

# Nodes
echo -e "${BLUE}[Kubernetes Nodes]${NC}"
kubectl get nodes -o wide 2>/dev/null || echo "  Não foi possível obter nodes"

echo ""

# Namespaces
echo -e "${BLUE}[Namespaces]${NC}"
kubectl get namespaces 2>/dev/null | grep -E "nexo|argocd|monitoring|ingress" || echo "  Nenhum namespace nexo encontrado"

echo ""

# Pods por namespace
for ns in nexo-develop argocd monitoring ingress-nginx; do
    echo -e "${BLUE}[Pods - $ns]${NC}"
    kubectl get pods -n "$ns" 2>/dev/null || echo "  Namespace não existe"
    echo ""
done

# Services
echo -e "${BLUE}[Services com NodePort]${NC}"
kubectl get svc -A 2>/dev/null | grep -E "NodePort|LoadBalancer" | head -20 || echo "  Nenhum serviço encontrado"

echo ""

# URLs de acesso
echo -e "${BLUE}[URLs de Acesso]${NC}"
echo "  ArgoCD:       http://localhost:30080"
echo "  Grafana:      http://localhost:30030"
echo "  Prometheus:   http://localhost:30090"
echo "  Alertmanager: http://localhost:30093"

echo ""

# ArgoCD password
echo -e "${BLUE}[Credenciais]${NC}"
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
if [ -n "$ARGOCD_PASS" ]; then
    echo "  ArgoCD: admin / $ARGOCD_PASS"
fi

GRAFANA_PASS=$(kubectl get secret --namespace monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 --decode)
if [ -n "$GRAFANA_PASS" ]; then
    echo "  Grafana: admin / $GRAFANA_PASS"
fi

echo ""
echo "============================================================================"
echo ""
