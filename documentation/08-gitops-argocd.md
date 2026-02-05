# 🔄 GitOps e ArgoCD

Guia completo sobre GitOps e gerenciamento de aplicações com ArgoCD.

## 🎯 O que é GitOps?

GitOps é uma metodologia de deploy onde:

- 📝 **Git é a única fonte da verdade**
- 🔄 **Deploy automático via sync**
- 🔙 **Rollback = git revert**
- 📊 **Estado desejado vs estado real**
- ✅ **Auditoria completa via Git history**

## 🏗️ Arquitetura GitOps

```
┌─────────────────────────────────────────────────────┐
│                  Developer                          │
│           git push → develop/main                   │
└──────────────────┬──────────────────────────────────┘
                   │
         ┌─────────▼──────────┐
         │   GitHub Repo      │
         │  (Source of Truth) │
         └─────────┬──────────┘
                   │
         ┌─────────▼──────────┐
         │  GitHub Actions    │
         │  (CI Pipeline)     │
         │  - Build images    │
         │  - Push to GHCR    │
         │  - Update manifests│
         └─────────┬──────────┘
                   │
         ┌─────────▼──────────┐
         │    ArgoCD          │
         │  (CD Controller)   │
         │  - Detect changes  │
         │  - Sync to K8s     │
         │  - Monitor health  │
         └─────────┬──────────┘
                   │
         ┌─────────▼──────────┐
         │  Kubernetes K3D    │
         │  - nexo-develop    │
         │  - nexo-qa         │
         │  - nexo-staging    │
         │  - nexo-prod       │
         └────────────────────┘
```

## 📁 Estrutura de Arquivos

```
nexo/
├── local/
│   ├── argocd/
│   │   ├── projects/
│   │   │   └── nexo.yaml           # ArgoCD Project
│   │   │
│   │   ├── apps/
│   │   │   ├── nexo-develop.yaml   # App develop
│   │   │   ├── nexo-qa.yaml        # App qa
│   │   │   ├── nexo-staging.yaml   # App staging
│   │   │   └── nexo-prod.yaml      # App prod
│   │   │
│   │   └── applicationsets/
│   │       └── nexo-apps.yaml      # ApplicationSet (all envs)
│   │
│   └── helm/
│       ├── nexo-be/
│       │   ├── Chart.yaml
│       │   ├── values.yaml         # Default values
│       │   ├── values-develop.yaml # Develop overrides
│       │   ├── values-qa.yaml      # QA overrides
│       │   ├── values-staging.yaml # Staging overrides
│       │   ├── values-prod.yaml    # Prod overrides
│       │   └── templates/
│       │       ├── deployment.yaml
│       │       ├── service.yaml
│       │       ├── ingress.yaml
│       │       └── configmap.yaml
│       │
│       ├── nexo-fe/
│       │   └── ... (mesma estrutura)
│       │
│       └── nexo-auth/
│           └── ... (mesma estrutura)
```

## 🚀 ArgoCD Setup

### Instalação

```bash
# Via script (já incluso no setup)
cd local
./scripts/setup.sh

# Manual
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# NodePort para acesso
kubectl apply -f local/argocd/nodeport.yaml
```

### Acessar UI

```bash
# URL
open http://localhost:30080

# Usuário
echo "admin"

# Senha
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### CLI Login

```bash
# Instalar CLI
brew install argocd

# Login
argocd login localhost:30080 \
  --username admin \
  --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) \
  --insecure

# Trocar senha
argocd account update-password
```

## 📦 ArgoCD Project

```yaml
# local/argocd/projects/nexo.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: nexo
  namespace: argocd
spec:
  description: Nexo Project - All environments

  # Repositórios permitidos
  sourceRepos:
    - "https://github.com/geraldobl58/nexo.git"

  # Clusters permitidos
  destinations:
    - namespace: "nexo-*"
      server: https://kubernetes.default.svc
    - namespace: argocd
      server: https://kubernetes.default.svc

  # Recursos permitidos
  clusterResourceWhitelist:
    - group: "*"
      kind: "*"

  # Namespaced resources
  namespaceResourceWhitelist:
    - group: "*"
      kind: "*"
```

## 🎯 ArgoCD Application

### Application Develop

```yaml
# local/argocd/apps/nexo-develop.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nexo-be-develop
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: nexo

  source:
    repoURL: https://github.com/geraldobl58/nexo.git
    targetRevision: develop
    path: local/helm/nexo-be
    helm:
      valueFiles:
        - values.yaml
        - values-develop.yaml

  destination:
    server: https://kubernetes.default.svc
    namespace: nexo-develop

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m

  revisionHistoryLimit: 10
```

### Application Production

```yaml
# local/argocd/apps/nexo-prod.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nexo-be-prod
  namespace: argocd
spec:
  project: nexo

  source:
    repoURL: https://github.com/geraldobl58/nexo.git
    targetRevision: main
    path: local/helm/nexo-be
    helm:
      valueFiles:
        - values.yaml
        - values-prod.yaml

  destination:
    server: https://kubernetes.default.svc
    namespace: nexo-prod

  syncPolicy:
    # MANUAL em produção (deploy controlado)
    automated: null
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 3
      backoff:
        duration: 5s
        maxDuration: 1m
```

## 🔄 ApplicationSet

Para gerenciar múltiplos ambientes:

```yaml
# local/argocd/applicationsets/nexo-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: nexo-apps
  namespace: argocd
spec:
  generators:
    - matrix:
        generators:
          # Lista de apps
          - list:
              elements:
                - app: nexo-be
                - app: nexo-fe
                - app: nexo-auth

          # Lista de ambientes
          - list:
              elements:
                - env: develop
                  branch: develop
                  syncAuto: true
                - env: qa
                  branch: develop
                  syncAuto: true
                - env: staging
                  branch: main
                  syncAuto: false
                - env: prod
                  branch: main
                  syncAuto: false

  template:
    metadata:
      name: "{{app}}-{{env}}"
      namespace: argocd
    spec:
      project: nexo

      source:
        repoURL: https://github.com/geraldobl58/nexo.git
        targetRevision: "{{branch}}"
        path: "local/helm/{{app}}"
        helm:
          valueFiles:
            - values.yaml
            - "values-{{env}}.yaml"

      destination:
        server: https://kubernetes.default.svc
        namespace: "nexo-{{env}}"

      syncPolicy:
        automated:
          prune: "{{syncAuto}}"
          selfHeal: "{{syncAuto}}"
        syncOptions:
          - CreateNamespace=true
        retry:
          limit: 5
```

## 🎨 Helm Values Structure

### Base Values

```yaml
# local/helm/nexo-be/values.yaml
replicaCount: 1

image:
  repository: ghcr.io/geraldobl58/nexo-be
  pullPolicy: Always
  tag: "latest"

imagePullSecrets:
  - name: ghcr-secret

service:
  type: ClusterIP
  port: 3333

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: api.nexo.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

env:
  - name: NODE_ENV
    value: "production"
  - name: PORT
    value: "3333"

livenessProbe:
  httpGet:
    path: /health
    port: 3333
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health
    port: 3333
  initialDelaySeconds: 10
  periodSeconds: 5
```

### Environment Overrides

```yaml
# local/helm/nexo-be/values-develop.yaml
image:
  tag: "develop-abc123"

ingress:
  hosts:
    - host: develop.api.nexo.local
      paths:
        - path: /
          pathType: Prefix

env:
  - name: NODE_ENV
    value: "development"
  - name: LOG_LEVEL
    value: "debug"

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 50m
    memory: 64Mi
```

```yaml
# local/helm/nexo-be/values-prod.yaml
replicaCount: 3

image:
  tag: "v1.0.0"

ingress:
  hosts:
    - host: api.nexo.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: nexo-api-tls
      hosts:
        - api.nexo.com

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

env:
  - name: NODE_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "info"
```

## 🔄 Sync Strategies

### Auto Sync

```yaml
syncPolicy:
  automated:
    prune: true # Remove recursos deletados
    selfHeal: true # Corrige drift automático
    allowEmpty: false # Não permite estado vazio
```

**Quando usar:**

- ✅ Development
- ✅ QA
- ⚠️ Staging (opcional)
- ❌ Production (requer aprovação)

### Manual Sync

```yaml
syncPolicy:
  automated: null # Desabilita auto-sync
```

**Quando usar:**

- ✅ Production
- ✅ Deploys críticos
- ✅ Mudanças com impacto

## 🎛️ Operações ArgoCD

### Sync Manual

```bash
# Via CLI
argocd app sync nexo-be-develop

# Via kubectl
kubectl patch application nexo-be-develop -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'

# Via UI
# Applications → nexo-be-develop → Sync
```

### Hard Refresh

```bash
# Força refresh do estado
argocd app get nexo-be-develop --hard-refresh

# Via kubectl
kubectl patch application nexo-be-develop -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"retry":{"limit":"1"}}}'
```

### Rollback

```bash
# Via CLI
argocd app rollback nexo-be-develop <revision>

# Via Git (preferido)
git revert <commit-hash>
git push
# ArgoCD detecta e faz rollback automático
```

### Diff

```bash
# Ver diferenças entre estado atual e desejado
argocd app diff nexo-be-develop

# Via kubectl
kubectl get application nexo-be-develop -n argocd -o yaml
```

### History

```bash
# Ver histórico de deploys
argocd app history nexo-be-develop

# Via kubectl
kubectl get application nexo-be-develop -n argocd \
  -o jsonpath='{.status.history}' | jq
```

## 📊 Status e Health

### Application Status

```bash
# Status de uma app
argocd app get nexo-be-develop

# Status de todas
argocd app list

# Via kubectl
kubectl get applications -n argocd
```

**Estados:**

- 🟢 **Synced** - Em sync com Git
- 🟡 **OutOfSync** - Diferente do Git
- 🔵 **Unknown** - Estado desconhecido
- 🔴 **Error** - Erro no sync

**Health:**

- 🟢 **Healthy** - Todos recursos OK
- 🟡 **Progressing** - Deploy em andamento
- 🟡 **Degraded** - Alguns recursos com problema
- 🔴 **Missing** - Recursos faltando

### Resource Status

```bash
# Ver recursos de uma app
argocd app resources nexo-be-develop

# Tree view
argocd app get nexo-be-develop --show-operation

# Via UI
# Application → Resource Tree
```

## 🔍 Troubleshooting

### App não sincroniza

```bash
# 1. Verificar status
argocd app get nexo-be-develop

# 2. Ver eventos
kubectl get events -n nexo-develop --sort-by='.lastTimestamp'

# 3. Logs do ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller -f

# 4. Hard refresh
argocd app get nexo-be-develop --hard-refresh

# 5. Forçar sync
argocd app sync nexo-be-develop --force
```

### Sync loop (CrashLoopBackOff)

```bash
# Suspender auto-sync
argocd app set nexo-be-develop --sync-policy none

# Investigar pods
kubectl describe pod -n nexo-develop -l app.kubernetes.io/name=nexo-be

# Ver logs
kubectl logs -n nexo-develop -l app.kubernetes.io/name=nexo-be --tail=100

# Corrigir issue
# ... fix code or config ...

# Re-habilitar auto-sync
argocd app set nexo-be-develop --sync-policy automated
```

### Image não atualiza

```bash
# 1. Verificar tag no values.yaml
cat local/helm/nexo-be/values-develop.yaml | grep tag

# 2. Verificar imagem no pod
kubectl get pod -n nexo-develop -l app.kubernetes.io/name=nexo-be \
  -o jsonpath='{.items[0].spec.containers[0].image}'

# 3. Forçar pull da imagem
kubectl delete pod -n nexo-develop -l app.kubernetes.io/name=nexo-be

# 4. Verificar imagePullSecret
kubectl get secret -n nexo-develop ghcr-secret
```

### Helm template error

```bash
# Testar template localmente
helm template nexo-be local/helm/nexo-be \
  -f local/helm/nexo-be/values-develop.yaml

# Ver diff
argocd app diff nexo-be-develop

# Ver manifests gerados
argocd app manifests nexo-be-develop
```

## 🔐 Segurança

### RBAC

```yaml
# Roles por ambiente
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: argocd-developer
  namespace: nexo-develop
rules:
  - apiGroups: [""]
    resources: ["pods", "services"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch"]
```

### Git Authentication

```bash
# HTTPS com token
argocd repo add https://github.com/geraldobl58/nexo.git \
  --username git \
  --password $GITHUB_TOKEN

# SSH
argocd repo add git@github.com:geraldobl58/nexo.git \
  --ssh-private-key-path ~/.ssh/id_rsa
```

### Image Pull Secrets

```bash
# Criado automaticamente pelo setup
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=geraldobl58 \
  --docker-password=$GHCR_TOKEN \
  -n nexo-develop
```

## 📈 Métricas e Monitoramento

### Prometheus Metrics

```promql
# Sync status
argocd_app_info{sync_status="Synced"}

# Health status
argocd_app_info{health_status="Healthy"}

# Sync duration
argocd_app_sync_total

# Sync failures
rate(argocd_app_sync_total{phase="Failed"}[5m])
```

### Grafana Dashboard

Importar dashboard: ID 14584 (ArgoCD)

**Métricas:**

- Applications por status
- Sync frequency
- Sync duration
- Failed syncs
- Resource count

## 💡 Boas Práticas

### 1. Git como Source of Truth

```bash
# ✅ Correto: mudar via Git
vim local/helm/nexo-be/values-develop.yaml
git commit -m "feat: aumenta replicas para 3"
git push
# ArgoCD detecta e aplica

# ❌ Errado: mudar direto no K8s
kubectl scale deployment nexo-be-develop --replicas=3 -n nexo-develop
# ArgoCD vai reverter (self-heal)
```

### 2. Environment Separation

```yaml
# Cada ambiente = branch + values específicos
develop  → develop branch → values-develop.yaml
qa       → develop branch → values-qa.yaml
staging  → main branch    → values-staging.yaml
prod     → main branch    → values-prod.yaml
```

### 3. Progressive Rollout

```
1. develop → Auto-sync, deploy contínuo
2. qa      → Auto-sync, testes automáticos
3. staging → Manual sync, validação humana
4. prod    → Manual sync, aprovação + validação
```

### 4. Sync Policies

```yaml
# Development: agressivo
automated:
  prune: true
  selfHeal: true

# Production: conservador
automated: null  # manual only
```

### 5. Health Checks

```yaml
# Sempre definir probes
livenessProbe:
  httpGet:
    path: /health
    port: 3333

readinessProbe:
  httpGet:
    path: /health
    port: 3333
```

## 📚 Recursos

- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://opengitops.dev/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)

---

[← CI/CD Pipeline](./07-cicd-pipeline.md) | [Voltar](./README.md) | [Próximo: Ambientes →](./09-environments.md)
