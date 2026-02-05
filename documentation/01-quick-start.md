# 🚀 Início Rápido

Guia para ter o Nexo Platform rodando em **5 minutos**.

## 📋 Pré-requisitos

- **Docker Desktop** instalado e rodando
- **Git** configurado
- **macOS** ou **Linux** (Windows via WSL2)
- **8GB RAM** mínimo (16GB recomendado)
- **20GB espaço** em disco

## ⚡ Setup Rápido

### 1. Clone o Repositório

```bash
git clone https://github.com/geraldobl58/nexo.git
cd nexo
```

### 2. Configure o GitHub Token

Você precisa de um GitHub Personal Access Token com permissão `read:packages`:

**Opção A: Arquivo .env (Recomendado - Token carrega automaticamente)**

```bash
# 1. Copie o template
cp .env.template .env

# 2. Edite o .env e adicione seu token
nano .env

# Conteúdo do .env:
GITHUB_TOKEN=ghp_seu_token_aqui
GITHUB_USERNAME=seu_usuario

# 3. Pronto! O script carrega automaticamente
```

**Opção B: Variável de Ambiente**

```bash
# Adicione ao ~/.zshrc ou ~/.bashrc
export GITHUB_TOKEN=ghp_seu_token_aqui
export GITHUB_USERNAME=seu_usuario

# Recarregue o shell
source ~/.zshrc
```

**Opção C: GitHub Secret (Para CI/CD)**

1. Acesse: https://github.com/seu-usuario/nexo/settings/secrets/actions
2. Clique em **"New repository secret"**
3. Nome: `GHCR_TOKEN`
4. Valor: `ghp_...`

### 3. Execute o Setup

```bash
cd local
make setup
```

**O setup irá:**
- 🔍 Detectar e carregar token do `.env` automaticamente
- ✅ OU pedir o token manualmente se não encontrar

**O que acontece:**

- ✅ Instala dependências (Helm, k3d, kubectl)
- ✅ Cria cluster K3D com 3 nodes
- ✅ Instala NGINX Ingress Controller
- ✅ Instala ArgoCD
- ✅ Instala Prometheus + Grafana + Alertmanager
- ✅ Cria 4 ambientes (develop, qa, staging, prod)
- ✅ Deploy de 12 aplicações (nexo-auth, nexo-be, nexo-fe × 4)
- ✅ Configura secrets GHCR

**Tempo estimado**: 5-7 minutos

## 🎯 Acessar Serviços

Após o setup, você terá acesso a:

### ArgoCD

```bash
# URL
http://localhost:30080

# Credenciais
Username: admin
Password: <exibido no final do setup>

# OU obtenha a senha com:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### Grafana, Prometheus e Alertmanager

Adicione ao `/etc/hosts`:

```bash
sudo nano /etc/hosts

# Adicione estas linhas:
127.0.0.1 grafana.local.nexo.app
127.0.0.1 prometheus.local.nexo.app
127.0.0.1 alertmanager.local.nexo.app
```

Acesse:

- **Grafana**: http://grafana.local.nexo.app (admin/admin)
- **Prometheus**: http://prometheus.local.nexo.app
- **Alertmanager**: http://alertmanager.local.nexo.app

### Aplicações Nexo (Develop)

Adicione ao `/etc/hosts`:

```bash
127.0.0.1 develop.nexo.local develop.api.nexo.local develop.auth.nexo.local
```

Acesse:

- **Frontend**: http://develop.nexo.local
- **API Backend**: http://develop.api.nexo.local
- **Keycloak Auth**: http://develop.auth.nexo.local

## ✅ Verificar Instalação

```bash
# Status geral
make status

# Listar pods
kubectl get pods -A

# Ver aplicações no ArgoCD
kubectl get applications -n argocd

# Deve mostrar 12 apps com status "Synced" e "Healthy"
```

## 📦 Estrutura do Ambiente

```
nexo/
├── apps/                    # Código das aplicações
│   ├── nexo-auth/          # Keycloak Auth
│   ├── nexo-be/            # Backend NestJS
│   └── nexo-fe/            # Frontend Next.js
├── local/                   # Ambiente K3D local
│   ├── scripts/            # Scripts de setup/destroy
│   ├── argocd/             # Configurações ArgoCD
│   ├── helm/               # Helm charts
│   └── k3d/                # Config cluster K3D
├── scripts/                 # Scripts CI/CD
└── documentation/           # Esta documentação
```

## 🎓 Próximos Passos

1. 📖 [Entenda a Arquitetura](./02-architecture.md)
2. 🔐 [Configure GitHub Secrets](./03-setup-github.md)
3. 🛠️ [Desenvolva Localmente](./04-local-development.md)
4. 🚢 [Configure CI/CD](./07-cicd-pipeline.md)

## 🆘 Problemas?

### Cluster não inicia

```bash
# Verificar Docker
docker ps

# Recriar cluster
make destroy
make setup
```

### Pods não sobem

```bash
# Ver eventos
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Forçar sync ArgoCD
make argocd-sync
```

### Erro de imagem

```bash
# Verificar secret
kubectl get secret ghcr-secret -n nexo-develop

# Recriar secrets
for ns in nexo-develop nexo-qa nexo-staging nexo-prod; do
  kubectl delete secret ghcr-secret -n $ns
  kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username=geraldobl58 \
    --docker-password=$GITHUB_TOKEN \
    --namespace=$ns
done
```

Veja mais em [Troubleshooting](./11-troubleshooting.md).

## 🧹 Limpar Ambiente

```bash
# Destruir tudo
cd local
make destroy

# Remove cluster, volumes e configurações
```

---

[← Voltar](./README.md) | [Próximo: Arquitetura →](./02-architecture.md)
