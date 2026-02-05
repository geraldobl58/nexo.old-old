# 🚀 Guia de Setup Multi-Ambiente

Setup automatizado completo para **4 ambientes** (develop, qa, staging, prod) com **12 aplicações** no total.

## ⚡ Quick Start

```bash
# Com token do GitHub
cd local
./scripts/setup.sh ghp_YOUR_TOKEN

# Ou com variável de ambiente
export GITHUB_TOKEN=ghp_YOUR_TOKEN
./scripts/setup.sh

# Ou interativo (será solicitado durante o setup)
./scripts/setup.sh
```

## 📦 O que é instalado automaticamente

### Infraestrutura Base

- ✅ Cluster K3D (nexo-local) - 3 nodes
- ✅ NGINX Ingress Controller
- ✅ ArgoCD + NodePort (porta 30080)
- ✅ kube-prometheus-stack:
  - Grafana (porta 30030)
  - Prometheus (porta 30090)
  - Alertmanager (porta 30093)

### Namespaces

- `nexo-develop` - Ambiente de desenvolvimento
- `nexo-qa` - Ambiente de qualidade
- `nexo-staging` - Ambiente de homologação
- `nexo-prod` - Ambiente de produção
- `argocd` - GitOps
- `monitoring` - Observabilidade

### Aplicações (4 ambientes x 3 apps = 12 apps)

Cada ambiente possui:

- **Backend** (NestJS API)
- **Frontend** (Next.js)
- **Auth** (Keycloak + PostgreSQL)

### GHCR Secrets

O script cria automaticamente o secret `ghcr-secret` em todos os namespaces para autenticação no GitHub Container Registry.

## 🔐 Credenciais

### ArgoCD

- URL: http://localhost:30080
- User: `admin`
- Password: Obter com `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

### Grafana

- URL: http://localhost:30030
- User: `admin`
- Password: `admin`

### Prometheus

- URL: http://localhost:30090

### Alertmanager

- URL: http://localhost:30093

## 🌐 Configurar /etc/hosts

Adicione ao arquivo `/etc/hosts`:

```bash
# Nexo Platform - Ambientes Locais
127.0.0.1 develop.nexo.local develop.api.nexo.local develop.auth.nexo.local
127.0.0.1 qa.nexo.local qa.api.nexo.local qa.auth.nexo.local
127.0.0.1 staging.nexo.local staging.api.nexo.local staging.auth.nexo.local
127.0.0.1 prod.nexo.local prod.api.nexo.local prod.auth.nexo.local
```

## 📊 Monitoramento

### Ver todas as aplicações

```bash
kubectl get applications -n argocd
```

### Ver pods por ambiente

```bash
kubectl get pods -n nexo-develop
kubectl get pods -n nexo-qa
kubectl get pods -n nexo-staging
kubectl get pods -n nexo-prod
```

### Ver status geral

```bash
cd local && make status
```

### Logs de aplicações

```bash
# Backend
kubectl logs -f -n nexo-develop deployment/nexo-be-develop

# Frontend
kubectl logs -f -n nexo-develop deployment/nexo-fe-develop

# Auth
kubectl logs -f -n nexo-develop deployment/nexo-auth-develop
```

## 🔄 Sincronizar manualmente

```bash
cd local && make argocd-sync
```

Ou individualmente:

```bash
kubectl patch application nexo-be-develop -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```

## 🗑️ Destruir ambiente

```bash
cd local && ./scripts/destroy.sh
```

## 💾 Volumes SSD

Os dados são persistidos em `/Volumes/Backup/DockerSSD/`:

- `nexo/` - Dados de produção
- `nexo-dev/` - Dados de desenvolvimento

### Estrutura de volumes:

```
/Volumes/Backup/DockerSSD/
├── nexo/
│   ├── postgres/
│   └── keycloak/
└── nexo-dev/
    ├── postgres/
    ├── redis/
    ├── keycloak/
    ├── api-uploads/
    ├── prometheus/
    ├── grafana/
    └── loki/
```

## ⚠️ Troubleshooting

### ArgoCD não sincroniza

```bash
# Verificar logs do application controller
kubectl logs -n argocd statefulset/argocd-application-controller --tail=100

# Hard refresh
kubectl delete application nexo-be-develop -n argocd
kubectl apply -f local/argocd/apps/nexo-develop.yaml
```

### Pods não sobem

```bash
# Verificar eventos
kubectl describe pod <POD_NAME> -n nexo-develop

# Verificar se secret GHCR existe
kubectl get secret ghcr-secret -n nexo-develop
```

### Recriar secrets GHCR

```bash
for ns in nexo-develop nexo-qa nexo-staging nexo-prod; do
  kubectl delete secret ghcr-secret -n $ns
  kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username=YOUR_USERNAME \
    --docker-password=YOUR_TOKEN \
    -n $ns
done
```

### Postgres com problemas

```bash
# Limpar volumes
rm -rf /Volumes/Backup/DockerSSD/nexo-dev/postgres/*

# Recriar pod
kubectl delete pod -n nexo-develop -l app=nexo-auth-develop-postgres
```

## 📚 Documentação Adicional

- [Quick Start](01-quick-start.md)
- [Arquitetura](02-architecture.md)
- [CI/CD Flow](05-cicd.md)
- [Troubleshooting](10-troubleshooting.md)
- [SSD Volumes](13-ssd-volumes.md)

## 🎯 Próximos Passos

1. **Acesse o ArgoCD** para monitorar deployments
2. **Configure Dashboards no Grafana** para cada ambiente
3. **Teste os Ingresses** de cada aplicação
4. **Configure alertas** no Alertmanager
5. **Valide os workflows** do GitHub Actions

## 💡 Dicas

- Use `kubectl get all -n nexo-develop` para ver todos os recursos
- Configure aliases úteis no seu `.zshrc`:
  ```bash
  alias k="kubectl"
  alias kgp="kubectl get pods"
  alias kga="kubectl get applications -n argocd"
  ```
- Monitore recursos com `k9s` (instalar com `brew install k9s`)

## 🔗 Links Úteis

- [K3D Documentation](https://k3d.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [NGINX Ingress](https://kubernetes.github.io/ingress-nginx/)
