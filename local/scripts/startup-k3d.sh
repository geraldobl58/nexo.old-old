#!/bin/bash
# =============================================================================
# Nexo Local Development - Auto Startup Script
# =============================================================================
# Este script é executado automaticamente no login para garantir que o
# ambiente de desenvolvimento local esteja funcionando.
# =============================================================================

LOG_FILE="$HOME/.nexo-startup.log"
CLUSTER_NAME="nexo-local"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=========================================="
log "Iniciando Nexo Local Development Environment"
log "=========================================="

# 1. Aguardar Docker Desktop iniciar (máximo 120 segundos)
log "Aguardando Docker Desktop..."
COUNTER=0
MAX_WAIT=120

while ! docker info > /dev/null 2>&1; do
    sleep 2
    COUNTER=$((COUNTER + 2))
    if [ $COUNTER -ge $MAX_WAIT ]; then
        log "❌ ERRO: Docker não iniciou após ${MAX_WAIT}s"
        exit 1
    fi
done

log "✅ Docker está rodando (aguardou ${COUNTER}s)"

# 2. Verificar se o cluster k3d existe
if ! k3d cluster list 2>/dev/null | grep -q "$CLUSTER_NAME"; then
    log "❌ Cluster $CLUSTER_NAME não encontrado"
    exit 1
fi

# 3. Verificar se o cluster está rodando
CLUSTER_STATUS=$(docker ps --filter "name=k3d-${CLUSTER_NAME}" --format "{{.Status}}" | head -1)

if [ -z "$CLUSTER_STATUS" ]; then
    log "🔄 Iniciando cluster $CLUSTER_NAME..."
    k3d cluster start "$CLUSTER_NAME" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        log "✅ Cluster iniciado com sucesso"
    else
        log "❌ Falha ao iniciar cluster"
        exit 1
    fi
else
    log "✅ Cluster já está rodando: $CLUSTER_STATUS"
fi

# 4. Aguardar pods do sistema ficarem prontos
log "Aguardando pods do sistema..."
sleep 10

# 5. Verificar pods do ArgoCD
log "Verificando pods do ArgoCD..."
ARGOCD_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$ARGOCD_PODS" -gt 0 ]; then
    # Verificar se há pods com problema
    PROBLEM_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep -E "CrashLoopBackOff|Error|Unknown" | awk '{print $1}')
    
    if [ -n "$PROBLEM_PODS" ]; then
        log "⚠️ Encontrados pods com problemas, reiniciando..."
        for pod in $PROBLEM_PODS; do
            log "  Deletando pod: $pod"
            kubectl delete pod "$pod" -n argocd >> "$LOG_FILE" 2>&1
        done
        log "✅ Pods problemáticos reiniciados"
    else
        log "✅ Todos os pods do ArgoCD estão saudáveis"
    fi
else
    log "⚠️ Nenhum pod do ArgoCD encontrado"
fi

# 6. Verificar namespaces das aplicações
for ns in nexo-develop nexo-qa nexo-staging nexo-prod; do
    if kubectl get namespace "$ns" > /dev/null 2>&1; then
        POD_COUNT=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l | tr -d ' ')
        log "✅ Namespace $ns: $POD_COUNT pods"
    fi
done

log "=========================================="
log "✅ Ambiente Nexo pronto!"
log "=========================================="

# 7. Mostrar notificação no macOS (opcional)
if command -v osascript &> /dev/null; then
    osascript -e 'display notification "Cluster k3d e ArgoCD prontos!" with title "Nexo Dev Environment" sound name "Glass"'
fi

exit 0
