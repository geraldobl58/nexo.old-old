# 04 - GitHub Setup

Configuração completa do GitHub para CI/CD.

---

## 📋 Pré-requisitos

- Conta no GitHub
- Conta no DockerHub
- Acesso de admin ao repositório `geraldobl58/nexo`

---

## 🔐 Secrets do Repositório

Acesse: **Settings → Secrets and variables → Actions → Secrets**

### Secrets Obrigatórios

| Secret               | Descrição              | Como Obter                            |
| -------------------- | ---------------------- | ------------------------------------- |
| `DOCKERHUB_USERNAME` | Usuário DockerHub      | geraldobl58                           |
| `DOCKERHUB_TOKEN`    | Access Token DockerHub | [Gerar Token](#gerar-token-dockerhub) |

### Gerar Token DockerHub

1. Acesse [hub.docker.com](https://hub.docker.com)
2. Vá em **Account Settings → Security → Access Tokens**
3. Clique em **New Access Token**
4. Nome: `github-actions-nexo`
5. Permissions: **Read, Write, Delete**
6. Copie e salve o token

---

## 🌍 Environments

Acesse: **Settings → Environments**

Crie os seguintes ambientes:

### 1. develop

- **Deployment branches**: `develop`
- **Secrets**: (herda do repositório)
- **Variables**:
  | Variable | Value |
  |----------|-------|
  | `K8S_NAMESPACE` | nexo-develop |
  | `IMAGE_TAG` | develop |

### 2. qa

- **Deployment branches**: `qa`
- **Secrets**: (herda do repositório)
- **Variables**:
  | Variable | Value |
  |----------|-------|
  | `K8S_NAMESPACE` | nexo-qa |
  | `IMAGE_TAG` | qa |

### 3. staging

- **Deployment branches**: `staging`
- **Secrets**: (herda do repositório)
- **Variables**:
  | Variable | Value |
  |----------|-------|
  | `K8S_NAMESPACE` | nexo-staging |
  | `IMAGE_TAG` | staging |

### 4. production

- **Deployment branches**: `main`
- **Required reviewers**: Adicionar aprovadores
- **Secrets**: (herda do repositório)
- **Variables**:
  | Variable | Value |
  |----------|-------|
  | `K8S_NAMESPACE` | nexo-prod |
  | `IMAGE_TAG` | prod |

---

## 🔀 Branch Protection Rules

Acesse: **Settings → Branches → Add branch protection rule**

### Regra: `main`

```
Branch name pattern: main

☑️ Require a pull request before merging
  ☑️ Require approvals: 1
  ☑️ Dismiss stale pull request approvals when new commits are pushed

☑️ Require status checks to pass before merging
  ☑️ Require branches to be up to date before merging
  Status checks:
    - ci-backend
    - ci-frontend
    - ci-auth

☑️ Require conversation resolution before merging

☐ Do not allow bypassing the above settings
```

### Regra: `develop`

```
Branch name pattern: develop

☑️ Require status checks to pass before merging
  Status checks:
    - ci-backend
    - ci-frontend
    - ci-auth
```

---

## 📁 Estrutura de Workflows

```
.github/
└── workflows/
    ├── ci-main.yml          # CI - Orquestrador principal
    ├── cd-main.yml          # CD - Deploy automático
    ├── _ci-reusable.yml     # CI reutilizável (build/test)
    └── _cd-reusable.yml     # CD reutilizável (push DockerHub)
```

---

## 🔄 Fluxo CI/CD

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  git push    │────▶│   CI Tests   │────▶│  CD Build    │
│  (branch)    │     │  (lint/test) │     │  (DockerHub) │
└──────────────┘     └──────────────┘     └──────────────┘
                                                 │
                                                 ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    K3D       │◀────│    ArgoCD    │◀────│   Image      │
│   (pods)     │     │    Sync      │     │  Updater     │
└──────────────┘     └──────────────┘     └──────────────┘
```

### Trigger por Branch

| Branch     | CI  | CD  | Ambiente     |
| ---------- | --- | --- | ------------ |
| develop    | ✅  | ✅  | nexo-develop |
| qa         | ✅  | ✅  | nexo-qa      |
| staging    | ✅  | ✅  | nexo-staging |
| main       | ✅  | ✅  | nexo-prod    |
| feature/\* | ✅  | ❌  | -            |
| fix/\*     | ✅  | ❌  | -            |

---

## ⚙️ Configurar Actions

### Habilitar Actions

1. **Settings → Actions → General**
2. **Actions permissions**: Allow all actions
3. **Workflow permissions**: Read and write permissions
4. ☑️ Allow GitHub Actions to create and approve pull requests

---

## 🐳 DockerHub Repositories

Crie os repositórios no DockerHub:

1. Acesse [hub.docker.com](https://hub.docker.com)
2. Create Repository para cada:
   - `geraldobl58/nexo-fe`
   - `geraldobl58/nexo-be`
   - `geraldobl58/nexo-auth`
3. Visibility: **Public** (ou Private com plano pago)

---

## ✅ Checklist de Verificação

```bash
# Verificar se os secrets estão configurados
# GitHub → Settings → Secrets → Actions

☑️ DOCKERHUB_USERNAME    = geraldobl58
☑️ DOCKERHUB_TOKEN       = <token>
☑️ DOCKERHUB_NAMESPACE   = geraldobl58 (variable)

# Verificar environments
☑️ develop    (branch: develop)
☑️ qa         (branch: qa)
☑️ staging    (branch: staging)
☑️ production (branch: main, com aprovação)

# Verificar DockerHub repos
☑️ geraldobl58/nexo-fe
☑️ geraldobl58/nexo-be
☑️ geraldobl58/nexo-auth

# Testar pipeline
git checkout develop
git commit --allow-empty -m "test: trigger CI/CD"
git push
```

---

## 🔍 Monitorar Pipelines

1. Acesse **Actions** no GitHub
2. Veja os workflows em execução
3. Verifique logs de cada job
4. Em caso de falha, veja o erro detalhado

---

## ➡️ Próximos Passos

- [05-cicd.md](05-cicd.md) - Detalhes do pipeline CI/CD
- [06-git-workflow.md](06-git-workflow.md) - Fluxo de branches
