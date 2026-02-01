# GitHub Actions Workflows - Enterprise CI/CD

## 📋 Visão Geral

Esta seção detalha os workflows GitHub Actions projetados para máxima reutilização, segurança e performance, seguindo padrões de empresas como Spotify (Backstage) e Uber.

## 🏗️ Arquitetura de Workflows

```
┌─────────────────────────────────────────────────────────────────────┐
│                    REUSABLE WORKFLOW PATTERN                         │
├─────────────────────────────────────────────────────────────────────┤
│  Caller Workflow (ci-nexo-be.yml)                                   │
│       │                                                              │
│       ├─► _reusable-ci.yml (jobs: lint, test, build)               │
│       ├─► _reusable-security-scan.yml                              │
│       └─► _reusable-deploy-gitops.yml                              │
└─────────────────────────────────────────────────────────────────────┘
```

## 📁 Estrutura de Diretórios

```
.github/
├── workflows/
│   ├── ci-nexo-be.yml              ← Caller para nexo-be
│   ├── ci-nexo-fe.yml              ← Caller para nexo-fe
│   ├── ci-nexo-auth.yml            ← Caller para nexo-auth
│   ├── promote.yml                 ← Promoção entre ambientes
│   ├── _reusable-ci.yml            ← Core CI logic (DRY)
│   ├── _reusable-security.yml      ← Security scanning
│   └── _reusable-gitops-update.yml ← Update GitOps repo
├── actions/
│   ├── setup-node/action.yml       ← Custom composite action
│   └── docker-build/action.yml
└── CODEOWNERS                       ← Aprovações de PR
```

## 🔧 Reusable Workflow: Core CI

**Arquivo**: `.github/workflows/_reusable-ci.yml`

```yaml
name: Reusable CI Workflow

on:
  workflow_call:
    inputs:
      service-name:
        required: true
        type: string
        description: "Nome do serviço (nexo-be, nexo-fe, nexo-auth)"
      working-directory:
        required: true
        type: string
        description: "Diretório do serviço (apps/nexo-be)"
      node-version:
        required: false
        type: string
        default: "20"
      runs-integration-tests:
        required: false
        type: boolean
        default: false
      dockerfile-path:
        required: false
        type: string
        default: "Dockerfile"
    outputs:
      version:
        description: "Versão gerada (CalVer)"
        value: ${{ jobs.version.outputs.version }}
      image-tag:
        description: "Tag completa da imagem Docker"
        value: ${{ jobs.build.outputs.image-tag }}
    secrets:
      GITHUB_TOKEN:
        required: true
      REGISTRY_URL:
        required: false
      SONAR_TOKEN:
        required: false

# Otimização: Cancel in-progress runs da mesma branch
concurrency:
  group: ci-${{ inputs.service-name }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # JOB 1: Versionamento CalVer
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  version:
    name: Generate Version
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.generate.outputs.version }}
      short-sha: ${{ steps.generate.outputs.short-sha }}
    steps:
      - name: Generate CalVer version
        id: generate
        run: |
          # CalVer: YYYY.MM.BUILD
          BUILD_NUMBER=${{ github.run_number }}
          VERSION=$(date +'%Y.%m.')${BUILD_NUMBER}
          SHORT_SHA=$(echo ${{ github.sha }} | cut -c1-7)

          echo "version=${VERSION}" >> $GITHUB_OUTPUT
          echo "short-sha=${SHORT_SHA}" >> $GITHUB_OUTPUT

          echo "📦 Version: ${VERSION}"
          echo "🔖 Short SHA: ${SHORT_SHA}"

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # JOB 2: Lint & Format Check
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  lint:
    name: Lint & Format
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ inputs.working-directory }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0 # Para blame history

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: "pnpm"
          cache-dependency-path: ${{ inputs.working-directory }}/pnpm-lock.yaml

      - name: Install pnpm
        run: npm install -g pnpm

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Run ESLint
        run: pnpm lint
        continue-on-error: false

      - name: Check code formatting (Prettier)
        run: pnpm format:check
        if: always()

      - name: Type checking (TypeScript)
        run: pnpm type-check
        if: always()

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # JOB 3: Unit Tests
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  test-unit:
    name: Unit Tests
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ inputs.working-directory }}
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: "pnpm"

      - run: npm install -g pnpm
      - run: pnpm install --frozen-lockfile

      - name: Run unit tests
        run: pnpm test:cov
        env:
          NODE_ENV: test

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: ${{ inputs.working-directory }}/coverage/lcov.info
          flags: ${{ inputs.service-name }}
          name: ${{ inputs.service-name }}-coverage
          fail_ci_if_error: false

      - name: SonarCloud Scan
        if: secrets.SONAR_TOKEN != ''
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        with:
          projectBaseDir: ${{ inputs.working-directory }}
          args: >
            -Dsonar.organization=nexo
            -Dsonar.projectKey=nexo-${{ inputs.service-name }}
            -Dsonar.sources=src
            -Dsonar.tests=test
            -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # JOB 4: Integration Tests (opcional)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  test-integration:
    name: Integration Tests
    runs-on: ubuntu-latest
    if: ${{ inputs.runs-integration-tests }}
    defaults:
      run:
        working-directory: ${{ inputs.working-directory }}
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: nexo_test
          POSTGRES_PASSWORD: nexo_test
          POSTGRES_DB: nexo_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: "pnpm"

      - run: npm install -g pnpm
      - run: pnpm install --frozen-lockfile

      - name: Run Prisma migrations
        run: pnpm prisma migrate deploy
        env:
          DATABASE_URL: postgresql://nexo_test:nexo_test@localhost:5432/nexo_test

      - name: Run integration tests
        run: pnpm test:e2e
        env:
          NODE_ENV: test
          DATABASE_URL: postgresql://nexo_test:nexo_test@localhost:5432/nexo_test
          REDIS_URL: redis://localhost:6379

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # JOB 5: Security Scanning
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  security:
    name: Security Scan
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ inputs.working-directory }}
    steps:
      - uses: actions/checkout@v4

      # SAST: Semgrep (alternativa open-source)
      - name: Run Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/secrets
            p/owasp-top-ten

      # Dependency Check
      - name: Audit npm dependencies
        run: pnpm audit --audit-level=high
        continue-on-error: true

      # Snyk (se configurado)
      - name: Run Snyk to check for vulnerabilities
        uses: snyk/actions/node@master
        continue-on-error: true
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high --file=${{ inputs.working-directory }}/package.json

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # JOB 6: Build Docker Image
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  build:
    name: Build & Push Image
    runs-on: ubuntu-latest
    needs: [version, lint, test-unit, security]
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
    permissions:
      contents: read
      packages: write
      id-token: write # Para OIDC
    steps:
      - uses: actions/checkout@v4

      # Setup Docker Buildx (multi-arch support)
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      # Login no GitHub Container Registry
      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # Extrai metadata (tags, labels)
      - name: Docker metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository_owner }}/${{ inputs.service-name }}
          tags: |
            type=raw,value=${{ needs.version.outputs.version }}
            type=raw,value=${{ needs.version.outputs.version }}-${{ needs.version.outputs.short-sha }}
            type=raw,value=sha-${{ needs.version.outputs.short-sha }}
            type=ref,event=pr,prefix=pr-
            type=raw,value=develop,enable=${{ github.ref == 'refs/heads/main' }}
          labels: |
            org.opencontainers.image.title=${{ inputs.service-name }}
            org.opencontainers.image.version=${{ needs.version.outputs.version }}
            org.opencontainers.image.revision=${{ github.sha }}

      # Build e Push (com cache)
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: ${{ inputs.working-directory }}
          file: ${{ inputs.working-directory }}/${{ inputs.dockerfile-path }}
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          build-args: |
            VERSION=${{ needs.version.outputs.version }}
            COMMIT_SHA=${{ github.sha }}
            BUILD_DATE=${{ github.event.head_commit.timestamp }}

      # Image Scanning (Trivy)
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ghcr.io/${{ github.repository_owner }}/${{ inputs.service-name }}:${{ needs.version.outputs.version }}
          format: "sarif"
          output: "trivy-results.sarif"
          severity: "CRITICAL,HIGH"

      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: "trivy-results.sarif"

      # SBOM Generation (SLSA provenance)
      - name: Generate SBOM
        uses: anchore/sbom-action@v0
        with:
          image: ghcr.io/${{ github.repository_owner }}/${{ inputs.service-name }}:${{ needs.version.outputs.version }}
          format: spdx-json
          output-file: sbom.spdx.json

      - name: Upload SBOM
        uses: actions/upload-artifact@v4
        with:
          name: sbom-${{ inputs.service-name }}
          path: sbom.spdx.json

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # JOB 7: Update GitOps Repo
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  update-gitops:
    name: Update GitOps Repo
    runs-on: ubuntu-latest
    needs: [version, build]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - name: Checkout GitOps repo
        uses: actions/checkout@v4
        with:
          repository: ${{ github.repository_owner }}/nexo-gitops
          token: ${{ secrets.GITOPS_PAT }}
          path: gitops

      - name: Update image tag in develop
        working-directory: gitops
        run: |
          VERSION="${{ needs.version.outputs.version }}"
          SERVICE="${{ inputs.service-name }}"

          # Atualiza values-develop.yaml
          yq eval ".image.tag = \"${VERSION}\"" -i helm/${SERVICE}/values-develop.yaml

          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add helm/${SERVICE}/values-develop.yaml
          git commit -m "chore(${SERVICE}): update develop to ${VERSION}"
          git push origin main

      - name: Notify ArgoCD (opcional)
        run: |
          # Trigger manual sync via ArgoCD API
          curl -X POST \
            -H "Authorization: Bearer ${{ secrets.ARGOCD_TOKEN }}" \
            https://argocd.example.com/api/v1/applications/${SERVICE}-develop/sync
```

---

## 📞 Caller Workflow: nexo-be

**Arquivo**: `.github/workflows/ci-nexo-be.yml`

```yaml
name: CI - nexo-be

on:
  push:
    branches: [main]
    paths:
      - "apps/nexo-be/**"
      - ".github/workflows/ci-nexo-be.yml"
      - ".github/workflows/_reusable-ci.yml"
  pull_request:
    branches: [main]
    paths:
      - "apps/nexo-be/**"

jobs:
  ci:
    name: Build & Test
    uses: ./.github/workflows/_reusable-ci.yml
    with:
      service-name: nexo-be
      working-directory: apps/nexo-be
      node-version: "20"
      runs-integration-tests: true
      dockerfile-path: Dockerfile
    secrets: inherit
```

---

## 🔄 Promotion Workflow

**Arquivo**: `.github/workflows/promote.yml`

```yaml
name: Promote Service

on:
  workflow_dispatch:
    inputs:
      service:
        description: "Service name (nexo-be, nexo-fe, nexo-auth)"
        required: true
        type: choice
        options:
          - nexo-be
          - nexo-fe
          - nexo-auth
      version:
        description: "Version to promote (e.g., 2026.02.1)"
        required: true
        type: string
      from-env:
        description: "Source environment"
        required: true
        type: choice
        options:
          - develop
          - qa
          - staging
      to-env:
        description: "Target environment"
        required: true
        type: choice
        options:
          - qa
          - staging
          - production

jobs:
  validate:
    name: Validate Promotion
    runs-on: ubuntu-latest
    steps:
      - name: Validate environment progression
        run: |
          FROM="${{ inputs.from-env }}"
          TO="${{ inputs.to-env }}"

          # Regras de promoção
          if [[ "$FROM" == "develop" && "$TO" != "qa" ]]; then
            echo "❌ develop só pode promover para qa"
            exit 1
          fi

          if [[ "$FROM" == "qa" && "$TO" != "staging" ]]; then
            echo "❌ qa só pode promover para staging"
            exit 1
          fi

          if [[ "$FROM" == "staging" && "$TO" != "production" ]]; then
            echo "❌ staging só pode promover para production"
            exit 1
          fi

          echo "✅ Promoção válida: $FROM → $TO"

      - name: Check version exists in source environment
        run: |
          # Verifica se a versão existe no ambiente de origem
          echo "🔍 Verificando se versão ${{ inputs.version }} existe em ${{ inputs.from-env }}"
          # TODO: Implementar checagem real via ArgoCD API ou GitOps repo

  promote:
    name: Promote to ${{ inputs.to-env }}
    runs-on: ubuntu-latest
    needs: validate
    environment:
      name: ${{ inputs.to-env }}
      url: https://${{ inputs.service }}-${{ inputs.to-env }}.example.com
    steps:
      - name: Checkout GitOps repo
        uses: actions/checkout@v4
        with:
          repository: ${{ github.repository_owner }}/nexo-gitops
          token: ${{ secrets.GITOPS_PAT }}

      - name: Update target environment
        run: |
          SERVICE="${{ inputs.service }}"
          VERSION="${{ inputs.version }}"
          TARGET_ENV="${{ inputs.to-env }}"

          # Atualiza values file do ambiente alvo
          yq eval ".image.tag = \"${VERSION}\"" -i helm/${SERVICE}/values-${TARGET_ENV}.yaml

          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add helm/${SERVICE}/values-${TARGET_ENV}.yaml
          git commit -m "promote(${SERVICE}): ${TARGET_ENV} → ${VERSION}

          Promoted from: ${{ inputs.from-env }}
          Triggered by: @${{ github.actor }}"
          git push origin main

      - name: Create audit log
        run: |
          echo "📊 Deployment Audit Log"
          echo "Service: ${{ inputs.service }}"
          echo "Version: ${{ inputs.version }}"
          echo "Environment: ${{ inputs.to-env }}"
          echo "Promoted from: ${{ inputs.from-env }}"
          echo "Triggered by: ${{ github.actor }}"
          echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "🚀 Deployment: ${{ inputs.service }} → ${{ inputs.to-env }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Deployment*\n*Service:* ${{ inputs.service }}\n*Version:* ${{ inputs.version }}\n*Environment:* ${{ inputs.to-env }}\n*By:* @${{ github.actor }}"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 🔑 Secrets Necessários

| Secret          | Descrição                              | Escopo          |
| --------------- | -------------------------------------- | --------------- |
| `GITHUB_TOKEN`  | Auto-provisionado pelo GitHub          | Repo            |
| `GITOPS_PAT`    | Personal Access Token para nexo-gitops | Repo            |
| `ARGOCD_TOKEN`  | Token de autenticação ArgoCD           | Environment     |
| `SONAR_TOKEN`   | SonarCloud authentication              | Repo            |
| `SNYK_TOKEN`    | Snyk API token                         | Repo (opcional) |
| `SLACK_WEBHOOK` | Webhook para notificações              | Repo            |

---

## 🎯 GitHub Environments

Configurar em: **Settings → Environments**

### develop

- ✅ Auto-deployment
- ❌ Required reviewers: 0
- ⏱️ Wait timer: 0

### qa

- ✅ Auto-deployment
- ❌ Required reviewers: 0
- ⏱️ Wait timer: 0

### staging

- ⚠️ Manual deployment
- ✅ Required reviewers: 1 (Platform team)
- ⏱️ Wait timer: 0

### production

- ⚠️ Manual deployment
- ✅ Required reviewers: 2 (SRE + Platform lead)
- ⏱️ Wait timer: 30min (soak time)
- 🔒 Deployment branches: `main` only

---

## 📊 Workflow Insights & Métricas

### Dashboards Recomendados

```yaml
# Métricas a monitorar
- Deployment frequency (DORA)
- Lead time for changes
- Mean time to recovery (MTTR)
- Change failure rate
- CI duration (p50, p95, p99)
- Flaky test rate
```

### Otimizações Implementadas

1. **Cache estratégico**: pnpm cache, Docker layer cache
2. **Paralelização**: Testes unitários + lint + security em paralelo
3. **Early exit**: Linting falha rápido, economiza minutos CI
4. **Conditional jobs**: Integration tests apenas quando necessário
5. **Concurrency groups**: Cancela builds antigos da mesma branch

---

## 🚨 Troubleshooting

### Build Lento

```yaml
# Adicionar cache para pnpm
- uses: pnpm/action-setup@v2
  with:
    version: 8
- uses: actions/setup-node@v4
  with:
    cache: "pnpm"
```

### Testes Flaky

```yaml
# Retry automático
- name: Run tests
  uses: nick-fields/retry@v2
  with:
    timeout_minutes: 10
    max_attempts: 3
    command: pnpm test
```

### DockerHub Rate Limit

```yaml
# Usar GitHub Container Registry (GHCR)
# Ou autenticar no DockerHub
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```

---

**Próximo**: [ArgoCD Configuration](02-argocd-configuration.md)
