# Scripts de Desenvolvimento Local

Scripts para gerenciar o ambiente K3D local do Nexo Platform.

## 📋 Scripts Disponíveis

### Setup e Gerenciamento

- **`setup.sh`** - Setup completo do ambiente local (K3D + ArgoCD + Observabilidade)

  ```bash
  # Opção 1: Passar token como argumento
  ./scripts/setup.sh ghp_YOUR_GITHUB_TOKEN

  # Opção 2: Usar variável de ambiente
  export GITHUB_TOKEN=ghp_YOUR_GITHUB_TOKEN
  ./scripts/setup.sh

  # Opção 3: Via Makefile
  export GITHUB_TOKEN=ghp_YOUR_GITHUB_TOKEN
  make setup
  ```

- **`destroy.sh`** - Remove completamente o ambiente local

  ```bash
  ./scripts/destroy.sh
  # ou
  make destroy
  ```

- **`status.sh`** - Mostra status completo do ambiente
  ```bash
  ./scripts/status.sh
  # ou
  make status
  ```

## 🚀 O que o setup.sh faz?

O script de setup automatiza todo o processo de criação do ambiente local:

1. ✅ Verifica e instala dependências (Helm, k3d, kubectl)
2. ✅ Configura repositórios Helm (ingress-nginx, prometheus-community, argo)
3. ✅ Cria cluster K3D com 3 nodes (1 server + 2 agents)
4. ✅ Verifica registry local (localhost:5050)
5. ✅ Cria namespaces para todos os ambientes (develop, qa, staging, prod, argocd, monitoring)
6. ✅ Instala NGINX Ingress Controller
7. ✅ Instala ArgoCD + configura NodePort (porta 30080)
8. ✅ Instala stack de observabilidade (Prometheus + Grafana + Alertmanager)
9. ✅ Aplica Ingress do observability
10. ✅ Cria secrets GHCR em todos os namespaces
11. ✅ Aplica projetos do ArgoCD (4 projetos)
12. ✅ Aplica aplicações do ArgoCD (12 apps: nexo-auth, nexo-be, nexo-fe × 4 ambientes)
13. ✅ Sincroniza todas as aplicações automaticamente

**Tudo em um único comando!** 🎉

## 🔐 Configuração do GitHub Token

O token do GitHub Container Registry (GHCR) é necessário para que o Kubernetes possa fazer pull das imagens privadas.

### Como obter o token:

1. Acesse: https://github.com/settings/tokens
2. Clique em "Generate new token (classic)"
3. Selecione os scopes:
   - ✅ `read:packages` (obrigatório)
   - ✅ `write:packages` (se quiser fazer push)
4. Copie o token gerado (começa com `ghp_...`)

## 📊 Acessos após o Setup

Após executar o setup, você terá acesso a:

### ArgoCD

- **URL**: http://localhost:30080
- **Username**: `admin`
- **Password**: Exibida no final do setup ou obtida com:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d && echo
  ```

### Observabilidade

- **Grafana**: http://grafana.local.nexo.app
- **Prometheus**: http://prometheus.local.nexo.app
- **Alertmanager**: http://alertmanager.local.nexo.app

### Aplicações Nexo (ambiente develop)

- **Frontend**: http://develop.nexo.local
- **Backend API**: http://develop.api.nexo.local
- **Keycloak Auth**: http://develop.auth.nexo.local

> **Nota**: Adicione os domínios ao seu `/etc/hosts`:
>
> ```
> 127.0.0.1 develop.nexo.local develop.api.nexo.local develop.auth.nexo.local
> 127.0.0.1 grafana.local.nexo.app prometheus.local.nexo.app alertmanager.local.nexo.app
> ```

## 🛠️ Comandos Úteis (via Makefile)

```bash
# Ver status geral
make status

# Listar todos os pods
make pods

# Ver logs das aplicações
make logs-be      # Backend
make logs-fe      # Frontend
make logs-auth    # Keycloak

# Forçar sync do ArgoCD
make argocd-sync

# Destruir ambiente
make destroy
```

## ⚠️ Diferença entre /scripts e /local/scripts

- **`/scripts`** → Scripts de CI/CD para GitHub Actions (promote, validate, etc.)
- **`/local/scripts`** → Scripts para desenvolvimento local (setup, destroy, status)

Os scripts de CI/CD **não devem ser executados manualmente** no ambiente local.

## 📚 Documentação Completa

Para mais detalhes sobre o ambiente local, veja:

- `/documentation/local/01-quick-start.md` - Guia de início rápido
- `/documentation/local/02-architecture.md` - Arquitetura do ambiente
- `/documentation/local/03-environment.md` - Variáveis de ambiente
- `/documentation/local/07-development.md` - Guia de desenvolvimento

## 🐛 Troubleshooting

### Cluster não inicia

```bash
# Verificar Docker
docker ps

# Recriar cluster
make destroy
make setup
```

### Pods não estão rodando

```bash
# Verificar eventos
kubectl get events -A --sort-by='.lastTimestamp'

# Forçar sync do ArgoCD
make argocd-sync
```

### Imagens não fazem pull

```bash
# Verificar secret GHCR
kubectl get secret ghcr-secret -n nexo-develop

# Recriar secrets
for ns in nexo-develop nexo-qa nexo-staging nexo-prod; do
  kubectl delete secret ghcr-secret -n $ns
  kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username=YOUR_USERNAME \
    --docker-password=YOUR_TOKEN \
    --namespace=$ns
done
```

Para mais troubleshooting, veja `/documentation/local/10-troubleshooting.md`.
