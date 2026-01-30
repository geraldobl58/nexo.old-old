# 05 - CI/CD

Pipeline de Integração e Entrega Contínua.

---

## 📋 Visão Geral

O pipeline usa GitHub Actions + DockerHub + ArgoCD:

```
┌─────────┐    ┌──────────┐    ┌───────────┐    ┌────────┐    ┌──────┐
│ Commit  │───▶│    CI    │───▶│    CD     │───▶│ ArgoCD │───▶│ K3D  │
│         │    │(build+   │    │(notifica) │    │(deploy)│    │      │
│         │    │  push)   │    │           │    │        │    │      │
└─────────┘    └──────────┘    └───────────┘    └────────┘    └──────┘
```

### Fluxo Simplificado

1. **Commit/Push** → Dispara CI
2. **CI** → Build da imagem + Push para DockerHub (tag: `develop`)
3. **CD** → Atualiza `podAnnotations.app.kubernetes.io/commit` com SHA curto
4. **Git** → Commit automático `[skip ci]`
5. **ArgoCD** → Detecta mudança na annotation e faz sync
6. **Kubernetes** → Recria pods (annotation mudou) + baixa nova imagem

> **GitOps completo**:
>
> - Tag da imagem: fixa (`develop`, `staging`, `prod`)
> - `imagePullPolicy: Always`: sempre baixa a imagem mais recente
> - Annotation com commit SHA: garante que pods sejam recriados

---

## 📁 Arquivos de Workflow

```
.github/workflows/
├── ci-main.yml          # Orquestrador CI
├── cd-main.yml          # Orquestrador CD
├── _ci-reusable.yml     # Job reutilizável - build/push
└── _cd-reusable.yml     # Job reutilizável - notifica ArgoCD
```

---

## Configuração do GitHub

### Repository Secrets (obrigatórios)

Acessar: **Settings → Secrets and variables → Actions → Secrets**

| Nome                 | Descrição              | Como Obter                                   |
| -------------------- | ---------------------- | -------------------------------------------- |
| `DOCKERHUB_USERNAME` | Usuário DockerHub      | hub.docker.com → Account Settings            |
| `DOCKERHUB_TOKEN`    | Access Token DockerHub | hub.docker.com → Security → New Access Token |
| `GH_TOKEN`           | GitHub Personal Token  | GitHub → Settings → Developer → Tokens       |

> ⚠️ **Nota**: Os secrets `KUBECONFIG_*` **não são mais necessários**.
> O ArgoCD gerencia os deploys automaticamente.

### Repository Variables (obrigatórios)

Acessar: **Settings → Secrets and variables → Actions → Variables**

| Nome                    | Valor Exemplo     | Descrição                |
| ----------------------- | ----------------- | ------------------------ |
| `REGISTRY`              | `docker.io`       | Registry Docker          |
| `ARGOCD_SERVER`         | `argocd.nexo.io`  | URL do ArgoCD            |
| `ARGOCD_AUTH_TOKEN`     | `eyJhb...`        | Token auth do ArgoCD     |
| `DOMAIN_DEV`            | `develop.nexo.io` | Domínio ambiente develop |
| `DOMAIN_STAGING`        | `staging.nexo.io` | Domínio ambiente staging |
| `DOMAIN_PROD`           | `prod.nexo.io`    | Domínio ambiente prod    |
| `K8S_NAMESPACE_DEV`     | `nexo-develop`    | Namespace K8s develop    |
| `K8S_NAMESPACE_QA`      | `nexo-qa`         | Namespace K8s qa         |
| `K8S_NAMESPACE_STAGING` | `nexo-staging`    | Namespace K8s staging    |
| `K8S_NAMESPACE_PROD`    | `nexo-prod`       | Namespace K8s production |

### Environments (proteção de branches)

Acessar: **Settings → Environments**

Criar os seguintes environments com protection rules:

| Environment | Protection Rules                                |
| ----------- | ----------------------------------------------- |
| `develop`   | Nenhuma (deploy automático)                     |
| `qa`        | Required reviewers (opcional)                   |
| `staging`   | Required reviewers (1 aprovador)                |
| `prod`      | Required reviewers (2 aprovadores) + Wait timer |

### Criando o Token DockerHub

1. Acesse https://hub.docker.com
2. Vá em **Account Settings → Security**
3. Clique **New Access Token**
4. Nome: `github-actions`
5. Permissões: `Read, Write, Delete`
6. Copie o token e salve como `DOCKERHUB_TOKEN`

### Criando o GitHub Token (GH_TOKEN)

1. Acesse https://github.com/settings/tokens
2. Clique **Generate new token (classic)**
3. Permissões necessárias:
   - `repo` (full control)
   - `write:packages`
   - `workflow`
4. Copie e salve como `GH_TOKEN`

---

## 🔑 ImagePullSecret no Kubernetes

Para que o Kubernetes/ArgoCD faça pull das imagens do DockerHub, é necessário criar um **ImagePullSecret** em cada namespace.

### Criando o Secret (Automático)

Execute o script que cria o secret em todos os namespaces:

```bash
# Via Makefile
cd local
make dockerhub-secret

# Ou diretamente
./local/scripts/create-dockerhub-secret.sh
```

O script irá solicitar:

- **DockerHub Username**: seu usuário
- **DockerHub Token**: o Access Token (mesmo usado no GitHub Actions)

### Criando o Secret (Manual)

```bash
# Para cada namespace
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=geraldobl58 \
  --docker-password=YOUR_TOKEN \
  --docker-email=geraldobl58@users.noreply.dockerhub.com \
  -n nexo-develop

# Repetir para: nexo-qa, nexo-staging, nexo-prod
```

### Verificando o Secret

```bash
# Verificar se o secret existe
kubectl get secret dockerhub-secret -n nexo-develop

# Ver detalhes (decodificado)
kubectl get secret dockerhub-secret -n nexo-develop -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq
```

### Namespaces que Precisam do Secret

| Namespace      | Uso                         |
| -------------- | --------------------------- |
| `nexo-develop` | Ambiente de desenvolvimento |
| `nexo-qa`      | Ambiente de QA              |
| `nexo-staging` | Ambiente de staging         |
| `nexo-prod`    | Ambiente de produção        |
| `argocd`       | ArgoCD (para sincronização) |

### Configuração nos Helm Charts

Os Helm charts já estão configurados para usar o secret:

```yaml
# local/helm/nexo-be/values.yaml
imagePullSecrets:
  - name: dockerhub-secret
```

---

### �🔵 CI - Continuous Integration

### ci-main.yml

```yaml
name: CI

on:
  push:
    branches: [develop, qa, staging, main]
  pull_request:
    branches: [develop, qa, staging, main]

jobs:
  # Detectar mudanças
  changes:
    runs-on: ubuntu-latest
    outputs:
      frontend: ${{ steps.filter.outputs.frontend }}
      backend: ${{ steps.filter.outputs.backend }}
      auth: ${{ steps.filter.outputs.auth }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            frontend:
              - 'apps/nexo-fe/**'
            backend:
              - 'apps/nexo-be/**'
            auth:
              - 'apps/nexo-auth/**'

  # CI Frontend
  ci-frontend:
    needs: changes
    if: needs.changes.outputs.frontend == 'true'
    uses: ./.github/workflows/_ci-reusable.yml
    with:
      app: nexo-fe
      working-directory: apps/nexo-fe

  # CI Backend
  ci-backend:
    needs: changes
    if: needs.changes.outputs.backend == 'true'
    uses: ./.github/workflows/_ci-reusable.yml
    with:
      app: nexo-be
      working-directory: apps/nexo-be

  # CI Auth
  ci-auth:
    needs: changes
    if: needs.changes.outputs.auth == 'true'
    uses: ./.github/workflows/_ci-reusable.yml
    with:
      app: nexo-auth
      working-directory: apps/nexo-auth
```

### \_ci-reusable.yml

```yaml
name: CI Reusable

on:
  workflow_call:
    inputs:
      app:
        required: true
        type: string
      working-directory:
        required: true
        type: string

jobs:
  test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ inputs.working-directory }}
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm

      - run: pnpm install --frozen-lockfile

      - run: pnpm lint
        if: inputs.app != 'nexo-auth'

      - run: pnpm test
        if: inputs.app != 'nexo-auth'

      - run: pnpm build
        if: inputs.app != 'nexo-auth'
```

---

## 🟢 CD - Continuous Delivery

### cd-main.yml

```yaml
name: CD

on:
  push:
    branches: [develop, qa, staging, main]

jobs:
  # Detectar mudanças
  changes:
    runs-on: ubuntu-latest
    outputs:
      frontend: ${{ steps.filter.outputs.frontend }}
      backend: ${{ steps.filter.outputs.backend }}
      auth: ${{ steps.filter.outputs.auth }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            frontend:
              - 'apps/nexo-fe/**'
            backend:
              - 'apps/nexo-be/**'
            auth:
              - 'apps/nexo-auth/**'

  # Determinar ambiente
  set-env:
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.set.outputs.environment }}
      tag: ${{ steps.set.outputs.tag }}
    steps:
      - id: set
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "environment=production" >> $GITHUB_OUTPUT
            echo "tag=prod" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/staging" ]]; then
            echo "environment=staging" >> $GITHUB_OUTPUT
            echo "tag=staging" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/qa" ]]; then
            echo "environment=qa" >> $GITHUB_OUTPUT
            echo "tag=qa" >> $GITHUB_OUTPUT
          else
            echo "environment=develop" >> $GITHUB_OUTPUT
            echo "tag=develop" >> $GITHUB_OUTPUT
          fi

  # CD Frontend
  cd-frontend:
    needs: [changes, set-env]
    if: needs.changes.outputs.frontend == 'true'
    uses: ./.github/workflows/_cd-reusable.yml
    with:
      app: nexo-fe
      dockerfile: apps/nexo-fe/Dockerfile
      context: .
      environment: ${{ needs.set-env.outputs.environment }}
      tag: ${{ needs.set-env.outputs.tag }}
    secrets: inherit

  # CD Backend
  cd-backend:
    needs: [changes, set-env]
    if: needs.changes.outputs.backend == 'true'
    uses: ./.github/workflows/_cd-reusable.yml
    with:
      app: nexo-be
      dockerfile: apps/nexo-be/Dockerfile
      context: .
      environment: ${{ needs.set-env.outputs.environment }}
      tag: ${{ needs.set-env.outputs.tag }}
    secrets: inherit

  # CD Auth
  cd-auth:
    needs: [changes, set-env]
    if: needs.changes.outputs.auth == 'true'
    uses: ./.github/workflows/_cd-reusable.yml
    with:
      app: nexo-auth
      dockerfile: apps/nexo-auth/Dockerfile
      context: apps/nexo-auth
      environment: ${{ needs.set-env.outputs.environment }}
      tag: ${{ needs.set-env.outputs.tag }}
    secrets: inherit
```

### \_cd-reusable.yml

```yaml
name: CD Reusable

on:
  workflow_call:
    inputs:
      app:
        required: true
        type: string
      dockerfile:
        required: true
        type: string
      context:
        required: true
        type: string
      environment:
        required: true
        type: string
      tag:
        required: true
        type: string

jobs:
  build-push:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and Push
        uses: docker/build-push-action@v5
        with:
          context: ${{ inputs.context }}
          file: ${{ inputs.dockerfile }}
          push: true
          tags: |
            ${{ vars.DOCKERHUB_NAMESPACE }}/${{ inputs.app }}:${{ inputs.tag }}
            ${{ vars.DOCKERHUB_NAMESPACE }}/${{ inputs.app }}:${{ inputs.tag }}-${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## 🔄 ArgoCD Image Updater

O ArgoCD Image Updater detecta automaticamente novas imagens no DockerHub.

### Configuração nas Applications

```yaml
# local/argocd/apps/nexo-develop.yaml
metadata:
  annotations:
    argocd-image-updater.argoproj.io/image-list: |
      nexo-fe=docker.io/geraldobl58/nexo-fe:develop
      nexo-be=docker.io/geraldobl58/nexo-be:develop
      nexo-auth=docker.io/geraldobl58/nexo-auth:develop
    argocd-image-updater.argoproj.io/write-back-method: argocd
```

### Fluxo Automático

1. **CI** testa o código
2. **CD** faz build e push para DockerHub com tag (ex: `develop`)
3. **Image Updater** detecta nova imagem (poll a cada 2 min)
4. **ArgoCD** atualiza a aplicação no K3D

---

## ⚡ Estratégia de Cache e Rate Limit

### Problema: Rate Limit do DockerHub

O DockerHub tem limite de pulls:

| Conta        | Limite       | Reset    |
| ------------ | ------------ | -------- |
| Anônimo      | 100 pulls/6h | Por IP   |
| Autenticado  | 200 pulls/6h | Por user |
| Pro ($5/mês) | Ilimitado    | -        |

Quando atingimos o limite, o build falha com:

```
toomanyrequests: You have reached your pull rate limit
```

### Solução: Builds Sequenciais + Cache

Para evitar o rate limit, implementamos:

#### 1. Builds Sequenciais (não paralelos)

```yaml
# Em vez de rodar em paralelo:
ci-backend:  ─┐
ci-frontend: ─┼─► (3x pulls simultâneos = rate limit)
ci-auth:     ─┘

# Rodamos sequencialmente:
ci-backend: ───► ci-frontend: ───► ci-auth:
                    │                   │
              (reusa cache)      (reusa cache)
```

#### 2. Cache de Imagens Base

O workflow faz pull da imagem base ANTES do Buildx:

```yaml
- name: Pull base images (with retry)
  run: |
    for i in 1 2 3; do
      docker pull node:20-alpine && break || sleep 30
    done
  continue-on-error: true
```

Isso garante que a imagem esteja no cache local.

#### 3. Cache Multinível

Usamos dois níveis de cache:

```yaml
cache-from: |
  type=gha                                           # GitHub Actions cache
  type=registry,ref=geraldobl58/nexo-fe:buildcache   # Registry cache
cache-to: type=gha,mode=max
```

| Tipo     | Descrição                  | Velocidade      |
| -------- | -------------------------- | --------------- |
| GHA      | GitHub Actions cache (S3)  | ⚡ Muito rápido |
| Registry | Cache no próprio DockerHub | 🔄 Médio        |

#### 4. Flags de Otimização

```yaml
provenance: false # Evita metadados extras (menos pulls)
sbom: false # SBOM gerado separadamente
platforms: linux/amd64 # Só uma plataforma (evita 2x pulls)
```

### Fluxo Completo com Cache

```
┌─────────────────────────────────────────────────────────────────┐
│                        CI Pipeline                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Backend ────────────────────────────────────────────────────►  │
│     │                                                           │
│     ├── Login DockerHub                                         │
│     ├── Pull node:20-alpine (1º pull, vai para cache)          │
│     ├── Build com cache GHA                                     │
│     └── Push para DockerHub                                     │
│                                                                 │
│  Frontend (após Backend) ────────────────────────────────────►  │
│     │                                                           │
│     ├── Login DockerHub                                         │
│     ├── Pull node:20-alpine (USA CACHE - sem pull!)            │
│     ├── Build com cache GHA                                     │
│     └── Push para DockerHub                                     │
│                                                                 │
│  Auth (após Frontend) ───────────────────────────────────────►  │
│     │                                                           │
│     ├── Login DockerHub                                         │
│     ├── Pull keycloak:26 (1º pull, vai para cache)             │
│     ├── Build com cache GHA                                     │
│     └── Push para DockerHub                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Resultado

| Métrica         | Antes     | Depois                      |
| --------------- | --------- | --------------------------- |
| Pulls por build | ~15-20    | ~3-5                        |
| Rate limit hits | Frequente | Raro                        |
| Tempo de build  | ~8 min    | ~10 min (aceito pelo ganho) |

### Se Ainda Atingir Rate Limit

1. **Aguardar 6 horas** - O limite reseta automaticamente
2. **Re-run failed jobs** - GitHub Actions → Re-run
3. **Upgrade DockerHub Pro** - $5/mês para pulls ilimitados

---

## 📊 Tags de Imagem

| Branch  | Tag Docker | Exemplo                     |
| ------- | ---------- | --------------------------- |
| develop | develop    | geraldobl58/nexo-fe:develop |
| qa      | qa         | geraldobl58/nexo-fe:qa      |
| staging | staging    | geraldobl58/nexo-fe:staging |
| main    | prod       | geraldobl58/nexo-fe:prod    |

Além da tag do ambiente, também é criada uma tag com o SHA:

```
geraldobl58/nexo-fe:develop-abc123
```

---

## 🔍 Monitoramento

### Verificar Pipelines

```bash
# GitHub Actions
# https://github.com/geraldobl58/nexo/actions

# Ver logs de um workflow específico
# Clique no workflow → job → step
```

### Verificar ArgoCD

```bash
# Acessar ArgoCD
open http://localhost:30080

# Ou via CLI
argocd app list
argocd app get nexo-develop
argocd app sync nexo-develop
```

### Verificar Imagens DockerHub

```bash
# Listar tags
curl -s https://hub.docker.com/v2/repositories/geraldobl58/nexo-fe/tags \
  | jq '.results[].name'
```

---

## 🐛 Troubleshooting CI/CD

### CI Falhou

| Erro                | Causa                | Solução             |
| ------------------- | -------------------- | ------------------- |
| pnpm install falhou | Cache corrompido     | Re-run workflow     |
| Lint errors         | Código com problemas | Corrigir e commitar |
| Test failed         | Testes quebrando     | Debugar testes      |
| Build failed        | Erro de compilação   | Ver logs detalhados |

### CD Falhou

| Erro         | Causa           | Solução                   |
| ------------ | --------------- | ------------------------- |
| Login failed | Token inválido  | Regenerar token DockerHub |
| Push denied  | Sem permissão   | Verificar namespace       |
| Build failed | Dockerfile erro | Testar build local        |

### ArgoCD não Atualizou

```bash
# Verificar Image Updater logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater

# Forçar sync
argocd app sync nexo-develop --force

# Verificar se imagem existe
docker pull geraldobl58/nexo-fe:develop
```

---

## ➡️ Próximos Passos

- [06-git-workflow.md](06-git-workflow.md) - Fluxo de branches
- [07-development.md](07-development.md) - Desenvolvimento diário
