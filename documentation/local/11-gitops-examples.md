# Exemplos Práticos - GitOps Pipeline

## Cenário 1: Nova Feature

### Desenvolvimento
```bash
# 1. Criar branch de feature
git checkout develop
git pull origin develop
git checkout -b feature/add-user-profile

# 2. Desenvolver
# ... editar arquivos ...

# 3. Testar localmente
pnpm --filter nexo-be test
pnpm --filter nexo-be build

# 4. Commit
git add apps/nexo-be/src/
git commit -m "feat(be): adiciona endpoint de perfil de usuário"

# 5. Push
git push origin feature/add-user-profile

# 6. Criar PR para develop no GitHub
# Revisar código → Merge PR

# 7. Deploy automático em develop acontece
```

### Promoção
```bash
# Após validação no develop
./scripts/promote.sh develop qa

# Após QA aprovar
./scripts/promote.sh qa staging

# Após homologação
./scripts/promote.sh staging prod

# Aprovar deploy em produção
argocd app sync nexo-be-prod --prune
```

## Cenário 2: Hotfix em Produção

### Urgência: Bug crítico em produção

```bash
# 1. Criar hotfix branch a partir de main
git checkout main
git pull origin main
git checkout -b hotfix/fix-critical-bug

# 2. Corrigir bug
# ... editar arquivos ...

# 3. Testar
pnpm test

# 4. Commit e push
git add .
git commit -m "fix: corrige bug crítico em autenticação"
git push origin hotfix/fix-critical-bug

# 5. Merge para main (produção)
git checkout main
git merge hotfix/fix-critical-bug
git push origin main

# 6. GitHub Actions builda e publica imagem :latest

# 7. Deploy em produção (manual)
argocd app sync nexo-be-prod --prune

# 8. Propagar fix para outras branches
git checkout staging
git merge main
git push origin staging

git checkout qa
git merge staging
git push origin qa

git checkout develop
git merge qa
git push origin develop
```

## Cenário 3: Rollback

### Situação: Deploy com problema em QA

```bash
# Opção 1: Rollback via ArgoCD
argocd app rollback nexo-be-qa

# Opção 2: Ver histórico e escolher versão
argocd app history nexo-be-qa
# Output:
# ID  DATE                           REVISION
# 5   2026-01-31 10:30:00 -0300 -03  abc1234 (current)
# 4   2026-01-31 10:00:00 -0300 -03  def5678
# 3   2026-01-31 09:30:00 -0300 -03  ghi9012

# Rollback para versão específica
argocd app rollback nexo-be-qa 4
```

### Situação: Deploy com problema em Produção

```bash
# 1. Rollback imediato via ArgoCD
argocd app rollback nexo-be-prod

# 2. Ou reverter commit no Git
git checkout main
git revert HEAD
git push origin main

# 3. Aguardar build e deploy
# GitHub Actions → Docker Hub → ArgoCD
```

## Cenário 4: Múltiplos Apps Mudaram

### Situação: Mudanças em BE, FE e Auth

```bash
# 1. Fazer mudanças em múltiplos apps
git checkout -b feature/multi-app-changes

# Editar apps/nexo-be/...
# Editar apps/nexo-fe/...
# Editar apps/nexo-auth/...

# 2. Commit único ou separado (preferível)
git add apps/nexo-be/
git commit -m "feat(be): adiciona nova API"

git add apps/nexo-fe/
git commit -m "feat(fe): adiciona nova tela"

git add apps/nexo-auth/
git commit -m "feat(auth): adiciona novo tema"

# 3. Push para develop
git checkout develop
git merge feature/multi-app-changes
git push origin develop

# 4. GitHub Actions detecta mudanças em todos os 3 apps
# Builda e publica as 3 imagens em paralelo

# 5. ArgoCD Image Updater detecta as 3 novas imagens
# Atualiza as 3 aplicações

# 6. Deploy dos 3 apps acontece em paralelo
```

## Cenário 5: Testar em Ambiente Específico

### Testar uma feature isoladamente em QA

```bash
# 1. Criar branch de test
git checkout -b test/experimental-feature
# ... desenvolver ...

# 2. Criar tag específica para QA
git add .
git commit -m "test: feature experimental"
git tag qa-experimental
git push origin test/experimental-feature --tags

# 3. Build manual com tag específica
# (ou modificar workflow para aceitar tags)

# 4. Atualizar ArgoCD temporariamente
kubectl -n argocd patch app nexo-be-qa \
  -p '{"spec":{"source":{"helm":{"parameters":[{"name":"image.tag","value":"qa-experimental"}]}}}}' \
  --type=merge

# 5. Testar

# 6. Reverter quando terminar
kubectl -n argocd patch app nexo-be-qa \
  -p '{"spec":{"source":{"helm":{"parameters":[{"name":"image.tag","value":"qa"}]}}}}' \
  --type=merge
```

## Cenário 6: Debug de Deploy Falhando

### Deploy travado em "Progressing"

```bash
# 1. Ver detalhes da aplicação
argocd app get nexo-be-qa

# 2. Ver eventos do Kubernetes
kubectl get events -n nexo-qa --sort-by='.lastTimestamp' | tail -20

# 3. Ver logs do pod
kubectl logs -n nexo-qa deployment/nexo-be --tail=100

# 4. Descrever pod para ver problemas
kubectl describe pod -n nexo-qa -l app=nexo-be

# Problemas comuns:
# - ImagePullBackOff: Imagem não existe no registry
# - CrashLoopBackOff: Aplicação falhando ao iniciar
# - Pending: Recursos insuficientes
```

### Imagem não está sendo atualizada

```bash
# 1. Verificar se imagem existe no Docker Hub
curl -s https://hub.docker.com/v2/repositories/geraldobl58/nexo-be/tags \
  | jq '.results[] | select(.name=="qa")'

# 2. Verificar logs do Image Updater
kubectl logs -n argocd deployment/argocd-image-updater -f

# 3. Forçar refresh do Image Updater
kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-image-updater

# 4. Verificar anotações da aplicação
kubectl get app nexo-be-qa -n argocd -o yaml | grep argocd-image-updater

# 5. Forçar atualização manual se necessário
argocd app sync nexo-be-qa --force
```

## Cenário 7: Canary Deployment (Avançado)

### Deploy gradual em produção

```bash
# 1. Atualizar configuração do ArgoCD para usar Argo Rollouts
# (requer setup adicional)

# 2. Modificar Helm chart para incluir Rollout
# local/helm/nexo-be/templates/rollout.yaml

# 3. Fazer deploy normal
./scripts/promote.sh staging prod
argocd app sync nexo-be-prod

# 4. Monitorar progresso
kubectl argo rollouts get rollout nexo-be -n nexo-prod

# 5. Promover manualmente se tudo ok
kubectl argo rollouts promote nexo-be -n nexo-prod

# 6. Ou fazer rollback se tiver problema
kubectl argo rollouts abort nexo-be -n nexo-prod
```

## Cenário 8: Verificar Diferenças Entre Ambientes

### Ver diferenças entre develop e qa

```bash
# 1. Ver commits que estão em develop mas não em qa
git log qa..develop --oneline

# 2. Ver diferença de arquivos
git diff qa develop

# 3. Ver diferença de arquivos de um app específico
git diff qa develop -- apps/nexo-be/

# 4. Ver imagens deployadas em cada ambiente
# Develop
kubectl get deployment nexo-be -n nexo-develop -o jsonpath='{.spec.template.spec.containers[0].image}'

# QA
kubectl get deployment nexo-be -n nexo-qa -o jsonpath='{.spec.template.spec.containers[0].image}'

# Staging
kubectl get deployment nexo-be -n nexo-staging -o jsonpath='{.spec.template.spec.containers[0].image}'

# Produção
kubectl get deployment nexo-be -n nexo-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
```

## Cenário 9: Disaster Recovery

### Situação: Cluster K8s foi destruído

```bash
# 1. Recriar cluster
make local-destroy
make local-setup

# 2. ArgoCD irá recriar tudo automaticamente
# Todos os apps serão sincronizados do Git

# 3. Verificar status
argocd app list
kubectl get pods --all-namespaces
```

### Situação: Repositório Git com problema

```bash
# 1. Fixar repositório Git
# ... corrigir problemas ...

# 2. Forçar resync de todas as aplicações
argocd app sync --all

# 3. Ou resync seletivo
argocd app sync -l environment=qa
```

## Cenário 10: Configuração por Ambiente

### Ajustar configuração específica de um ambiente

```bash
# Exemplo: Aumentar réplicas em produção

# 1. Editar values específico
vim local/helm/nexo-be/values-prod.yaml

# Alterar:
# replicaCount: 3  # Era 1

# 2. Commit e push
git add local/helm/nexo-be/values-prod.yaml
git commit -m "chore(prod): aumenta réplicas para 3"
git push origin main

# 3. ArgoCD detecta mudança e aplica
# (ou forçar sync)
argocd app sync nexo-be-prod
```

## Scripts Úteis

### Script para verificar status de todos os ambientes

```bash
#!/bin/bash
# scripts/check-all-envs.sh

ENVS=("develop" "qa" "staging" "prod")
APPS=("nexo-be" "nexo-fe" "nexo-auth")

for env in "${ENVS[@]}"; do
  echo "=== Ambiente: $env ==="
  for app in "${APPS[@]}"; do
    status=$(argocd app get ${app}-${env} -o json | jq -r '.status.sync.status')
    health=$(argocd app get ${app}-${env} -o json | jq -r '.status.health.status')
    echo "  $app: Sync=$status Health=$health"
  done
  echo ""
done
```

### Script para promover em massa

```bash
#!/bin/bash
# scripts/promote-all.sh

FROM_ENV=$1
TO_ENV=$2

APPS=("nexo-be" "nexo-fe" "nexo-auth")

echo "Promovendo de $FROM_ENV para $TO_ENV..."

# Usar o script de promoção existente
./scripts/promote.sh $FROM_ENV $TO_ENV

echo "Aguardando builds..."
sleep 300  # 5 minutos

echo "Verificando status..."
for app in "${APPS[@]}"; do
  status=$(argocd app get ${app}-${TO_ENV} -o json | jq -r '.status.sync.status')
  echo "$app-$TO_ENV: $status"
done
```

---

**Dica:** Salve estes exemplos para referência rápida!
