# ═══════════════════════════════════════════════════════════════════════════════
# NEXO PLATFORM - Makefile
# ═══════════════════════════════════════════════════════════════════════════════
# Documentação: make help
# ═══════════════════════════════════════════════════════════════════════════════

.PHONY: help setup start stop dev-be dev-fe build test lint clean
.DEFAULT_GOAL := help

# ───────────────────────────────────────────────────────────────────────────────
# Variáveis
# ───────────────────────────────────────────────────────────────────────────────
REGISTRY := docker.io/geraldobl58

# Cores
C := \033[36m
G := \033[32m
Y := \033[33m
R := \033[31m
B := \033[1m
N := \033[0m

# ═══════════════════════════════════════════════════════════════════════════════
# 📖 HELP
# ═══════════════════════════════════════════════════════════════════════════════

help:
	@echo ""
	@echo "$(B)🏗️  NEXO PLATFORM$(N)"
	@echo ""
	@echo "$(B)SETUP$(N)"
	@echo "  make setup         Instala dependências + Docker (PostgreSQL, Keycloak)"
	@echo ""
	@echo "$(B)DEV LOCAL$(N)"
	@echo "  make start         Inicia PostgreSQL + Keycloak (Docker Compose)"
	@echo "  make stop          Para containers"
	@echo "  make status        Status dos containers"
	@echo "  make logs          Logs dos containers"
	@echo ""
	@echo "$(B)APLICAÇÕES$(N)"
	@echo "  make dev-be        Backend NestJS (localhost:3333)"
	@echo "  make dev-fe        Frontend Next.js (localhost:3000)"
	@echo ""
	@echo "$(B)BUILD & TEST$(N)"
	@echo "  make build         Build de todos os pacotes"
	@echo "  make test          Executa testes"
	@echo "  make lint          Lint do código"
	@echo ""
	@echo "$(B)DOCKER$(N)"
	@echo "  make build-fe      Build imagem Frontend"
	@echo "  make build-be      Build imagem Backend"
	@echo "  make build-auth    Build imagem Auth"
	@echo "  make build-all     Build todas as imagens"
	@echo ""
	@echo "$(B)GIT WORKFLOW$(N)"
	@echo "  make promote-qa       Promover develop → qa"
	@echo "  make promote-staging  Promover qa → staging"
	@echo "  make promote-prod     Promover staging → main (prod)"
	@echo ""
	@echo "$(B)DATABASE$(N)"
	@echo "  make db-migrate    Executa migrações Prisma"
	@echo "  make db-generate   Gera client Prisma"
	@echo "  make db-studio     Abre Prisma Studio"
	@echo "  make db-seed       Popula banco com dados iniciais"
	@echo "  make db-reset      Reset completo do banco (⚠️ DESTRUTIVO)"
	@echo ""
	@echo "$(B)UTILS$(N)"
	@echo "  make doctor        Verifica dependências instaladas"
	@echo "  make clean         Limpa node_modules e containers"
	@echo ""
	@echo "$(Y)🏠 K3D LOCAL: cd local && make help$(N)"
	@echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 SETUP
# ═══════════════════════════════════════════════════════════════════════════════

setup: doctor
	@echo "$(B)📦 Instalando dependências...$(N)"
	@pnpm install
	@echo "$(B)🐳 Iniciando infraestrutura local...$(N)"
	@docker compose up -d
	@sleep 5
	@cd apps/nexo-be && pnpm prisma generate 2>/dev/null || true
	@echo "$(G)✅ Setup concluído!$(N)"
	@echo ""
	@echo "   Próximos passos:"
	@echo "   make dev-be  → Backend (localhost:3333)"
	@echo "   make dev-fe  → Frontend (localhost:3000)"

# ═══════════════════════════════════════════════════════════════════════════════
# 🐳 DOCKER COMPOSE - Infraestrutura Local
# ═══════════════════════════════════════════════════════════════════════════════

start:
	@docker compose up -d
	@sleep 5
	@./scripts/keycloak-init.sh 2>/dev/null || true
	@echo "$(G)✅ PostgreSQL:5432 | Keycloak:8080$(N)"

stop:
	@docker compose down
	@echo "$(G)✅ Containers parados$(N)"

keycloak-init:
	@./scripts/keycloak-init.sh

status:
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

logs:
	@docker compose logs -f --tail=100

# ═══════════════════════════════════════════════════════════════════════════════
# 💻 DESENVOLVIMENTO LOCAL
# ═══════════════════════════════════════════════════════════════════════════════

dev-be:
	@echo "$(B)⚙️  Backend$(N) → http://localhost:3333"
	@cd apps/nexo-be && pnpm start:dev

dev-fe:
	@echo "$(B)🎨 Frontend$(N) → http://localhost:3000"
	@cd apps/nexo-fe && pnpm dev

build:
	@pnpm build

test:
	@pnpm test

lint:
	@pnpm lint

# ═══════════════════════════════════════════════════════════════════════════════
# 🐳 DOCKER BUILD
# ═══════════════════════════════════════════════════════════════════════════════

build-fe:
	@echo "$(B)🔨 Building Frontend...$(N)"
	@docker build -t $(REGISTRY)/nexo-fe:latest -f apps/nexo-fe/Dockerfile .

build-be:
	@echo "$(B)🔨 Building Backend...$(N)"
	@docker build -t $(REGISTRY)/nexo-be:latest -f apps/nexo-be/Dockerfile .

build-auth:
	@echo "$(B)🔨 Building Auth...$(N)"
	@docker build -t $(REGISTRY)/nexo-auth:latest -f apps/nexo-auth/Dockerfile apps/nexo-auth

build-all: build-fe build-be build-auth
	@echo "$(G)✅ Todas as imagens buildadas$(N)"

# ═══════════════════════════════════════════════════════════════════════════════
# � GIT WORKFLOW (Promoção entre Ambientes)
# ═══════════════════════════════════════════════════════════════════════════════

promote-qa:
	@echo "$(B)🚀 Promovendo develop → qa$(N)"
	@./scripts/promote.sh develop qa

promote-staging:
	@echo "$(B)🚀 Promovendo qa → staging$(N)"
	@./scripts/promote.sh qa staging

promote-prod:
	@echo "$(B)🚀 Promovendo staging → main (prod)$(N)"
	@./scripts/promote.sh staging main

# ═══════════════════════════════════════════════════════════════════════════════
# �🗄️ DATABASE (Prisma)
# ═══════════════════════════════════════════════════════════════════════════════

db-migrate:
	@cd apps/nexo-be && pnpm prisma migrate dev

db-generate:
	@cd apps/nexo-be && pnpm prisma generate

db-studio:
	@cd apps/nexo-be && pnpm prisma studio

db-seed:
	@cd apps/nexo-be && pnpm prisma db seed

db-reset:
	@echo "$(R)⚠️  ATENÇÃO: Isso irá APAGAR todos os dados!$(N)"
	@read -p "Continuar? [y/N] " c && [ "$$c" = "y" ] || exit 1
	@cd apps/nexo-be && pnpm prisma migrate reset --force

# ═══════════════════════════════════════════════════════════════════════════════
# 🛠️ UTILITÁRIOS
# ═══════════════════════════════════════════════════════════════════════════════

doctor:
	@echo "$(B)🩺 Verificando dependências...$(N)"
	@printf "Node.js:  " && node --version 2>/dev/null || echo "❌ Não instalado"
	@printf "pnpm:     " && pnpm --version 2>/dev/null || echo "❌ Não instalado"
	@printf "Docker:   " && docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "❌ Não instalado"
	@printf "Git:      " && git --version 2>/dev/null | cut -d' ' -f3 || echo "❌ Não instalado"
	@echo "$(G)✅ Verificação concluída$(N)"

clean:
	@echo "$(R)⚠️  Isso irá remover containers e node_modules!$(N)"
	@read -p "Continuar? [y/N] " c && [ "$$c" = "y" ] || exit 1
	@docker compose down -v --remove-orphans 2>/dev/null || true
	@rm -rf node_modules apps/*/node_modules packages/*/node_modules 2>/dev/null || true
	@echo "$(G)✅ Limpeza concluída$(N)"
