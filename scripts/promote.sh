#!/bin/bash

# ============================================================================
# Nexo Platform - Promotion Script
# ============================================================================
# Script para promover código entre ambientes seguindo o fluxo GitOps
# Uso: ./scripts/promote.sh [from-env] [to-env]
# Exemplo: ./scripts/promote.sh develop qa
# ============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        NEXO PLATFORM - ENVIRONMENT PROMOTION              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Mapeamento de ambientes para branches
declare -A ENV_BRANCH_MAP=(
    ["develop"]="develop"
    ["qa"]="qa"
    ["staging"]="staging"
    ["prod"]="main"
    ["production"]="main"
)

# Validação de argumentos
FROM_ENV=${1:-}
TO_ENV=${2:-}

# Menu interativo se não passar argumentos
if [ -z "$FROM_ENV" ] || [ -z "$TO_ENV" ]; then
    log_info "Fluxo de promoção disponível:"
    echo "  1) develop → qa"
    echo "  2) qa → staging"
    echo "  3) staging → production"
    echo ""
    read -p "Escolha uma opção (1-3): " choice
    
    case $choice in
        1)
            FROM_ENV="develop"
            TO_ENV="qa"
            ;;
        2)
            FROM_ENV="qa"
            TO_ENV="staging"
            ;;
        3)
            FROM_ENV="staging"
            TO_ENV="prod"
            ;;
        *)
            log_error "Opção inválida"
            exit 1
            ;;
    esac
fi

# Normalizar production -> prod
if [ "$TO_ENV" == "production" ]; then
    TO_ENV="prod"
fi

# Validar ambientes
FROM_BRANCH=${ENV_BRANCH_MAP[$FROM_ENV]}
TO_BRANCH=${ENV_BRANCH_MAP[$TO_ENV]}

if [ -z "$FROM_BRANCH" ] || [ -z "$TO_BRANCH" ]; then
    log_error "Ambiente inválido!"
    echo "Ambientes válidos: develop, qa, staging, prod"
    exit 1
fi

# Verificar se é um fluxo válido de promoção
VALID_FLOWS=(
    "develop:qa"
    "qa:staging"
    "staging:prod"
)

CURRENT_FLOW="${FROM_ENV}:${TO_ENV}"
if [[ ! " ${VALID_FLOWS[@]} " =~ " ${CURRENT_FLOW} " ]]; then
    log_warning "Fluxo de promoção incomum: $FROM_ENV → $TO_ENV"
    read -p "Deseja continuar? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_info "Promoção cancelada"
        exit 0
    fi
fi

log_info "Promoção: ${FROM_ENV} → ${TO_ENV}"
log_info "Branches: ${FROM_BRANCH} → ${TO_BRANCH}"
echo ""

# Verificar se estamos em um repositório git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Não é um repositório git!"
    exit 1
fi

# Verificar se há mudanças não commitadas
if ! git diff-index --quiet HEAD --; then
    log_error "Há mudanças não commitadas! Commit ou stash antes de continuar."
    git status --short
    exit 1
fi

# Atualizar repositório
log_info "Atualizando repositório..."
git fetch origin

# Checkout na branch de destino
log_info "Mudando para branch ${TO_BRANCH}..."
git checkout "$TO_BRANCH"
git pull origin "$TO_BRANCH"

# Verificar diferenças
log_info "Verificando diferenças entre ${FROM_BRANCH} e ${TO_BRANCH}..."
COMMITS_BEHIND=$(git rev-list --count "${TO_BRANCH}..origin/${FROM_BRANCH}")

if [ "$COMMITS_BEHIND" -eq 0 ]; then
    log_success "Não há novas alterações para promover!"
    log_info "${TO_BRANCH} já está atualizado com ${FROM_BRANCH}"
    exit 0
fi

log_warning "Há ${COMMITS_BEHIND} commit(s) novos em ${FROM_BRANCH}"
echo ""

# Mostrar commits que serão promovidos
log_info "Commits que serão promovidos:"
git log --oneline --graph --decorate "${TO_BRANCH}..origin/${FROM_BRANCH}" | head -n 10
echo ""

# Confirmação
if [ "$TO_ENV" == "prod" ]; then
    log_warning "⚠️  ATENÇÃO: Você está promovendo para PRODUÇÃO! ⚠️"
fi

read -p "Deseja fazer o merge? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    log_info "Promoção cancelada"
    exit 0
fi

# Fazer o merge
log_info "Fazendo merge de ${FROM_BRANCH} em ${TO_BRANCH}..."
if git merge "origin/${FROM_BRANCH}" --no-ff -m "chore: promote ${FROM_ENV} to ${TO_ENV}"; then
    log_success "Merge realizado com sucesso!"
else
    log_error "Conflitos detectados!"
    log_info "Resolva os conflitos manualmente e depois:"
    echo "  git merge --continue"
    echo "  git push origin ${TO_BRANCH}"
    exit 1
fi

# Push das mudanças
log_info "Enviando alterações para ${TO_BRANCH}..."
if git push origin "$TO_BRANCH"; then
    log_success "Push realizado com sucesso!"
else
    log_error "Falha no push! Você pode estar sem permissão ou a branch está protegida."
    exit 1
fi

echo ""
log_success "🎉 Promoção concluída com sucesso!"
echo ""
log_info "Próximos passos:"
echo "  1. GitHub Actions irá buildar e publicar as novas imagens"
echo "  2. ArgoCD Image Updater detectará as novas imagens"
echo "  3. Deploy automático no ambiente ${TO_ENV}"
echo ""
log_info "Monitorar deploy:"
echo "  • GitHub Actions: https://github.com/geraldobl58/nexo/actions"
echo "  • ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""

# Mostrar informações do último commit
LAST_COMMIT=$(git log -1 --pretty=format:"%h - %s (%an)")
log_info "Último commit: ${LAST_COMMIT}"
