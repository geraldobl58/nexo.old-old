# 02 - Arquitetura

Visão geral da arquitetura do Nexo Platform.

---

## 🏗️ Stack Tecnológica

| Camada            | Tecnologia                  | Versão     |
| ----------------- | --------------------------- | ---------- |
| **Frontend**      | Next.js + TailwindCSS       | 15.x       |
| **Backend**       | NestJS + Prisma             | 10.x       |
| **Auth**          | Keycloak                    | 26.5       |
| **Database**      | PostgreSQL                  | 16-alpine  |
| **Container**     | Docker + K3D                | 24.x / 5.x |
| **Orquestração**  | Kubernetes (K3D)            | 1.28.x     |
| **GitOps**        | ArgoCD + Image Updater      | 2.x        |
| **Observability** | Prometheus + Grafana + Loki | -          |
| **CI/CD**         | GitHub Actions              | -          |
| **Registry**      | DockerHub                   | -          |

---

## 📐 Diagrama de Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                            K3D Cluster                              │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │                        Traefik Ingress                          ││
│  │    *.nexo.local → Route por IngressRoute                        ││
│  └──────────────────┬────────────────┬────────────────┬────────────┘│
│                     │                │                │             │
│  ┌──────────────────▼──┐  ┌─────────▼──────┐  ┌─────▼──────────┐  │
│  │      nexo-fe        │  │    nexo-be     │  │   nexo-auth    │  │
│  │  (Next.js :3000)    │  │ (NestJS :3333) │  │ (Keycloak:8080)│  │
│  └─────────────────────┘  └───────┬────────┘  └───────┬────────┘  │
│                                   │                   │            │
│                           ┌───────▼────────┐  ┌───────▼────────┐  │
│                           │   PostgreSQL   │  │   PostgreSQL   │  │
│                           │ (nexo-be:5432) │  │(keycloak:5432) │  │
│                           └────────────────┘  └────────────────┘  │
│                                                                    │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐       │
│  │    ArgoCD      │  │  Prometheus    │  │    Grafana     │       │
│  │  (port 30080)  │  │  (port 30090)  │  │  (port 30030)  │       │
│  └────────────────┘  └────────────────┘  └────────────────┘       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Estrutura do Repositório

```
nexo/
├── apps/                     # Aplicações
│   ├── nexo-fe/             # Frontend Next.js
│   │   ├── src/app/         # App Router
│   │   ├── src/components/  # Componentes React
│   │   └── src/lib/         # Utilitários
│   │
│   ├── nexo-be/             # Backend NestJS
│   │   ├── src/             # Source code
│   │   ├── prisma/          # Schema e migrations
│   │   └── test/            # Testes E2E
│   │
│   └── nexo-auth/           # Keycloak customizado
│       └── themes/nexo/     # Tema customizado
│
├── packages/                 # Packages compartilhados
│   ├── auth/                # Lógica de autenticação
│   ├── config/              # Configurações
│   └── ui/                  # Componentes UI
│
├── local/                    # Infraestrutura K3D
│   ├── argocd/              # ArgoCD Apps e Projects
│   │   ├── apps/            # Application definitions
│   │   └── projects/        # Project definitions
│   ├── helm/                # Helm Charts
│   │   ├── nexo-fe/         # Chart Frontend
│   │   ├── nexo-be/         # Chart Backend
│   │   └── nexo-auth/       # Chart Keycloak
│   ├── k3d/                 # Configuração K3D
│   ├── k8s/                 # Manifests base
│   ├── observability/       # Prometheus/Grafana
│   └── scripts/             # Scripts de automação
│
├── documentation/            # Documentação
│   └── local/               # Docs consolidados
│
├── .github/                  # GitHub
│   └── workflows/           # CI/CD Pipelines
│
└── scripts/                  # Scripts gerais
```

---

## 🔄 Fluxo de Deploy (GitOps)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Developer  │────▶│    GitHub    │────▶│  DockerHub   │────▶│    ArgoCD    │
│  (git push)  │     │   Actions    │     │   Registry   │     │ Image Updater│
└──────────────┘     └──────────────┘     └──────────────┘     └──────┬───────┘
                                                                       │
                     ┌──────────────┐                                  │
                     │  K3D Cluster │◀─────────────────────────────────┘
                     │  (Pods)      │     (Pull & Deploy)
                     └──────────────┘
```

### Etapas:

1. **Developer** faz `git push` para branch (develop/qa/staging/main)
2. **GitHub Actions (CI)** roda testes, build, push para DockerHub
3. **ArgoCD Image Updater** detecta nova imagem no DockerHub
4. **ArgoCD** faz sync e atualiza pods no K3D

---

## 🌍 Ambientes e Namespaces

| Ambiente    | Namespace    | Branch  | Descrição             |
| ----------- | ------------ | ------- | --------------------- |
| **develop** | nexo-develop | develop | Desenvolvimento ativo |
| **qa**      | nexo-qa      | qa      | Quality Assurance     |
| **staging** | nexo-staging | staging | Pré-produção          |
| **prod**    | nexo-prod    | main    | Produção              |

---

## 🔌 Comunicação entre Serviços

### Dentro do Cluster (K8S DNS)

```bash
# Frontend → Backend
http://nexo-be.nexo-develop.svc.cluster.local:3333

# Backend → Keycloak
http://nexo-auth.nexo-develop.svc.cluster.local:8080

# Backend → PostgreSQL
postgresql://user:pass@nexo-be-postgresql:5432/nexo
```

### Fora do Cluster (Ingress)

```bash
# Ambiente develop
http://develop.nexo.local      # Frontend
http://develop.api.nexo.local  # Backend
http://develop.auth.nexo.local # Keycloak
```

---

## 💾 Persistência de Dados

| Serviço               | StorageClass | Volume Size |
| --------------------- | ------------ | ----------- |
| PostgreSQL (Backend)  | local-path   | 8Gi         |
| PostgreSQL (Keycloak) | local-path   | 8Gi         |

> **Nota:** `local-path` é o provisioner padrão do K3D para volumes persistentes.

---

## ➡️ Próximos Passos

- [03-environment.md](03-environment.md) - Detalhes de cada ambiente
- [05-cicd.md](05-cicd.md) - Pipeline CI/CD completo
