# 📚 Nexo Platform - Documentação

Guia completo para desenvolver, testar e fazer deploy da Plataforma Nexo.

## 🗂️ Índice

| #   | Documento                                | Descrição                         |
| --- | ---------------------------------------- | --------------------------------- |
| 01  | [Quick Start](01-quick-start.md)         | Começar em 5 minutos              |
| 02  | [Arquitetura](02-architecture.md)        | Visão técnica do sistema          |
| 03  | [Ambiente K3D](03-environment.md)        | Setup do Kubernetes local         |
| 04  | [GitHub Setup](04-github-setup.md)       | Secrets, Variables e Environments |
| 05  | [CI/CD Pipeline](05-cicd.md)             | GitHub Actions + ArgoCD           |
| 06  | [Git Workflow](06-git-workflow.md)       | Branches e fluxo de trabalho      |
| 07  | [Desenvolvimento](07-development.md)     | Guia do dia a dia                 |
| 08  | [API Reference](08-api.md)               | Documentação da API REST          |
| 09  | [Observabilidade](09-observability.md)   | Métricas, Logs e Alertas          |
| 10  | [Troubleshooting](10-troubleshooting.md) | Solução de problemas              |

---

## 🎯 Por Onde Começar?

### Novo no projeto?

1. Leia [01-quick-start.md](01-quick-start.md) - Setup em 5 minutos
2. Configure o GitHub seguindo [04-github-setup.md](04-github-setup.md)
3. Entenda o fluxo em [06-git-workflow.md](06-git-workflow.md)

### Vai fazer deploy?

1. Verifique [03-environment.md](03-environment.md) - Ambientes e URLs
2. Siga [05-cicd.md](05-cicd.md) - Pipeline CI/CD

### Precisa debugar?

1. Consulte [10-troubleshooting.md](10-troubleshooting.md)

---

## 🏗️ Stack Tecnológica

| Componente | Tecnologia     | Versão |
| ---------- | -------------- | ------ |
| Backend    | NestJS         | 10.x   |
| Frontend   | Next.js        | 14.x   |
| Auth       | Keycloak       | 26.x   |
| Database   | PostgreSQL     | 16     |
| Kubernetes | K3D            | 1.29+  |
| GitOps     | ArgoCD         | 2.x    |
| CI/CD      | GitHub Actions | -      |
| Registry   | DockerHub      | -      |

---

## 🌐 URLs de Acesso

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

> (\*) Senha ArgoCD: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

---

## 🌿 Fluxo de Branches

```
feature/* → develop → qa → staging → main
    │          │        │       │        │
    │          │        │       │        └─► Produção (aprovação)
    │          │        │       └─► Staging (automático)
    │          │        └─► QA (automático)
    │          └─► Develop (automático)
    └─► Desenvolvimento local
```

---

## ⚡ Comandos Rápidos

### Raiz do Projeto (`/nexo`)

```bash
make help       # Ver todos os comandos
make setup      # Setup inicial (deps + Docker)
make start      # Iniciar PostgreSQL + Keycloak
make stop       # Parar containers
make dev-be     # Backend localhost:3333
make dev-fe     # Frontend localhost:3000
make db-studio  # Prisma Studio
```

### Local K3D (`/nexo/local`)

```bash
make help           # Ver todos os comandos
make setup          # Setup K3D + ArgoCD + Observabilidade
make destroy        # Destruir cluster
make status         # Status do ambiente
make pods           # Listar pods
make logs-be        # Logs backend
make logs-fe        # Logs frontend
make logs-auth      # Logs Keycloak
make argocd-password # Senha ArgoCD
make restart-all    # Restart pods
```

---

## 📞 Suporte

- **Issues:** https://github.com/geraldobl58/nexo/issues
- **Wiki:** https://github.com/geraldobl58/nexo/wiki
