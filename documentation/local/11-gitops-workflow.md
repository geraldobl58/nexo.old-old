# Pipeline CI/CD - Fluxo GitOps Completo

## 📋 Visão Geral

Este documento descreve o fluxo completo de CI/CD implementado no Nexo Platform, seguindo as melhores práticas de empresas enterprise com GitOps.

## 🔄 Fluxo de Branches e Ambientes

```
feature/* → develop → qa → staging → main (production)
    ↓          ↓        ↓       ↓         ↓
  PR/Test   Develop    QA   Staging   Production
```

### Mapeamento Branch → Ambiente

| Branch    | Ambiente    | Tag Docker | Sync Automático | Descrição                          |
| --------- | ----------- | ---------- | --------------- | ---------------------------------- |
| `develop` | Development | `develop`  | ✅ Sim          | Ambiente de desenvolvimento ativo  |
| `qa`      | QA          | `qa`       | ✅ Sim          | Testes de qualidade                |
| `staging` | Staging     | `staging`  | ✅ Sim          | Homologação/pré-produção           |
| `main`    | Production  | `latest`   | ❌ Não          | Produção (requer aprovação manual) |

## 🚀 Como o Fluxo Funciona

### 1️⃣ Desenvolvimento e Push para Develop

```bash
# Você desenvolve sua feature
git checkout -b feature/nova-funcionalidade
git add .
git commit -m "feat: adiciona nova funcionalidade"

# Merge para develop (via PR ou direto)
git checkout develop
git merge feature/nova-funcionalidade
git push origin develop
```

**O que acontece automaticamente:**

1. ✅ GitHub Actions detecta push na branch `develop`
2. ✅ Executa testes e linting
3. ✅ Builda as imagens Docker
4. ✅ Publica imagens com tags:
   - `geraldobl58/nexo-be:develop`
   - `geraldobl58/nexo-be:develop-abc1234` (SHA)
5. ✅ ArgoCD Image Updater detecta nova imagem
6. ✅ Deploy automático no ambiente **develop**

### 2️⃣ Promoção para QA

Quando seu código está estável no develop e você quer promover para QA:

```bash
# Opção 1: Usando o script (RECOMENDADO)
./scripts/promote.sh develop qa

# Opção 2: Manual
git checkout qa
git pull origin qa
git merge origin/develop --no-ff -m "chore: promote develop to qa"
git push origin qa
```

**O que acontece automaticamente:**

1. ✅ GitHub Actions detecta push na branch `qa`
2. ✅ Executa testes e linting
3. ✅ Builda novas imagens com tags:
   - `geraldobl58/nexo-be:qa`
   - `geraldobl58/nexo-be:qa-def5678` (SHA)
4. ✅ ArgoCD Image Updater detecta nova imagem com tag `qa`
5. ✅ Deploy automático no ambiente **QA**

### 3️⃣ Promoção para Staging

```bash
# Após validação no QA
./scripts/promote.sh qa staging
```

**O que acontece automaticamente:**

1. ✅ GitHub Actions detecta push na branch `staging`
2. ✅ Executa testes e linting
3. ✅ Builda imagens com tags:
   - `geraldobl58/nexo-be:staging`
4. ✅ ArgoCD Image Updater detecta nova imagem
5. ✅ Deploy automático no ambiente **Staging**

### 4️⃣ Promoção para Produção

```bash
# Após validação completa no staging
./scripts/promote.sh staging prod
```

**O que acontece automaticamente:**

1. ✅ GitHub Actions detecta push na branch `main`
2. ✅ Executa testes e linting
3. ✅ Builda imagens com tags:
   - `geraldobl58/nexo-be:latest`
4. ✅ ArgoCD Image Updater detecta nova imagem
5. ⚠️ **Deploy manual** (por segurança)
   - Você precisa aprovar no ArgoCD UI ou executar:
   ```bash
   argocd app sync nexo-be-prod
   ```

## 🔧 Configurações Importantes

### GitHub Actions Workflow

O workflow [.github/workflows/ci-cd.yaml](../.github/workflows/ci-cd.yaml) é acionado:

- ✅ Em **push** nas branches: `develop`, `qa`, `staging`, `main`
- ✅ Em **pull requests** para essas branches (apenas testes, sem deploy)
- ✅ Detecta automaticamente quais apps mudaram (nexo-be, nexo-fe, nexo-auth)
- ✅ Builda apenas os apps que tiveram alterações

### ArgoCD Image Updater

Configurado para:

- 🔍 Monitorar Docker Hub a cada 2 minutos
- 🏷️ Detectar mudanças em tags específicas por ambiente
- 🔄 Atualizar automaticamente os manifests do ArgoCD
- ✅ Trigger de sync automático (exceto produção)

### Secrets Necessários no GitHub

Configure no seu repositório: **Settings** → **Secrets and variables** → **Actions**

```
DOCKERHUB_TOKEN = seu_token_dockerhub
```

Para criar um token:

1. Acesse: https://hub.docker.com/settings/security
2. Clique em "New Access Token"
3. Nome: `github-actions`
4. Permissões: Read & Write
5. Copie o token e adicione no GitHub

## 📊 Monitoramento

### GitHub Actions

```bash
# Ver status dos workflows
open https://github.com/geraldobl58/nexo/actions
```

### ArgoCD

```bash
# Acessar ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Ver status das aplicações
argocd app list

# Ver detalhes de uma aplicação
argocd app get nexo-be-qa

# Forçar sync manual
argocd app sync nexo-be-qa

# Ver logs do Image Updater
kubectl logs -n argocd deployment/argocd-image-updater -f
```

### Docker Hub

Verificar se as imagens foram publicadas:

```bash
# Ver tags disponíveis
curl -s https://hub.docker.com/v2/repositories/geraldobl58/nexo-be/tags | jq '.results[].name'
```

## 🐛 Troubleshooting

### Problema: ArgoCD não detecta novas imagens

**Solução:**

1. Verificar se a imagem foi publicada no Docker Hub
2. Verificar se o Image Updater está rodando:
   ```bash
   kubectl get pods -n argocd | grep image-updater
   ```
3. Verificar logs do Image Updater:
   ```bash
   kubectl logs -n argocd deployment/argocd-image-updater -f
   ```
4. Forçar refresh do Image Updater:
   ```bash
   kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-image-updater
   ```

### Problema: GitHub Actions falhando no build

**Solução:**

1. Verificar se o token do Docker Hub está configurado
2. Verificar se os testes estão passando localmente:
   ```bash
   pnpm test
   ```
3. Ver logs detalhados no GitHub Actions

### Problema: Ambiente não atualiza após merge

**Possíveis causas:**

1. ❌ GitHub Actions não foi executado
   - Verificar se o workflow foi acionado
   - Verificar logs no GitHub Actions

2. ❌ Build falhou
   - Ver logs do workflow
   - Corrigir erros e fazer novo push

3. ❌ Imagem não foi publicada
   - Verificar Docker Hub
   - Verificar credenciais

4. ❌ Tag incorreta
   - Verificar se a tag no ArgoCD corresponde à branch
   - `develop` → tag `develop`
   - `qa` → tag `qa`
   - `staging` → tag `staging`
   - `main` → tag `latest`

## 🎯 Boas Práticas

### ✅ DOs

- ✅ Sempre teste localmente antes de fazer push
- ✅ Use o script `./scripts/promote.sh` para promoções
- ✅ Faça deploys incrementais (develop → qa → staging → prod)
- ✅ Verifique se o deploy anterior foi bem-sucedido antes de promover
- ✅ Use branches de feature para desenvolvimento
- ✅ Faça PRs para review antes de merge

### ❌ DON'Ts

- ❌ Não faça push diretamente para `main`
- ❌ Não pule ambientes (ex: develop → prod)
- ❌ Não promova código com testes falhando
- ❌ Não faça deploys manuais pulando o GitOps
- ❌ Não edite recursos do Kubernetes diretamente

## 📝 Exemplo Completo de Fluxo

```bash
# 1. Criar feature
git checkout -b feature/add-user-api
# ... desenvolver código ...
git add .
git commit -m "feat: adiciona API de usuários"

# 2. Merge para develop
git checkout develop
git pull origin develop
git merge feature/add-user-api
git push origin develop
# ⏱️ Aguardar: GitHub Actions → Deploy em develop

# 3. Validar no ambiente develop
curl https://develop.api.nexo.local/users

# 4. Promover para QA
./scripts/promote.sh develop qa
# ⏱️ Aguardar: GitHub Actions → Deploy em QA

# 5. Validar no ambiente QA
curl https://qa.api.nexo.local/users

# 6. Promover para Staging
./scripts/promote.sh qa staging
# ⏱️ Aguardar: GitHub Actions → Deploy em Staging

# 7. Validar no ambiente Staging
curl https://staging.api.nexo.local/users

# 8. Promover para Produção
./scripts/promote.sh staging prod
# ⏱️ Aguardar: GitHub Actions → Imagem publicada

# 9. Deploy manual em produção
argocd app sync nexo-be-prod --prune

# 10. Validar em produção
curl https://prod.api.nexo.local/users
```

## 🔐 Segurança

- 🔒 Produção requer sync manual (segurança extra)
- 🔒 Todas as imagens passam por testes antes do deploy
- 🔒 Credenciais do Docker Hub armazenadas como secrets
- 🔒 RBAC configurado no ArgoCD
- 🔒 Namespaces isolados por ambiente

## 📚 Recursos Adicionais

- [Documentação ArgoCD](https://argo-cd.readthedocs.io/)
- [ArgoCD Image Updater](https://argocd-image-updater.readthedocs.io/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GitOps Principles](https://www.gitops.tech/)

## 🆘 Suporte

Para problemas ou dúvidas:

1. Consulte a [documentação de troubleshooting](./10-troubleshooting.md)
2. Verifique os logs do ArgoCD e GitHub Actions
3. Abra uma issue no repositório

---

**Última atualização:** 31 de Janeiro de 2026
