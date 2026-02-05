# 🔐 Configuração GitHub

Guia completo para configurar GitHub Secrets, Tokens e Repositórios.

## 🎯 Objetivo

Configurar secrets do GitHub para **evitar passar tokens diretamente no código ou comandos**.

## 📋 Pré-requisitos

- Conta no GitHub
- Repositório `nexo` criado
- Permissões de admin no repositório

## 🔑 GitHub Personal Access Token (PAT)

### 1. Criar Token

1. Acesse: https://github.com/settings/tokens
2. Clique em **"Generate new token"** → **"Generate new token (classic)"**
3. Configure:
   - **Note**: `Nexo Platform - GHCR Access`
   - **Expiration**: `No expiration` ou `1 year`
   - **Scopes**:
     - ✅ `repo` (Full control of private repositories)
     - ✅ `write:packages` (Upload packages to GitHub Package Registry)
     - ✅ `read:packages` (Download packages from GitHub Package Registry)
     - ✅ `delete:packages` (Delete packages from GitHub Package Registry)
4. Clique em **"Generate token"**
5. **COPIE O TOKEN** (ghp\_...) - você não verá novamente!

### 2. Armazenar com Segurança

**❌ NUNCA faça:**

```bash
# ERRADO - token em código
git commit -m "add token ghp_123abc..."

# ERRADO - token em arquivo versionado
echo "TOKEN=ghp_123abc..." > .env
git add .env
```

**✅ SEMPRE faça:**

- Use GitHub Secrets (para CI/CD)
- Use variáveis de ambiente locais (para desenvolvimento)
- Adicione ao `.gitignore`:
  ```
  .env
  .env.local
  **/secrets/
  ```

## 🔐 Configurar GitHub Secrets

### 📊 Tabela de Configuração Completa

| Tipo         | Nome                    | Valor                     | Descrição            | Uso                          |
| ------------ | ----------------------- | ------------------------- | -------------------- | ---------------------------- |
| **Secret**   | `DISCORD_WEBHOOK`       | `https://discord.com/...` | Webhook notificações | Alertas de deploy            |
| **Variable** | `ARGOCD_AUTH_TOKEN`     | `eyJhbG...`               | Token ArgoCD         | Sync apps via API            |
| **Variable** | `ARGOCD_SERVER`         | `argocd.nexo.io`          | URL do ArgoCD        | Integração CI/CD             |
| **Variable** | `DOMAIN_DEV`            | `develop.nexo.io`         | Domínio develop      | Ingress                      |
| **Variable** | `DOMAIN_PROD`           | `prod.nexo.io`            | Domínio produção     | Ingress                      |
| **Variable** | `DOMAIN_STAGING`        | `staging.nexo.io`         | Domínio staging      | Ingress                      |
| **Variable** | `K8S_NAMESPACE_DEV`     | `nexo-develop`            | Namespace develop    | Deploy                       |
| **Variable** | `K8S_NAMESPACE_PROD`    | `nexo-prod`               | Namespace prod       | Deploy                       |
| **Variable** | `K8S_NAMESPACE_QA`      | `nexo-qa`                 | Namespace QA         | Deploy                       |
| **Variable** | `K8S_NAMESPACE_STAGING` | `nexo-staging`            | Namespace staging    | Deploy                       |

> **✅ Secrets Necessários:** Apenas `DISCORD_WEBHOOK`!
> 
> O GitHub Actions fornece automaticamente `GITHUB_TOKEN` com todas as permissões necessárias:
> - `packages: write` - Push de imagens Docker no GHCR
> - `contents: write` - Commit de values files
> - `pull-requests: write` - Comentários do Danger.js
> - `issues: write` - Labels e comentários

### Secrets do Repositório

Para que o CI/CD funcione automaticamente:

1. Acesse seu repositório no GitHub
2. Vá em: **Settings** → **Secrets and variables** → **Actions**
3. Clique em **"New repository secret"**

Configure o seguinte secret:

#### Secret: DISCORD_WEBHOOK

```
Name: DISCORD_WEBHOOK
Value: https://discord.com/api/webhooks/...
Description: Webhook para notificações de deploy
```

**Usado em:**

- Notificações de deploy bem-sucedido
- Alertas de falhas no pipeline
- Resumo de mudanças por ambiente

> **⚠️ Importante:** `GITHUB_TOKEN` é fornecido automaticamente pelo GitHub Actions e já tem permissões para:
> - Push/pull de imagens no GitHub Container Registry (GHCR)
> - Comentar em Pull Requests (Danger.js)
> - Atualizar repositório (update values files)
> 
> **Não é necessário criar nenhum token customizado!**

#### GHCR_USERNAME (Opcional)

```
Name: GHCR_USERNAME
Value: seu-usuario-github
Description: Username do GitHub (normalmente público)
```

### Secrets de Ambiente (Opcional)

Para diferentes ambientes (develop, staging, prod):

1. Vá em: **Settings** → **Environments**
2. Crie ambientes:
   - `develop`
   - `qa`
   - `staging`
   - `production`
3. Para cada ambiente, adicione secrets específicos se necessário

## 🏠 Configuração Local

### Opção 1: Variável de Ambiente Global

Adicione ao `~/.zshrc` ou `~/.bashrc`:

```bash
# GitHub Container Registry Token
export GITHUB_TOKEN=ghp_seu_token_aqui

# Username (opcional)
export GITHUB_USERNAME=geraldobl58
```

Recarregue:

```bash
source ~/.zshrc  # ou source ~/.bashrc
```

Agora você pode executar:

```bash
cd local
make setup  # Usa automaticamente $GITHUB_TOKEN
```

### Opção 2: Arquivo .env Local

Crie um arquivo `.env` na raiz do projeto:

```bash
# .env (NÃO versionar!)
GITHUB_TOKEN=ghp_seu_token_aqui
GITHUB_USERNAME=geraldobl58
```

Carregue antes de usar:

```bash
export $(cat .env | xargs)
cd local && make setup
```

### Opção 3: Passar Diretamente (Menos Seguro)

```bash
cd local
./scripts/setup.sh ghp_seu_token_aqui
```

⚠️ **Cuidado**: Token fica no histórico do shell!

## 🔄 Uso em CI/CD (GitHub Actions)

### Workflow Exemplo

```yaml
name: Build and Push Images

on:
  push:
    branches: [develop]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_TOKEN }}

      - name: Build and Push
        run: |
          docker build -t ghcr.io/geraldobl58/nexo-be:${{ github.sha }} .
          docker push ghcr.io/geraldobl58/nexo-be:${{ github.sha }}
```

### Acessar Secrets no Workflow

```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GHCR_TOKEN }}
  GITHUB_USERNAME: ${{ secrets.GHCR_USERNAME }}
```

## 🔒 Segurança e Boas Práticas

### ✅ O que FAZER

- ✅ Usar GitHub Secrets para CI/CD
- ✅ Usar variáveis de ambiente para dev local
- ✅ Adicionar `.env` ao `.gitignore`
- ✅ Rotacionar tokens periodicamente (a cada 90 dias)
- ✅ Usar tokens com escopos mínimos necessários
- ✅ Documentar onde cada secret é usado
- ✅ Usar diferentes tokens para CI/CD e desenvolvimento

### ❌ O que NÃO FAZER

- ❌ Commitar tokens no Git
- ❌ Compartilhar tokens em Slack/Discord
- ❌ Usar tokens pessoais em servidores de produção
- ❌ Logar tokens em console/logs
- ❌ Usar o mesmo token para tudo
- ❌ Tokens sem expiração em ambientes críticos

## 🔄 Rotação de Tokens

### Quando Rotacionar

- ✅ A cada 90 dias (política de segurança)
- ✅ Quando alguém sai da equipe
- ✅ Se houver suspeita de vazamento
- ✅ Após incident de segurança

### Como Rotacionar

1. **Criar novo token** no GitHub
2. **Atualizar GitHub Secrets**:
   - Settings → Secrets → GHCR_TOKEN → Update
3. **Atualizar localmente**:
   ```bash
   # Atualizar ~/.zshrc
   export GITHUB_TOKEN=ghp_novo_token
   source ~/.zshrc
   ```
4. **Revogar token antigo**:
   - https://github.com/settings/tokens
   - Encontre o token antigo → Delete
5. **Testar**:
   ```bash
   # Testar push de imagem
   docker login ghcr.io -u geraldobl58 -p $GITHUB_TOKEN
   ```

## 🎓 Verificar Configuração

### GitHub Secrets

```bash
# Você NÃO pode ver os secrets via CLI
# Verifique via UI: Settings → Secrets
```

### Local

```bash
# Verificar se variável está definida
echo $GITHUB_TOKEN

# Deve exibir: ghp_...
# Se vazio, não está configurado

# Testar login GHCR
docker login ghcr.io -u geraldobl58 -p $GITHUB_TOKEN

# Deve exibir: Login Succeeded
```

### CI/CD

Crie um workflow de teste:

```yaml
name: Test Secrets

on: workflow_dispatch

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Check GHCR_TOKEN
        run: |
          if [ -z "${{ secrets.GHCR_TOKEN }}" ]; then
            echo "❌ GHCR_TOKEN não configurado"
            exit 1
          else
            echo "✅ GHCR_TOKEN configurado"
          fi
```

## 🆘 Troubleshooting

### Erro: "authentication required"

```bash
# Causa: Token não configurado ou inválido
# Solução:
docker login ghcr.io -u geraldobl58 -p $GITHUB_TOKEN
```

### Erro: "secret not found"

```bash
# Causa: Secret não existe no repositório
# Solução: Adicione via Settings → Secrets → Actions
```

### Token expirado

```bash
# Gere novo token e atualize secrets
# https://github.com/settings/tokens
```

## 📚 Recursos

- [GitHub PAT Docs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [GitHub Secrets Docs](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GHCR Docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

---

[← Início Rápido](./01-quick-start.md) | [Voltar](./README.md) | [Próximo: Desenvolvimento Local →](./04-local-development.md)
