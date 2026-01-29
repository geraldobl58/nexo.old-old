# 07 - Development

Guia de desenvolvimento diário.

---

## 🚀 Setup Diário

### Iniciar o Dia

```bash
# 1. Atualizar repositório
cd ~/Development/fullstack/nexo
git checkout develop
git pull origin develop

# 2. Verificar cluster K3D
kubectl get nodes
kubectl get pods -A | grep -v Running

# 3. Se cluster não existir
cd local
./scripts/setup.sh
```

### Verificar Serviços

```bash
# Status rápido
cd local
./scripts/status.sh

# URLs disponíveis
open http://develop.nexo.local      # Frontend
open http://develop.api.nexo.local  # Backend/Swagger
open http://develop.auth.nexo.local # Keycloak
```

---

## 💻 Desenvolvimento Local (Hot Reload)

### Opção 1: Desenvolvimento Direto (Recomendado para FE/BE)

```bash
# Terminal 1 - Backend
cd apps/nexo-be
pnpm dev
# http://localhost:3333

# Terminal 2 - Frontend
cd apps/nexo-fe
pnpm dev
# http://localhost:3000
```

### Opção 2: Desenvolvimento no K3D

Para testar integração completa:

```bash
# Fazer alterações no código
# Commit e push para develop
git add .
git commit -m "feat: minha alteração"
git push origin develop

# CI/CD vai:
# 1. Rodar testes
# 2. Build imagem Docker
# 3. Push para DockerHub
# 4. ArgoCD detecta e atualiza K3D

# Monitorar deploy
kubectl get pods -n nexo-develop -w
```

---

## 📦 Estrutura dos Apps

### nexo-fe (Frontend)

```
apps/nexo-fe/
├── src/
│   ├── app/              # App Router (Next.js 15)
│   │   ├── layout.tsx    # Layout principal
│   │   ├── page.tsx      # Página inicial
│   │   └── (routes)/     # Rotas agrupadas
│   ├── components/       # Componentes React
│   │   ├── ui/          # Componentes base (shadcn)
│   │   └── shared/      # Componentes compartilhados
│   └── lib/             # Utilitários
├── public/              # Arquivos estáticos
└── package.json
```

**Comandos:**

```bash
cd apps/nexo-fe
pnpm dev          # Desenvolvimento
pnpm build        # Build produção
pnpm lint         # Linter
pnpm test         # Testes
```

### nexo-be (Backend)

```
apps/nexo-be/
├── src/
│   ├── main.ts           # Entry point
│   ├── app.module.ts     # Módulo principal
│   └── modules/          # Módulos de domínio
│       ├── users/
│       ├── auth/
│       └── ...
├── prisma/
│   ├── schema.prisma     # Schema do banco
│   └── migrations/       # Migrations
├── test/                 # Testes E2E
└── package.json
```

**Comandos:**

```bash
cd apps/nexo-be
pnpm dev              # Desenvolvimento
pnpm build            # Build
pnpm test             # Testes unitários
pnpm test:e2e         # Testes E2E
pnpm prisma:generate  # Gerar Prisma Client
pnpm prisma:migrate   # Rodar migrations
pnpm prisma:studio    # UI do banco
```

### nexo-auth (Keycloak)

```
apps/nexo-auth/
├── Dockerfile            # Imagem customizada
├── themes/
│   └── nexo/            # Tema customizado
│       ├── login/       # Tela de login
│       └── account/     # Área do usuário
└── package.json
```

**Para desenvolver tema:**

```bash
# Editar arquivos em themes/nexo/
# Push para develop dispara rebuild da imagem

# Para teste local rápido:
cd apps/nexo-auth
docker build -t nexo-auth:local .
k3d image import nexo-auth:local -c nexo-local
```

---

## 🔄 Fluxo de Trabalho

### 1. Criar Feature

```bash
# Partir do develop
git checkout develop
git pull origin develop
git checkout -b feature/minha-feature

# Desenvolver...
```

### 2. Testar Localmente

```bash
# Frontend
cd apps/nexo-fe && pnpm dev

# Backend
cd apps/nexo-be && pnpm dev

# Testar no browser
```

### 3. Commit e Push

```bash
git add .
git commit -m "feat(fe): adiciona componente X"
git push origin feature/minha-feature
```

### 4. Abrir Pull Request

1. GitHub → Compare & pull request
2. Base: `develop` ← Compare: `feature/minha-feature`
3. Aguardar CI passar
4. Solicitar review (se necessário)
5. Merge

### 5. Verificar Deploy

Após merge em develop:

1. Acompanhar GitHub Actions
2. Verificar ArgoCD (http://localhost:30080)
3. Testar em http://develop.nexo.local

---

## 🗄️ Database

### Prisma Studio

```bash
cd apps/nexo-be
pnpm prisma studio
# Abre UI do banco em http://localhost:5555
```

### Migrations

```bash
# Criar migration
pnpm prisma migrate dev --name descricao

# Aplicar migrations
pnpm prisma migrate deploy

# Resetar banco (dev only)
pnpm prisma migrate reset
```

### Schema

```prisma
// apps/nexo-be/prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

---

## 🧪 Testes

### Frontend

```bash
cd apps/nexo-fe

# Rodar todos os testes
pnpm test

# Watch mode
pnpm test:watch

# Coverage
pnpm test:coverage
```

### Backend

```bash
cd apps/nexo-be

# Testes unitários
pnpm test

# Watch mode
pnpm test:watch

# Testes E2E
pnpm test:e2e

# Coverage
pnpm test:cov
```

---

## 📝 Logs

### Ver Logs no K3D

```bash
# Logs do frontend
kubectl logs -f deployment/nexo-fe -n nexo-develop

# Logs do backend
kubectl logs -f deployment/nexo-be -n nexo-develop

# Logs do Keycloak
kubectl logs -f deployment/nexo-auth -n nexo-develop

# Ou usar Makefile
cd local
make logs-fe
make logs-be
make logs-auth
```

### Grafana (Loki)

1. Acesse http://localhost:30030
2. Explore → Data source: Loki
3. Query: `{namespace="nexo-develop"}`

---

## 🔧 Debug

### VSCode Launch Config

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Backend",
      "type": "node",
      "request": "launch",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["run", "start:debug"],
      "cwd": "${workspaceFolder}/apps/nexo-be",
      "skipFiles": ["<node_internals>/**"]
    },
    {
      "name": "Debug Frontend",
      "type": "node",
      "request": "launch",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["run", "dev"],
      "cwd": "${workspaceFolder}/apps/nexo-fe"
    }
  ]
}
```

### Port Forward (se necessário)

```bash
# Backend no cluster
kubectl port-forward svc/nexo-be 3333:3333 -n nexo-develop

# PostgreSQL no cluster
kubectl port-forward svc/nexo-be-postgresql 5432:5432 -n nexo-develop
```

---

## 📊 Monitoramento

### Métricas (Prometheus)

- URL: http://localhost:30090
- Queries úteis:

  ```promql
  # CPU por pod
  container_cpu_usage_seconds_total{namespace="nexo-develop"}

  # Memória por pod
  container_memory_usage_bytes{namespace="nexo-develop"}
  ```

### Dashboards (Grafana)

- URL: http://localhost:30030
- Login: admin / admin123
- Dashboards pré-configurados:
  - Kubernetes Pods
  - Node Exporter
  - Traefik

---

## ⚡ Comandos Rápidos

```bash
# Alias sugeridos (adicionar no ~/.zshrc)
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgpa="kubectl get pods -A"
alias kdp="kubectl describe pod"
alias kl="kubectl logs -f"
alias kns="kubectl config set-context --current --namespace"

# Uso
kgp -n nexo-develop
kl deployment/nexo-be -n nexo-develop
kns nexo-develop  # Mudar namespace padrão
```

---

## ➡️ Próximos Passos

- [08-api.md](08-api.md) - Documentação da API
- [09-observability.md](09-observability.md) - Métricas e logs
- [10-troubleshooting.md](10-troubleshooting.md) - Resolução de problemas
