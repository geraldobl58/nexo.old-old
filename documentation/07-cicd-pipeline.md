# 🚀 CI/CD Pipeline

Guia completo sobre o pipeline de Integração Contínua e Entrega Contínua no GitHub Actions.

## 🎯 Visão Geral

Pipeline automatizado que:
- ✅ Valida código (lint, test, build)
- 📦 Build e push de imagens Docker
- 🔄 Deploy automático via ArgoCD
- 📊 Notificações no Discord
- 🔒 Segurança com GitHub Secrets

## 📋 Workflows

### 1. CI Pipeline (Pull Request)

**Trigger:** PR para `develop` ou `main`  
**Objetivo:** Validar mudanças antes do merge

```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
  pull_request:
    branches: [develop, main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          
      - name: Install pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 8
          
      - name: Install dependencies
        run: pnpm install
        
      - name: Lint
        run: pnpm lint
        
      - name: Format check
        run: pnpm format:check

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          
      - name: Install pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 8
          
      - name: Install dependencies
        run: pnpm install
        
      - name: Run tests
        run: pnpm test
        
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

  build:
    runs-on: ubuntu-latest
    needs: test
    strategy:
      matrix:
        app: [nexo-be, nexo-fe, nexo-auth]
    steps:
      - uses: actions/checkout@v4
      
      - name: Build ${{ matrix.app }}
        run: |
          docker build \
            -t ghcr.io/${{ github.repository_owner }}/${{ matrix.app }}:pr-${{ github.event.pull_request.number }} \
            -f apps/${{ matrix.app }}/Dockerfile \
            .
```

**Etapas:**
1. ✅ Lint (ESLint, Prettier)
2. ✅ Tests (Unit + Integration)
3. ✅ Build (Docker images)
4. ✅ Code coverage
5. ✅ Security scan

### 2. CD Pipeline (Deploy)

**Trigger:** Push para `develop` ou `main`  
**Objetivo:** Build e deploy automático

```yaml
# .github/workflows/cd.yml
name: CD Pipeline

on:
  push:
    branches:
      - develop
      - main

env:
  REGISTRY: ghcr.io
  IMAGE_TAG: ${{ github.ref_name }}-${{ github.sha }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        app: [nexo-be, nexo-fe, nexo-auth]
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ github.repository_owner }}/${{ matrix.app }}
          tags: |
            type=ref,event=branch
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: apps/${{ matrix.app }}/Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  update-manifests:
    runs-on: ubuntu-latest
    needs: build-and-push
    strategy:
      matrix:
        app: [nexo-be, nexo-fe, nexo-auth]
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GH_TOKEN }}

      - name: Update image tag
        run: |
          sed -i "s|tag:.*|tag: ${{ github.ref_name }}-${{ github.sha }}|g" \
            local/helm/${{ matrix.app }}/values-${{ github.ref_name }}.yaml

      - name: Commit and push
        run: |
          git config --global user.name "github-actions[bot]"
          git config --global user.email "github-actions[bot]@users.noreply.github.com"
          git add .
          git commit -m "ci: update ${{ matrix.app }} image to ${{ github.ref_name }}-${{ github.sha }}"
          git push

  notify:
    runs-on: ubuntu-latest
    needs: [build-and-push, update-manifests]
    if: always()
    steps:
      - name: Discord notification
        uses: sarisia/actions-status-discord@v1
        with:
          webhook: ${{ secrets.DISCORD_WEBHOOK }}
          status: ${{ job.status }}
          title: "Deploy ${{ github.ref_name }}"
          description: |
            **Commit:** ${{ github.sha }}
            **Author:** ${{ github.actor }}
            **Message:** ${{ github.event.head_commit.message }}
```

**Etapas:**
1. 🔨 Build de imagens Docker
2. 📦 Push para GHCR
3. 📝 Update de manifests Helm
4. 🔔 Notificação Discord
5. 🚀 ArgoCD detecta mudanças e faz sync

### 3. Release Pipeline

**Trigger:** Tag `v*.*.*`  
**Objetivo:** Release versionado

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate changelog
        id: changelog
        uses: metcalfc/changelog-generator@v4
        with:
          myToken: ${{ secrets.GH_TOKEN }}

      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GH_TOKEN }}
        with:
          tag_name: ${{ github.ref_name }}
          release_name: Release ${{ github.ref_name }}
          body: ${{ steps.changelog.outputs.changelog }}
          draft: false
          prerelease: false

  build-release:
    runs-on: ubuntu-latest
    needs: release
    strategy:
      matrix:
        app: [nexo-be, nexo-fe, nexo-auth]
    steps:
      - uses: actions/checkout@v4

      - name: Build and push release
        uses: docker/build-push-action@v5
        with:
          context: .
          file: apps/${{ matrix.app }}/Dockerfile
          push: true
          tags: |
            ghcr.io/${{ github.repository_owner }}/${{ matrix.app }}:${{ github.ref_name }}
            ghcr.io/${{ github.repository_owner }}/${{ matrix.app }}:latest
```

### 4. Promote Pipeline

**Trigger:** Manual workflow dispatch  
**Objetivo:** Promover entre ambientes

```yaml
# .github/workflows/promote.yml
name: Promote Environment

on:
  workflow_dispatch:
    inputs:
      from:
        description: 'Source environment'
        required: true
        type: choice
        options:
          - develop
          - qa
          - staging
      to:
        description: 'Target environment'
        required: true
        type: choice
        options:
          - qa
          - staging
          - prod

jobs:
  promote:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.GH_TOKEN }}

      - name: Get source image tags
        id: get-tags
        run: |
          BE_TAG=$(yq e '.image.tag' local/helm/nexo-be/values-${{ inputs.from }}.yaml)
          FE_TAG=$(yq e '.image.tag' local/helm/nexo-fe/values-${{ inputs.from }}.yaml)
          AUTH_TAG=$(yq e '.image.tag' local/helm/nexo-auth/values-${{ inputs.from }}.yaml)
          
          echo "be_tag=$BE_TAG" >> $GITHUB_OUTPUT
          echo "fe_tag=$FE_TAG" >> $GITHUB_OUTPUT
          echo "auth_tag=$AUTH_TAG" >> $GITHUB_OUTPUT

      - name: Update target environment
        run: |
          yq e ".image.tag = \"${{ steps.get-tags.outputs.be_tag }}\"" -i \
            local/helm/nexo-be/values-${{ inputs.to }}.yaml
          yq e ".image.tag = \"${{ steps.get-tags.outputs.fe_tag }}\"" -i \
            local/helm/nexo-fe/values-${{ inputs.to }}.yaml
          yq e ".image.tag = \"${{ steps.get-tags.outputs.auth_tag }}\"" -i \
            local/helm/nexo-auth/values-${{ inputs.to }}.yaml

      - name: Commit and push
        run: |
          git config --global user.name "github-actions[bot]"
          git config --global user.email "github-actions[bot]@users.noreply.github.com"
          git add .
          git commit -m "ci: promote from ${{ inputs.from }} to ${{ inputs.to }}"
          git push

      - name: Wait for sync
        run: sleep 30

      - name: Validate deployment
        run: |
          ./scripts/validate-deploy.sh ${{ inputs.to }}

      - name: Notify success
        uses: sarisia/actions-status-discord@v1
        if: success()
        with:
          webhook: ${{ secrets.DISCORD_WEBHOOK }}
          title: "✅ Promote Success"
          description: "Promoted from **${{ inputs.from }}** to **${{ inputs.to }}**"

      - name: Notify failure
        uses: sarisia/actions-status-discord@v1
        if: failure()
        with:
          webhook: ${{ secrets.DISCORD_WEBHOOK }}
          title: "❌ Promote Failed"
          description: "Failed to promote from **${{ inputs.from }}** to **${{ inputs.to }}**"
```

## 🔐 GitHub Secrets

Configurados em: `Settings > Secrets and variables > Actions`

### Secrets

```bash
GHCR_TOKEN          # Token para push de imagens (packages: write)
GH_TOKEN            # Token para commits/PRs (repo, workflow)
DISCORD_WEBHOOK     # Webhook para notificações
```

### Variables

```bash
ARGOCD_SERVER       # ArgoCD server URL
ARGOCD_USERNAME     # ArgoCD username (admin)
ARGOCD_PASSWORD     # ArgoCD password

DOMAIN_DEVELOP      # develop.nexo.local
DOMAIN_QA           # qa.nexo.local
DOMAIN_STAGING      # staging.nexo.local
DOMAIN_PROD         # nexo.com

K8S_NAMESPACE_DEVELOP   # nexo-develop
K8S_NAMESPACE_QA        # nexo-qa
K8S_NAMESPACE_STAGING   # nexo-staging
K8S_NAMESPACE_PROD      # nexo-prod
```

## 📊 Pipeline Flow

### Develop Branch

```
Push develop
    │
    ├─> CI Pipeline (lint, test)
    │   └─> ✅ Pass
    │
    ├─> Build Images
    │   ├─> nexo-be:develop-abc123
    │   ├─> nexo-fe:develop-abc123
    │   └─> nexo-auth:develop-abc123
    │
    ├─> Push to GHCR
    │   └─> ✅ Images pushed
    │
    ├─> Update Helm values
    │   └─> values-develop.yaml (image.tag)
    │
    ├─> Commit changes
    │   └─> git push
    │
    ├─> ArgoCD Auto-Sync
    │   └─> Deploy to nexo-develop
    │
    └─> Discord Notification
        └─> ✅ Deploy successful
```

### Production Release

```
Tag v1.0.0
    │
    ├─> Release Pipeline
    │   └─> Create GitHub Release
    │
    ├─> Build Images
    │   ├─> nexo-be:v1.0.0
    │   ├─> nexo-fe:v1.0.0
    │   └─> nexo-auth:v1.0.0
    │
    ├─> Push to GHCR
    │   └─> Also tag as :latest
    │
    ├─> Manual Promote
    │   ├─> staging → prod
    │   └─> Update values-prod.yaml
    │
    ├─> ArgoCD Sync
    │   └─> Deploy to nexo-prod
    │
    ├─> Validate Deployment
    │   ├─> Health checks
    │   ├─> Smoke tests
    │   └─> Metrics validation
    │
    └─> Discord Notification
        └─> 🎉 Release v1.0.0 deployed
```

## 🧪 Testes no CI

### Unit Tests

```typescript
// apps/nexo-be/src/users/users.service.spec.ts
describe('UsersService', () => {
  it('should create user', async () => {
    const user = await service.create({
      email: 'test@example.com',
      name: 'Test User',
    });
    expect(user.email).toBe('test@example.com');
  });
});
```

### Integration Tests

```typescript
// apps/nexo-be/test/app.e2e-spec.ts
describe('AppController (e2e)', () => {
  it('/health (GET)', () => {
    return request(app.getHttpServer())
      .get('/health')
      .expect(200)
      .expect((res) => {
        expect(res.body.status).toBe('ok');
      });
  });
});
```

### E2E Tests (Playwright)

```typescript
// apps/nexo-fe/tests/login.spec.ts
test('user can login', async ({ page }) => {
  await page.goto('http://nexo.local/login');
  
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'password');
  await page.click('button[type="submit"]');
  
  await expect(page).toHaveURL('http://nexo.local/dashboard');
});
```

## 📦 Docker Build Optimization

### Multi-stage Build

```dockerfile
# apps/nexo-be/Dockerfile
# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable pnpm && pnpm install --frozen-lockfile

# Stage 2: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN corepack enable pnpm && pnpm build

# Stage 3: Production
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3333
CMD ["node", "dist/main.js"]
```

### Build Cache

```yaml
# .github/workflows/cd.yml
- name: Build and push
  uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

## 🔍 Monitoramento do Pipeline

### GitHub Actions UI

```
https://github.com/geraldobl58/nexo/actions
```

**Visualizar:**
- ✅ Status de workflows
- ⏱️ Tempo de execução
- 📝 Logs detalhados
- 📊 Métricas de uso

### Discord Notifications

```
✅ Deploy successful
📦 nexo-be:develop-abc123
👤 @geraldobl58
📝 feat: adiciona endpoint de usuários
🔗 View deployment
```

### ArgoCD UI

```
http://localhost:30080
```

**Monitorar:**
- 🔄 Sync status
- ✅ Health status
- 📊 Resource state
- 📝 Recent events

## 🚨 Troubleshooting

### Build Failed

```bash
# Ver logs
gh run view <run-id>

# Re-run
gh run rerun <run-id>

# Cancelar
gh run cancel <run-id>
```

### Image Push Failed

```bash
# Verificar token GHCR
gh secret list

# Testar localmente
echo $GHCR_TOKEN | docker login ghcr.io -u geraldobl58 --password-stdin
docker push ghcr.io/geraldobl58/nexo-be:test
```

### Sync Stuck

```bash
# Force refresh ArgoCD
kubectl patch application nexo-be-develop -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'

# Restart ArgoCD
kubectl rollout restart deployment argocd-server -n argocd
```

### Promote Failed

```bash
# Verificar health do ambiente destino
./scripts/validate-deploy.sh prod

# Rollback
git revert HEAD
git push
```

## 💡 Boas Práticas

### 1. Fast Feedback

- ⚡ Pipeline < 10 minutos
- ✅ Lint primeiro (fail fast)
- 🧪 Tests em paralelo
- 📊 Cache agressivo

### 2. Segurança

- 🔒 Secrets em GitHub Secrets
- 🔑 Tokens com permissões mínimas
- 🔐 Scan de vulnerabilidades
- 📝 Audit logs

### 3. Reliability

- 🔄 Retry em falhas temporárias
- ⏱️ Timeout em steps
- 📊 Monitoramento de métricas
- 🚨 Alertas em falhas

### 4. Observability

- 📝 Logs estruturados
- 📊 Métricas de pipeline
- 🔍 Tracing de deploys
- 📈 Dashboards de CI/CD

## 📈 Métricas

### Pipeline Metrics

```promql
# Build duration
github_workflow_run_duration_seconds{workflow="CD Pipeline"}

# Success rate
sum(rate(github_workflow_run_conclusion_total{conclusion="success"}[1d]))
/
sum(rate(github_workflow_run_conclusion_total[1d]))

# Deploy frequency
sum(increase(github_workflow_run_conclusion_total{workflow="CD Pipeline",conclusion="success"}[1d]))
```

### DORA Metrics

- **Deployment Frequency:** Múltiplos por dia
- **Lead Time:** < 1 hora (commit → prod)
- **MTTR:** < 1 hora
- **Change Failure Rate:** < 15%

## 🔗 Recursos

- [GitHub Actions Docs](https://docs.github.com/actions)
- [Docker Build Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)

---

[← APIs e Serviços](./06-apis-services.md) | [Voltar](./README.md) | [Próximo: GitOps e ArgoCD →](./08-gitops-argocd.md)
