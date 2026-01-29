# 01 - Quick Start

Comece a desenvolver em 5 minutos.

---

## 📋 Pré-requisitos

### Software Necessário

```bash
# macOS - Instalar via Homebrew
brew install node@20 pnpm k3d kubectl helm

# Verificar versões
node -v      # v20.x
pnpm -v      # 9.x
k3d version  # v5.x
kubectl version --client
helm version
docker --version  # 24.x+
```

### Requisitos de Sistema

| Recurso | Mínimo     | Recomendado |
| ------- | ---------- | ----------- |
| RAM     | 8GB        | 16GB        |
| CPU     | 4 cores    | 8 cores     |
| Disco   | 20GB livre | 50GB livre  |

---

## 🚀 Setup (5 minutos)

### 1. Clonar o Repositório

```bash
git clone https://github.com/geraldobl58/nexo.git
cd nexo
```

### 2. Instalar Dependências

```bash
pnpm install
```

### 3. Configurar /etc/hosts

```bash
sudo nano /etc/hosts
```

Adicionar:

```
# Nexo Platform - Ambientes K3D
127.0.0.1 develop.nexo.local develop.api.nexo.local develop.auth.nexo.local
127.0.0.1 qa.nexo.local qa.api.nexo.local qa.auth.nexo.local
127.0.0.1 staging.nexo.local staging.api.nexo.local staging.auth.nexo.local
127.0.0.1 prod.nexo.local prod.api.nexo.local prod.auth.nexo.local
```

### 4. Criar Cluster K3D

```bash
cd local
./scripts/setup.sh
```

Isso vai:

- ✅ Criar cluster K3D (1 server + 2 agents)
- ✅ Instalar ArgoCD
- ✅ Instalar Prometheus + Grafana
- ✅ Configurar namespaces (develop, qa, staging, prod)
- ✅ Deploy das aplicações via ArgoCD

### 5. Verificar Status

```bash
./scripts/status.sh

# Ou manualmente:
kubectl get pods -A
```

---

## 🌐 Acessar Aplicações

Após o setup, acesse:

| Serviço     | URL                            | Credenciais      |
| ----------- | ------------------------------ | ---------------- |
| Frontend    | http://develop.nexo.local      | -                |
| Backend API | http://develop.api.nexo.local  | -                |
| Keycloak    | http://develop.auth.nexo.local | admin / admin    |
| ArgoCD      | http://localhost:30080         | admin / (\*)     |
| Grafana     | http://localhost:30030         | admin / admin123 |

> (\*) Obter senha ArgoCD:
>
> ```bash
> kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
> ```

---

## 💻 Desenvolvimento Local (sem K3D)

Se preferir desenvolver sem K3D:

```bash
# Terminal 1 - Backend
cd apps/nexo-be
pnpm dev

# Terminal 2 - Frontend
cd apps/nexo-fe
pnpm dev
```

Acesse:

- Frontend: http://localhost:3000
- Backend: http://localhost:3333
- Swagger: http://localhost:3333/api

---

## 🛠️ Comandos Úteis

### Makefile Raiz (`/nexo`)

```bash
make help         # Ver todos os comandos
make setup        # Setup inicial completo
make start        # Iniciar PostgreSQL + Keycloak (Docker)
make stop         # Parar containers
make status       # Status dos containers
make dev-be       # Backend localhost:3333
make dev-fe       # Frontend localhost:3000
make build        # Build todos os pacotes
make test         # Rodar testes
make lint         # Linter

# Docker Build
make build-fe     # Build imagem frontend
make build-be     # Build imagem backend
make build-auth   # Build imagem Keycloak
make build-all    # Build todas as imagens

# Database
make db-migrate   # Rodar migrations
make db-generate  # Gerar Prisma Client
make db-studio    # Abrir Prisma Studio
make db-reset     # Reset banco (DESTRUTIVO)

# Utilitários
make doctor       # Verificar dependências
make clean        # Limpar node_modules e containers
```

### Makefile Local K3D (`/nexo/local`)

```bash
make help             # Ver todos os comandos
make doctor           # Verificar dependências K3D
make setup            # Setup K3D + ArgoCD + Observabilidade
make destroy          # Destruir cluster
make status           # Status do ambiente

# Pods e Serviços
make pods             # Listar pods
make services         # Listar serviços
make nodes            # Listar nodes

# Logs
make logs-be          # Logs backend
make logs-fe          # Logs frontend
make logs-auth        # Logs Keycloak
make logs-argocd      # Logs ArgoCD

# Build e Deploy
make docker-login     # Login DockerHub
make build-be         # Build + push backend
make build-fe         # Build + push frontend
make build-auth       # Build + push Keycloak
make build-all        # Build + push tudo
make deploy-all       # Deploy todos os serviços
make pull-latest      # Forçar pull das últimas imagens

# ArgoCD
make argocd-password  # Mostrar senha ArgoCD
make argocd-sync      # Sincronizar applications
make image-updater    # Logs do Image Updater

# Restart
make restart-be       # Restart backend
make restart-fe       # Restart frontend
make restart-all      # Restart todos os pods

# Shell
make shell-be         # Shell no pod backend
make shell-fe         # Shell no pod frontend
```

---

## ❓ Problemas?

Consulte [10-troubleshooting.md](10-troubleshooting.md) para soluções.

### Problemas Comuns

| Problema              | Solução                             |
| --------------------- | ----------------------------------- |
| Porta 80 em uso       | `sudo lsof -i :80` e matar processo |
| Docker não inicia     | Reiniciar Docker Desktop            |
| Pods em CrashLoop     | `kubectl logs <pod> -n <namespace>` |
| Imagem não encontrada | Verificar DockerHub credentials     |

---

## ➡️ Próximos Passos

1. [04-github-setup.md](04-github-setup.md) - Configurar GitHub (secrets, environments)
2. [06-git-workflow.md](06-git-workflow.md) - Entender fluxo de branches
3. [07-development.md](07-development.md) - Guia de desenvolvimento diário
