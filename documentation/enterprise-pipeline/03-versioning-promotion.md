# Versioning & Promotion Strategy

## 📋 Visão Geral

Esta seção detalha a estratégia de versionamento semântico e promoção de artefatos entre ambientes, inspirada nas práticas de Spotify, Netflix e Uber.

## 🏷️ Estratégia de Versionamento: CalVer

### Formato: `YYYY.MM.BUILD[-METADATA]`

```
2026.02.1                    ← Build #1 de fevereiro/2026
2026.02.1-a3f2b1c           ← Com commit SHA
2026.02.15                   ← Build #15 do mesmo mês
2026.02.16-hotfix-auth      ← Hotfix identificado
2026.03.1                    ← Novo mês, reset do build
```

### Justificativa Técnica

**Por que CalVer ao invés de SemVer?**

| Critério                 | SemVer (1.2.3)                 | CalVer (2026.02.1)           | Vencedor |
| ------------------------ | ------------------------------ | ---------------------------- | -------- |
| Rastreabilidade temporal | ❌ Não intuitivo               | ✅ Timestamp claro           | CalVer   |
| Troubleshooting          | ❓ "Quando deployamos v1.5.0?" | ✅ "Em fevereiro/2026"       | CalVer   |
| Breaking changes         | ✅ Major version bump          | ❌ Sem distinção clara       | SemVer   |
| Múltiplos serviços       | ❌ Versões dessincronizadas    | ✅ Alinhamento temporal      | CalVer   |
| Hotfix ordering          | ⚠️ Patches podem confundir     | ✅ Incremental claro         | CalVer   |
| Adoção indústria         | Bibliotecas públicas           | SaaS interno (Spotify, Uber) | -        |

**Decisão**: CalVer para nosso SaaS interno, onde rastreabilidade temporal e troubleshooting são mais importantes que API versioning.

### Quando usar SemVer?

Se você tem:

- ✅ Biblioteca pública com consumidores externos
- ✅ API versionada com breaking changes frequentes
- ✅ SDK que clientes dependem

Então use SemVer. **Não é nosso caso**.

---

## 🔢 Geração de Versão

### Automático via GitHub Actions

```yaml
# .github/workflows/_reusable-ci.yml
jobs:
  version:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.generate.outputs.version }}
      full-version: ${{ steps.generate.outputs.full-version }}
    steps:
      - name: Generate CalVer
        id: generate
        run: |
          # CalVer: YYYY.MM.BUILD
          YEAR=$(date +'%Y')
          MONTH=$(date +'%m')
          BUILD=${{ github.run_number }}
          SHORT_SHA=$(git rev-parse --short=7 HEAD)

          VERSION="${YEAR}.${MONTH}.${BUILD}"
          FULL_VERSION="${VERSION}-${SHORT_SHA}"

          echo "version=${VERSION}" >> $GITHUB_OUTPUT
          echo "full-version=${FULL_VERSION}" >> $GITHUB_OUTPUT

          echo "📦 Version: ${VERSION}"
          echo "🔖 Full Version: ${FULL_VERSION}"
```

### Tags Docker Geradas

Cada build gera **múltiplas tags** para diferentes casos de uso:

```dockerfile
# 1. Primary version tag (immutable)
ghcr.io/nexo-org/nexo-be:2026.02.1

# 2. Full version com SHA (debug)
ghcr.io/nexo-org/nexo-be:2026.02.1-a3f2b1c

# 3. SHA-only (para cherry-pick)
ghcr.io/nexo-org/nexo-be:sha-a3f2b1c

# 4. Environment-specific (mutable, usado por ArgoCD)
ghcr.io/nexo-org/nexo-be:develop
ghcr.io/nexo-org/nexo-be:qa
ghcr.io/nexo-org/nexo-be:staging
ghcr.io/nexo-org/nexo-be:production

# 5. PR preview (ephemeral)
ghcr.io/nexo-org/nexo-be:pr-123

# 6. Latest (não recomendado em produção)
ghcr.io/nexo-org/nexo-be:latest
```

### Exemplo de Implementação

```yaml
# Docker metadata action
- name: Docker metadata
  id: meta
  uses: docker/metadata-action@v5
  with:
    images: ghcr.io/${{ github.repository_owner }}/nexo-be
    tags: |
      # Primary: CalVer
      type=raw,value=${{ needs.version.outputs.version }}

      # Full version com SHA
      type=raw,value=${{ needs.version.outputs.version }}-{{sha}}

      # SHA only
      type=sha,prefix=sha-,format=short

      # Environment (apenas main branch)
      type=raw,value=develop,enable=${{ github.ref == 'refs/heads/main' }}

      # PR preview
      type=ref,event=pr,prefix=pr-

      # Latest (edge case)
      type=raw,value=latest,enable=${{ github.ref == 'refs/heads/main' }}

    labels: |
      org.opencontainers.image.title=nexo-be
      org.opencontainers.image.version=${{ needs.version.outputs.version }}
      org.opencontainers.image.created={{date 'YYYY-MM-DDTHH:mm:ssZ'}}
      org.opencontainers.image.revision={{sha}}
      org.opencontainers.image.source={{ctx.server}}/{{ctx.owner}}/{{ctx.repo}}
```

---

## 🔄 Estratégia de Promoção

### Filosofia Core: "Promote Artifacts, Not Code"

```
┌─────────────────────────────────────────────────────────────────────┐
│                         IMMUTABLE ARTIFACTS                          │
├─────────────────────────────────────────────────────────────────────┤
│  Uma vez buildada, a imagem Docker NUNCA muda                       │
│  A mesma imagem (SHA256) é promovida entre ambientes                │
│  Apenas configurações (Helm values) são diferentes                  │
│                                                                      │
│  Garante: "O que funciona em staging, funcionará em prod"           │
└─────────────────────────────────────────────────────────────────────┘
```

### Fluxo de Promoção

```
   CODE PUSH              CI BUILD               GITOPS UPDATE
   (main branch)          (GitHub Actions)       (nexo-gitops repo)
       │                        │                        │
       ▼                        ▼                        ▼
┌──────────────┐      ┌──────────────┐        ┌──────────────┐
│ git push     │      │ Build Image  │        │ Update       │
│ origin main  │ ───► │ v2026.02.1   │ ────►  │ values-dev   │
│              │      │              │        │ .yaml        │
└──────────────┘      └──────────────┘        └──────────────┘
                                                      │
                                                      ▼
                                              ┌──────────────┐
                                              │ ArgoCD Sync  │
                                              │ DEVELOP      │
                                              └──────────────┘
                                                      │
                                 ┌────────────────────┴────────────────────┐
                                 │ Validações em DEVELOP                    │
                                 │ - Health checks OK                       │
                                 │ - Smoke tests passam                     │
                                 │ - Métricas normais (error rate < 1%)    │
                                 │ - Logs sem erros críticos                │
                                 └──────────────────────────────────────────┘
                                                      │
                                                      ▼
                                         ┌─────────────────────┐
                                         │ AUTO-PROMOTE TO QA  │
                                         │ (GitHub Actions)    │
                                         └─────────────────────┘
                                                      │
                                                      ▼
                                              ┌──────────────┐
                                              │ ArgoCD Sync  │
                                              │ QA           │
                                              └──────────────┘
                                                      │
                                 ┌────────────────────┴────────────────────┐
                                 │ Validações em QA                         │
                                 │ - Testes E2E automatizados               │
                                 │ - Performance tests                      │
                                 │ - Security scans                         │
                                 └──────────────────────────────────────────┘
                                                      │
                                                      ▼
                                         ┌─────────────────────┐
                                         │ MANUAL PROMOTION    │
                                         │ TO STAGING          │
                                         │ (via PR approval)   │
                                         └─────────────────────┘
                                                      │
                                                      ▼
                                              ┌──────────────┐
                                              │ ArgoCD Sync  │
                                              │ STAGING      │
                                              └──────────────┘
                                                      │
                                 ┌────────────────────┴────────────────────┐
                                 │ Validações em STAGING                    │
                                 │ - Replica de produção                    │
                                 │ - Load testing                           │
                                 │ - Canary deployment                      │
                                 │ - Soak time: 30 minutos                  │
                                 └──────────────────────────────────────────┘
                                                      │
                                                      ▼
                                         ┌─────────────────────┐
                                         │ MANUAL PROMOTION    │
                                         │ TO PRODUCTION       │
                                         │ (2+ approvals)      │
                                         └─────────────────────┘
                                                      │
                                                      ▼
                                              ┌──────────────┐
                                              │ ArgoCD Sync  │
                                              │ PRODUCTION   │
                                              │ (Blue/Green) │
                                              └──────────────┘
```

---

## 🚀 Matriz de Promoção

| From → To          | Trigger                    | Approval                | Time      | Strategy      | Rollback |
| ------------------ | -------------------------- | ----------------------- | --------- | ------------- | -------- |
| **main → develop** | Auto (push)                | ❌ None                 | ~10min    | RollingUpdate | Auto     |
| **develop → qa**   | Auto (health OK)           | ❌ None                 | ~5min     | RollingUpdate | Auto     |
| **qa → staging**   | Manual (workflow_dispatch) | ✅ 1 Platform Engineer  | On-demand | Blue/Green    | Manual   |
| **staging → prod** | Manual (PR in gitops)      | ✅✅ 2 SREs + Soak time | +30min    | Blue/Green    | Manual   |

---

## 🛠️ Implementação: Auto-Promotion

### Auto-Promote: develop → qa

```yaml
# .github/workflows/auto-promote.yml
name: Auto-Promote to QA

on:
  repository_dispatch:
    types: [deploy-success-develop]

jobs:
  validate-develop:
    name: Validate Develop Health
    runs-on: ubuntu-latest
    steps:
      - name: Wait for health stabilization
        run: sleep 300 # 5 minutos

      - name: Check ArgoCD app health
        run: |
          APP_HEALTH=$(argocd app get nexo-be-develop -o json | jq -r '.status.health.status')

          if [ "$APP_HEALTH" != "Healthy" ]; then
            echo "❌ Develop não está healthy: $APP_HEALTH"
            exit 1
          fi

          echo "✅ Develop is healthy"

      - name: Run smoke tests
        run: |
          # Curl health endpoint
          curl -f https://nexo-be-develop.example.com/health || exit 1

          # Validações básicas
          curl -f https://nexo-be-develop.example.com/api/status || exit 1

      - name: Check error rate (last 5min)
        run: |
          # Query Prometheus
          ERROR_RATE=$(curl -s 'http://prometheus:9090/api/v1/query?query=rate(http_requests_total{status=~"5.."}[5m])' | jq '.data.result[0].value[1]')

          if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
            echo "❌ Error rate too high: $ERROR_RATE"
            exit 1
          fi

          echo "✅ Error rate OK: $ERROR_RATE"

  promote-to-qa:
    name: Promote to QA
    runs-on: ubuntu-latest
    needs: validate-develop
    steps:
      - name: Checkout GitOps repo
        uses: actions/checkout@v4
        with:
          repository: nexo-org/nexo-gitops
          token: ${{ secrets.GITOPS_PAT }}

      - name: Get current develop version
        id: version
        run: |
          VERSION=$(yq eval '.image.tag' helm/nexo-be/values-develop.yaml)
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "🔖 Promoting version: $VERSION"

      - name: Update QA values
        run: |
          VERSION="${{ steps.version.outputs.version }}"
          yq eval ".image.tag = \"${VERSION}\"" -i helm/nexo-be/values-qa.yaml

          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add helm/nexo-be/values-qa.yaml
          git commit -m "auto-promote(nexo-be): qa → ${VERSION}

          Auto-promoted from develop after health checks passed"
          git push origin main

      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "✅ Auto-promoted nexo-be to QA: ${{ steps.version.outputs.version }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 🎯 Manual Promotion: staging → production

### Via Pull Request (GitOps)

```bash
# 1. Engineer cria branch de promoção
cd nexo-gitops
git checkout -b promote/nexo-be-prod-2026.02.1

# 2. Atualiza values-prod.yaml
yq eval '.image.tag = "2026.02.1"' -i helm/nexo-be/values-prod.yaml

# 3. Commit e push
git add helm/nexo-be/values-prod.yaml
git commit -m "promote(nexo-be): production → 2026.02.1

## Changelog
- Fix: Authentication timeout issue
- Feat: Add rate limiting
- Perf: Optimize database queries

## Validation
- ✅ Staging deployed for 24h without issues
- ✅ Load test passed (1000 RPS)
- ✅ Security scan: 0 HIGH/CRITICAL vulns
- ✅ Rollback plan tested

## Rollback Plan
1. Revert this PR
2. OR: Set image.tag = \"2026.01.45\" (previous version)

Reviewed-by: @alice-sre @bob-platform"

git push origin promote/nexo-be-prod-2026.02.1

# 4. Abrir PR no GitHub
gh pr create \
  --title "promote(nexo-be): production → 2026.02.1" \
  --body "See commit message for details" \
  --label "production-deploy" \
  --reviewer alice-sre,bob-platform
```

### CODEOWNERS para Aprovações

```
# .github/CODEOWNERS no nexo-gitops repo

# Production values requerem 2 aprovadores
helm/*/values-prod.yaml @nexo-sre-team @nexo-platform-leads

# Staging requer 1 aprovador
helm/*/values-staging.yaml @nexo-platform-team

# Develop e QA: auto-merge permitido
helm/*/values-develop.yaml
helm/*/values-qa.yaml
```

---

## 🔄 Rollback Strategies

### Estratégia por Ambiente

```yaml
┌────────────┬─────────────────┬────────────────┬───────────────┐
│ Environment│ Rollback Method │ Target Time    │ Trigger       │
├────────────┼─────────────────┼────────────────┼───────────────┤
│ develop    │ Auto (ArgoCD)   │ <2min          │ Health check  │
│ qa         │ Auto (ArgoCD)   │ <2min          │ Health check  │
│ staging    │ Manual (CLI)    │ <5min          │ Manual        │
│ production │ Manual (PR)     │ <10min         │ Manual/Alert  │
└────────────┴─────────────────┴────────────────┴───────────────┘
```

### Rollback em Produção (Blue/Green)

```bash
# Opção 1: Switch back via Ingress (instantâneo)
kubectl patch ingress nexo-be-ingress -n nexo-production \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/name", "value": "nexo-be-blue"}]'

# Opção 2: Rollback via ArgoCD
argocd app rollback nexo-be-production --revision 45

# Opção 3: Revert PR no GitOps (auditável, recomendado)
cd nexo-gitops
git revert HEAD
git push origin main
# ArgoCD detecta e aplica automaticamente
```

---

## 📊 Tracking de Versões

### Dashboard de Promoção

```
┌─────────────────────────────────────────────────────────────────────┐
│                      NEXO-BE VERSION MATRIX                          │
├─────────────┬─────────────┬────────────────┬───────────────────────┤
│ Environment │ Version     │ Deployed At    │ Health                │
├─────────────┼─────────────┼────────────────┼───────────────────────┤
│ develop     │ 2026.02.17  │ 2h ago         │ ✅ Healthy            │
│ qa          │ 2026.02.15  │ 6h ago         │ ✅ Healthy            │
│ staging     │ 2026.02.10  │ 2 days ago     │ ✅ Healthy            │
│ production  │ 2026.01.45  │ 1 week ago     │ ✅ Healthy            │
└─────────────┴─────────────┴────────────────┴───────────────────────┘

Drift Alert: production is 28 versions behind develop (🟡 Medium Risk)
```

### Script de Comparação

```bash
#!/bin/bash
# scripts/version-diff.sh

ENVIRONMENTS=("develop" "qa" "staging" "production")
SERVICE=$1

echo "Version matrix for $SERVICE:"
echo "---"

for env in "${ENVIRONMENTS[@]}"; do
  VERSION=$(yq eval '.image.tag' helm/$SERVICE/values-$env.yaml)
  echo "$env: $VERSION"
done

# Calcular drift
DEVELOP_VER=$(yq eval '.image.tag' helm/$SERVICE/values-develop.yaml)
PROD_VER=$(yq eval '.image.tag' helm/$SERVICE/values-production.yaml)

DEVELOP_BUILD=$(echo $DEVELOP_VER | cut -d. -f3)
PROD_BUILD=$(echo $PROD_VER | cut -d. -f3)

DRIFT=$((DEVELOP_BUILD - PROD_BUILD))

echo "---"
echo "Drift: $DRIFT versions"

if [ $DRIFT -gt 20 ]; then
  echo "⚠️  High drift detected! Consider promoting to production"
fi
```

---

## 🔐 Auditoria de Promoção

### Git History = Audit Log

```bash
# Ver histórico de deploys em produção
cd nexo-gitops
git log --oneline --follow helm/nexo-be/values-prod.yaml

# Output:
# a3f2b1c promote(nexo-be): production → 2026.02.1
# b5d8e9f promote(nexo-be): production → 2026.01.45
# c7f1a3d promote(nexo-be): production → 2026.01.32
```

### Structured Audit Log (opcional)

```json
// audit-logs/2026-02-01-nexo-be-prod.json
{
  "event": "promotion",
  "service": "nexo-be",
  "version": "2026.02.1",
  "from_environment": "staging",
  "to_environment": "production",
  "timestamp": "2026-02-01T10:30:00Z",
  "initiator": "alice@nexo.com",
  "approvers": ["bob@nexo.com", "charlie@nexo.com"],
  "pr_url": "https://github.com/nexo-org/nexo-gitops/pull/123",
  "argocd_sync_id": "abc123",
  "rollback": false,
  "validation_results": {
    "smoke_tests": "passed",
    "load_test": "passed",
    "security_scan": "passed"
  }
}
```

---

## 🎯 SLOs de Promoção

```yaml
# Service Level Objectives
promotion_slos:
  develop:
    target_time: 10min
    success_rate: 99%

  qa:
    target_time: 15min
    success_rate: 98%

  staging:
    target_time: 30min
    success_rate: 98%

  production:
    target_time: 60min # Inclui soak time
    success_rate: 99.9%
    rollback_rate: <5%
```

---

**Próximo**: [Security & Secrets Management](04-security-secrets.md)
