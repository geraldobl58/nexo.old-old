#!/bin/bash
# ============================================================================
# Script para aplicar dashboards customizados do Nexo no Grafana
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARDS_DIR="$SCRIPT_DIR/../observability/dashboards"
NAMESPACE="monitoring"

echo "📊 Aplicando dashboards customizados do Nexo..."

# Verificar se os arquivos de dashboard existem
if [ ! -d "$DASHBOARDS_DIR" ]; then
    echo "❌ Diretório de dashboards não encontrado: $DASHBOARDS_DIR"
    exit 1
fi

# Criar ConfigMap com os dashboards
echo "📁 Criando ConfigMap com dashboards..."

kubectl create configmap nexo-dashboards \
    --from-file="$DASHBOARDS_DIR" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# Adicionar label para o sidecar do Grafana detectar
kubectl label configmap nexo-dashboards \
    grafana_dashboard=1 \
    --namespace="$NAMESPACE" \
    --overwrite

echo "✅ Dashboards aplicados com sucesso!"
echo ""
echo "📋 Dashboards disponíveis:"
echo "  - Nexo Backend (NestJS)"
echo "  - Nexo Frontend (Next.js)"
echo "  - Nexo Auth (Keycloak)"
echo ""
echo "🔗 Acesse: http://localhost:30030/dashboards"
