# 00 - Integração com K3D Local

**Contexto**: Adaptação da pipeline enterprise para K3D como ambiente "cloud" local

---

## 🎯 Visão Geral

A **Nexo Platform** usa **K3D** (Kubernetes in Docker) como ambiente local que **espelha produção**. Toda a arquitetura enterprise documentada neste diretório está adaptada para funcionar com K3D.

### Por Que K3D?

| Benefício                 | Descrição                                |
| ------------------------- | ---------------------------------------- |
| **Paridade com Produção** | Ambiente K8s real, não simulação         |
| **GitOps Nativo**         | ArgoCD funciona identicamente à produção |
| **Baixo Custo**           | Desenvolvimento sem custos de cloud      |
| **Velocidade**            | Setup em 5 minutos, rebuild instantâneo  |
| **Multi-Ambiente**        | 4 ambientes isolados no mesmo cluster    |

---

## 🏗️ Infraestrutura Existente

### Estrutura Local

```
/local/                          # 🏗️ Toda infraestrutura K3D
├── argocd/                      # ArgoCD configuration
│   ├── applicationsets/
│   │   └── nexo-apps.yaml      # 12 apps (3 services × 4 envs)
│   ├── apps/                    # App manifests por ambiente
│   └── projects/                # ArgoCD Projects
├── helm/                        # Helm charts
│   ├── nexo-be/
│   │   ├── values-dev.yaml
│   │   ├── values-qa.yaml
│   │   ├── values-staging.yaml
│   │   └── values-prod.yaml
│   ├── nexo-fe/
│   └── nexo-auth/
├── k3d/
│   └── config.yaml              # Cluster configuration
├── k8s/                         # Kubernetes manifests
│   ├── base/                    # Base configs (namespaces, RBAC)
│   └── overlays/                # Environment-specific
├── observability/               # Prometheus, Grafana, Loki
│   ├── dashboards/
│   ├── prometheus/
│   └── grafana/
└── scripts/
    ├── setup.sh                 # 🚀 Setup completo (1 comando)
    ├── destroy.sh               # Destruir cluster
    └── status.sh                # Status do ambiente

/documentation/local/            # 📚 Documentação operacional
├── 01-quick-start.md
├── 02-architecture.md
├── 03-environment.md
├── 04-github-setup.md
├── 05-cicd.md
├── 06-git-workflow.md
├── 07-development.md
├── 08-api.md
├── 09-observability.md
└── 10-troubleshooting.md
```

---

## 🔄 Fluxo CI/CD Adaptado

### Fluxo Original (Cloud)

```
Commit → CI → Push Registry → Update GitOps Repo → ArgoCD Sync → Cloud K8s
```

### Fluxo Adaptado (K3D)

```
Commit → CI (GitHub Actions) → Push DockerHub → Update Values → ArgoCD (K3D) → K3D Cluster
   │                                  │                │              │              │
   │                                  │                │              │              └─► Local (127.0.0.1)
   │                                  │                │              └─► Roda no K3D cluster
   │                                  │                └─► Annotation commit SHA no values
   │                                  └─► Tag por ambiente (develop, qa, staging, prod)
   └─► GitHub Actions (cloud)
```

### Diferenças Chave

| Aspecto           | Cloud (Típico)            | K3D (Nexo)          |
| ----------------- | ------------------------- | ------------------- |
| **Registry**      | ECR/GCR privado           | DockerHub público   |
| **GitOps Repo**   | Separado                  | Monorepo (`/local`) |
| **Secrets**       | External Secrets Operator | K8s Secrets (local) |
| **Ingress**       | ALB/Cloud LB              | Traefik (NodePort)  |
| **DNS**           | Route53/Cloud DNS         | `/etc/hosts`        |
| **Observability** | Cloud-managed             | Self-hosted (K3D)   |

---

## 🚀 Setup Rápido

### 1. Setup Inicial (5 minutos)

```bash
cd /Users/geraldoluiz/Development/fullstack/nexo/local
./scripts/setup.sh
```

**O que o script faz:**

- ✅ Cria cluster K3D com 4 nodes
- ✅ Instala ArgoCD + Image Updater
- ✅ Configura 4 namespaces (develop, qa, staging, prod)
- ✅ Deploy apps via ApplicationSet
- ✅ Configura Prometheus + Grafana + Loki
- ✅ Expõe serviços via NodePort

### 2. Configurar /etc/hosts

```bash
sudo tee -a /etc/hosts <<EOF
127.0.0.1 develop.nexo.local develop.api.nexo.local develop.auth.nexo.local
127.0.0.1 qa.nexo.local qa.api.nexo.local qa.auth.nexo.local
127.0.0.1 staging.nexo.local staging.api.nexo.local staging.auth.nexo.local
127.0.0.1 prod.nexo.local prod.api.nexo.local prod.auth.nexo.local
EOF
```

### 3. Verificar Status

```bash
cd local
./scripts/status.sh
```

---

## 🌍 Ambientes

### Topologia K3D

```
┌─────────────────────────────────────────────────────────────┐
│                    K3D Cluster: nexo-develop                 │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ nexo-develop │  │   nexo-qa    │  │ nexo-staging │      │
│  │              │  │              │  │              │      │
│  │ be, fe, auth │  │ be, fe, auth │  │ be, fe, auth │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  ┌──────────────┐                                            │
│  │  nexo-prod   │                                            │
│  │              │                                            │
│  │ be, fe, auth │                                            │
│  └──────────────┘                                            │
│                                                               │
│  ┌─────────────────────────────────────────────┐            │
│  │          Serviços Compartilhados            │            │
│  ├─────────────────────────────────────────────┤            │
│  │ ArgoCD | Prometheus | Grafana | Loki        │            │
│  └─────────────────────────────────────────────┘            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Mapeamento Branch → Namespace

| Branch    | Namespace      | URL                | Auto-Deploy |
| --------- | -------------- | ------------------ | ----------- |
| `develop` | `nexo-develop` | develop.nexo.local | ✅ Sim      |
| `qa`      | `nexo-qa`      | qa.nexo.local      | ✅ Sim      |
| `staging` | `nexo-staging` | staging.nexo.local | ✅ Sim      |
| `main`    | `nexo-prod`    | prod.nexo.local    | ❌ Manual   |

---

## 📦 Estratégia de Versionamento

### CalVer Adaptado para K3D

```yaml
# /local/helm/nexo-be/values-dev.yaml
image:
  repository: docker.io/geraldobl58/nexo-be
  tag: "develop" # Tag fixa por ambiente
  pullPolicy: Always # Sempre puxa imagem mais recente

podAnnotations:
  app.kubernetes.io/commit: "16ff42f" # SHA do commit (muda a cada deploy)
```

**Como funciona:**

1. **CI** (GitHub Actions):
   - Build da imagem
   - Tag com nome do ambiente: `develop`, `qa`, `staging`, `prod`
   - Push para DockerHub (sobrescreve tag)

2. **CD** (ArgoCD):
   - Detecta mudança no `podAnnotations.commit`
   - Force restart dos pods (annotation mudou)
   - Pods puxam nova imagem (mesmo tag, conteúdo diferente)

**Vantagens:**

- ✅ Simples: 1 tag por ambiente
- ✅ Rápido: Sem versionamento complexo
- ✅ Compatível: ArgoCD sync detecta via annotations

---

## 🔐 Secrets Management (Adaptado)

### Desenvolvimento Local

```yaml
# K8s Secret (plain) - OK para dev local
apiVersion: v1
kind: Secret
metadata:
  name: nexo-be-secrets
  namespace: nexo-develop
type: Opaque
data:
  DATABASE_URL: cG9zdGdyZXM6Ly8uLi4= # base64
  REDIS_URL: cmVkaXM6Ly8uLi4=
```

### Staging/Production (Futuro)

Quando migrar para cloud, trocar por **External Secrets Operator**:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: nexo-be-secrets
  namespace: nexo-prod
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: nexo-be-secrets
  data:
    - secretKey: DATABASE_URL
      remoteRef:
        key: nexo/prod/database-url
```

Ver: [04-security-secrets.md](04-security-secrets.md) para detalhes completos.

---

## 📊 Observabilidade

### Stack Completa no K3D

| Componente | URL                    | Descrição                   |
| ---------- | ---------------------- | --------------------------- |
| Grafana    | http://localhost:30030 | Dashboards (admin/admin123) |
| Prometheus | http://localhost:30090 | Métricas time-series        |
| ArgoCD     | http://localhost:30080 | GitOps UI                   |

### Dashboards Pré-Configurados

```bash
ls -la /local/observability/dashboards/
# → nexo-be-metrics.json
# → nexo-fe-performance.json
# → kubernetes-cluster.json
# → argocd-health.json
```

Importação automática via ConfigMap. Ver: [09-observability.md](../local/09-observability.md)

---

## 🔄 Migração para Cloud (Futuro)

Quando for migrar K3D → Cloud (EKS/GKE/AKS), ajustar:

### 1. Registry

```yaml
# K3D (atual)
image:
  repository: docker.io/geraldobl58/nexo-be

# Cloud (futuro)
image:
  repository: 123456789012.dkr.ecr.us-east-1.amazonaws.com/nexo-be
```

### 2. Ingress

```yaml
# K3D (atual)
ingress:
  className: traefik
  hosts:
    - host: develop.nexo.local  # /etc/hosts

# Cloud (futuro)
ingress:
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
  hosts:
    - host: api.nexo.io  # Route53
```

### 3. Secrets

```bash
# K3D → Cloud
kubectl get secret -n nexo-prod nexo-be-secrets -o yaml \
  | yq eval 'del(.metadata.namespace)' - \
  > migration/secrets-backup.yaml

# Migrar para External Secrets Operator
```

### 4. Observability

- **K3D**: Self-hosted (Prometheus in-cluster)
- **Cloud**: Migrar para Amazon Managed Prometheus/Grafana

---

## 📚 Documentação Relacionada

### Setup & Operação (Local)

- [Quick Start](../local/01-quick-start.md) - Setup em 5 minutos
- [Arquitetura](../local/02-architecture.md) - Visão técnica K3D
- [Ambientes](../local/03-environment.md) - URLs e namespaces
- [CI/CD](../local/05-cicd.md) - Pipeline GitHub Actions
- [Troubleshooting](../local/10-troubleshooting.md) - Problemas comuns

### Pipeline Enterprise (Este diretório)

- [Overview](00-overview.md) - Arquitetura geral da pipeline
- [GitHub Actions](01-github-actions-workflows.md) - Workflows CI/CD
- [ArgoCD Configuration](02-argocd-configuration.md) - GitOps setup
- [Versioning](03-versioning-promotion.md) - Estratégia de releases
- [Security](04-security-secrets.md) - Segurança e secrets
- [Observability](05-observability.md) - Métricas, logs, traces

---

## 🎯 Quick Commands

```bash
# Criar/recriar cluster
cd local && ./scripts/setup.sh

# Status do cluster
./scripts/status.sh

# Destruir tudo
./scripts/destroy.sh

# Logs de um serviço
kubectl logs -f -n nexo-develop deployment/nexo-be

# Port-forward para debug
kubectl port-forward -n nexo-develop svc/nexo-be 3000:3000

# Sync manual ArgoCD
argocd app sync nexo-be-dev

# Ver todas as apps
argocd app list
```

---

## ✅ Checklist de Setup

- [ ] Docker instalado e rodando
- [ ] k3d, kubectl, helm instalados
- [ ] `/etc/hosts` configurado com domínios locais
- [ ] Cluster criado (`./scripts/setup.sh`)
- [ ] ArgoCD acessível (http://localhost:30080)
- [ ] GitHub Secrets configurados (DOCKERHUB_USERNAME, DOCKERHUB_TOKEN)
- [ ] Primeiro deploy testado (push para `develop`)
- [ ] Grafana acessível com dashboards (http://localhost:30030)

---

**Próximos Passos:**

1. Ler [00-overview.md](00-overview.md) para entender a arquitetura geral
2. Configurar GitHub Actions seguindo [01-github-actions-workflows.md](01-github-actions-workflows.md)
3. Testar primeiro deploy seguindo [playbook.md](playbook.md)

---

**Mantido por**: Platform Engineering Team  
**Ambiente**: K3D Local Development  
**Cloud Migration**: Q3 2026 (planejado)
