# 🔧 Troubleshooting

Guia completo de resolução de problemas comuns no ambiente Nexo.

## 🎯 Estrutura de Troubleshooting

```
1. Identificar o problema
2. Coletar informações
3. Diagnosticar causa raiz
4. Aplicar solução
5. Validar fix
6. Documentar
```

## 🚨 Problemas Comuns

### 1. Cluster K3D não inicia

**Sintomas:**

- `k3d cluster list` não mostra cluster
- `kubectl get nodes` retorna erro de conexão

**Diagnóstico:**

```bash
# Ver clusters
k3d cluster list

# Ver logs do Docker
docker ps -a | grep k3d
docker logs <container-id>

# Ver contexto kubectl
kubectl config current-context
kubectl config get-contexts
```

**Soluções:**

```bash
# Opção 1: Restart cluster
k3d cluster stop nexo-local
k3d cluster start nexo-local

# Opção 2: Deletar e recriar
k3d cluster delete nexo-local
cd local && make setup

# Opção 3: Verificar Docker
docker info
docker system prune -a  # limpar recursos
```

**Prevenção:**

- Sempre usar `make destroy` antes de desligar
- Garantir recursos suficientes (RAM, CPU)
- Manter Docker atualizado

---

### 2. Pods em CrashLoopBackOff

**Sintomas:**

- Pod reinicia constantemente
- Status: `CrashLoopBackOff`

**Diagnóstico:**

```bash
# Ver pods
kubectl get pods -n nexo-develop

# Describe pod
kubectl describe pod <pod-name> -n nexo-develop

# Ver logs
kubectl logs <pod-name> -n nexo-develop
kubectl logs <pod-name> -n nexo-develop --previous

# Ver eventos
kubectl get events -n nexo-develop --sort-by='.lastTimestamp' | tail -20
```

**Causas Comuns:**

#### A. Erro na aplicação

```bash
# Ver logs detalhados
kubectl logs nexo-be-xxx-yyy -n nexo-develop -f

# Possíveis erros:
# - Database connection failed
# - Missing environment variable
# - Syntax error
# - Port já em uso
```

**Solução:**

```bash
# Corrigir código/config
# Rebuild imagem
make build-images

# Force refresh ArgoCD
make argocd-sync
```

#### B. Falha no Health Check

```bash
# Ver probes
kubectl describe pod <pod-name> -n nexo-develop | grep -A5 "Liveness\|Readiness"

# Testar endpoint
kubectl port-forward <pod-name> 3333:3333 -n nexo-develop
curl http://localhost:3333/health
```

**Solução:**

```yaml
# Ajustar probes no values.yaml
livenessProbe:
  initialDelaySeconds: 60 # Aumentar delay
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 5 # Aumentar tolerância
```

#### C. Recursos insuficientes

```bash
# Ver uso de recursos
kubectl top pod <pod-name> -n nexo-develop
kubectl describe node

# Ver limits
kubectl describe pod <pod-name> -n nexo-develop | grep -A5 "Limits\|Requests"
```

**Solução:**

```yaml
# Aumentar resources no values.yaml
resources:
  limits:
    cpu: 500m # Aumentar
    memory: 512Mi # Aumentar
  requests:
    cpu: 200m
    memory: 256Mi
```

---

### 3. ArgoCD não sincroniza

**Sintomas:**

- App stuck em `OutOfSync`
- Sync manual falha
- App não detecta mudanças no Git

**Diagnóstico:**

```bash
# Ver status da app
argocd app get nexo-be-develop

# Ver diff
argocd app diff nexo-be-develop

# Ver logs ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller -f
```

**Causas Comuns:**

#### A. Erro no Helm template

```bash
# Testar template
helm template nexo-be local/helm/nexo-be \
  -f local/helm/nexo-be/values-develop.yaml

# Ver manifests gerados
argocd app manifests nexo-be-develop
```

**Solução:**

```bash
# Corrigir template
# Validar sintaxe
helm lint local/helm/nexo-be

# Commit e push
git add .
git commit -m "fix: corrige helm template"
git push
```

#### B. Repo não autenticado

```bash
# Ver repositórios
argocd repo list

# Reconectar repo
argocd repo add https://github.com/geraldobl58/nexo.git \
  --username git \
  --password $GITHUB_TOKEN
```

#### C. Sync policy desabilitado

```bash
# Verificar policy
kubectl get application nexo-be-develop -n argocd -o yaml | grep -A5 "syncPolicy"

# Habilitar auto-sync
argocd app set nexo-be-develop --sync-policy automated
```

**Hard Refresh:**

```bash
# Força refresh completo
argocd app get nexo-be-develop --hard-refresh

# Delete e recria app
kubectl delete application nexo-be-develop -n argocd
kubectl apply -f local/argocd/apps/nexo-develop.yaml
```

---

### 4. Imagem não atualiza

**Sintomas:**

- Pod usa imagem antiga
- Build novo não aparece no cluster

**Diagnóstico:**

```bash
# Ver imagem do pod
kubectl get pod <pod-name> -n nexo-develop \
  -o jsonpath='{.spec.containers[0].image}'

# Ver tag no values.yaml
cat local/helm/nexo-be/values-develop.yaml | grep tag

# Ver imagem no GHCR
gh api /user/packages/container/nexo-be/versions
```

**Soluções:**

```bash
# 1. Verificar se build completou
gh run list --workflow=cd.yml

# 2. Verificar se values.yaml foi atualizado
git log -1 local/helm/nexo-be/values-develop.yaml

# 3. Force pull da imagem
kubectl delete pod <pod-name> -n nexo-develop

# 4. Verificar imagePullPolicy
# values.yaml:
image:
  pullPolicy: Always  # Sempre puxar imagem nova

# 5. Verificar imagePullSecret
kubectl get secret ghcr-secret -n nexo-develop
kubectl describe secret ghcr-secret -n nexo-develop
```

**Recriar secret:**

```bash
kubectl delete secret ghcr-secret -n nexo-develop

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=geraldobl58 \
  --docker-password=$GHCR_TOKEN \
  -n nexo-develop
```

---

### 5. Ingress não funciona

**Sintomas:**

- URL não resolve
- `curl` retorna timeout
- Browser mostra "can't reach"

**Diagnóstico:**

```bash
# Ver ingresses
kubectl get ingress -n nexo-develop

# Describe ingress
kubectl describe ingress nexo-be-develop -n nexo-develop

# Ver NGINX controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=ingress-nginx

# Ver logs NGINX
kubectl logs -n kube-system -l app.kubernetes.io/name=ingress-nginx -f
```

**Soluções:**

#### A. Hosts não configurados

```bash
# Verificar /etc/hosts
cat /etc/hosts | grep nexo

# Adicionar se faltando
sudo tee -a /etc/hosts <<EOF
127.0.0.1 develop.nexo.local
127.0.0.1 develop.api.nexo.local
127.0.0.1 develop.auth.nexo.local
EOF
```

#### B. Service não existe

```bash
# Ver services
kubectl get svc -n nexo-develop

# Criar service se necessário
# (normalmente criado pelo Helm)
```

#### C. NGINX não instalado

```bash
# Verificar instalação
kubectl get deployment -n kube-system ingress-nginx-controller

# Reinstalar se necessário
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace kube-system \
  --create-namespace
```

---

### 6. Database connection failed

**Sintomas:**

- App não conecta no PostgreSQL
- Erro: "connection refused"

**Diagnóstico:**

```bash
# Ver pods postgres
kubectl get pods -n nexo-develop | grep postgres

# Ver logs
kubectl logs <postgres-pod> -n nexo-develop

# Testar conexão do pod da app
kubectl exec -it <app-pod> -n nexo-develop -- \
  psql postgresql://nexo:password@postgres:5432/nexo
```

**Soluções:**

```bash
# 1. Verificar se postgres está rodando
kubectl get pods -n nexo-develop -l app=postgres

# 2. Verificar service
kubectl get svc -n nexo-develop postgres

# 3. Verificar DATABASE_URL
kubectl describe pod <app-pod> -n nexo-develop | grep DATABASE_URL

# 4. Port forward para testar
kubectl port-forward svc/postgres 5432:5432 -n nexo-develop
psql postgresql://nexo:password@localhost:5432/nexo

# 5. Recriar postgres (CUIDADO: perde dados)
kubectl delete pod <postgres-pod> -n nexo-develop
```

---

### 7. GitHub Actions falham

**Sintomas:**

- Workflow com status "failed"
- Build não completa
- Push de imagem falha

**Diagnóstico:**

```bash
# Ver runs
gh run list

# Ver logs
gh run view <run-id>
gh run view <run-id> --log

# Ver status de um job
gh run view <run-id> --job <job-id>
```

**Causas Comuns:**

#### A. Secrets inválidos

```bash
# Listar secrets
gh secret list

# Atualizar secret
gh secret set GHCR_TOKEN
# Cola token: ghp_...

# Testar token
curl -H "Authorization: Bearer $GHCR_TOKEN" \
  https://api.github.com/user
```

#### B. Lint/Test falhou

```bash
# Rodar localmente
pnpm lint
pnpm test

# Ver qual arquivo falhou
gh run view <run-id> --log | grep "Error"

# Corrigir e push
git add .
git commit -m "fix: corrige lint errors"
git push
```

#### C. Build timeout

```bash
# Ver duração
gh run view <run-id>

# Otimizar build:
# - Usar cache
# - Build paralelo
# - Reduzir dependências
```

---

### 8. Prometheus não coleta métricas

**Sintomas:**

- Grafana sem dados
- Queries vazias
- Targets down

**Diagnóstico:**

```bash
# Ver targets
open http://prometheus.local.nexo.app/targets

# Ver service monitors
kubectl get servicemonitors -A

# Ver logs prometheus
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus -f
```

**Soluções:**

```bash
# 1. Verificar endpoint /metrics
curl http://develop.api.nexo.local/metrics

# 2. Verificar ServiceMonitor
kubectl get servicemonitor -n nexo-develop

# 3. Verificar labels
kubectl get pod -n nexo-develop --show-labels

# 4. Criar ServiceMonitor se faltando
cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nexo-be-develop
  namespace: nexo-develop
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: nexo-be
  endpoints:
    - port: http
      path: /metrics
EOF
```

---

### 9. Disk full no cluster

**Sintomas:**

- Pods não iniciam
- `docker pull` falha
- Erro: "no space left on device"

**Diagnóstico:**

```bash
# Ver uso de disco
docker system df

# Ver volumes
docker volume ls
du -sh /var/lib/docker/volumes/*

# Ver nodes
kubectl describe nodes | grep -A5 "Allocated resources"
```

**Soluções:**

```bash
# 1. Limpar imagens não usadas
docker system prune -a

# 2. Limpar volumes
docker volume prune

# 3. Limpar build cache
docker builder prune

# 4. Remover logs antigos
sudo rm -rf /var/lib/docker/containers/*/logfile*

# 5. Se necessário, aumentar disco do Docker
# Docker Desktop → Settings → Resources → Disk image size
```

---

## 🛠️ Comandos de Debug

### Logs

```bash
# Logs de um pod
kubectl logs <pod-name> -n nexo-develop

# Logs anteriores (após restart)
kubectl logs <pod-name> -n nexo-develop --previous

# Follow logs
kubectl logs <pod-name> -n nexo-develop -f

# Logs de todos containers
kubectl logs <pod-name> -n nexo-develop --all-containers=true

# Logs com timestamp
kubectl logs <pod-name> -n nexo-develop --timestamps

# Últimas 100 linhas
kubectl logs <pod-name> -n nexo-develop --tail=100
```

### Exec em Pods

```bash
# Shell interativo
kubectl exec -it <pod-name> -n nexo-develop -- /bin/sh

# Comando único
kubectl exec <pod-name> -n nexo-develop -- ls -la /app

# Ver env vars
kubectl exec <pod-name> -n nexo-develop -- env

# Testar conectividade
kubectl exec <pod-name> -n nexo-develop -- curl http://postgres:5432
```

### Describe

```bash
# Pod
kubectl describe pod <pod-name> -n nexo-develop

# Deployment
kubectl describe deployment nexo-be-develop -n nexo-develop

# Service
kubectl describe svc nexo-be-develop -n nexo-develop

# Ingress
kubectl describe ingress nexo-be-develop -n nexo-develop

# Node
kubectl describe node <node-name>
```

### Port Forward

```bash
# Para um service
kubectl port-forward -n nexo-develop svc/nexo-be-develop 3333:3333

# Para um pod
kubectl port-forward -n nexo-develop <pod-name> 3333:3333

# Múltiplas portas
kubectl port-forward -n nexo-develop <pod-name> 3333:3333 9229:9229
```

### Top

```bash
# Pods
kubectl top pods -n nexo-develop

# Nodes
kubectl top nodes

# Ordenar por CPU
kubectl top pods -n nexo-develop --sort-by=cpu

# Ordenar por Memory
kubectl top pods -n nexo-develop --sort-by=memory
```

## 🔍 Checklist de Troubleshooting

### Problema: Pod não inicia

- [ ] Pod existe? `kubectl get pods -n <namespace>`
- [ ] Status? `kubectl describe pod <pod> -n <namespace>`
- [ ] Imagem existe? Verificar GHCR
- [ ] ImagePullSecret configurado?
- [ ] Resources suficientes? `kubectl top nodes`
- [ ] Volumes montados corretamente?
- [ ] Secrets/ConfigMaps existem?

### Problema: App não responde

- [ ] Pod rodando? `kubectl get pods`
- [ ] Logs mostram erro? `kubectl logs <pod>`
- [ ] Health check passou? `curl /health`
- [ ] Service existe? `kubectl get svc`
- [ ] Ingress configurado? `kubectl get ingress`
- [ ] DNS resolve? `nslookup <domain>`
- [ ] Port correto? `kubectl describe svc`

### Problema: Deploy não funciona

- [ ] Código commitado? `git status`
- [ ] CI passou? `gh run list`
- [ ] Imagem buildada? Verificar GHCR
- [ ] Values.yaml atualizado? `git log`
- [ ] ArgoCD sincronizado? `argocd app get`
- [ ] Pods atualizados? Verificar image tag
- [ ] Rollout completo? `kubectl rollout status`

## 📚 Logs de Sistema

### ArgoCD

```bash
# Application controller
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller -f

# Server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Repo server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server -f
```

### NGINX Ingress

```bash
# Controller
kubectl logs -n kube-system -l app.kubernetes.io/name=ingress-nginx -f

# Access logs
kubectl logs -n kube-system <ingress-pod> -c nginx | grep "GET /"
```

### Prometheus

```bash
# Server
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus -f

# Alertmanager
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager -f
```

## 🚨 Emergência: Rollback

### Via Git

```bash
# Rollback via revert (preferido)
git revert HEAD
git push

# ArgoCD vai detectar e fazer rollback
```

### Via ArgoCD

```bash
# Ver histórico
argocd app history nexo-be-prod

# Rollback para revisão específica
argocd app rollback nexo-be-prod <revision>
```

### Via Kubectl

```bash
# Rollback deployment
kubectl rollout undo deployment/nexo-be-prod -n nexo-prod

# Rollback para revisão específica
kubectl rollout undo deployment/nexo-be-prod --to-revision=3 -n nexo-prod

# Ver histórico
kubectl rollout history deployment/nexo-be-prod -n nexo-prod
```

## 💡 Prevenção

### 1. Health Checks

```yaml
# Sempre definir probes
livenessProbe:
  httpGet:
    path: /health
    port: 3333
  initialDelaySeconds: 30

readinessProbe:
  httpGet:
    path: /health
    port: 3333
  initialDelaySeconds: 10
```

### 2. Resource Limits

```yaml
# Sempre definir limits
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### 3. Logging Estruturado

```typescript
// Usar logger estruturado
logger.info("User created", {
  userId: user.id,
  email: user.email,
  timestamp: new Date(),
});
```

### 4. Monitoramento

```yaml
# Alertas para problemas comuns
- PodDown
- HighErrorRate
- HighLatency
- HighMemoryUsage
- HighCPUUsage
```

### 5. Testes

```bash
# Sempre testar antes de deploy
pnpm lint
pnpm test
pnpm test:e2e

# Testar localmente
docker build -t test .
docker run -p 3333:3333 test
```

## 📞 Suporte

### Recursos Internos

- **Documentação:** `/documentation`
- **Runbooks:** `/documentation/runbooks`
- **Dashboards:** http://grafana.local.nexo.app

### Recursos Externos

- [Kubernetes Docs](https://kubernetes.io/docs/)
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [K3D Docs](https://k3d.io/)
- [GitHub Actions Docs](https://docs.github.com/actions)

### Community

- **GitHub Issues:** https://github.com/geraldobl58/nexo/issues
- **Discussions:** https://github.com/geraldobl58/nexo/discussions

---

[← Observabilidade](./10-observability.md) | [Voltar](./README.md)
