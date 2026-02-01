# 🏗️ Nexo Platform

<div align="center">

**Plataforma SaaS de Produção | GitOps | K3D Kubernetes**

[![CI](https://github.com/geraldobl58/nexo/actions/workflows/ci-main.yml/badge.svg)](https://github.com/geraldobl58/nexo/actions/workflows/ci-main.yml)
[![CD](https://github.com/geraldobl58/nexo/actions/workflows/cd-main.yml/badge.svg)](https://github.com/geraldobl58/nexo/actions/workflows/cd-main.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Node](https://img.shields.io/badge/node-20+-green.svg)](https://nodejs.org/)
[![pnpm](https://img.shields.io/badge/pnpm-9+-orange.svg)](https://pnpm.io/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-1.29+-326CE5.svg)](https://kubernetes.io/)

[Início Rápido](#-início-rápido) •
[Documentação](#-documentação) •
[Arquitetura](#-arquitetura) •
[Ambientes](#-ambientes) •
[Deploy](#-deploy)

</div>

---

## 🎯 Sobre o Projeto

A **Plataforma Nexo** é uma solução SaaS profissional para o mercado imobiliário, usando **K3D** como ambiente Kubernetes local que espelha produção com **GitOps automatizado**.

### Stack Fixa

| Componente      | Tecnologia             | Versão |
| --------------- | ---------------------- | ------ |
| Backend         | NestJS                 | 10.x   |
| Frontend        | Next.js                | 14.x   |
| Auth            | Keycloak               | 26.x   |
| Database        | PostgreSQL             | 16     |
| Cache           | Redis                  | 7      |
| Orquestração    | K3D (Kubernetes local) | 1.29+  |
| GitOps          | ArgoCD + Image Updater | 2.x    |
| CI/CD           | GitHub Actions         | -      |
| Ingress         | Traefik                | -      |
| Observabilidade | Prometheus + Grafana   | -      |

### Características

- ✅ **Monorepo** com Turborepo + pnpm workspaces
- ✅ **4 Ambientes** isolados por namespace (develop, qa, staging, prod)
- ✅ **GitOps** com ArgoCD (deploy automático por branch)
- ✅ **Observabilidade** completa (Prometheus, Grafana, Alertmanager)
- ✅ **Autenticação** enterprise com Keycloak + temas customizados
- ✅ **CI/CD** automatizado com GitHub Actions + ArgoCD Image Updater

---

## 🌿 Fluxo de Branches (GitFlow)

```
feature/* → develop → qa → staging → main (production)
     │          │       │       │          │
     │          │       │       │          └─► Deploy Produção (manual + aprovação)
     │          │       │       └─► Deploy Staging (automático)
     │          │       └─► Deploy QA (automático)
     │          └─► Deploy Develop (automático)
     └─► Desenvolvimento local
```

| Branch      | Ambiente   | Deploy     | Aprovação |
| ----------- | ---------- | ---------- | --------- |
| `feature/*` | local      | -          | -         |
| `develop`   | develop    | Automático | Não       |
| `qa`        | qa         | Automático | Não       |
| `staging`   | staging    | Automático | Não       |
| `main`      | production | Manual     | Sim       |

> 📖 Veja [Git Branching Strategy](documentation/local/git-branching-strategy.md) para detalhes completos.

---

## 🚀 Início Rápido

### Pré-requisitos

```bash
# macOS - Instalar via Homebrew
brew install k3d kubectl helm

# Verificar instalação
k3d version      # v5.x
kubectl version  # v1.29+
helm version     # v3.x
docker --version # 24.x+
```

### Setup K3D (1 comando!)

```bash
cd local
./scripts/setup.sh
```

### Acessos via /etc/hosts

Adicione ao `/etc/hosts`:

```
127.0.0.1 develop.nexo.local develop.api.nexo.local develop.auth.nexo.local
127.0.0.1 qa.nexo.local qa.api.nexo.local qa.auth.nexo.local
127.0.0.1 staging.nexo.local staging.api.nexo.local staging.auth.nexo.local
127.0.0.1 prod.nexo.local prod.api.nexo.local prod.auth.nexo.local
```

### URLs de Acesso

| Serviço       | URL                            | Credenciais      |
| ------------- | ------------------------------ | ---------------- |
| 🖥️ Frontend   | http://develop.nexo.local      | -                |
| ⚙️ Backend    | http://develop.api.nexo.local  | -                |
| 🔐 Keycloak   | http://develop.auth.nexo.local | admin / admin    |
| 📈 Grafana    | http://localhost:30030         | admin / admin123 |
| 🔀 ArgoCD     | http://localhost:30080         | admin / (\*)     |
| 📊 Prometheus | http://localhost:30090         | -                |

> (\*) Execute `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d` para obter a senha.

---

## 📖 Documentação

Toda a documentação está consolidada em `/documentation`:

| Documento                                                                 | Descrição                                                                                       |
| ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| **[🚀 Enterprise Pipeline](documentation/enterprise-pipeline/README.md)** | **⭐ NOVO** - Pipeline CI/CD enterprise-grade (Netflix/Spotify/Uber patterns) adaptada para K3D |
| [README K3D](documentation/local/README.md)                               | Guia completo do ambiente K3D                                                                   |
| [Quick Start](documentation/local/01-quick-start.md)                      | Setup em 5 minutos                                                                              |
| [Environments](documentation/local/03-environment.md)                     | Diferenças entre ambientes                                                                      |
| [Kubernetes](documentation/local/02-architecture.md)                      | Arquitetura técnica                                                                             |
| [Deploy](documentation/local/05-cicd.md)                                  | CI/CD e deploy (implementação atual)                                                            |
| [GitHub Actions](documentation/local/04-github-setup.md)                  | GitHub Secrets e Variables                                                                      |
| [Observabilidade](documentation/local/09-observability.md)                | Prometheus, Grafana, Alertas                                                                    |
| [Troubleshooting](documentation/local/10-troubleshooting.md)              | Erros comuns e soluções                                                                         |

**🎯 Por onde começar:**

1. **Arquitetura & Estratégia**: [Enterprise Pipeline Overview](documentation/enterprise-pipeline/00-k3d-integration.md)
2. **Setup Prático**: [Quick Start K3D](documentation/local/01-quick-start.md)
3. **Operação Diária**: [Development Guide](documentation/local/07-development.md)

---

## 🛠️ Comandos

### K3D / Kubernetes

```bash
cd local
./scripts/setup.sh      # 🚀 Setup completo K3D
./scripts/destroy.sh    # 🗑️  Destruir cluster
./scripts/status.sh     # 📊 Status do cluster
make pods               # 📋 Listar pods
make logs-be            # 📜 Logs backend
make logs-fe            # 📜 Logs frontend
make logs-auth          # 📜 Logs Keycloak
```

### Desenvolvimento

```bash
pnpm install            # Instalar dependências
pnpm dev                # Dev local (sem K3D)
pnpm build              # Build de produção
pnpm test               # Executar testes
pnpm lint               # Linting
```

---

## 📁 Estrutura do Projeto

```
nexo/
├── apps/
│   ├── nexo-be/         # Backend NestJS
│   ├── nexo-fe/         # Frontend Next.js
│   └── nexo-auth/       # Keycloak themes
├── packages/
│   ├── auth/            # Auth utils
│   ├── config/          # Config compartilhada
│   └── ui/              # UI components
├── local/               # 🏗️ Infraestrutura K3D
│   ├── argocd/          # ArgoCD apps/projects
│   ├── helm/            # Helm charts
│   ├── k3d/             # Config do cluster
│   ├── k8s/             # Manifests Kubernetes
│   ├── observability/   # Grafana, Prometheus, Loki
│   └── scripts/         # Setup scripts
├── documentation/
│   └── local/           # 📚 Toda documentação
└── .github/
    └── workflows/       # CI/CD pipelines
```

---

## 🧪 Ambientes

Todos os ambientes rodam no **mesmo cluster K3D**, separados por **namespaces**:

| Namespace      | Branch    | URL                | Deploy             |
| -------------- | --------- | ------------------ | ------------------ |
| `nexo-develop` | `develop` | develop.nexo.local | Automático         |
| `nexo-qa`      | `qa`      | qa.nexo.local      | Automático         |
| `nexo-staging` | `staging` | staging.nexo.local | Automático         |
| `nexo-prod`    | `main`    | prod.nexo.local    | Manual + Aprovação |

---

## 🚀 Deploy GitOps

### Fluxo Automático

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Commit  │───►│    CI    │───►│   Push   │───►│  ArgoCD  │───►│   K3D    │
│  (Git)   │    │  (Test)  │    │(DockerHub)│   │  (Sync)  │    │  (K8s)   │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### Deploy por Branch

| Ação                      | Resultado                                          |
| ------------------------- | -------------------------------------------------- |
| `git push origin develop` | CI → Build → DockerHub → ArgoCD → Deploy Develop   |
| `git push origin qa`      | CI → Build → DockerHub → ArgoCD → Deploy QA        |
| `git push origin staging` | CI → Build → DockerHub → ArgoCD → Deploy Staging   |
| Merge PR para `main`      | CI → Build → Aguarda Aprovação → Deploy Production |

> O **ArgoCD Image Updater** detecta automaticamente novas imagens no DockerHub e atualiza o cluster.

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua branch (`git checkout -b feature/nova-feature` a partir de `develop`)
3. Commit suas mudanças (`git commit -m 'feat: adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request para `develop`

> ⚠️ PRs diretos para `main` não são permitidos. Use o fluxo: `feature/* → develop → qa → staging → main`

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

<div align="center">

**🏗️ Nexo Platform** - Enterprise-grade Architecture

_Desenvolvido com ❤️ para alta performance e escalabilidade_

[⬆ Voltar ao topo](#-nexo-platform)

</div>
