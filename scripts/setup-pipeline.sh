#!/bin/bash

# ============================================================================
# Quick Setup - CI/CD Pipeline
# ============================================================================
# Execute este script para configurar a pipeline completa
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        NEXO PLATFORM - CI/CD PIPELINE SETUP               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar se estamos no repositório correto
if [ ! -f "package.json" ]; then
    echo -e "${YELLOW}⚠️  Execute este script na raiz do projeto${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Configuração da Pipeline CI/CD${NC}"
echo ""

# 1. Verificar GitHub Token
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Passo 1: Configurar GitHub Secrets"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Você precisa configurar o secret no GitHub:"
echo ""
echo "1. Acesse: https://hub.docker.com/settings/security"
echo "2. Clique em 'New Access Token'"
echo "   - Nome: github-actions"
echo "   - Permissões: Read & Write"
echo "3. Copie o token"
echo ""
echo "4. No GitHub, vá para:"
echo "   https://github.com/geraldobl58/nexo/settings/secrets/actions"
echo ""
echo "5. Clique em 'New repository secret'"
echo "   - Name: DOCKERHUB_TOKEN"
echo "   - Secret: [cole o token aqui]"
echo ""
read -p "Pressione ENTER quando tiver configurado o secret..."

# 2. Verificar branches
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Passo 2: Criar branches necessárias"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

git fetch origin

BRANCHES=("develop" "qa" "staging" "main")
for branch in "${BRANCHES[@]}"; do
    if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        echo -e "${GREEN}✅ Branch $branch já existe${NC}"
    else
        echo -e "${YELLOW}⚠️  Criando branch $branch...${NC}"
        git checkout -b "$branch"
        git push -u origin "$branch"
    fi
done

# Voltar para develop
git checkout develop

# 3. Aplicar configurações do ArgoCD
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Passo 3: Aplicar configurações do ArgoCD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if kubectl get namespace argocd &> /dev/null; then
    echo -e "${GREEN}✅ ArgoCD encontrado${NC}"
    
    echo "Aplicando configurações..."
    kubectl apply -f local/argocd/projects/nexo-environments.yaml
    kubectl apply -f local/argocd/apps/nexo-develop.yaml
    kubectl apply -f local/argocd/apps/nexo-qa.yaml
    kubectl apply -f local/argocd/apps/nexo-staging.yaml
    kubectl apply -f local/argocd/apps/nexo-prod.yaml
    
    echo -e "${GREEN}✅ Configurações do ArgoCD aplicadas${NC}"
else
    echo -e "${YELLOW}⚠️  ArgoCD não encontrado. Execute primeiro:${NC}"
    echo "   make local-setup"
fi

# 4. Tornar scripts executáveis
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Passo 4: Configurar scripts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

chmod +x scripts/promote.sh
echo -e "${GREEN}✅ Scripts configurados${NC}"

# 5. Resumo final
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Setup Completo!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✅ Pipeline CI/CD configurada com sucesso!${NC}"
echo ""
echo "📚 Próximos passos:"
echo ""
echo "1. Fazer uma alteração no código"
echo "2. Commit e push para develop:"
echo "   git add ."
echo "   git commit -m 'test: validando pipeline'"
echo "   git push origin develop"
echo ""
echo "3. Acompanhar o build:"
echo "   https://github.com/geraldobl58/nexo/actions"
echo ""
echo "4. Promover para QA quando pronto:"
echo "   ./scripts/promote.sh develop qa"
echo ""
echo "📖 Documentação completa:"
echo "   cat documentation/local/11-gitops-workflow.md"
echo ""
