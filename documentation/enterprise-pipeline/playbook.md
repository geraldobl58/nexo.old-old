# Playbook - Cenários Práticos

## 📋 Visão Geral

Este documento contém **exemplos práticos e executáveis** para cenários comuns de deploy, troubleshooting e operações da pipeline.

---

## 🚀 Cenário 1: Deploy de Nova Feature

### Contexto

Você desenvolveu uma nova funcionalidade no `nexo-be` e quer deployar em produção.

### Passo a Passo

```bash
# 1. Criar feature branch
git checkout main
git pull origin main
git checkout -b feature/add-payment-webhooks

# 2. Desenvolver e testar localmente
# ... código, testes ...

# 3. Commit com Conventional Commits
git add .
git commit -m "feat(nexo-be): adiciona webhook de pagamentos

- Implementa endpoint POST /webhooks/stripe
- Adiciona validação de signature
- Testes unitários e integração

Closes #123"

# 4. Push e abrir PR
git push origin feature/add-payment-webhooks
gh pr create \
  --title "feat(nexo-be): adiciona webhook de pagamentos" \
  --body "Ver detalhes no commit message" \
  --label "feature" \
  --assignee @me

# 5. Aguardar CI passar
# GitHub Actions roda automaticamente:
# - Lint (ESLint, Prettier)
# - Tests (Jest)
# - Security scan (Semgrep, Trivy)
# - Build check

# 6. Code review
# Aguardar aprovação de 1+ reviewer (CODEOWNERS)

# 7. Merge para main
gh pr merge --squash

# 8. Acompanhar deploy
# CI roda novamente em main:
# - Build imagem: ghcr.io/nexo-org/nexo-be:2026.02.17
# - Push para registry
# - Update GitOps repo: values-develop.yaml

# 9. Verificar deploy em develop
argocd app get nexo-be-develop

# Ou via kubectl
kubectl get pods -n nexo-develop -l app=nexo-be
kubectl logs -n nexo-develop -l app=nexo-be --tail=100

# 10. Validar em develop
curl https://nexo-be-develop.example.com/health
curl https://nexo-be-develop.example.com/webhooks/stripe -X POST \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# 11. Aguardar auto-promotion para QA (5min)
# GitHub Actions roda workflow auto-promote.yml

# 12. Validar em QA
curl https://nexo-be-qa.example.com/health

# 13. Promover para staging (manual)
cd nexo-gitops
git checkout -b promote/nexo-be-staging-2026.02.17

yq eval '.image.tag = "2026.02.17"' -i helm/nexo-be/values-staging.yaml

git add helm/nexo-be/values-staging.yaml
git commit -m "promote(nexo-be): staging → 2026.02.17"
gh pr create --reviewer @nexo-platform-team

# 14. Após aprovação e merge
argocd app sync nexo-be-staging

# 15. Validar em staging (30min soak time)
# Rodar load tests, smoke tests, etc.

# 16. Promover para produção (manual)
cd nexo-gitops
git checkout -b promote/nexo-be-prod-2026.02.17

yq eval '.image.tag = "2026.02.17"' -i helm/nexo-be/values-prod.yaml

git add helm/nexo-be/values-prod.yaml
git commit -m "promote(nexo-be): production → 2026.02.17

## Changelog
- feat: Webhook de pagamentos Stripe
- fix: Validação de signature
- perf: Otimização de queries

## Validation
- ✅ Staging stable for 24h
- ✅ Load test: 1000 RPS sustained
- ✅ Security scan: 0 CRITICAL/HIGH
- ✅ Rollback plan documented

## Rollback Plan
1. Revert this PR
2. OR: argocd app rollback nexo-be-production
3. Previous version: 2026.02.10

Reviewed-by: @alice-sre @bob-sre"

gh pr create --reviewer @nexo-sre-team --label production-deploy

# 17. Após 2+ aprovações, merge e sync
# Merge PR
argocd app sync nexo-be-production

# 18. Monitor produção intensivamente (30min)
watch -n 10 'argocd app get nexo-be-production'

# Verificar métricas no Grafana
# Verificar logs no Loki
# Verificar traces no Jaeger

# 19. ✅ Deploy concluído!
```

---

## 🔥 Cenário 2: Hotfix Crítico em Produção

### Contexto

Bug crítico detectado em produção, precisa de fix imediato.

### Passo a Passo

```bash
# 1. Criar branch de hotfix (direto de main)
git checkout main
git pull origin main
git checkout -b hotfix/fix-auth-timeout

# 2. Implementar fix mínimo
# ... código ...

# 3. Commit e push
git add .
git commit -m "fix(nexo-be): corrige timeout de autenticação

Bug: Usuários não conseguiam fazer login após 30s
Root cause: Connection pool esgotado
Fix: Aumenta pool de 10 para 50 conexões

URGENT: Afeta 100% dos usuários"

git push origin hotfix/fix-auth-timeout

# 4. Abrir PR com label urgente
gh pr create \
  --title "HOTFIX: corrige timeout de autenticação" \
  --label "hotfix,P0" \
  --reviewer @nexo-sre-team \
  --assignee @me

# 5. Fast-track review (15min SLA)
# SRE aprova rapidamente após validação

# 6. Merge para main
gh pr merge --squash

# 7. CI builda nova imagem
# Tag: 2026.02.17-hotfix (incremental)

# 8. Deploy direto para produção (skip develop/qa/staging)
cd nexo-gitops
git checkout -b hotfix/prod-2026.02.17-hotfix

yq eval '.image.tag = "2026.02.17"' -i helm/nexo-be/values-prod.yaml

git add helm/nexo-be/values-prod.yaml
git commit -m "hotfix(nexo-be): production → 2026.02.17 (auth timeout fix)

URGENT: P0 incident #456
Fix: Connection pool exhaustion
Approved by: @alice-sre @bob-sre"

git push origin hotfix/prod-2026.02.17-hotfix

# 9. Merge sem aguardar CI (override em emergência)
gh pr merge --admin --squash

# 10. Sync imediato
argocd app sync nexo-be-production

# 11. Monitor recovery
watch -n 5 'kubectl get pods -n nexo-production -l app=nexo-be'

# Verificar error rate
curl -s 'http://prometheus:9090/api/v1/query?query=rate(http_requests_errors_total[1m])' | jq

# 12. Validar fix
curl https://api.nexo.com/health
# Response time deve cair de 30s+ para <100ms

# 13. Backfill para ambientes anteriores
# Promover mesma versão para staging, qa, develop
# (Reverso do fluxo normal, pois hotfix foi direto em prod)

# 14. Post-incident
# - Update #incidents: "RESOLVED"
# - Schedule post-mortem (48h)
# - Criar GitHub issue para preventive measures
```

---

## 🔄 Cenário 3: Rollback de Produção

### Contexto

Deploy em produção causou degradação, precisa reverter.

### Opção 1: Rollback via ArgoCD (Rápido)

```bash
# 1. Listar histórico
argocd app history nexo-be-production

# Output:
# ID  DATE                   REVISION
# 10  2026-02-01T10:30:00Z   a3f2b1c (v2026.02.17)  ← ATUAL (problemática)
# 9   2026-01-28T15:20:00Z   b5d8e9f (v2026.02.10)  ← STABLE
# 8   2026-01-25T09:10:00Z   c7f1a3d (v2026.02.05)

# 2. Rollback para revisão anterior
argocd app rollback nexo-be-production 9

# 3. Verificar sync
argocd app get nexo-be-production
# Revision: b5d8e9f
# Health Status: Healthy

# 4. Monitor recovery (2-5min)
watch -n 5 'kubectl get pods -n nexo-production -l app=nexo-be'

# 5. Validar métricas
# Error rate deve normalizar
# Latency deve cair
```

### Opção 2: Rollback via GitOps (Auditável)

```bash
# 1. Revert PR no GitOps repo
cd nexo-gitops
git log --oneline helm/nexo-be/values-prod.yaml

# a3f2b1c promote(nexo-be): production → 2026.02.17  ← REVERT ESTE
# b5d8e9f promote(nexo-be): production → 2026.02.10

# 2. Criar revert
git revert a3f2b1c --no-edit

# Ou manualmente:
git checkout -b rollback/nexo-be-prod-2026.02.10
yq eval '.image.tag = "2026.02.10"' -i helm/nexo-be/values-prod.yaml

git add helm/nexo-be/values-prod.yaml
git commit -m "rollback(nexo-be): production → 2026.02.10

Reason: v2026.02.17 caused high error rate (5%)
Incident: #789
Approved by: @alice-sre"

# 3. Push e merge (fast-track)
git push origin rollback/nexo-be-prod-2026.02.10
gh pr create --reviewer @nexo-sre-team
gh pr merge --admin --squash

# 4. ArgoCD detecta automaticamente (ou sync manual)
argocd app sync nexo-be-production

# 5. Validar recovery
```

### Opção 3: Blue/Green Switch (Instantâneo)

```bash
# Se Blue/Green deployment está configurado:

# 1. Identificar deployment ativo
kubectl get ingress nexo-be-ingress -n nexo-production -o yaml

# spec:
#   rules:
#   - http:
#       paths:
#       - backend:
#           service:
#             name: nexo-be-green  ← ATUAL (problemático)

# 2. Switch para Blue (versão anterior)
kubectl patch ingress nexo-be-ingress -n nexo-production \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/name", "value": "nexo-be-blue"}]'

# 3. Validar instantaneamente
curl https://api.nexo.com/health
# Agora aponta para nexo-be-blue (versão estável)

# Rollback em < 10 segundos! ✅
```

---

## 🔍 Cenário 4: Troubleshooting de Deploy Failure

### Contexto

Deploy falhou, precisa investigar e corrigir.

```bash
# 1. Verificar status do Application
argocd app get nexo-be-staging

# Output:
# Health Status:       Degraded
# Sync Status:         Synced
# Last Sync:           2026-02-01T10:30:00Z
# Conditions:          ComparisonError: Failed to load target state

# 2. Ver logs do ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=100

# 3. Verificar eventos do namespace
kubectl get events -n nexo-staging --sort-by='.lastTimestamp'

# 4. Verificar pods
kubectl get pods -n nexo-staging -l app=nexo-be

# Output:
# NAME                       READY   STATUS             RESTARTS   AGE
# nexo-be-5d8f9c7b6d-abc12   0/1     ImagePullBackOff   0          2m

# 5. Descrever pod com problema
kubectl describe pod nexo-be-5d8f9c7b6d-abc12 -n nexo-staging

# Events:
#   Failed to pull image "ghcr.io/nexo-org/nexo-be:2026.02.99": not found

# 6. PROBLEMA: Imagem não existe!
# Verificar no GHCR
gh api /orgs/nexo-org/packages/container/nexo-be/versions

# 7. SOLUÇÃO: Corrigir tag no values
cd nexo-gitops
git checkout -b fix/nexo-be-staging-image-tag

yq eval '.image.tag = "2026.02.17"' -i helm/nexo-be/values-staging.yaml

git add helm/nexo-be/values-staging.yaml
git commit -m "fix(nexo-be): corrige image tag em staging

Erro: Tag 2026.02.99 não existe
Correção: Usa tag correta 2026.02.17"

git push origin fix/nexo-be-staging-image-tag
gh pr create --reviewer @nexo-platform-team
gh pr merge --squash

# 8. Sync novamente
argocd app sync nexo-be-staging

# 9. Validar correção
kubectl get pods -n nexo-staging -l app=nexo-be
# NAME                       READY   STATUS    RESTARTS   AGE
# nexo-be-5d8f9c7b6d-xyz34   1/1     Running   0          30s

# ✅ Corrigido!
```

---

## 📊 Cenário 5: Investigar Incidente (High Error Rate)

### Contexto

Alert disparou: error rate > 1% em produção.

```bash
# 1. Verificar dashboard do Grafana
# URL: https://grafana.nexo.com/d/nexo-be-prod

# 2. Identificar quando começou
# Gráfico mostra spike às 10:30 UTC

# 3. Verificar deploys recentes
argocd app history nexo-be-production

# Output:
# ID  DATE                   REVISION
# 10  2026-02-01T10:25:00Z   a3f2b1c  ← DEPLOY 5min antes do spike!

# 4. Checar logs de erro
# Loki query:
{namespace="nexo-production", service="nexo-be", level="error"}
  | json
  | line_format "{{.timestamp}} | {{.error}} | {{.trace_id}}"

# Output:
# 2026-02-01T10:31:15Z | Database connection timeout | trace-abc123
# 2026-02-01T10:31:20Z | Database connection timeout | trace-def456
# 2026-02-01T10:31:25Z | Database connection timeout | trace-ghi789

# 5. PROBLEMA: Database connection pool!

# 6. Ver configuração atual
kubectl get configmap nexo-be-config -n nexo-production -o yaml

# database:
#   pool:
#     max: 10  ← POOL PEQUENO!

# 7. Investigar traces (Jaeger)
# Query: service=nexo-be operation=db.query
# Durations: 30s+ (timeout)

# 8. DECISÃO: Rollback + hotfix

# Rollback imediato
argocd app rollback nexo-be-production 9

# 9. Criar hotfix com pool maior
# (Ver Cenário 2: Hotfix)

# 10. Documentar incident
cat > incidents/2026-02-01-high-error-rate.md <<EOF
# Incident: High Error Rate - nexo-be Production

## Timeline
- 10:25 UTC: Deploy v2026.02.17
- 10:31 UTC: Error rate spike (5%)
- 10:35 UTC: Alert fired
- 10:37 UTC: Rollback initiated
- 10:40 UTC: Service recovered

## Root Cause
Database connection pool too small (10 connections)
New feature increased concurrent DB queries

## Resolution
1. Rollback to v2026.02.10
2. Hotfix: Increase pool to 50 connections
3. Deploy v2026.02.18 with fix

## Prevention
- [ ] Add load testing to staging
- [ ] Monitor connection pool usage
- [ ] Update runbook with pool sizing guide

## Lessons Learned
- Connection pool size não foi testado em staging
- Alerting funcionou perfeitamente (detected in 4min)
- Rollback foi rápido (recovery in 9min)
EOF

git add incidents/2026-02-01-high-error-rate.md
git commit -m "docs: post-mortem do incident de 2026-02-01"
```

---

## 🔐 Cenário 6: Rotacionar Secrets

### Contexto

Precisa rotacionar database password (compromised ou política de 30 dias).

```bash
# 1. Gerar novo password
NEW_PASSWORD=$(openssl rand -base64 32)

# 2. Atualizar no AWS Secrets Manager
aws secretsmanager update-secret \
  --secret-id nexo/production/database \
  --secret-string "{
    \"host\": \"prod-db.example.com\",
    \"port\": \"5432\",
    \"database\": \"nexo_prod\",
    \"username\": \"nexo_user\",
    \"password\": \"${NEW_PASSWORD}\"
  }"

# 3. Atualizar password no banco
PGPASSWORD=$OLD_PASSWORD psql \
  -h prod-db.example.com \
  -U nexo_user \
  -d nexo_prod \
  -c "ALTER USER nexo_user PASSWORD '${NEW_PASSWORD}';"

# 4. External Secrets Operator sincroniza automaticamente (15min)
# Ou forçar refresh:
kubectl annotate externalsecret nexo-be-db-credentials \
  -n nexo-production \
  force-sync="$(date +%s)" \
  --overwrite

# 5. Verificar secret atualizado
kubectl get secret nexo-be-db-credentials -n nexo-production -o jsonpath='{.data.password}' | base64 -d
# Deve mostrar o novo password

# 6. Pods detectam mudança e reconectam automaticamente
# (Se configurado com hot-reload)

# Ou restart pods:
kubectl rollout restart deployment nexo-be -n nexo-production

# 7. Validar conectividade
kubectl logs -n nexo-production -l app=nexo-be --tail=10
# Deve mostrar "Database connected successfully"

# 8. ✅ Rotation completa!
```

---

## 📈 Cenário 7: Analisar DORA Metrics

### Contexto

Time quer entender velocidade de deploy e qualidade.

```bash
# 1. Rodar script de cálculo de DORA metrics
cd nexo-gitops/scripts

./calculate-dora.sh nexo-be production \
  --start-date 2026-01-01 \
  --end-date 2026-02-01

# Output:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DORA Metrics - nexo-be production (Jan 2026)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# Deployment Frequency:    2.3 deploys/day   ✅ Elite
# Lead Time for Changes:   45 minutes         ✅ Elite
# Time to Restore Service: 18 minutes         ✅ Elite
# Change Failure Rate:     3.2%               ✅ Elite
#
# Overall Performance:     🏆 ELITE PERFORMER
#
# Top 5 Fastest Deploys:
# 1. v2026.01.15  (commit → prod: 22 minutes)
# 2. v2026.01.23  (commit → prod: 28 minutes)
# 3. v2026.01.08  (commit → prod: 35 minutes)
# ...

# 2. Analisar tendências no Grafana
# Dashboard: "DORA Metrics - Executive View"

# 3. Identificar oportunidades de melhoria
# - Lead time: Pode reduzir CI duration?
# - Failure rate: Quais tipos de falha são comuns?
```

---

## 🎓 Comandos Úteis (Cheat Sheet)

```bash
# ArgoCD
argocd app list                                    # Listar applications
argocd app get nexo-be-production                  # Status detalhado
argocd app sync nexo-be-production                 # Forçar sync
argocd app rollback nexo-be-production 9           # Rollback
argocd app history nexo-be-production              # Histórico
argocd app diff nexo-be-production                 # Ver diferenças

# Kubectl
kubectl get pods -n nexo-production -l app=nexo-be
kubectl logs -n nexo-production -l app=nexo-be --tail=100 -f
kubectl describe pod <pod-name> -n nexo-production
kubectl exec -it <pod-name> -n nexo-production -- /bin/sh
kubectl port-forward -n nexo-production svc/nexo-be 8080:8080

# GitOps
cd nexo-gitops
yq eval '.image.tag' helm/nexo-be/values-prod.yaml    # Ver versão atual
git log --oneline helm/nexo-be/values-prod.yaml       # Histórico de deploys

# Metrics
curl 'http://prometheus:9090/api/v1/query?query=http_requests_total'
curl 'http://prometheus:9090/api/v1/query_range?query=rate(http_requests_total[5m])&start=2026-02-01T00:00:00Z&end=2026-02-01T23:59:59Z&step=1m'

# Logs (Loki CLI)
logcli query '{namespace="nexo-production", level="error"}'
logcli query '{namespace="nexo-production", trace_id="abc123"}'

# GitHub CLI
gh pr list --label production-deploy
gh pr create --reviewer @nexo-sre-team
gh workflow run promote.yml -f service=nexo-be -f version=2026.02.17
```

---

**Dica**: Bookmark este playbook! É sua referência rápida para operações do dia-a-dia.
