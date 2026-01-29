# 10 - Troubleshooting

Guia de resolução de problemas.

---

## 🏠 Índice Rápido

- [K3D / Cluster](#k3d--cluster)
- [Pods / Containers](#pods--containers)
- [Network / Ingress](#network--ingress)
- [ArgoCD](#argocd)
- [CI/CD Pipeline](#cicd-pipeline)
- [Database](#database)
- [Keycloak](#keycloak)
- [Frontend / Backend](#frontend--backend)

---

## 🎯 K3D / Cluster

### Cluster não inicia

```bash
# Verificar se Docker está rodando
docker info

# Verificar clusters existentes
k3d cluster list

# Recriar cluster
cd local
./scripts/destroy.sh
./scripts/setup.sh
```

### Porta 80 em uso

```bash
# Verificar o que está usando
sudo lsof -i :80

# Parar processo (exemplo: Apache)
sudo apachectl stop

# Ou matar por PID
sudo kill -9 <PID>
```

### kubectl não conecta

```bash
# Verificar contexto atual
kubectl config current-context

# Listar contextos
kubectl config get-contexts

# Trocar para k3d
kubectl config use-context k3d-nexo-local

# Verificar conexão
kubectl cluster-info
```

### Cluster sem recursos

```bash
# Ver recursos do node
kubectl top nodes

# Ver uso por pod
kubectl top pods -A

# Liberar imagens não usadas
docker system prune -a
```

---

## 🐳 Pods / Containers

### Pod em CrashLoopBackOff

```bash
# Ver status
kubectl get pods -n nexo-develop

# Ver logs do pod
kubectl logs <pod-name> -n nexo-develop

# Ver logs anteriores (antes do crash)
kubectl logs <pod-name> -n nexo-develop --previous

# Ver eventos
kubectl describe pod <pod-name> -n nexo-develop
```

**Causas comuns:**

| Erro             | Causa                 | Solução                        |
| ---------------- | --------------------- | ------------------------------ |
| OOMKilled        | Memória insuficiente  | Aumentar limits no Helm values |
| Error 1          | App falhou ao iniciar | Ver logs, corrigir código      |
| ImagePullBackOff | Imagem não existe     | Verificar DockerHub            |

### Pod em Pending

```bash
# Ver motivo
kubectl describe pod <pod-name> -n nexo-develop

# Verificar se há nodes disponíveis
kubectl get nodes

# Verificar eventos do cluster
kubectl get events -A --sort-by='.lastTimestamp'
```

**Causas comuns:**

- Node sem recursos (CPU/RAM)
- PVC não consegue provisionar
- Node selector/affinity não satisfeito

### OOMKilled

```bash
# Ver limites atuais
kubectl describe pod <pod-name> -n nexo-develop | grep -A5 Limits

# Aumentar no values.yaml
# local/helm/nexo-auth/values-local.yaml
resources:
  limits:
    memory: "2Gi"  # Aumentar

# Aplicar
cd local/argocd/apps
kubectl apply -f nexo-develop.yaml
```

### ImagePullBackOff

```bash
# Verificar erro
kubectl describe pod <pod-name> -n nexo-develop | grep -A5 "Failed"

# Verificar secret de pull
kubectl get secrets -n nexo-develop

# Criar secret se não existir
kubectl create secret docker-registry nexo-dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=geraldobl58 \
  --docker-password=<token> \
  -n nexo-develop

# Testar pull manual
docker pull geraldobl58/nexo-fe:develop
```

---

## 🌐 Network / Ingress

### Site não abre (Connection refused)

```bash
# Verificar /etc/hosts
cat /etc/hosts | grep nexo

# Verificar ingress
kubectl get ingressroute -A

# Verificar Traefik
kubectl get pods -n kube-system | grep traefik

# Verificar serviço
kubectl get svc -n nexo-develop
```

### 404 Not Found

```bash
# Verificar IngressRoute
kubectl get ingressroute -n nexo-develop -o yaml

# Verificar se serviço existe
kubectl get svc nexo-fe -n nexo-develop

# Verificar endpoints
kubectl get endpoints nexo-fe -n nexo-develop
```

### 502 Bad Gateway

```bash
# Pod está rodando?
kubectl get pods -n nexo-develop

# Pod está Ready?
kubectl describe pod <pod-name> -n nexo-develop | grep -A10 Conditions

# Serviço aponta para porta correta?
kubectl get svc nexo-be -n nexo-develop -o yaml
```

---

## 🔄 ArgoCD

### App OutOfSync

```bash
# Verificar status
argocd app get nexo-develop

# Forçar sync
argocd app sync nexo-develop --force

# Ver diff
argocd app diff nexo-develop
```

### App Degraded

```bash
# Ver recursos com problema
argocd app get nexo-develop --resource-filter kind=Pod

# Ver eventos
kubectl get events -n nexo-develop --sort-by='.lastTimestamp'
```

### Image Updater não atualiza

```bash
# Ver logs do Image Updater
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater

# Verificar annotations
kubectl get app nexo-develop -n argocd -o yaml | grep -A10 annotations

# Forçar check
kubectl rollout restart deploy/argocd-image-updater -n argocd
```

### Não consigo acessar ArgoCD UI

```bash
# Verificar pod
kubectl get pods -n argocd | grep server

# Verificar NodePort
kubectl get svc argocd-server -n argocd

# Aplicar NodePort se não existir
kubectl apply -f local/argocd/nodeport.yaml

# Senha
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

---

## 🔧 CI/CD Pipeline

### Rate Limit do DockerHub (429 Too Many Requests)

**Erro:**

```
toomanyrequests: You have reached your pull rate limit as 'geraldobl58'
ERROR: failed to solve: failed to resolve source metadata for docker.io/library/node:20-alpine
```

**Causa:** DockerHub limita a 200 pulls/6h para contas gratuitas.

**Soluções:**

| Solução  | Ação                                 |
| -------- | ------------------------------------ |
| Aguardar | Esperar 6 horas para reset do limite |
| Re-run   | GitHub Actions → Re-run failed jobs  |
| Upgrade  | DockerHub Pro ($5/mês) = ilimitado   |

**Verificar limite atual:**

```bash
# Fazer login e verificar headers
TOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/node:pull" | jq -r .token)

curl -s -H "Authorization: Bearer $TOKEN" \
  "https://registry-1.docker.io/v2/library/node/manifests/20-alpine" \
  -o /dev/null -D - 2>&1 | grep -i ratelimit
```

**Estratégia implementada:**

- Builds sequenciais (não paralelos)
- Cache de imagens base
- Cache multinível (GHA + Registry)

Ver detalhes em [05-cicd.md#estratégia-de-cache-e-rate-limit](05-cicd.md#-estratégia-de-cache-e-rate-limit)

### CI falhou

| Erro                | Causa              | Solução             |
| ------------------- | ------------------ | ------------------- |
| pnpm install failed | Cache corrompido   | Re-run workflow     |
| Lint failed         | Código com erros   | Corrigir e commitar |
| Test failed         | Testes quebrando   | Debugar testes      |
| Build failed        | Erro de compilação | Ver logs detalhados |

### CD falhou

```bash
# Login DockerHub falhou
# → Verificar DOCKERHUB_TOKEN no GitHub Secrets

# Push denied
# → Verificar DOCKERHUB_NAMESPACE variable

# Build failed
# → Testar build local:
cd apps/nexo-fe
docker build -t test:local -f Dockerfile ../..
```

### Pipeline não dispara

```bash
# Verificar branch pattern no workflow
# .github/workflows/cd-main.yml deve ter:
on:
  push:
    branches: [develop, qa, staging, main]

# Verificar se tem mudanças nos paths filtrados
# paths-filter deve incluir seus arquivos
```

---

## 🗄️ Database

### Não conecta ao PostgreSQL

```bash
# Verificar pod do PostgreSQL
kubectl get pods -n nexo-develop | grep postgresql

# Ver logs
kubectl logs -n nexo-develop -l app.kubernetes.io/name=postgresql

# Testar conexão (via port-forward)
kubectl port-forward svc/nexo-be-postgresql 5432:5432 -n nexo-develop
psql -h localhost -U nexo -d nexo
```

### PVC não provisiona

```bash
# Ver PVCs
kubectl get pvc -n nexo-develop

# Ver PVs
kubectl get pv

# Ver StorageClass
kubectl get storageclass

# Deve usar local-path para K3D
```

### Migration falhou

```bash
# Conectar no pod do backend
kubectl exec -it deploy/nexo-be -n nexo-develop -- sh

# Rodar migration manualmente
npx prisma migrate deploy

# Ver status
npx prisma migrate status
```

---

## 🔐 Keycloak

### Login admin não funciona

```bash
# Verificar pod
kubectl get pods -n nexo-develop | grep auth

# Ver logs
kubectl logs -n nexo-develop -l app.kubernetes.io/name=nexo-auth

# Verificar variáveis de ambiente
kubectl describe pod -n nexo-develop -l app.kubernetes.io/name=nexo-auth | grep KEYCLOAK_ADMIN
```

### Tema não aparece

```bash
# Verificar se imagem tem o tema
kubectl exec -it deploy/nexo-auth -n nexo-develop -- ls /opt/keycloak/themes/

# Verificar se está configurado
kubectl describe pod -n nexo-develop -l app.kubernetes.io/name=nexo-auth | grep -i theme
```

### OOMKilled

```bash
# Keycloak precisa de bastante memória
# Editar values-local.yaml:
resources:
  limits:
    memory: "2Gi"  # Mínimo recomendado

# Aplicar
kubectl apply -f local/argocd/apps/nexo-develop.yaml
```

---

## 💻 Frontend / Backend

### Frontend não conecta ao Backend

```bash
# Verificar variáveis de ambiente
kubectl describe pod -n nexo-develop -l app=nexo-fe | grep API_URL

# Deve apontar para o serviço interno ou ingress
# NEXT_PUBLIC_API_URL=http://develop.api.nexo.local
```

### Backend não conecta ao Keycloak

```bash
# Verificar variáveis
kubectl describe pod -n nexo-develop -l app=nexo-be | grep KEYCLOAK

# Testar conectividade interna
kubectl exec -it deploy/nexo-be -n nexo-develop -- \
  curl http://nexo-auth:8080/health
```

### Hot reload não funciona

Para desenvolvimento local, use:

```bash
# Fora do K3D
cd apps/nexo-fe && pnpm dev
cd apps/nexo-be && pnpm dev
```

---

## 📋 Comandos de Diagnóstico

### Status Geral

```bash
# Cluster
kubectl cluster-info
kubectl get nodes

# Pods em todos namespaces
kubectl get pods -A

# Eventos recentes
kubectl get events -A --sort-by='.lastTimestamp' | head -20
```

### Por Namespace

```bash
# Todos os recursos
kubectl get all -n nexo-develop

# Pods com mais detalhes
kubectl get pods -n nexo-develop -o wide

# Recursos com problemas
kubectl get pods -n nexo-develop --field-selector=status.phase!=Running
```

### Logs

```bash
# Logs de um deployment
kubectl logs -f deploy/nexo-be -n nexo-develop

# Logs anteriores (após crash)
kubectl logs deploy/nexo-be -n nexo-develop --previous

# Todos os containers de um pod
kubectl logs <pod-name> -n nexo-develop --all-containers
```

---

## 🔄 Reset Completo

Se nada funcionar:

```bash
# Destruir tudo
cd local
./scripts/destroy.sh

# Limpar Docker
docker system prune -a --volumes

# Recriar
./scripts/setup.sh

# Aguardar pods ficarem Ready
watch kubectl get pods -A
```

---

## 📞 Recursos Adicionais

- [Kubernetes Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [K3D Documentation](https://k3d.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
