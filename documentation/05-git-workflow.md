# 🌳 Git Workflow

Guia completo sobre o workflow de Git e estratégia de branches no projeto Nexo.

## 🎯 Estratégia de Branches

Usamos **GitFlow modificado** adaptado para GitOps e deploy contínuo.

### Estrutura de Branches

```
main (produção)
│
└── develop (desenvolvimento)
    │
    ├── feature/nova-funcionalidade
    ├── feature/adicionar-login
    ├── fix/corrigir-bug-xyz
    ├── chore/atualizar-deps
    └── hotfix/corrigir-producao
```

### Tipos de Branches

| Branch | Propósito | Base | Merge para |
|--------|-----------|------|------------|
| `main` | **Produção** - código estável em produção | - | - |
| `develop` | **Desenvolvimento** - código em desenvolvimento | `main` | `main` |
| `feature/*` | Nova funcionalidade | `develop` | `develop` |
| `fix/*` | Correção de bug | `develop` | `develop` |
| `hotfix/*` | Correção urgente produção | `main` | `main` + `develop` |
| `chore/*` | Manutenção, deps, refactor | `develop` | `develop` |
| `docs/*` | Apenas documentação | `develop` | `develop` |

## 🚀 Workflow Completo

### 1. Iniciar Nova Feature

```bash
# Atualizar develop
git checkout develop
git pull origin develop

# Criar branch de feature
git checkout -b feature/adicionar-perfil-usuario

# Confirmar branch
git branch
```

### 2. Desenvolvimento

```bash
# Fazer mudanças
# ... editar código ...

# Ver status
git status

# Ver diff
git diff

# Add arquivos específicos
git add apps/nexo-be/src/users/profile.controller.ts
git add apps/nexo-be/src/users/profile.service.ts

# OU add todos
git add .
```

### 3. Commit (Conventional Commits)

```bash
# Commit com mensagem descritiva
git commit -m "feat(users): adiciona endpoint de perfil do usuário"

# Exemplos:
git commit -m "fix(auth): corrige validação de token JWT"
git commit -m "chore(deps): atualiza nestjs para v10.3.0"
git commit -m "docs: atualiza README com novos endpoints"
git commit -m "refactor(api): reorganiza estrutura de controllers"
```

### 4. Push para Origin

```bash
# Push branch
git push origin feature/adicionar-perfil-usuario

# Se primeira vez
git push -u origin feature/adicionar-perfil-usuario
```

### 5. Criar Pull Request

```bash
# Via GitHub CLI
gh pr create \
  --base develop \
  --title "feat(users): adiciona perfil de usuário" \
  --body "Implementa endpoints para gerenciar perfil do usuário"

# OU via UI
open https://github.com/geraldobl58/nexo/compare
```

### 6. Code Review

- Aguardar aprovação
- Resolver conflitos se necessário
- Aplicar feedback
- Push de commits adicionais

### 7. Merge

```bash
# Squash and Merge (preferido)
# - Mantém histórico limpo
# - Um commit por feature

# OU Merge Commit
# - Preserva histórico completo
# - Útil para features grandes
```

### 8. Deletar Branch

```bash
# Localmente
git checkout develop
git pull origin develop
git branch -d feature/adicionar-perfil-usuario

# Remotamente (se não foi auto-deletada)
git push origin --delete feature/adicionar-perfil-usuario
```

## 📝 Conventional Commits

Formato: `<tipo>[escopo opcional]: <descrição>`

### Tipos

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| `feat` | Nova funcionalidade | `feat(api): adiciona endpoint de busca` |
| `fix` | Correção de bug | `fix(auth): corrige expiração de token` |
| `docs` | Apenas documentação | `docs: atualiza guia de setup` |
| `style` | Formatação, lint | `style: formata código com prettier` |
| `refactor` | Refatoração (sem mudança de comportamento) | `refactor(db): otimiza queries` |
| `perf` | Melhoria de performance | `perf(api): cacheia respostas frequentes` |
| `test` | Adiciona ou corrige testes | `test(users): adiciona testes unitários` |
| `chore` | Manutenção, deps, config | `chore(deps): atualiza dependências` |
| `ci` | CI/CD | `ci: adiciona workflow de deploy` |
| `build` | Build system | `build: configura webpack` |
| `revert` | Reverter commit | `revert: "feat: adiciona feature X"` |

### Escopos Comuns

- `api` - Backend/API
- `ui` - Frontend/Interface
- `auth` - Autenticação/Autorização
- `db` - Database/Prisma
- `k8s` - Kubernetes
- `ci` - CI/CD
- `docs` - Documentação
- `deps` - Dependências

### Exemplos Completos

```bash
# Feature
git commit -m "feat(auth): implementa login com OAuth2"

# Fix
git commit -m "fix(api): corrige validação de email"

# Breaking Change
git commit -m "feat(api)!: remove endpoint v1/users

BREAKING CHANGE: endpoint v1/users foi removido, use v2/users"

# Com descrição longa
git commit -m "feat(users): adiciona sistema de notificações

- Implementa envio de emails
- Adiciona templates de notificação
- Configura fila com Bull
- Adiciona testes e2e

Closes #123"

# Múltiplas linhas
git commit -m "chore(deps): atualiza dependências

- nestjs: 9.4.0 -> 10.3.0
- prisma: 5.8.0 -> 5.9.0
- typescript: 5.3.0 -> 5.4.0"
```

## 🔄 Sincronização

### Atualizar Branch com Develop

```bash
# Opção 1: Rebase (preferido - histórico linear)
git checkout feature/minha-feature
git fetch origin
git rebase origin/develop

# Resolver conflitos se houver
git add .
git rebase --continue

# Force push (branch é sua)
git push --force-with-lease

# Opção 2: Merge
git checkout feature/minha-feature
git merge origin/develop
git push
```

### Resolver Conflitos

```bash
# Durante rebase/merge, conflitos aparecem
# Arquivos marcados com <<<<<<< HEAD

# Ver arquivos conflitantes
git status

# Abrir arquivo e resolver
code apps/nexo-be/src/app.module.ts

# Após resolver
git add apps/nexo-be/src/app.module.ts

# Continuar rebase
git rebase --continue

# OU continuar merge
git commit
```

### Desfazer Mudanças

```bash
# Desfazer arquivo não commitado
git checkout -- apps/nexo-be/src/users/users.service.ts

# Desfazer todos não commitados
git reset --hard

# Desfazer último commit (mantém mudanças)
git reset --soft HEAD~1

# Desfazer último commit (descarta mudanças)
git reset --hard HEAD~1

# Reverter commit específico
git revert abc123def
```

## 🔥 Hotfix Workflow

Para bugs críticos em produção:

```bash
# 1. Partir de main
git checkout main
git pull origin main

# 2. Criar branch de hotfix
git checkout -b hotfix/corrige-falha-login

# 3. Fazer correção
# ... editar código ...

# 4. Commit
git commit -m "fix(auth)!: corrige falha no login OAuth

Corrige bug crítico que impedia login de usuários.

HOTFIX: deploy urgente em produção"

# 5. Push
git push origin hotfix/corrige-falha-login

# 6. PR para main
gh pr create --base main --title "hotfix: corrige falha no login"

# 7. Após merge em main, também mergar em develop
git checkout develop
git pull origin develop
git merge main
git push origin develop
```

## 📦 Release Workflow

### Criar Release

```bash
# 1. Checkout develop
git checkout develop
git pull origin develop

# 2. Criar release branch
git checkout -b release/v1.2.0

# 3. Bump versão
# Editar package.json, CHANGELOG.md, etc.

# 4. Commit
git commit -m "chore(release): v1.2.0"

# 5. Merge em main
git checkout main
git merge release/v1.2.0

# 6. Tag
git tag -a v1.2.0 -m "Release v1.2.0

Changelog:
- feat: adiciona dashboard de usuários
- fix: corrige bug no login
- chore: atualiza dependências
"

# 7. Push
git push origin main --tags

# 8. Merge em develop
git checkout develop
git merge release/v1.2.0
git push origin develop

# 9. Deletar branch
git branch -d release/v1.2.0
git push origin --delete release/v1.2.0
```

### Versionamento Semântico

```
v1.2.3
│ │ └─ PATCH: correções de bugs
│ └─── MINOR: novas features (compatível)
└───── MAJOR: breaking changes
```

**Exemplos:**
- `v1.0.0` - Release inicial
- `v1.1.0` - Adiciona nova feature (compatível)
- `v1.1.1` - Corrige bug
- `v2.0.0` - Breaking change

## 🛡️ Branch Protection

### Regras para `main`

```yaml
# Configurado no GitHub
- Require pull request before merging
- Require approvals: 1
- Dismiss stale reviews
- Require status checks: CI/CD
- Require branches up to date
- Require linear history
- No force push
- No deletion
```

### Regras para `develop`

```yaml
# Configurado no GitHub
- Require pull request before merging
- Require status checks: CI/CD
- Require branches up to date
- Allow force push: No
```

## 🤖 Automação com GitHub Actions

### Auto-assign

```yaml
# .github/workflows/auto-assign.yml
name: Auto Assign
on:
  pull_request:
    types: [opened]
jobs:
  assign:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/auto-assign@v1
```

### Auto-label

```yaml
# .github/workflows/label.yml
name: Label PRs
on:
  pull_request:
    types: [opened]
jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/labeler@v4
```

## 📊 Git Flow Diagram

```
main ──────●────────────────●─────────────●──────────
           │                │             │
           │                │             │ v1.2.0
           │                │             │
develop ───●────●────●──────●────●────●───●──────────
           │    │    │           │    │
           │    │    └─ fix/bug  │    └─ feat/b
           │    └───── feat/a    │
           │                     │
           └───── hotfix ────────┘
```

## 🔍 Inspeção e Histórico

```bash
# Ver histórico
git log --oneline --graph --all

# Ver commits de um autor
git log --author="Geraldo"

# Ver commits com palavra-chave
git log --grep="feat"

# Ver mudanças em arquivo
git log -p apps/nexo-be/src/main.ts

# Ver quem mudou cada linha
git blame apps/nexo-be/src/main.ts

# Ver tags
git tag -l

# Ver branches
git branch -a
git branch -r

# Ver remotes
git remote -v
```

## 💡 Dicas e Boas Práticas

### 1. Commits Pequenos e Frequentes

❌ **Ruim:**
```bash
git commit -m "fix: várias correções"
# 50 arquivos alterados
```

✅ **Bom:**
```bash
git commit -m "fix(auth): corrige validação de token"
# 2 arquivos alterados

git commit -m "fix(api): corrige tratamento de erro"
# 1 arquivo alterado
```

### 2. Mensagens Descritivas

❌ **Ruim:**
```bash
git commit -m "ajustes"
git commit -m "wip"
git commit -m "fix"
```

✅ **Bom:**
```bash
git commit -m "feat(users): adiciona endpoint de busca avançada"
git commit -m "fix(auth): corrige expiração prematura de tokens"
git commit -m "refactor(api): extrai lógica de validação para service"
```

### 3. Rebase antes de PR

```bash
# Atualizar branch com develop
git fetch origin
git rebase origin/develop

# Squash commits locais (opcional)
git rebase -i HEAD~5
```

### 4. Verificar antes de Push

```bash
# Ver mudanças
git diff

# Ver arquivos
git status

# Ver commits
git log --oneline -5

# Testar localmente
pnpm test
pnpm lint
```

### 5. Use .gitignore Corretamente

```bash
# Nunca commitar
.env
*.log
node_modules/
dist/
.DS_Store

# Sempre commitar
.env.template
.gitignore
README.md
```

## 🚨 Troubleshooting

### Branch desatualizada

```bash
git fetch origin
git rebase origin/develop
```

### Commit errado

```bash
# Desfazer último commit
git reset --soft HEAD~1

# Editar
git add .
git commit -m "mensagem correta"
```

### Esqueceu de criar branch

```bash
# Salvar mudanças
git stash

# Criar branch
git checkout -b feature/nova-feature

# Recuperar mudanças
git stash pop
```

### Push rejeitado

```bash
# Atualizar primeiro
git pull origin develop --rebase
git push origin feature/minha-feature
```

## 📚 Referências

- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Semantic Versioning](https://semver.org/)

---

[← Desenvolvimento Local](./04-local-development.md) | [Voltar](./README.md) | [Próximo: APIs e Serviços →](./06-apis-services.md)
