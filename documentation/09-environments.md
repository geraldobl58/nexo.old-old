# 🌍 Ambientes

Guia completo sobre os ambientes de deploy e estratégia multi-ambiente.

## 🎯 Estratégia de Ambientes

O projeto usa **4 ambientes isolados** em Kubernetes:

```
Development → QA → Staging → Production
    ↓         ↓      ↓         ↓
  develop   develop  main     main
   branch   branch  branch   branch
```

## 📊 Tabela de Ambientes

| Ambiente        | Branch    | Namespace      | Domain               | Auto-sync | Objetivo                 |
| --------------- | --------- | -------------- | -------------------- | --------- | ------------------------ |
| **Development** | `develop` | `nexo-develop` | `develop.nexo.local` | ✅ Sim    | Desenvolvimento contínuo |
| **QA**          | `develop` | `nexo-qa`      | `qa.nexo.local`      | ✅ Sim    | Testes automatizados     |
| **Staging**     | `main`    | `nexo-staging` | `staging.nexo.local` | ⚠️ Manual | Validação pré-produção   |
| **Production**  | `main`    | `nexo-prod`    | `nexo.com`           | ❌ Manual | Ambiente de produção     |

## 🚀 Development

### Características

- **Branch:** `develop`
- **Namespace:** `nexo-develop`
- **Auto-sync:** Habilitado
- **Deploy:** Automático a cada push
- **Recursos:** Baixos (dev/test)
- **Monitoramento:** Básico

### Configuração

```yaml
# local/helm/nexo-be/values-develop.yaml
replicaCount: 1

image:
  repository: ghcr.io/geraldobl58/nexo-be
  tag: develop-abc123
  pullPolicy: Always

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: develop.api.nexo.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 50m
    memory: 64Mi

env:
  - name: NODE_ENV
    value: development
  - name: LOG_LEVEL
    value: debug
  - name: DATABASE_URL
    value: postgresql://nexo:password@postgres-develop:5432/nexo_dev
```

### URLs

- Frontend: http://develop.nexo.local
- Backend: http://develop.api.nexo.local
- Auth: http://develop.auth.nexo.local

### Uso

```bash
# Deploy automático
git checkout develop
git add .
git commit -m "feat: nova funcionalidade"
git push origin develop

# CI/CD Pipeline
# 1. Build images → nexo-be:develop-abc123
# 2. Push to GHCR
# 3. Update values-develop.yaml
# 4. ArgoCD auto-sync
# 5. Deploy em ~2 minutos

# Verificar
kubectl get pods -n nexo-develop
argocd app get nexo-be-develop
```

## 🧪 QA (Quality Assurance)

### Características

- **Branch:** `develop`
- **Namespace:** `nexo-qa`
- **Auto-sync:** Habilitado
- **Deploy:** Automático após develop
- **Recursos:** Médios (testes)
- **Monitoramento:** Completo

### Configuração

```yaml
# local/helm/nexo-be/values-qa.yaml
replicaCount: 2

image:
  repository: ghcr.io/geraldobl58/nexo-be
  tag: develop-abc123
  pullPolicy: Always

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: qa.api.nexo.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 300m
    memory: 384Mi
  requests:
    cpu: 100m
    memory: 128Mi

env:
  - name: NODE_ENV
    value: test
  - name: LOG_LEVEL
    value: info
  - name: DATABASE_URL
    value: postgresql://nexo:password@postgres-qa:5432/nexo_qa
```

### URLs

- Frontend: http://qa.nexo.local
- Backend: http://qa.api.nexo.local
- Auth: http://qa.auth.nexo.local

### Uso

```bash
# Promover de develop para QA
./scripts/promote.sh develop qa

# Testes E2E automáticos
npm run test:e2e -- --baseUrl=http://qa.nexo.local

# Validar
curl http://qa.api.nexo.local/health
```

### Testes Automatizados

```yaml
# .github/workflows/qa-tests.yml
name: QA Tests

on:
  deployment_status:

jobs:
  e2e-tests:
    if: github.event.deployment_status.state == 'success' && github.event.deployment_status.environment == 'qa'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run E2E tests
        run: |
          npm install
          npm run test:e2e -- --baseUrl=http://qa.nexo.local

      - name: Run API tests
        run: |
          newman run tests/postman-collection.json \
            --environment tests/qa-environment.json

      - name: Performance tests
        run: |
          k6 run tests/load-test.js
```

## 🎭 Staging

### Características

- **Branch:** `main`
- **Namespace:** `nexo-staging`
- **Auto-sync:** Desabilitado (manual)
- **Deploy:** Manual após aprovação
- **Recursos:** Próximos de produção
- **Monitoramento:** Completo + APM

### Configuração

```yaml
# local/helm/nexo-be/values-staging.yaml
replicaCount: 2

image:
  repository: ghcr.io/geraldobl58/nexo-be
  tag: main-xyz789
  pullPolicy: IfNotPresent

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging
  hosts:
    - host: staging.api.nexo.local
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: staging-nexo-tls
      hosts:
        - staging.api.nexo.local

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70

env:
  - name: NODE_ENV
    value: production
  - name: LOG_LEVEL
    value: info
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: nexo-be-staging
        key: database-url
```

### URLs

- Frontend: http://staging.nexo.local
- Backend: http://staging.api.nexo.local
- Auth: http://staging.auth.nexo.local

### Processo de Deploy

```bash
# 1. Merge develop → main
git checkout main
git merge develop
git push origin main

# 2. CI/CD build
# - Build images: main-xyz789
# - Push to GHCR
# - Update values-staging.yaml

# 3. Deploy manual (aprovação)
argocd app sync nexo-be-staging --prune

# 4. Validação
./scripts/validate-deploy.sh staging

# 5. Smoke tests
curl http://staging.api.nexo.local/health
curl http://staging.api.nexo.local/api/v1/users

# 6. Aprovar para produção (se OK)
```

### Validações

```bash
#!/bin/bash
# scripts/validate-deploy.sh staging

NAMESPACE="nexo-staging"
API_URL="http://staging.api.nexo.local"

echo "🔍 Validando deploy em $NAMESPACE..."

# Health check
echo "✓ Health check..."
curl -sf "$API_URL/health" || exit 1

# Pods running
echo "✓ Verificando pods..."
PODS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=nexo-be -o json | jq '.items | length')
if [ "$PODS" -lt 2 ]; then
  echo "❌ Menos de 2 pods rodando"
  exit 1
fi

# Metrics
echo "✓ Verificando métricas..."
curl -sf "$API_URL/metrics" | grep "http_requests_total" || exit 1

# Database connectivity
echo "✓ Testando database..."
curl -sf "$API_URL/api/v1/health/db" || exit 1

echo "✅ Validação completa!"
```

## 🏭 Production

### Características

- **Branch:** `main`
- **Namespace:** `nexo-prod`
- **Auto-sync:** Desabilitado (manual + aprovação)
- **Deploy:** Manual com múltiplas validações
- **Recursos:** Altos (HA, scaling)
- **Monitoramento:** 24/7 + alertas

### Configuração

```yaml
# local/helm/nexo-be/values-prod.yaml
replicaCount: 3

image:
  repository: ghcr.io/geraldobl58/nexo-be
  tag: v1.0.0
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: ghcr-secret

strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: api.nexo.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: nexo-prod-tls
      hosts:
        - api.nexo.com

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

podDisruptionBudget:
  enabled: true
  minAvailable: 2

livenessProbe:
  httpGet:
    path: /health
    port: 3333
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health
    port: 3333
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3

env:
  - name: NODE_ENV
    value: production
  - name: LOG_LEVEL
    value: warn
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: nexo-be-prod
        key: database-url
  - name: REDIS_URL
    valueFrom:
      secretKeyRef:
        name: nexo-be-prod
        key: redis-url

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
  prometheusRule:
    enabled: true
```

### URLs

- Frontend: https://nexo.com
- Backend: https://api.nexo.com
- Auth: https://auth.nexo.com

### Processo de Deploy

```bash
# 1. Tag release
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# 2. CI/CD build release
# - Build images: v1.0.0 + latest
# - Push to GHCR
# - Create GitHub Release

# 3. Promover staging → prod (manual)
./scripts/promote.sh staging prod

# 4. Validação staging
./scripts/validate-deploy.sh staging

# 5. Deploy em produção (aprovação)
argocd app sync nexo-be-prod --prune

# 6. Monitorar deploy
watch kubectl get pods -n nexo-prod

# 7. Health check
./scripts/validate-deploy.sh prod

# 8. Smoke tests produção
curl https://api.nexo.com/health
curl https://api.nexo.com/metrics

# 9. Monitorar métricas
# - Grafana: http://grafana.local.nexo.app
# - Prometheus: http://prometheus.local.nexo.app
# - Alertmanager: http://alertmanager.local.nexo.app

# 10. Notificação Discord
# ✅ Deploy v1.0.0 em produção concluído
```

### Blue-Green Deployment (Futuro)

```yaml
# ArgoCD Rollout
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: nexo-be-prod
spec:
  replicas: 3
  strategy:
    blueGreen:
      activeService: nexo-be-active
      previewService: nexo-be-preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 300
```

## 🔄 Fluxo de Promoção

### 1. Development → QA

**Automático** após push em `develop`

```bash
git checkout develop
git push origin develop
# CI/CD → Build → Deploy develop + QA
```

### 2. QA → Staging

**Manual** após validação QA

```bash
# Merge develop → main
git checkout main
git pull origin main
git merge develop
git push origin main

# Promote
./scripts/promote.sh qa staging

# Deploy manual
argocd app sync nexo-staging
```

### 3. Staging → Production

**Manual** com aprovação

```bash
# Tag release
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Promote (após validação staging)
./scripts/promote.sh staging prod

# Deploy manual com validação
argocd app sync nexo-prod
./scripts/validate-deploy.sh prod
```

## 🎯 Ambiente Comparison

```
┌───────────────┬──────────┬──────────┬──────────┬──────────┐
│   Feature     │  Develop │    QA    │ Staging  │   Prod   │
├───────────────┼──────────┼──────────┼──────────┼──────────┤
│ Auto Deploy   │    ✅    │    ✅    │    ❌    │    ❌    │
│ Replicas      │     1    │     2    │     2    │     3+   │
│ Autoscaling   │    ❌    │    ❌    │    ✅    │    ✅    │
│ SSL/TLS       │    ❌    │    ❌    │    ✅    │    ✅    │
│ Monitoring    │  Basic   │   Full   │   Full   │ 24/7+APM │
│ Alerts        │    ❌    │    ⚠️    │    ✅    │    ✅    │
│ Backup        │    ❌    │    ❌    │   Daily  │  Hourly  │
│ DR Plan       │    ❌    │    ❌    │    ⚠️    │    ✅    │
│ SLA           │    -     │    -     │  99.9%   │  99.99%  │
└───────────────┴──────────┴──────────┴──────────┴──────────┘
```

## 🔧 Gerenciamento de Secrets

### Development

```bash
# Plain secrets (local)
kubectl create secret generic nexo-be-develop \
  --from-literal=database-url='postgresql://...' \
  -n nexo-develop
```

### Production

```bash
# Sealed Secrets (encrypted)
kubectl create secret generic nexo-be-prod \
  --from-literal=database-url='postgresql://...' \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > nexo-be-prod-sealed.yaml

kubectl apply -f nexo-be-prod-sealed.yaml -n nexo-prod
```

## 📊 Monitoramento por Ambiente

### Dashboards

```
http://grafana.local.nexo.app/d/nexo-overview

Filtros:
- Environment: develop | qa | staging | prod
- Namespace: nexo-develop | nexo-qa | nexo-staging | nexo-prod
- App: nexo-be | nexo-fe | nexo-auth
```

### Alertas

```yaml
# Prometheus Alert
groups:
  - name: prod-alerts
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: |
          rate(http_requests_total{namespace="nexo-prod",status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
          environment: production
        annotations:
          summary: "Alta taxa de erros em produção"
          description: "{{ $value }}% de erros nos últimos 5 minutos"
```

## 💡 Boas Práticas

### 1. Isolamento

```yaml
# Cada ambiente = namespace isolado
- Recursos separados
- Secrets separados
- RBAC por namespace
- Network policies
```

### 2. Progressão Gradual

```
develop (rápido, instável)
   ↓
qa (testes automáticos)
   ↓
staging (validação humana)
   ↓
prod (controlado, estável)
```

### 3. Rollback Rápido

```bash
# Via Git
git revert <commit>
git push

# Via ArgoCD
argocd app rollback nexo-be-prod <revision>

# Via Kubectl (emergência)
kubectl rollout undo deployment/nexo-be-prod -n nexo-prod
```

### 4. Feature Flags

```typescript
// Habilitar features por ambiente
if (process.env.NODE_ENV === "production") {
  enableFeature("new-dashboard", false);
} else {
  enableFeature("new-dashboard", true);
}
```

## 📚 Scripts Úteis

```bash
# Status de todos ambientes
./scripts/status.sh

# Promover entre ambientes
./scripts/promote.sh <from> <to>

# Validar deploy
./scripts/validate-deploy.sh <env>

# Rollback
./scripts/rollback.sh <env> <revision>
```

---

[← GitOps e ArgoCD](./08-gitops-argocd.md) | [Voltar](./README.md) | [Próximo: Observability →](./10-observability.md)
