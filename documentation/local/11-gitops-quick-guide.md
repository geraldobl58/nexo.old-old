# GitOps Pipeline - Guia Rápido

## 🚀 Início Rápido

### 1. Configuração Inicial (Uma vez)

```bash
# Execute o script de setup
./scripts/setup-pipeline.sh
```

Isso irá:

- ✅ Criar branches necessárias (develop, qa, staging, main)
- ✅ Configurar ArgoCD
- ✅ Preparar scripts

### 2. Configurar GitHub Secret

1. Criar token Docker Hub: https://hub.docker.com/settings/security
2. Adicionar no GitHub: https://github.com/geraldobl58/nexo/settings/secrets/actions
   - Nome: `DOCKERHUB_TOKEN`
   - Valor: [seu token]

## 📊 Fluxo Diário de Trabalho

### Desenvolver Feature

```bash
# 1. Criar branch de feature
git checkout develop
git pull
git checkout -b feature/minha-feature

# 2. Desenvolver e testar
# ... código ...
pnpm test
pnpm build

# 3. Commit
git add .
git commit -m "feat: adiciona minha feature"

# 4. Push para develop
git checkout develop
git merge feature/minha-feature
git push origin develop
```

**Resultado:** Deploy automático em **develop** em ~5min

### Promover para QA

```bash
./scripts/promote.sh develop qa
```

**Resultado:** Deploy automático em **QA** em ~5min

### Promover para Staging

```bash
./scripts/promote.sh qa staging
```

**Resultado:** Deploy automático em **Staging** em ~5min

### Promover para Produção

```bash
# 1. Promover código
./scripts/promote.sh staging prod

# 2. Aprovar deploy (manual por segurança)
argocd app sync nexo-be-prod
argocd app sync nexo-fe-prod
argocd app sync nexo-auth-prod
```

## 🔍 Monitoramento

### Ver status do GitHub Actions

```bash
open https://github.com/geraldobl58/nexo/actions
```

### Ver status do ArgoCD

```bash
# Acessar UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Abrir: https://localhost:8080

# Via CLI
argocd app list
argocd app get nexo-be-qa
```

### Ver logs do Image Updater

```bash
kubectl logs -n argocd deployment/argocd-image-updater -f
```

## 🐛 Problemas Comuns

### Deploy não acontece após merge

1. **Verificar GitHub Actions:**

   ```bash
   # Ver último workflow
   gh run list --limit 1
   # Ver logs
   gh run view --log
   ```

2. **Verificar imagem no Docker Hub:**

   ```bash
   curl -s https://hub.docker.com/v2/repositories/geraldobl58/nexo-be/tags | jq '.results[].name'
   ```

3. **Forçar refresh do Image Updater:**

   ```bash
   kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-image-updater
   ```

4. **Verificar aplicação no ArgoCD:**
   ```bash
   argocd app get nexo-be-qa
   ```

### Build falha no GitHub Actions

1. **Ver erro:**

   ```bash
   gh run view --log
   ```

2. **Problemas comuns:**
   - ❌ Token Docker Hub expirado → Renovar token
   - ❌ Testes falhando → Corrigir testes localmente
   - ❌ Build error → Testar localmente: `pnpm build`

## 📋 Checklist Diário

### Antes de Promover

- [ ] Testes passando localmente
- [ ] Build bem-sucedido no GitHub Actions
- [ ] Deploy no ambiente anterior funcionando
- [ ] Validação/QA aprovado

### Após Deploy

- [ ] Verificar pods rodando: `kubectl get pods -n nexo-{env}`
- [ ] Testar endpoints principais
- [ ] Verificar logs: `kubectl logs -n nexo-{env} deployment/nexo-be`
- [ ] Verificar métricas no Grafana

## 🎯 Comandos Úteis

```bash
# Ver aplicações do ArgoCD
argocd app list

# Status de uma app
argocd app get nexo-be-qa

# Forçar sync
argocd app sync nexo-be-qa

# Ver histórico de uma app
argocd app history nexo-be-qa

# Rollback
argocd app rollback nexo-be-qa

# Ver diferenças pendentes
argocd app diff nexo-be-qa

# Ver pods em um ambiente
kubectl get pods -n nexo-qa

# Ver logs de um pod
kubectl logs -n nexo-qa deployment/nexo-be -f

# Ver eventos recentes
kubectl get events -n nexo-qa --sort-by='.lastTimestamp'

# Descrever pod
kubectl describe pod -n nexo-qa nexo-be-xxxx

# Acessar shell do pod
kubectl exec -it -n nexo-qa deployment/nexo-be -- /bin/sh
```

## 📞 Atalhos de Promoção

```bash
# Promoção rápida develop → qa → staging
./scripts/promote.sh develop qa && \
sleep 300 && \
./scripts/promote.sh qa staging

# Promoção completa (com pausa para validação)
./scripts/promote.sh develop qa
read -p "Validar QA e pressionar ENTER..."
./scripts/promote.sh qa staging
read -p "Validar Staging e pressionar ENTER..."
./scripts/promote.sh staging prod
```

## 🔗 Links Rápidos

- 📊 GitHub Actions: https://github.com/geraldobl58/nexo/actions
- 🐳 Docker Hub: https://hub.docker.com/u/geraldobl58
- 📖 Doc Completa: [11-gitops-workflow.md](./11-gitops-workflow.md)

---

**Dica:** Salve este arquivo nos favoritos para consulta rápida!
