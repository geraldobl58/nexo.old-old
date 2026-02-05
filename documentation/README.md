# 📚 Documentação Nexo Platform

Documentação completa do Nexo Platform - Sistema GitOps com K3D, ArgoCD e Multi-Ambientes.

## 🗂️ Índice Geral

### 🚀 Getting Started (Comece Aqui!)

| # | Documento | Descrição |
|---|-----------|-----------|
| 1 | [**Início Rápido**](./01-quick-start.md) | Setup completo em 5 minutos |
| 2 | [**Arquitetura**](./02-architecture.md) | Como o sistema funciona |
| 3 | [**Configuração GitHub**](./03-setup-github.md) | Secrets, Tokens e Repositórios |

### 🛠️ Desenvolvimento

| # | Documento | Descrição |
|---|-----------|-----------|
| 4 | [**Desenvolvimento Local**](./04-local-development.md) | K3D, ArgoCD, Observabilidade |
| 5 | [**Fluxo Git**](./05-git-workflow.md) | Branches, Commits, PRs |
| 6 | [**APIs e Serviços**](./06-apis-services.md) | Backend, Frontend, Auth |

### 🚢 Deploy e CI/CD

| # | Documento | Descrição |
|---|-----------|-----------|
| 7 | [**Pipeline CI/CD**](./07-cicd-pipeline.md) | GitHub Actions e Automação |
| 8 | [**GitOps com ArgoCD**](./08-gitops-argocd.md) | Deploy Declarativo |
| 9 | [**Ambientes**](./09-environments.md) | Develop → QA → Staging → Prod |

### 📊 Operações

| # | Documento | Descrição |
|---|-----------|-----------|
| 10 | [**Observabilidade**](./10-observability.md) | Prometheus, Grafana, Logs |
| 11 | [**Troubleshooting**](./11-troubleshooting.md) | Resolução de Problemas |
| 12 | [**Comandos Úteis**](./12-commands.md) | Referência Rápida |

---

## 🎯 Início Rápido (TL;DR)

```bash
# 1. Configure o GitHub Token como Secret (uma única vez)
# GitHub → Settings → Secrets and variables → Actions → New repository secret
# Nome: GHCR_TOKEN
# Valor: seu_github_token (ghp_...)

# 2. Setup do ambiente local (5 minutos)
cd local
export GITHUB_TOKEN=<seu_token_aqui>
make setup

# 3. Acessar serviços
# ArgoCD:   http://localhost:30080 (admin/<senha-gerada>)
# Grafana:  http://grafana.local.nexo.app
```

## 🌟 Principais Recursos

- ✅ **Setup Automatizado**: Um comando instala tudo (K3D + ArgoCD + Monitoring)
- ✅ **4 Ambientes**: develop, qa, staging, prod
- ✅ **GitOps**: Deploy declarativo com ArgoCD
- ✅ **CI/CD**: GitHub Actions com promoção automática
- ✅ **Observabilidade**: Prometheus + Grafana + Alertmanager
- ✅ **Multi-App**: nexo-auth, nexo-be, nexo-fe

## 📋 Stack Tecnológica

| Componente | Tecnologia | Versão |
|------------|-----------|---------|
| **Container** | Docker | 29.2.1 |
| **Kubernetes** | K3D (K3s) | v5.8.3 |
| **GitOps** | ArgoCD | 2.13+ |
| **Monitoring** | Prometheus + Grafana | latest |
| **Backend** | NestJS | 10.x |
| **Frontend** | Next.js | 15.x |
| **Auth** | Keycloak | 26.x |
| **Database** | PostgreSQL | 16 |
| **Cache** | Redis | 7 |

## 🔐 Segurança e Secrets

### GitHub Secrets (Recomendado)

Ao invés de passar o token no comando, configure como secret do repositório:

1. Acesse: `https://github.com/geraldobl58/nexo/settings/secrets/actions`
2. Clique em **"New repository secret"**
3. Configure:
   - **Name**: `GHCR_TOKEN`
   - **Value**: `ghp_...` (seu GitHub Personal Access Token)
4. No workflow, use: `${{ secrets.GHCR_TOKEN }}`

### Variáveis de Ambiente Locais

Para desenvolvimento local, use variável de ambiente:

```bash
# Adicione ao seu ~/.zshrc ou ~/.bashrc
export GITHUB_TOKEN=ghp_...

# Depois só execute
cd local && make setup
```

### ⚠️ Nunca Commite Tokens

```bash
# ❌ NUNCA faça isso
git commit -m "add token ghp_..."

# ✅ Use .env (já está no .gitignore)
echo "GITHUB_TOKEN=ghp_..." > .env
```

## 🔗 Links Rápidos

- **Repositório**: https://github.com/geraldobl58/nexo
- **Container Registry**: ghcr.io/geraldobl58/nexo-*
- **ArgoCD Local**: http://localhost:30080
- **Grafana Local**: http://grafana.local.nexo.app

## 🤝 Suporte

- 📖 Leia a documentação completa
- 🐛 Reporte bugs via GitHub Issues
- 💬 Perguntas? Abra uma Discussion

---

## 📚 Documentação Legacy

A documentação anterior foi movida para `legacy/` para referência histórica.

---

**Última atualização**: Fevereiro 2026
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

| Serviço      | URL                    | Credenciais   |
| ------------ | ---------------------- | ------------- |
| ArgoCD       | http://localhost:30080 | admin / (\*)  |
| Grafana      | http://localhost:30030 | admin / admin |
| Prometheus   | http://localhost:30090 | -             |
| Alertmanager | http://localhost:30093 | -             |

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
