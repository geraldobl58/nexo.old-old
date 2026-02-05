# 🛠️ Desenvolvimento Local

Guia completo para desenvolvimento local com K3D e ArgoCD.

## 🎯 Overview

O ambiente local espelha completamente a produção usando K3D (Kubernetes local), permitindo desenvolver e testar em um ambiente idêntico.

## 📋 Pré-requisitos

### Software Necessário

```bash
# Verificar instalações
docker --version        # 20.10+
k3d version            # 5.0+
kubectl version        # 1.28+
helm version           # 3.12+
```

### Recursos Mínimos

- **RAM**: 8GB (16GB recomendado)
- **CPU**: 4 cores (8 recomendado)
- **Disco**: 20GB livres
- **SO**: macOS, Linux ou Windows (WSL2)

## 🚀 Setup Inicial

### 1. Clone e Configure

```bash
# Clone o repositório
git clone https://github.com/geraldobl58/nexo.git
cd nexo

# Configure token GitHub
cp .env.template .env
nano .env  # Adicione GITHUB_TOKEN=ghp_...

# Carregue variáveis
export $(cat .env | xargs)
```

### 2. Execute Setup Completo

```bash
cd local
make setup

# OU manualmente
./scripts/setup.sh
```

**Tempo**: ~5-7 minutos

**O que acontece:**

1. ✅ Verifica dependências (instala se necessário)
2. ✅ Configura repositórios Helm
3. ✅ Cria cluster K3D (3 nodes)
4. ✅ Instala NGINX Ingress
5. ✅ Instala ArgoCD
6. ✅ Instala Prometheus/Grafana
7. ✅ Cria 4 ambientes (namespaces)
8. ✅ Cria secrets GHCR
9. ✅ Deploy 12 aplicações
10. ✅ Configura auto-sync

### 3. Verificar Instalação

```bash
# Status geral
make status

# Pods por namespace
kubectl get pods -A

# Aplicações ArgoCD
kubectl get applications -n argocd

# Deve mostrar 12 apps: Synced + Healthy
```

## 🏗️ Estrutura do Projeto

```
nexo/
├── apps/                      # Código das aplicações
│   ├── nexo-auth/            # Keycloak (Auth)
│   │   ├── Dockerfile
│   │   ├── themes/
│   │   └── package.json
│   │
│   ├── nexo-be/              # Backend (NestJS)
│   │   ├── Dockerfile
│   │   ├── src/
│   │   ├── prisma/
│   │   └── package.json
│   │
│   └── nexo-fe/              # Frontend (Next.js)
│       ├── Dockerfile
│       ├── src/
│       └── package.json
│
├── local/                     # Ambiente K3D
│   ├── scripts/              # Scripts de gerenciamento
│   │   ├── setup.sh         # Setup completo
│   │   ├── destroy.sh       # Limpar ambiente
│   │   └── status.sh        # Ver status
│   │
│   ├── argocd/              # Configurações ArgoCD
│   │   ├── projects/        # ArgoCD Projects
│   │   ├── apps/            # Applications (12 apps)
│   │   └── nodeport.yaml    # NodePort config
│   │
│   ├── helm/                # Helm Charts
│   │   ├── nexo-auth/
│   │   ├── nexo-be/
│   │   └── nexo-fe/
│   │
│   ├── k3d/                 # Config K3D
│   │   └── config.yaml
│   │
│   ├── observability/       # Monitoring
│   │   ├── values.yaml
│   │   └── ingress.yaml
│   │
│   └── Makefile             # Comandos úteis
│
├── scripts/                  # CI/CD Scripts
│   ├── promote.sh
│   ├── validate-deploy.sh
│   └── setup-pipeline.sh
│
├── packages/                 # Pacotes compartilhados
│   ├── auth/
│   ├── config/
│   └── ui/
│
└── documentation/            # Esta documentação
```

## 💻 Workflow de Desenvolvimento

### 1. Criar Feature Branch

```bash
# Sempre partir de develop
git checkout develop
git pull origin develop

# Criar branch de feature
git checkout -b feature/nova-funcionalidade

# OU usar convenção
git checkout -b feat/add-user-profile
git checkout -b fix/login-bug
git checkout -b chore/update-deps
```

### 2. Desenvolvimento Local (Fora do K3D)

Para desenvolvimento rápido, rode as apps localmente:

```bash
# Terminal 1: Backend
cd apps/nexo-be
pnpm install
pnpm dev
# API em http://localhost:3333

# Terminal 2: Frontend
cd apps/nexo-fe
pnpm install
pnpm dev
# UI em http://localhost:3000

# Terminal 3: Auth (se necessário)
cd apps/nexo-auth
# Keycloak via Docker Compose
```

**Vantagens:**

- ⚡ Hot reload instantâneo
- 🐛 Debug fácil
- 🔄 Iteração rápida

### 3. Testar no K3D

Quando pronto, teste no ambiente K3D:

```bash
# Build imagens
cd local
make build-images

# Sync ArgoCD (force update)
make argocd-sync

# Ver logs
make logs-be
make logs-fe
```

### 4. Commit e Push

```bash
# Add mudanças
git add .

# Commit (seguir Conventional Commits)
git commit -m "feat: adiciona perfil de usuário"

# Push
git push origin feature/nova-funcionalidade
```

### 5. Pull Request

```bash
# Criar PR via CLI
gh pr create --base develop --title "feat: adiciona perfil de usuário"

# OU via UI
# https://github.com/geraldobl58/nexo/compare
```

## 🔄 Hot Reload e Live Development

### Backend (NestJS)

```bash
cd apps/nexo-be

# Dev mode com watch
pnpm dev

# Com debug
pnpm dev:debug

# Attach debugger no VSCode (porta 9229)
```

### Frontend (Next.js)

```bash
cd apps/nexo-fe

# Dev mode com fast refresh
pnpm dev

# Turbo mode
pnpm dev --turbo
```

### Sincronizar com K3D

Opção 1: **Rebuild manual**

```bash
cd local
make build-images
make argocd-sync
```

Opção 2: **Watch mode** (futuro)

```bash
# Skaffold ou Tilt para auto-rebuild
skaffold dev
```

## 🐳 Docker e Imagens

### Build Local

```bash
# Build todas as imagens
cd local
make build-images

# Build individual
docker build -t ghcr.io/geraldobl58/nexo-be:dev -f apps/nexo-be/Dockerfile .

# Listar imagens
docker images | grep nexo
```

### Push para Registry Local

```bash
# Tag para registry local do K3D
docker tag ghcr.io/geraldobl58/nexo-be:dev localhost:5050/nexo-be:dev

# Push
docker push localhost:5050/nexo-be:dev
```

### Limpar Imagens

```bash
# Remove imagens não usadas
docker system prune -a

# Remove volumes
docker volume prune
```

## 🔍 Debug e Troubleshooting

### Ver Logs

```bash
# Logs de uma aplicação
kubectl logs -n nexo-develop -l app.kubernetes.io/name=nexo-be -f --tail=100

# Logs de um pod específico
kubectl logs -n nexo-develop nexo-be-xxx-yyy -f

# Logs de todos os containers de um pod
kubectl logs -n nexo-develop nexo-be-xxx-yyy --all-containers=true
```

### Port Forward

```bash
# Acessar serviço diretamente
kubectl port-forward -n nexo-develop svc/nexo-be-develop 3333:3333

# Acessar pod
kubectl port-forward -n nexo-develop pod/nexo-be-xxx-yyy 3333:3333

# Múltiplas portas
kubectl port-forward -n nexo-develop svc/nexo-be-develop 3333:3333 9229:9229
```

### Exec em Pod

```bash
# Shell interativo
kubectl exec -it -n nexo-develop nexo-be-xxx-yyy -- /bin/sh

# Comando único
kubectl exec -n nexo-develop nexo-be-xxx-yyy -- env
kubectl exec -n nexo-develop nexo-be-xxx-yyy -- ls -la /app

# Ver arquivos
kubectl exec -n nexo-develop nexo-be-xxx-yyy -- cat /app/package.json
```

### Describe Resources

```bash
# Pod
kubectl describe pod -n nexo-develop nexo-be-xxx-yyy

# Deployment
kubectl describe deployment -n nexo-develop nexo-be-develop

# Service
kubectl describe svc -n nexo-develop nexo-be-develop

# Ver eventos
kubectl get events -n nexo-develop --sort-by='.lastTimestamp' | tail -20
```

## 🧪 Testes

### Unit Tests

```bash
# Backend
cd apps/nexo-be
pnpm test
pnpm test:watch
pnpm test:cov

# Frontend
cd apps/nexo-fe
pnpm test
```

### E2E Tests

```bash
# Backend E2E
cd apps/nexo-be
pnpm test:e2e

# Frontend E2E
cd apps/nexo-fe
pnpm test:e2e
```

### Testes no K3D

```bash
# Health checks
curl http://develop.api.nexo.local/health

# API tests
curl http://develop.api.nexo.local/api/v1/users

# Frontend
curl http://develop.nexo.local
```

## 🔄 Sincronização ArgoCD

### Manual Sync

```bash
# Via Makefile
make argocd-sync

# Via kubectl (uma app)
kubectl patch application nexo-be-develop -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'

# Sync todas
for app in $(kubectl get applications -n argocd -o name); do
  kubectl patch $app -n argocd --type merge \
    -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
done
```

### Hard Refresh

```bash
# Forçar re-apply (útil quando stuck)
kubectl delete application nexo-be-develop -n argocd
kubectl apply -f local/argocd/apps/nexo-develop.yaml

# Restart ArgoCD
kubectl rollout restart deployment argocd-server -n argocd
```

## 📊 Monitoramento

### Prometheus

```bash
# Port forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Queries úteis:
# - container_memory_usage_bytes
# - container_cpu_usage_seconds_total
# - http_requests_total
```

### Grafana

```bash
# Acessar via Ingress
open http://grafana.local.nexo.app

# Port forward (alternativa)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Login: admin/admin
```

### Logs Agregados (Futuro: Loki)

```bash
# Instalar Loki Stack
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false

# Query logs no Grafana
# LogQL: {namespace="nexo-develop"}
```

## 🛠️ Comandos Úteis

```bash
# Ver todos os recursos
kubectl get all -n nexo-develop

# Restart de deployment
kubectl rollout restart deployment/nexo-be-develop -n nexo-develop

# Scale
kubectl scale deployment/nexo-be-develop --replicas=2 -n nexo-develop

# Ver uso de recursos
kubectl top nodes
kubectl top pods -n nexo-develop

# Config maps
kubectl get cm -n nexo-develop
kubectl describe cm nexo-be-config -n nexo-develop

# Secrets
kubectl get secrets -n nexo-develop
kubectl describe secret ghcr-secret -n nexo-develop
```

## 🧹 Limpeza

### Limpar Ambiente

```bash
# Destroy tudo
cd local && make destroy

# Manualmente
k3d cluster delete nexo-local
docker system prune -a -f --volumes
```

### Reset Parcial

```bash
# Deletar apenas aplicações
kubectl delete namespace nexo-develop
kubectl delete namespace nexo-qa
kubectl delete namespace nexo-staging
kubectl delete namespace nexo-prod

# Recriar via ArgoCD
kubectl apply -f local/argocd/apps/
make argocd-sync
```

## 💡 Dicas e Boas Práticas

### 1. Use Aliases

Adicione ao `~/.zshrc`:

```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kdp='kubectl describe pod'
alias kl='kubectl logs -f'
alias kex='kubectl exec -it'

alias nexo-dev='cd ~/nexo && code .'
alias nexo-setup='cd ~/nexo/local && make setup'
alias nexo-status='cd ~/nexo/local && make status'
```

### 2. Use Watch

```bash
# Watch pods
watch kubectl get pods -n nexo-develop

# Watch applications
watch kubectl get applications -n argocd
```

### 3. Use Stern para Logs

```bash
# Instalar
brew install stern

# Ver logs de todos os pods do backend
stern -n nexo-develop nexo-be

# Com regex
stern -n nexo-develop "nexo-.*"
```

### 4. Use k9s

```bash
# Instalar
brew install k9s

# Executar
k9s

# Atalhos:
# 0 - Todos namespaces
# : - Comando
# / - Filtro
# d - Describe
# l - Logs
```

## 📚 Recursos

- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [K3D Docs](https://k3d.io/)
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Helm Docs](https://helm.sh/docs/)

---

[← GitHub Setup](./03-setup-github.md) | [Voltar](./README.md) | [Próximo: Git Workflow →](./05-git-workflow.md)
