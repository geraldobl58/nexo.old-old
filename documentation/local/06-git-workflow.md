# 06 - Git Workflow

Estratégia de branches e fluxo de trabalho.

---

## 🌿 Branches Principais

| Branch      | Propósito         | Deploy       | Proteção                 |
| ----------- | ----------------- | ------------ | ------------------------ |
| **main**    | Produção          | nexo-prod    | ✅ Requer PR + Aprovação |
| **staging** | Pré-produção      | nexo-staging | ✅ Requer PR             |
| **qa**      | Quality Assurance | nexo-qa      | ✅ Requer PR             |
| **develop** | Desenvolvimento   | nexo-develop | ✅ Requer CI pass        |

---

## 🔀 Fluxo de Branches

```
main ◄───────────────────────────────────────────────────────────────┐
  │                                                                   │
  │ hotfix/*                                                          │
  │    ↓                                                              │
staging ◄──────────────────────────────────────────────────────┐      │
  │                                                             │      │
  │                                                             │      │
qa ◄─────────────────────────────────────────────────┐         │      │
  │                                                   │         │      │
  │                                                   │         │      │
develop ◄─────────────────────────────────────────┐   │         │      │
  │                                                │   │         │      │
  ├── feature/nova-funcionalidade ────────────────┘   │         │      │
  │                                                    │         │      │
  ├── fix/correcao-bug ───────────────────────────────┘         │      │
  │                                                              │      │
  └──────────────────────────────────────────────────────────────┴──────┘
```

---

## 🚀 Fluxo de Desenvolvimento

### 1. Criar Feature

```bash
# Partir do develop atualizado
git checkout develop
git pull origin develop

# Criar branch de feature
git checkout -b feature/minha-feature

# Desenvolver...
git add .
git commit -m "feat: implementa minha feature"

# Push
git push origin feature/minha-feature
```

### 2. Abrir Pull Request

1. Vá no GitHub
2. Clique em **Compare & pull request**
3. Base: `develop` ← Compare: `feature/minha-feature`
4. Preencha título e descrição
5. Aguarde CI passar
6. Merge

### 3. Promover para QA

```bash
git checkout qa
git merge develop
git push origin qa
```

Ou via Pull Request: `develop → qa`

### 4. Promover para Staging

```bash
git checkout staging
git merge qa
git push origin staging
```

Ou via Pull Request: `qa → staging`

### 5. Deploy para Produção

```bash
git checkout main
git merge staging
git push origin main
```

> ⚠️ **Requer aprovação** via Pull Request: `staging → main`

---

## 📝 Convenção de Commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

```
<tipo>(<escopo>): <descrição>

[corpo opcional]

[rodapé opcional]
```

### Tipos

| Tipo       | Descrição                          |
| ---------- | ---------------------------------- |
| `feat`     | Nova funcionalidade                |
| `fix`      | Correção de bug                    |
| `docs`     | Documentação                       |
| `style`    | Formatação (sem mudança de código) |
| `refactor` | Refatoração                        |
| `test`     | Testes                             |
| `chore`    | Manutenção                         |
| `ci`       | CI/CD                              |
| `perf`     | Performance                        |

### Exemplos

```bash
feat(auth): adiciona login com Google
fix(api): corrige validação de email
docs(readme): atualiza instruções de setup
refactor(fe): reorganiza componentes
test(be): adiciona testes de integração
chore(deps): atualiza dependências
ci(github): adiciona cache no workflow
```

---

## 📛 Convenção de Branches

```
<tipo>/<descrição-curta>
```

### Tipos de Branch

| Prefixo     | Uso                          |
| ----------- | ---------------------------- |
| `feature/`  | Nova funcionalidade          |
| `fix/`      | Correção de bug              |
| `hotfix/`   | Correção urgente em produção |
| `docs/`     | Documentação                 |
| `refactor/` | Refatoração                  |
| `test/`     | Testes                       |
| `chore/`    | Manutenção                   |

### Exemplos

```bash
feature/user-authentication
fix/login-redirect-loop
hotfix/payment-calculation
docs/api-documentation
refactor/database-queries
```

---

## 🔥 Hotfix (Correção Urgente)

Para bugs críticos em produção:

```bash
# Criar hotfix a partir de main
git checkout main
git pull origin main
git checkout -b hotfix/fix-critico

# Corrigir...
git add .
git commit -m "hotfix: corrige bug crítico"

# Push e PR para main
git push origin hotfix/fix-critico
# Abrir PR: hotfix/fix-critico → main (com aprovação urgente)

# Após merge em main, fazer backport para develop
git checkout develop
git merge main
git push origin develop
```

---

## 📊 Diagrama de Promoção

```
feature/xxx ──┬──▶ develop ──▶ qa ──▶ staging ──▶ main
              │
fix/xxx ──────┘

hotfix/xxx ─────────────────────────────────────▶ main
                                                    │
                                        ◀───────────┘
                                    (backport para develop)
```

---

## ✅ Checklist para PR

Antes de abrir um Pull Request:

```markdown
## Checklist

- [ ] Código segue as convenções do projeto
- [ ] Testes adicionados/atualizados
- [ ] Documentação atualizada (se necessário)
- [ ] Sem console.log ou código de debug
- [ ] Lint passa sem erros
- [ ] Build passa sem erros
- [ ] Testado localmente
```

---

## 🔄 Sincronização

### Manter branch atualizada

```bash
git checkout minha-feature
git fetch origin
git rebase origin/develop
# Resolver conflitos se houver
git push -f origin minha-feature
```

### Resolver conflitos

```bash
# Durante rebase
git rebase origin/develop
# Conflito detectado...

# Editar arquivos conflitantes
# Marcar como resolvido
git add .
git rebase --continue

# Se precisar abortar
git rebase --abort
```

---

## 🏷️ Tags e Releases

Para versões de produção:

```bash
# Criar tag
git checkout main
git pull origin main
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Listar tags
git tag -l

# Ver detalhes
git show v1.0.0
```

### Versionamento Semântico

```
MAJOR.MINOR.PATCH

v1.0.0 → v1.0.1 (patch: bug fix)
v1.0.0 → v1.1.0 (minor: nova feature, retrocompatível)
v1.0.0 → v2.0.0 (major: breaking changes)
```

---

## ➡️ Próximos Passos

- [07-development.md](07-development.md) - Desenvolvimento diário
- [05-cicd.md](05-cicd.md) - Pipeline CI/CD
