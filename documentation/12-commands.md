# 💻 Comandos Úteis

Referência rápida de comandos para o dia a dia.

## 🚀 Setup e Gerenciamento

### Setup Completo

```bash
# Com variável de ambiente (recomendado)
export GITHUB_TOKEN=ghp_...
cd local && make setup

# Com token direto
cd local && ./scripts/setup.sh ghp_...

# Via Makefile com variável
cd local && make setup
```

### Destruir Ambiente

```bash
cd local && make destroy
```

### Status Geral

```bash
cd local && make status
```

## 📦 Pods e Containers

### Listar Pods

```bash
# Todos os pods
kubectl get pods -A

# Por namespace
kubectl get pods -n nexo-develop
kubectl get pods -n argocd
kubectl get pods -n monitoring

# Com watch (atualiza automaticamente)
kubectl get pods -A -w
```

### Ver Logs

```bash
# Via Makefile
make logs-be      # Backend
make logs-fe      # Frontend
make logs-auth    # Keycloak

# Via kubectl
kubectl logs -n nexo-develop -l app.kubernetes.io/name=nexo-be -f --tail=100
kubectl logs -n nexo-develop deployment/nexo-fe-develop -f
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f
```

### Restart Pods

```bash
# Restart deployment
kubectl rollout restart deployment/nexo-be-develop -n nexo-develop

# Scale down/up
kubectl scale deployment/nexo-fe-develop --replicas=0 -n nexo-develop
kubectl scale deployment/nexo-fe-develop --replicas=1 -n nexo-develop
```

## 🔄 ArgoCD

### Aplicações

```bash
# Listar aplicações
kubectl get applications -n argocd

# Ver detalhes de uma app
kubectl describe application nexo-be-develop -n argocd

# Status detalhado
kubectl get application nexo-be-develop -n argocd -o yaml
```

### Sincronização

```bash
# Sync todas as apps
make argocd-sync

# Sync uma app específica
kubectl patch application nexo-be-develop -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'

# Refresh (detectar mudanças no Git)
make argocd-refresh
```

### Acesso UI

```bash
# Já configurado na porta 30080
open http://localhost:30080

# Obter senha
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

## 📊 Monitoring

### Prometheus

```bash
# Port forward (se não usar Ingress)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Via Ingress (recomendado)
open http://prometheus.local.nexo.app
```

### Grafana

```bash
# Port forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Via Ingress
open http://grafana.local.nexo.app

# Obter senha do Grafana
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo
```

### Métricas

```bash
# Node metrics
kubectl top nodes

# Pod metrics
kubectl top pods -A
kubectl top pods -n nexo-develop
```

## 🐳 Docker e Registry

### GHCR Login

```bash
# Login
echo $GITHUB_TOKEN | docker login ghcr.io -u geraldobl58 --password-stdin

# Logout
docker logout ghcr.io
```

### Imagens

```bash
# Listar imagens locais
docker images | grep nexo

# Pull imagem
docker pull ghcr.io/geraldobl58/nexo-be:latest

# Build e push
docker build -t ghcr.io/geraldobl58/nexo-be:latest .
docker push ghcr.io/geraldobl58/nexo-be:latest

# Limpar imagens não usadas
docker system prune -a
```

### Registry Local K3D

```bash
# Verificar registry
curl http://localhost:5050/v2/_catalog

# Listar tags de uma imagem
curl http://localhost:5050/v2/nexo-be/tags/list
```

## 🔐 Secrets

### Ver Secrets

```bash
# Listar secrets
kubectl get secrets -n nexo-develop

# Ver conteúdo de um secret
kubectl get secret ghcr-secret -n nexo-develop -o yaml

# Decodificar
kubectl get secret ghcr-secret -n nexo-develop -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
```

### Criar/Atualizar GHCR Secret

```bash
# Criar em um namespace
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=geraldobl58 \
  --docker-password=$GITHUB_TOKEN \
  --namespace=nexo-develop

# Criar em todos os namespaces
for ns in nexo-develop nexo-qa nexo-staging nexo-prod; do
  kubectl delete secret ghcr-secret -n $ns --ignore-not-found
  kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username=geraldobl58 \
    --docker-password=$GITHUB_TOKEN \
    --namespace=$ns
done
```

## 🌐 Networking

### Services

```bash
# Listar services
kubectl get svc -A

# Por namespace
kubectl get svc -n nexo-develop
kubectl get svc -n monitoring

# Detalhe de um service
kubectl describe svc nexo-be-develop -n nexo-develop
```

### Ingress

```bash
# Listar ingress
kubectl get ingress -A

# Detalhe
kubectl describe ingress -n nexo-develop
```

### Port Forward

```bash
# Port forward para um pod específico
kubectl port-forward -n nexo-develop pod/nexo-be-develop-xxx-xxx 3333:3333

# Port forward para um service
kubectl port-forward -n nexo-develop svc/nexo-be-develop 3333:3333
```

## 🔧 Cluster K3D

### Gerenciamento

```bash
# Listar clusters
k3d cluster list

# Parar cluster
k3d cluster stop nexo-local

# Iniciar cluster
k3d cluster start nexo-local

# Deletar cluster
k3d cluster delete nexo-local

# Info do cluster
k3d cluster list nexo-local
kubectl cluster-info
```

### Nodes

```bash
# Listar nodes
kubectl get nodes
kubectl get nodes -o wide

# Detalhe de um node
kubectl describe node k3d-nexo-local-server-0
```

### Contexto

```bash
# Ver contexto atual
kubectl config current-context

# Listar contextos
kubectl config get-contexts

# Mudar contexto
kubectl config use-context k3d-nexo-local
```

## 🐛 Debug

### Events

```bash
# Eventos recentes
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Eventos de um namespace
kubectl get events -n nexo-develop --sort-by='.lastTimestamp'

# Watch events
kubectl get events -A -w
```

### Describe

```bash
# Pod
kubectl describe pod <pod-name> -n nexo-develop

# Deployment
kubectl describe deployment nexo-be-develop -n nexo-develop

# Service
kubectl describe svc nexo-be-develop -n nexo-develop
```

### Exec em Pod

```bash
# Shell interativo
kubectl exec -it <pod-name> -n nexo-develop -- /bin/sh

# Comando único
kubectl exec <pod-name> -n nexo-develop -- env
kubectl exec <pod-name> -n nexo-develop -- ls -la
```

### Copiar Arquivos

```bash
# Do pod para local
kubectl cp nexo-develop/<pod-name>:/app/logs/app.log ./app.log

# Do local para pod
kubectl cp ./config.json nexo-develop/<pod-name>:/app/config.json
```

## 📝 Helm

### Releases

```bash
# Listar releases
helm list -A

# Status de um release
helm status kube-prometheus-stack -n monitoring

# Histórico
helm history kube-prometheus-stack -n monitoring
```

### Upgrade/Rollback

```bash
# Upgrade
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values local/observability/values.yaml

# Rollback
helm rollback kube-prometheus-stack 1 -n monitoring
```

### Repositórios

```bash
# Listar repos
helm repo list

# Atualizar repos
helm repo update

# Adicionar repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

## 🧹 Limpeza

### Pods Evicted/Failed

```bash
# Deletar pods failed
kubectl delete pods --field-selector status.phase=Failed -A

# Deletar pods evicted
kubectl get pods -A | grep Evicted | awk '{print $2 " -n " $1}' | xargs kubectl delete pod
```

### Imagens não usadas

```bash
# Docker cleanup
docker system prune -a -f

# Limpar volumes
docker volume prune -f
```

### Reset Completo

```bash
# Destruir ambiente
cd local && make destroy

# Limpar Docker
docker system prune -a -f --volumes

# Recriar
cd local && make setup
```

## 📊 Recursos

```bash
# Uso de recursos por node
kubectl top nodes

# Uso por pod
kubectl top pods -A

# Requests/Limits configurados
kubectl describe nodes | grep -A 5 "Allocated resources"
```

## 🔄 Aliases Úteis

Adicione ao `~/.zshrc` ou `~/.bashrc`:

```bash
# Kubectl
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kl='kubectl logs -f'
alias kex='kubectl exec -it'

# K3D
alias k3dl='k3d cluster list'
alias k3ds='k3d cluster start nexo-local'
alias k3dx='k3d cluster stop nexo-local'

# ArgoCD
alias argocd-apps='kubectl get applications -n argocd'
alias argocd-sync='kubectl patch application $1 -n argocd --type merge -p "{\"operation\":{\"initiatedBy\":{\"username\":\"admin\"},\"sync\":{}}}"'

# Nexo specific
alias nexo-setup='cd ~/nexo/local && make setup'
alias nexo-destroy='cd ~/nexo/local && make destroy'
alias nexo-status='cd ~/nexo/local && make status'
alias nexo-logs-be='cd ~/nexo/local && make logs-be'
```

---

[← Troubleshooting](./11-troubleshooting.md) | [Voltar](./README.md)
