# 🏗️ Arquitetura do Sistema

Visão completa da arquitetura do Nexo Platform.

## 🎯 Visão Geral

O Nexo Platform é um sistema GitOps multi-ambiente baseado em Kubernetes, que utiliza práticas modernas de DevOps para garantir deployments confiáveis e automatizados.

```
┌─────────────────────────────────────────────────────────────────┐
│                     🏠 Desenvolvimento Local                     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    K3D Cluster (K8s)                      │  │
│  │                                                            │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │  │
│  │  │   Develop   │  │     QA      │  │   Staging   │      │  │
│  │  │ (3 apps)    │  │  (3 apps)   │  │  (3 apps)   │      │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │  │
│  │                                                            │  │
│  │  ┌─────────────┐                                          │  │
│  │  │     Prod    │                                          │  │
│  │  │  (3 apps)   │                                          │  │
│  │  └─────────────┘                                          │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────┐        │  │
│  │  │          Observability Stack                  │        │  │
│  │  │  • Prometheus  • Grafana  • Alertmanager     │        │  │
│  │  └──────────────────────────────────────────────┘        │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────┐        │  │
│  │  │               ArgoCD                          │        │  │
│  │  │  • GitOps Controller  • UI :30080            │        │  │
│  │  └──────────────────────────────────────────────┘        │  │
│  └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │
                              │ Git Pull
                              │
┌─────────────────────────────┴───────────────────────────────────┐
│                      📦 GitHub Repository                        │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  Source Code │  │  Helm Charts │  │  Docker Files│         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
│  ┌─────────────────────────────────────────────────────┐       │
│  │              GitHub Actions (CI/CD)                  │       │
│  │  • Build  • Test  • Push GHCR  • Update Manifests  │       │
│  └─────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Docker Push
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│           📦 GitHub Container Registry (GHCR)                    │
│                                                                  │
│  ghcr.io/geraldobl58/nexo-auth:tag                             │
│  ghcr.io/geraldobl58/nexo-be:tag                               │
│  ghcr.io/geraldobl58/nexo-fe:tag                               │
└─────────────────────────────────────────────────────────────────┘
```

## 🧩 Componentes Principais

### 1. Cluster Kubernetes (K3D)

**K3D** é uma versão leve do Kubernetes (K3s) rodando em Docker, ideal para desenvolvimento local.

```yaml
Configuração:
  - 1 Server Node (Control Plane)
  - 2 Agent Nodes (Workers)
  - Registry Local (localhost:5050)
  - LoadBalancer integrado
  - Portas expostas: 80, 443, 30080, 30030, 30090, 30093
```

**Por que K3D?**

- ✅ Leve e rápido (consome ~2GB RAM)
- ✅ Espelha ambiente de produção
- ✅ Suporta todos os recursos do Kubernetes
- ✅ Registry local integrado
- ✅ Fácil de resetar (destroy/setup)

### 2. ArgoCD (GitOps)

**ArgoCD** é o coração do GitOps - sincroniza automaticamente o estado do cluster com o repositório Git.

```yaml
Responsabilidades:
  - Monitorar repositório Git (polling a cada 3min)
  - Detectar mudanças em manifests/charts
  - Aplicar mudanças automaticamente (auto-sync)
  - Gerenciar 12 aplicações (3 apps × 4 ambientes)
  - Rollback automático em caso de falha
  - Self-healing (reconstitui recursos deletados)

Acesso:
  - UI: http://localhost:30080
  - CLI: argocd (instalável via brew)
  - API: REST API para integração CI/CD
```

**Fluxo GitOps:**

```
1. Developer faz push → GitHub
2. GitHub Actions builda imagem → GHCR
3. GitHub Actions atualiza tag no Helm values → Git
4. ArgoCD detecta mudança no Git
5. ArgoCD aplica mudança no K8s
6. Aplicação atualizada automaticamente
```

### 3. Observability Stack

Stack completo de monitoramento e observabilidade.

#### Prometheus

```yaml
Função: Coleta de métricas
Fontes:
  - Node Exporter (métricas de nodes)
  - kube-state-metrics (métricas K8s)
  - Aplicações (custom metrics)
Retenção: 15 dias
Scrape interval: 30s
```

#### Grafana

```yaml
Função: Visualização e dashboards
Dashboards pré-configurados:
  - Cluster Overview
  - Pod Metrics
  - Application Performance
  - ArgoCD Status
Alerting: Integrado com Alertmanager
```

#### Alertmanager

```yaml
Função: Gerenciamento de alertas
Canais:
  - Discord (webhook configurado)
  - Email (opcional)
  - Slack (opcional)
Alertas configurados:
  - Pod CrashLooping
  - High Memory/CPU
  - Deployment failed
  - ArgoCD out of sync
```

### 4. Aplicações

#### nexo-auth (Keycloak)

```yaml
Função: Autenticação e autorização
Stack:
  - Keycloak 26.x
  - PostgreSQL 16 (banco de dados)
Recursos:
  - OIDC/OAuth2
  - SAML
  - User Federation
  - Themes customizados
```

#### nexo-be (Backend)

```yaml
Função: API REST
Stack:
  - NestJS 10.x
  - PostgreSQL 16
  - Redis 7 (cache)
  - TypeORM
APIs:
  - /api/v1/users
  - /api/v1/auth
  - /api/v1/products
  - /health (healthcheck)
  - /metrics (prometheus)
```

#### nexo-fe (Frontend)

```yaml
Função: Interface do usuário
Stack:
  - Next.js 15.x
  - React 19
  - TailwindCSS
  - shadcn/ui
Features:
  - SSR (Server-Side Rendering)
  - API Routes
  - Optimized Images
  - PWA ready
```

## 🌍 Multi-Ambiente

### Estratégia de Ambientes

```
develop   → Branch: develop   → Deploy automático
    ↓
   qa      → Branch: qa        → Promoção manual
    ↓
 staging   → Branch: staging   → Promoção manual
    ↓
  prod     → Branch: main       → Promoção manual + approval
```

### Configuração por Ambiente

| Ambiente | Branch  | Replicas | Resources    | Auto-Sync | Database  |
| -------- | ------- | -------- | ------------ | --------- | --------- |
| develop  | develop | 1        | 256Mi/0.5CPU | ✅        | Shared    |
| qa       | qa      | 1        | 512Mi/0.5CPU | ✅        | Shared    |
| staging  | staging | 2        | 1Gi/1CPU     | ✅        | Dedicated |
| prod     | main    | 3        | 2Gi/2CPU     | ⚠️ Manual | Dedicated |

### Isolamento

```yaml
Namespaces:
  - nexo-develop   (develop)
  - nexo-qa        (qa)
  - nexo-staging   (staging)
  - nexo-prod      (prod)

Network Policies:
  - Isolamento entre namespaces
  - Apenas Ingress exposto
  - Inter-service communication permitida
```

## 🔄 Fluxo de Deploy

### 1. Desenvolvimento Local

```bash
# Developer trabalha em feature
git checkout -b feature/nova-funcionalidade
git add .
git commit -m "feat: adiciona nova funcionalidade"
git push origin feature/nova-funcionalidade

# Cria PR para develop
gh pr create --base develop
```

### 2. CI/CD (GitHub Actions)

```yaml
Trigger: Push para develop/qa/staging/main

Jobs:
1. build:
  - Checkout código
  - Build aplicação
  - Run tests
  - Build imagem Docker
  - Tag: sha-123abc, develop, latest
  - Push para GHCR

2. update-manifest:
  - Update Helm values
  - Commit: "chore: update image tag to sha-123abc"
  - Push para branch correspondente

3. notify:
  - Discord webhook
  - Status: success/failure
```

### 3. ArgoCD Sync

```yaml
ArgoCD detecta mudança:
1. Git polling (a cada 3min)
2. Webhook (push imediato)

Sincronização:
1. Compare desired state (Git) vs current state (K8s)
2. Calculate diff
3. Apply changes:
   - Create new resources
   - Update existing
   - Delete removed
4. Health check
5. Notify status
```

### 4. Health Check

```yaml
Kubernetes probes:
  - liveness: /health (a cada 10s)
  - readiness: /health/ready (a cada 5s)
  - startup: /health (max 60s)

ArgoCD health:
  - Pods: Running
  - Services: Endpoints ready
  - Ingress: Rules configured
  - Status: Healthy/Degraded/Progressing
```

## 🔐 Segurança

### Secrets Management

```yaml
Desenvolvimento Local:
  - Secrets via kubectl
  - Armazenados no K8s etcd
  - Nunca em Git

CI/CD:
  - GitHub Secrets
  - Encriptados pelo GitHub
  - Acessíveis apenas em workflows

Produção (Futuro):
  - External Secrets Operator
  - Vault/AWS Secrets Manager
  - Rotação automática
```

### Network Security

```yaml
Ingress:
  - NGINX Ingress Controller
  - TLS termination
  - Rate limiting
  - IP whitelisting (opcional)

Network Policies:
  - Default deny all
  - Allow apenas tráfego necessário
  - Isolamento entre namespaces
```

### RBAC

```yaml
ArgoCD:
  - Admin: Full access
  - Developer: Read-only + sync
  - CI/CD: Sync via API token

Kubernetes:
  - ArgoCD ServiceAccount
  - Least privilege principle
  - Namespace-scoped
```

## 📊 Métricas e SLOs

### Objetivos de Nível de Serviço

```yaml
Availability:
  - Target: 99.9% uptime
  - Measure: Prometheus uptime checks

Latency:
  - P50: < 100ms
  - P95: < 500ms
  - P99: < 1s

Error Rate:
  - Target: < 0.1%
  - Measure: HTTP 5xx responses

Deployment:
  - Frequency: Multiple per day
  - Lead time: < 1h
  - MTTR: < 30min
  - Change failure rate: < 5%
```

## 🚀 Escalabilidade

### Horizontal Pod Autoscaling

```yaml
Triggers:
  - CPU > 70%
  - Memory > 80%
  - Custom metrics (RPS)

Limits:
  - develop: 1-2 pods
  - qa: 1-3 pods
  - staging: 2-5 pods
  - prod: 3-10 pods
```

### Vertical Scaling

```yaml
Resource requests/limits ajustáveis:
  - Per namespace
  - Per deployment
  - Via Helm values
```

## 📚 Tecnologias Utilizadas

| Categoria           | Tecnologia     | Versão | Uso                |
| ------------------- | -------------- | ------ | ------------------ |
| **Container**       | Docker         | 29.2.1 | Build e runtime    |
| **Orquestração**    | K3D/K3s        | v5.8.3 | Kubernetes local   |
| **GitOps**          | ArgoCD         | 2.13+  | Deploy declarativo |
| **Monitoring**      | Prometheus     | latest | Métricas           |
| **Visualization**   | Grafana        | latest | Dashboards         |
| **Alerts**          | Alertmanager   | latest | Notificações       |
| **Ingress**         | NGINX          | latest | Roteamento         |
| **Registry**        | GHCR           | -      | Imagens Docker     |
| **CI/CD**           | GitHub Actions | -      | Automação          |
| **Backend**         | NestJS         | 10.x   | API REST           |
| **Frontend**        | Next.js        | 15.x   | UI                 |
| **Auth**            | Keycloak       | 26.x   | SSO                |
| **Database**        | PostgreSQL     | 16     | Persistência       |
| **Cache**           | Redis          | 7      | Cache              |
| **Package Manager** | pnpm           | 9.x    | Monorepo           |

---

[← Início Rápido](./01-quick-start.md) | [Voltar](./README.md) | [Próximo: GitHub Setup →](./03-setup-github.md)
