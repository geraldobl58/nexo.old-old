#!/bin/bash
# ============================================================================
# Nexo Platform - Promote Script
# ============================================================================
# Script para promover código entre ambientes seguindo o fluxo GitOps:
#   develop → qa → staging → prod (main)
#
# Uso:
#   ./scripts/promote.sh <source> <target>
#
# Exemplos:
#   ./scripts/promote.sh develop qa       # Promover develop para qa
#   ./scripts/promote.sh qa staging       # Promover qa para staging
#   ./scripts/promote.sh staging main     # Promover staging para prod
#
# ============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
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

# Validar argumentos
if [ $# -lt 2 ]; then
    echo "============================================"
    echo "  Nexo Platform - Promote Script"
    echo "============================================"
    echo ""
    echo "Uso: ./scripts/promote.sh <source> <target>"
    echo ""
    echo "Fluxo de promoção:"
    echo "  develop → qa → staging → main (prod)"
    echo ""
    echo "Exemplos:"
    echo "  ./scripts/promote.sh develop qa"
    echo "  ./scripts/promote.sh qa staging"
    echo "  ./scripts/promote.sh staging main"
    echo ""
    exit 1
fi

SOURCE=$1
TARGET=$2

# Mapear nomes alternativos
if [ "$TARGET" == "prod" ]; then
    TARGET="main"
fi

# Validar branches
VALID_BRANCHES=("develop" "qa" "staging" "main")

validate_branch() {
    local branch=$1
    for valid in "${VALID_BRANCHES[@]}"; do
        if [ "$valid" == "$branch" ]; then
            return 0
        fi
    done
    return 1
}

if ! validate_branch "$SOURCE"; then
    log_error "Branch source inválida: $SOURCE"
    log_info "Branches válidas: ${VALID_BRANCHES[*]}"
    exit 1
fi

if ! validate_branch "$TARGET"; then
    log_error "Branch target inválida: $TARGET"
    log_info "Branches válidas: ${VALID_BRANCHES[*]}"
    exit 1
fi

# Validar fluxo correto
validate_flow() {
    case "$SOURCE-$TARGET" in
        "develop-qa") return 0 ;;
        "qa-staging") return 0 ;;
        "staging-main") return 0 ;;
        *)
            log_error "Fluxo inválido: $SOURCE → $TARGET"
            log_info "Fluxos permitidos:"
            log_info "  develop → qa"
            log_info "  qa → staging"
            log_info "  staging → main (prod)"
            return 1
            ;;
    esac
}

if ! validate_flow; then
    exit 1
fi

# Ambiente target para display
if [ "$TARGET" == "main" ]; then
    TARGET_ENV="prod"
else
    TARGET_ENV="$TARGET"
fi

echo ""
echo "============================================"
echo "  🚀 Nexo Platform - Promoção de Ambiente"
echo "============================================"
echo ""
log_info "Promovendo: $SOURCE → $TARGET ($TARGET_ENV)"
echo ""

# Verificar se há mudanças não commitadas
if ! git diff --quiet || ! git diff --staged --quiet; then
    log_error "Existem mudanças não commitadas no diretório de trabalho"
    log_info "Por favor, commit ou stash as mudanças antes de promover"
    exit 1
fi

# Buscar últimas atualizações
log_info "Buscando últimas atualizações..."
git fetch origin

# Trocar para branch source
log_info "Mudando para branch: $SOURCE"
git checkout $SOURCE

# Atualizar branch source
log_info "Atualizando $SOURCE..."
git pull origin $SOURCE

# Trocar para branch target
log_info "Mudando para branch: $TARGET"
git checkout $TARGET

# Atualizar branch target
log_info "Atualizando $TARGET..."
git pull origin $TARGET

# Realizar merge
log_info "Realizando merge de $SOURCE em $TARGET..."
if git merge $SOURCE --no-edit; then
    log_success "Merge realizado com sucesso!"
else
    log_error "Conflitos de merge detectados!"
    log_info "Resolva os conflitos manualmente e execute:"
    log_info "  git add ."
    log_info "  git commit"
    log_info "  git push origin $TARGET"
    exit 1
fi

# Confirmar push
echo ""
read -p "Deseja fazer push para origin/$TARGET? (y/N): " confirm
if [[ $confirm =~ ^[Yy]$ ]]; then
    log_info "Fazendo push para origin/$TARGET..."
    git push origin $TARGET
    log_success "Push realizado com sucesso!"
    echo ""
    log_success "🎉 Promoção concluída: $SOURCE → $TARGET ($TARGET_ENV)"
    echo ""
    log_info "A pipeline será acionada automaticamente."
    log_info "Monitore em: https://github.com/geraldobl58/nexo/actions"
else
    log_warning "Push cancelado"
    log_info "Para completar a promoção manualmente:"
    log_info "  git push origin $TARGET"
fi

echo ""
