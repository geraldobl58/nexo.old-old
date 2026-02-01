# 🔄 Nova Pipeline Unificada - Guia Rápido

## 📋 O que mudou?

### ❌ Antes (Problemas)

- 3 workflows diferentes (`ci-main.yml`, `cd-main.yml`, `ci-cd.yaml`)
- Executavam **2 vezes** (CI separado + CD)
- Deploy rodava em **todos os ambientes** mesmo mudando só um
- Difícil de debugar e manter

### ✅ Agora (Solução)

- **1 único workflow** (`pipeline.yml`)
- Executa **1 vez** por push
- Deploy **apenas no ambiente da branch** atual
- Simples, rápido e eficiente

---

## 🏗️ Arquitetura da Nova Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    PIPELINE UNIFICADA                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1️⃣ Pre-flight Check                                         │
│     ├─ Verificar [skip ci]                                   │
│     ├─ Detectar branch                                       │
│     └─ Mapear environment (develop→dev, qa→qa, etc)          │
│                                                               │
│  2️⃣ Detect Changes (paths-filter)                            │
│     ├─ nexo-be: apps/nexo-be/** ou packages/**               │
│     ├─ nexo-fe: apps/nexo-fe/** ou packages/**               │
│     └─ nexo-auth: apps/nexo-auth/**                          │
│                                                               │
│  3️⃣ CI (paralelo - apenas serviços alterados)                │
│     ├─ CI Backend   (se nexo-be mudou)                       │
│     ├─ CI Frontend  (se nexo-fe mudou)                       │
│     └─ CI Auth      (se nexo-auth mudou)                     │
│                                                               │
│  4️⃣ Build & Push Docker (paralelo - apenas serviços OK)      │
│     ├─ Build Backend   (tag: $branch)                        │
│     ├─ Build Frontend  (tag: $branch)                        │
│     └─ Build Auth      (tag: $branch)                        │
│                                                               │
│  5️⃣ Deploy (APENAS no ambiente da branch)                    │
│     ├─ Atualizar values-$env.yaml com commit SHA             │
│     ├─ Commit com [skip ci]                                  │
│     └─ Push → ArgoCD detecta e faz sync                      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Fluxo por Branch

| Branch    | Environment | Namespace      | Deploy     | ArgoCD Sync |
| --------- | ----------- | -------------- | ---------- | ----------- |
| `develop` | `dev`       | `nexo-develop` | Automático | Auto        |
| `qa`      | `qa`        | `nexo-qa`      | Automático | Auto        |
| `staging` | `staging`   | `nexo-staging` | Automático | Auto        |
| `main`    | `prod`      | `nexo-prod`    | Automático | Manual      |

---

## 💡 Cenários de Uso

### Cenário 1: Alterar apenas o Backend

```bash
# 1. Fazer mudança no backend
vim apps/nexo-be/src/app.module.ts

# 2. Commit e push
git add apps/nexo-be
git commit -m "feat(be): add new feature"
git push origin develop

# 3. O que acontece:
# ✅ Pre-flight passa
# ✅ Detect changes: nexo-be=true, nexo-fe=false, nexo-auth=false
# ✅ CI Backend executa (lint, test, build)
# ✅ CI Frontend/Auth NÃO executam
# ✅ Build & Push: APENAS nexo-be
# ✅ Deploy: Atualiza APENAS values-dev.yaml do nexo-be
# ✅ ArgoCD: Sync apenas nexo-be-dev
```

**Tempo estimado**: ~3-5 minutos

### Cenário 2: Alterar Frontend e Backend

```bash
# 1. Fazer mudanças
vim apps/nexo-be/src/health.controller.ts
vim apps/nexo-fe/src/app/page.tsx

# 2. Commit e push
git add apps/nexo-be apps/nexo-fe
git commit -m "feat: update health check and homepage"
git push origin develop

# 3. O que acontece:
# ✅ Detect changes: nexo-be=true, nexo-fe=true, nexo-auth=false
# ✅ CI Backend + CI Frontend (paralelo)
# ✅ Build nexo-be + Build nexo-fe (paralelo)
# ✅ Deploy: Atualiza values-dev.yaml de AMBOS
# ✅ ArgoCD: Sync nexo-be-dev + nexo-fe-dev
```

**Tempo estimado**: ~4-6 minutos (jobs paralelos)

### Cenário 3: Merge develop → qa

```bash
# 1. Merge para qa
git checkout qa
git merge develop
git push origin qa

# 3. O que acontece:
# ✅ Detect changes: detecta todas as mudanças do merge
# ✅ CI de todos os serviços alterados
# ✅ Build & Push com tag: qa
# ✅ Deploy: Atualiza APENAS values-qa.yaml
# ✅ ArgoCD: Sync APENAS no namespace nexo-qa
```

**Importante**: Deploy acontece **APENAS no ambiente QA**, não toca develop!

### Cenário 4: Hotfix em produção

```bash
# 1. Criar hotfix a partir de main
git checkout main
git checkout -b hotfix/critical-bug
vim apps/nexo-be/src/bug.ts
git commit -m "fix: critical bug"

# 2. Abrir PR para main
gh pr create --base main

# 3. Após aprovação e merge
# ✅ CI executa
# ✅ Build & Push com tag: main
# ✅ Deploy: Atualiza values-prod.yaml
# ⏸️ ArgoCD: NÃO faz sync automático (prod é manual)
# 👤 Operador faz sync manual no ArgoCD UI
```

---

## 🚫 Evitando Loops Infinitos

### Problema

Se o workflow commitasse sem `[skip ci]`, ia causar loop:

```
Push → CI → Commit → Push → CI → Commit → Push → ...
```

### Solução

Todo commit automático inclui `[skip ci]`:

```bash
git commit -m "deploy(dev): nexo-be → abc1234 [skip ci]"
```

O workflow verifica isso no pre-flight:

```yaml
if: |
  !contains(github.event.head_commit.message, '[skip ci]') &&
  github.actor != 'github-actions[bot]'
```

---

## 📊 Verificar Status

### GitHub Actions

```bash
# Ver workflows executando
open https://github.com/geraldobl58/nexo/actions

# Ou via CLI
gh run list --limit 5
gh run view <run-id>
```

### ArgoCD

```bash
# Via UI
open http://localhost:30080

# Via CLI
argocd app list
argocd app get nexo-be-dev
argocd app sync nexo-be-dev  # Forçar sync manual
```

### Kubernetes

```bash
# Ver pods no ambiente
kubectl get pods -n nexo-develop

# Ver logs do serviço
kubectl logs -f -n nexo-develop deployment/nexo-be

# Ver imagem atual
kubectl get deployment nexo-be -n nexo-develop -o jsonpath='{.spec.template.spec.containers[0].image}'
```

---

## 🐛 Troubleshooting

### Pipeline não executou

**Sintomas**: Push feito, mas pipeline não roda

**Causas possíveis**:

1. Commit contém `[skip ci]` ou `[ci skip]`
2. Mudanças fora de `apps/**` ou `packages/**`
3. Actor é o bot `github-actions[bot]`

**Solução**:

```bash
# Verificar última mensagem de commit
git log -1 --pretty=%B

# Forçar execução manual
gh workflow run pipeline.yml
```

### Pipeline rodou mas não fez deploy

**Sintomas**: CI passou, imagem buildada, mas values não atualizados

**Causas possíveis**:

1. É um PR (deploy só em push)
2. Branch não mapeada (feature/\*)
3. Build falhou

**Solução**:

```bash
# Verificar logs do job "deploy"
gh run view <run-id>

# Verificar se values foi commitado
git log --oneline -5 | grep deploy
```

### ArgoCD não sincronizou

**Sintomas**: Values atualizados, mas pods não recriados

**Causas possíveis**:

1. Auto-sync desabilitado para o environment
2. ArgoCD não detectou mudança
3. Erro de sync

**Solução**:

```bash
# Verificar status
argocd app get nexo-be-dev

# Forçar sync manual
argocd app sync nexo-be-dev --force

# Ver diff
argocd app diff nexo-be-dev
```

---

## 🔧 Configuração Manual (Se necessário)

### Forçar build de todos os serviços

Via GitHub UI:

1. Ir em **Actions** → **Pipeline**
2. Clicar em **Run workflow**
3. Marcar `force_all: true`
4. Clicar em **Run workflow**

Via CLI:

```bash
gh workflow run pipeline.yml -f force_all=true
```

---

## ✅ Checklist de Migração

- [x] Novo workflow `pipeline.yml` criado
- [x] Workflows antigos movidos para `.backup/`
- [ ] Testar push em `develop`
- [ ] Verificar que executa 1 vez apenas
- [ ] Testar merge `develop → qa`
- [ ] Verificar que deploy só em QA
- [ ] Atualizar documentação

---

## 📚 Próximos Passos

1. **Testar a pipeline**:

   ```bash
   # Fazer mudança simples
   echo "# Test" >> apps/nexo-fe/src/app/page.tsx
   git add .
   git commit -m "feat(fe): test new pipeline"
   git push origin develop
   ```

2. **Monitorar execução**:
   - GitHub Actions: https://github.com/geraldobl58/nexo/actions
   - ArgoCD: http://localhost:30080

3. **Validar resultado**:

   ```bash
   # Ver se deploy aconteceu
   git log -1 --grep="deploy(dev)"

   # Verificar pods
   kubectl get pods -n nexo-develop
   ```

4. **Ajustar documentação enterprise** (se necessário)

---

**Criado em**: 2026-02-01  
**Autor**: Platform Engineering Team  
**Versão**: 1.0 (Pipeline Unificada)
