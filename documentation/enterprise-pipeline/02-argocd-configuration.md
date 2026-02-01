# ArgoCD Configuration - Enterprise GitOps

## 📋 Visão Geral

ArgoCD é o motor de Continuous Delivery, responsável por sincronizar o estado desejado (Git) com o estado real (Kubernetes). Seguimos o padrão **App of Apps** usado por Spotify e Uber para escalar gerenciamento de múltiplos serviços.

## 🏗️ Arquitetura ArgoCD

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ARGOCD HIERARCHY                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   AppProject: nexo-platform                                          │
│        │                                                             │
│        ├── ApplicationSet: nexo-apps (Generator: List)              │
│        │    │                                                        │
│        │    ├─► Application: nexo-be-develop                        │
│        │    ├─► Application: nexo-be-qa                             │
│        │    ├─► Application: nexo-be-staging                        │
│        │    ├─► Application: nexo-be-production                     │
│        │    │                                                        │
│        │    ├─► Application: nexo-fe-develop                        │
│        │    ├─► Application: nexo-fe-qa                             │
│        │    ├─► Application: nexo-fe-staging                        │
│        │    ├─► Application: nexo-fe-production                     │
│        │    │                                                        │
│        │    └─► Application: nexo-auth-{env}... (12 apps total)    │
│        │                                                             │
│        └── ApplicationSet: nexo-infrastructure                       │
│             ├─► Application: monitoring                              │
│             ├─► Application: external-secrets                        │
│             └─► Application: ingress-nginx                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## 🔧 Helm vs Kustomize: Decisão Técnica

### ✅ Escolha: Helm

**Justificativa**:

1. **Templating avançado**: Lógica condicional, loops, funções
2. **Packaging**: Versionamento e distribuição via Helm repos
3. **Ecosystem**: Ampla adoção, charts de terceiros (prometheus, nginx, etc.)
4. **DRY**: `values-{env}.yaml` compartilham base template
5. **Padrão indústria**: Netflix, Spotify, Datadog usam Helm

**Quando Kustomize seria melhor**:

- ❌ Patches simples sobre manifestos K8s puros
- ❌ Evitar lógica de templating (opinião: YAML "puro")
- ❌ Built-in no kubectl (sem dependência externa)

**Nossa realidade**: Necessitamos lógica condicional (ex: enableMonitoring per env), múltiplos ambientes com ~80% overlap → Helm vence.

---

## 📁 Estrutura GitOps Repo

```
nexo-gitops/
├── argocd/
│   ├── projects/
│   │   └── nexo-platform.yaml           ← AppProject (multi-tenant)
│   │
│   ├── applicationsets/
│   │   ├── nexo-apps.yaml               ← Gera apps por serviço/ambiente
│   │   └── nexo-infrastructure.yaml     ← Infra compartilhada
│   │
│   └── root-app.yaml                     ← Bootstrap (App of Apps)
│
├── helm/
│   ├── nexo-be/
│   │   ├── Chart.yaml
│   │   ├── values.yaml                   ← Defaults
│   │   ├── values-develop.yaml
│   │   ├── values-qa.yaml
│   │   ├── values-staging.yaml
│   │   ├── values-prod.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── ingress.yaml
│   │       ├── hpa.yaml
│   │       ├── pdb.yaml
│   │       └── servicemonitor.yaml
│   │
│   ├── nexo-fe/
│   │   └── ... (estrutura similar)
│   │
│   └── nexo-auth/
│       └── ... (estrutura similar)
│
└── README.md
```

---

## 🎯 AppProject: nexo-platform

**Arquivo**: `argocd/projects/nexo-platform.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: nexo-platform
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  description: Nexo Platform Services

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Repositories permitidos (Source of Truth)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  sourceRepos:
    - "https://github.com/nexo-org/nexo-gitops.git"
    - "https://charts.bitnami.com/bitnami" # Para dependencies externas
    - "https://prometheus-community.github.io/helm-charts"

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Clusters de destino
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  destinations:
    - namespace: "nexo-*"
      server: "https://kubernetes.default.svc" # In-cluster

    # Prod em cluster separado (recomendado)
    - namespace: "nexo-*"
      server: "https://prod-k8s.example.com"
      name: prod-cluster

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Recursos Kubernetes permitidos
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  clusterResourceWhitelist:
    - group: ""
      kind: Namespace
    - group: "rbac.authorization.k8s.io"
      kind: ClusterRole
    - group: "rbac.authorization.k8s.io"
      kind: ClusterRoleBinding

  namespaceResourceWhitelist:
    - group: ""
      kind: Service
    - group: ""
      kind: ConfigMap
    - group: ""
      kind: Secret
    - group: "apps"
      kind: Deployment
    - group: "apps"
      kind: StatefulSet
    - group: "batch"
      kind: Job
    - group: "batch"
      kind: CronJob
    - group: "networking.k8s.io"
      kind: Ingress
    - group: "autoscaling"
      kind: HorizontalPodAutoscaler
    - group: "policy"
      kind: PodDisruptionBudget
    - group: "monitoring.coreos.com"
      kind: ServiceMonitor

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # RBAC dentro do projeto
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  roles:
    # Developers: apenas read em todos os ambientes
    - name: developer
      description: Read-only access
      policies:
        - p, proj:nexo-platform:developer, applications, get, nexo-platform/*, allow
        - p, proj:nexo-platform:developer, applications, sync, nexo-platform/*-develop, allow
        - p, proj:nexo-platform:developer, applications, sync, nexo-platform/*-qa, allow
      groups:
        - nexo-developers

    # Platform Engineers: full access exceto produção
    - name: platform-engineer
      description: Manage dev/qa/staging
      policies:
        - p, proj:nexo-platform:platform-engineer, applications, *, nexo-platform/*, allow
        - p, proj:nexo-platform:platform-engineer, applications, delete, nexo-platform/*-production, deny
        - p, proj:nexo-platform:platform-engineer, applications, override, nexo-platform/*-production, deny
      groups:
        - nexo-platform-team

    # SRE: full access incluindo produção
    - name: sre
      description: Full access including production
      policies:
        - p, proj:nexo-platform:sre, applications, *, nexo-platform/*, allow
      groups:
        - nexo-sre-team

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Sync Windows (maintenance windows)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  syncWindows:
    # Produção: apenas horário comercial (exceto emergência)
    - kind: allow
      schedule: "0 9-18 * * 1-5" # Segunda a Sexta, 9h-18h
      duration: 9h
      applications:
        - "*-production"
      manualSync: true # Permite manual sync mesmo fora da janela

    # Develop: 24/7
    - kind: allow
      schedule: "* * * * *"
      duration: 1440m
      applications:
        - "*-develop"
        - "*-qa"
```

---

## 🚀 ApplicationSet: nexo-apps

**Arquivo**: `argocd/applicationsets/nexo-apps.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: nexo-apps
  namespace: argocd
spec:
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Generator: List (explícito, sem surpresas)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  generators:
    - list:
        elements:
          # nexo-be
          - service: nexo-be
            environment: develop
            namespace: nexo-develop
            cluster: in-cluster
            autoSync: "true"
            prune: "true"
            selfHeal: "true"

          - service: nexo-be
            environment: qa
            namespace: nexo-qa
            cluster: in-cluster
            autoSync: "true"
            prune: "true"
            selfHeal: "true"

          - service: nexo-be
            environment: staging
            namespace: nexo-staging
            cluster: in-cluster
            autoSync: "false" # Manual sync
            prune: "true"
            selfHeal: "false"

          - service: nexo-be
            environment: production
            namespace: nexo-production
            cluster: prod-cluster # Cluster separado
            autoSync: "false"
            prune: "false" # Extra safety
            selfHeal: "false"

          # nexo-fe
          - service: nexo-fe
            environment: develop
            namespace: nexo-develop
            cluster: in-cluster
            autoSync: "true"
            prune: "true"
            selfHeal: "true"

          - service: nexo-fe
            environment: qa
            namespace: nexo-qa
            cluster: in-cluster
            autoSync: "true"
            prune: "true"
            selfHeal: "true"

          - service: nexo-fe
            environment: staging
            namespace: nexo-staging
            cluster: in-cluster
            autoSync: "false"
            prune: "true"
            selfHeal: "false"

          - service: nexo-fe
            environment: production
            namespace: nexo-production
            cluster: prod-cluster
            autoSync: "false"
            prune: "false"
            selfHeal: "false"

          # nexo-auth
          - service: nexo-auth
            environment: develop
            namespace: nexo-develop
            cluster: in-cluster
            autoSync: "true"
            prune: "true"
            selfHeal: "true"

          - service: nexo-auth
            environment: qa
            namespace: nexo-qa
            cluster: in-cluster
            autoSync: "true"
            prune: "true"
            selfHeal: "true"

          - service: nexo-auth
            environment: staging
            namespace: nexo-staging
            cluster: in-cluster
            autoSync: "false"
            prune: "true"
            selfHeal: "false"

          - service: nexo-auth
            environment: production
            namespace: nexo-production
            cluster: prod-cluster
            autoSync: "false"
            prune: "false"
            selfHeal: "false"

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Template de Application
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  template:
    metadata:
      name: "{{service}}-{{environment}}"
      namespace: argocd
      labels:
        service: "{{service}}"
        environment: "{{environment}}"
      annotations:
        argocd.argoproj.io/manifest-generate-paths: "helm/{{service}}"
        notifications.argoproj.io/subscribe.on-deployed.slack: nexo-deployments
        notifications.argoproj.io/subscribe.on-health-degraded.slack: nexo-alerts

    spec:
      project: nexo-platform

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Source: GitOps repo
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      source:
        repoURL: https://github.com/nexo-org/nexo-gitops.git
        targetRevision: main
        path: helm/{{service}}
        helm:
          releaseName: "{{service}}"
          valueFiles:
            - values.yaml
            - values-{{environment}}.yaml
          parameters:
            - name: image.tag
              value: "override-by-gitops-repo" # Vem do values-{env}.yaml

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Destination: Kubernetes cluster
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      destination:
        server: "{{cluster}}"
        namespace: "{{namespace}}"

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Sync Policy
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      syncPolicy:
        automated:
          prune: "{{prune}}"
          selfHeal: "{{selfHeal}}"
          allowEmpty: false

        syncOptions:
          - CreateNamespace=true
          - PrunePropagationPolicy=foreground
          - PruneLast=true # Prune após deploy bem-sucedido
          - RespectIgnoreDifferences=true

        retry:
          limit: 5
          backoff:
            duration: 5s
            factor: 2
            maxDuration: 3m

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Health Checks Customizados
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ignoreDifferences:
        # Ignora diferenças causadas por controllers externos
        - group: apps
          kind: Deployment
          jsonPointers:
            - /spec/replicas # HPA controla, não ArgoCD

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # Rollback Automático (apenas prod/staging)
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      revisionHistoryLimit: 10
```

---

## 🔍 Health Assessment Customizado

**Arquivo**: `argocd/health-checks/custom.lua`

```lua
-- Custom health check para Nexo services
hs = {}

-- Deployment health
if obj.kind == "Deployment" then
  if obj.status ~= nil then
    if obj.status.updatedReplicas == obj.spec.replicas and
       obj.status.replicas == obj.spec.replicas and
       obj.status.availableReplicas == obj.spec.replicas and
       obj.status.observedGeneration >= obj.metadata.generation then
      hs.status = "Healthy"
      hs.message = "All replicas are ready"
      return hs
    end

    -- Detecta crashloop
    if obj.status.conditions ~= nil then
      for i, condition in ipairs(obj.status.conditions) do
        if condition.type == "Progressing" and condition.status == "False" then
          hs.status = "Degraded"
          hs.message = condition.message
          return hs
        end
      end
    end
  end

  hs.status = "Progressing"
  hs.message = "Waiting for rollout to finish"
  return hs
end

-- Service health (valida se tem endpoints)
if obj.kind == "Service" then
  hs.status = "Healthy"
  hs.message = "Service is ready"
  return hs
end

return hs
```

Configurar no ArgoCD:

```yaml
# argocd-cm ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  resource.customizations.health.apps_Deployment: |
    -- (conteúdo do custom.lua)
```

---

## 📊 Monitoring & Notifications

### ArgoCD Notifications

**Arquivo**: `argocd/notifications/notifications-cm.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Trigger: Quando notificar
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      oncePer: app.status.operationState.syncResult.revision
      send: [app-deployed]

  trigger.on-health-degraded: |
    - when: app.status.health.status == 'Degraded'
      send: [app-health-degraded]

  trigger.on-sync-failed: |
    - when: app.status.operationState.phase in ['Error', 'Failed']
      send: [app-sync-failed]

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Templates: O que enviar
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  template.app-deployed: |
    message: |
      🚀 **Deployment Successful**
      Application: {{.app.metadata.name}}
      Sync Status: {{.app.status.sync.status}}
      Health Status: {{.app.status.health.status}}
      Repository: {{.app.spec.source.repoURL}}
      Revision: {{.app.status.sync.revision}}
      {{if eq .app.status.operationState.phase "Succeeded"}}
        ✅ Deployment completed successfully
      {{end}}

  template.app-health-degraded: |
    message: |
      ⚠️ **Application Health Degraded**
      Application: {{.app.metadata.name}}
      Health Status: {{.app.status.health.status}}
      {{range .app.status.conditions}}
      - {{.type}}: {{.message}}
      {{end}}

  template.app-sync-failed: |
    message: |
      ❌ **Sync Failed**
      Application: {{.app.metadata.name}}
      Sync Status: {{.app.status.sync.status}}
      Operation Phase: {{.app.status.operationState.phase}}
      Message: {{.app.status.operationState.message}}

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Services: Para onde enviar
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  service.slack: |
    token: $slack-token

---
apiVersion: v1
kind: Secret
metadata:
  name: argocd-notifications-secret
  namespace: argocd
type: Opaque
stringData:
  slack-token: xoxb-your-slack-token
```

---

## 🛡️ Disaster Recovery

### Backup ArgoCD State

```bash
# Backup declarativo (GitOps!)
# Applications estão em Git, apenas clusters precisam backup

# Backup secrets e configmaps
kubectl get secret -n argocd -o yaml > argocd-secrets-backup.yaml
kubectl get configmap -n argocd -o yaml > argocd-configmaps-backup.yaml

# Backup com Velero (recomendado)
velero backup create argocd-backup \
  --include-namespaces argocd \
  --include-cluster-resources=true
```

### Restore Procedure

```bash
# 1. Reinstalar ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Restore secrets
kubectl apply -f argocd-secrets-backup.yaml

# 3. Apply root app (App of Apps)
kubectl apply -f argocd/root-app.yaml

# 4. ArgoCD re-sincroniza tudo do Git
argocd app sync -l argocd.argoproj.io/instance=root
```

---

## 📋 Rollback Procedure

### Manual Rollback via CLI

```bash
# Listar histórico de deploys
argocd app history nexo-be-production

# Rollback para revisão anterior
argocd app rollback nexo-be-production 3  # Rollback para revisão 3

# Verificar status
argocd app get nexo-be-production
```

### Rollback via GitOps (recomendado)

```bash
# 1. Revert commit no GitOps repo
cd nexo-gitops
git revert HEAD
git push origin main

# 2. ArgoCD detecta automaticamente
# 3. Sync manual ou automático (dependendo do ambiente)
```

---

## 🚨 Common Pitfalls a Evitar

### ❌ Erro 1: Auto-sync em produção

```yaml
# ❌ NUNCA faça isso
environment: production
autoSync: "true" # Perigoso!
```

### ❌ Erro 2: Prune agressivo

```yaml
# ❌ Evite em prod
prune: "true"
selfHeal: "true"
# Pode deletar recursos criados manualmente em emergência
```

### ❌ Erro 3: Secrets em Git

```yaml
# ❌ NUNCA commite secrets
apiVersion: v1
kind: Secret
data:
  password: cGFzc3dvcmQ=  # Visível no Git!

# ✅ Use External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: nexo-db-secret
spec:
  secretStoreRef:
    name: aws-secrets-manager
```

---

**Próximo**: [Versioning & Promotion Strategy](03-versioning-promotion.md)
