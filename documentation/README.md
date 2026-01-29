# 📚 Nexo Platform - Documentação

Documentação técnica completa do projeto Nexo Platform.

> **Nota:** Toda a infraestrutura está consolidada na pasta `/local`. O K3D é usado como ambiente Kubernetes que espelha produção.

## 📖 Índice

### 🚀 Quick Start

| Documento                             | Descrição                     |
| ------------------------------------- | ----------------------------- |
| [Quick Start](local/quick-start.md)   | Setup em 5 minutos            |
| [README Local](local/README.md)       | Guia completo do ambiente K3D |
| [Environments](local/environments.md) | Diferenças entre ambientes    |

### 🏗️ Infraestrutura (K3D)

| Documento                                       | Descrição                    |
| ----------------------------------------------- | ---------------------------- |
| [Arquitetura](local/architecture.md)            | Visão técnica do sistema     |
| [Kubernetes](local/kubernetes.md)               | Namespaces, Ingress, PVC     |
| [Deploy](local/deploy.md)                       | CI/CD e deploy               |
| [Observabilidade](local/observability-guide.md) | Prometheus, Grafana, Alertas |

### 🔧 CI/CD & GitHub

| Documento                                        | Descrição                        |
| ------------------------------------------------ | -------------------------------- |
| [GitHub Actions](local/github-actions.md)        | CI/CD pipelines                  |
| [GitHub Secrets](local/github-secrets.md)        | Todos os secrets necessários     |
| [GitHub Config](local/github-config.md)          | Secrets, Variables, Environments |
| [Git Branching](local/git-branching-strategy.md) | GitFlow e proteção de branches   |
| [CI/CD Flow](local/cicd-flow.md)                 | Fluxo completo de CI/CD          |

### 💻 Desenvolvimento

| Documento                                       | Descrição                 |
| ----------------------------------------------- | ------------------------- |
| [Desenvolvimento](local/development.md)         | Fluxo de trabalho diário  |
| [Daily Development](local/daily-development.md) | Workflow e comandos úteis |
| [API](local/api.md)                             | Documentação da API       |
| [Troubleshooting](local/troubleshooting.md)     | Erros comuns e soluções   |

## 🌿 Fluxo de Branches

```
feature/* → develop → qa → staging → main (production)
```

| Branch      | Ambiente     | Deploy     | Aprovação |
| ----------- | ------------ | ---------- | --------- |
| `feature/*` | local        | -          | -         |
| `develop`   | nexo-develop | Automático | Não       |
| `qa`        | nexo-qa      | Automático | Não       |
| `staging`   | nexo-staging | Automático | Não       |
| `main`      | nexo-prod    | Manual     | Sim       |

## Container Registry

O projeto utiliza **DockerHub** para armazenar imagens Docker:

- **Registry:** `docker.io/geraldobl58`
- **Autenticação:** Via `DOCKERHUB_TOKEN` no GitHub Actions
- **Imagens:**
  - `geraldobl58/nexo-be` - Backend NestJS
  - `geraldobl58/nexo-fe` - Frontend Next.js
  - `geraldobl58/nexo-auth` - Keycloak customizado

## 🚀 Quick Start

```bash
# 1. Clone o repositório
git clone https://github.com/geraldobl58/nexo.git
cd nexo

# 2. Setup K3D
cd local
./scripts/setup.sh

# 3. Adicionar hosts
sudo nano /etc/hosts
# Adicionar:
# 127.0.0.1 develop.nexo.local develop.api.nexo.local develop.auth.nexo.local
```

## 📌 URLs de Acesso

### Aplicações (via Ingress)

| Ambiente | Frontend                  | Backend                       | Auth                           |
| -------- | ------------------------- | ----------------------------- | ------------------------------ |
| Develop  | http://develop.nexo.local | http://develop.api.nexo.local | http://develop.auth.nexo.local |
| QA       | http://qa.nexo.local      | http://qa.api.nexo.local      | http://qa.auth.nexo.local      |
| Staging  | http://staging.nexo.local | http://staging.api.nexo.local | http://staging.auth.nexo.local |
| Prod     | http://prod.nexo.local    | http://prod.api.nexo.local    | http://prod.auth.nexo.local    |

### Ferramentas (via NodePort)

| Serviço      | URL                    | Credenciais      |
| ------------ | ---------------------- | ---------------- |
| ArgoCD       | http://localhost:30080 | admin / (\*)     |
| Grafana      | http://localhost:30030 | admin / admin123 |
| Prometheus   | http://localhost:30090 | -                |
| Alertmanager | http://localhost:30093 | -                |

> (\*) Obter senha: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

## 📂 Estrutura do Projeto

```
nexo/
├── apps/
│   ├── nexo-be/          # Backend NestJS
│   ├── nexo-fe/          # Frontend Next.js
│   └── nexo-auth/        # Keycloak themes
├── packages/
│   ├── ui/               # Componentes compartilhados
│   ├── config/           # Configurações
│   └── auth/             # Lib autenticação
├── local/                # 🏗️ Infraestrutura K3D
│   ├── argocd/           # ArgoCD apps/projects
│   ├── helm/             # Helm charts
│   ├── k3d/              # Config do cluster
│   ├── k8s/              # Manifests Kubernetes
│   ├── observability/    # Grafana, Prometheus
│   └── scripts/          # Setup scripts
├── documentation/
│   └── local/            # 📚 Toda documentação
└── .github/
    └── workflows/        # CI/CD pipelines
```

## 🔗 Links Importantes

- [ArgoCD](http://localhost:30080) - GitOps Dashboard
- [Grafana](http://localhost:30030) - Métricas e Dashboards
- [GitHub Actions](https://github.com/geraldobl58/nexo/actions) - CI/CD
