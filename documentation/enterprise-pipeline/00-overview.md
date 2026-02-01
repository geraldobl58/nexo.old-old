# Enterprise CI/CD Pipeline - Nexo Platform

## 📋 Executive Summary

Esta documentação descreve uma pipeline de deploy enterprise-grade para a plataforma Nexo, projetada seguindo as práticas de empresas como Netflix, Spotify e Uber. A arquitetura prioriza:

- **Confiabilidade**: Zero-downtime deployments, rollback automático, health checks
- **Segurança**: Zero secrets em repositório, OIDC, least privilege
- **Escalabilidade**: Suporte para dezenas de serviços, multi-tenant
- **Observabilidade**: Auditoria completa, métricas, logs estruturados
- **Velocidade**: Deploy contínuo em develop, aprovações manuais em produção

## 🏗️ Arquitetura de Alto Nível

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DEVELOPER WORKFLOW                           │
├─────────────────────────────────────────────────────────────────────┤
│  Feature Branch ──► PR ──► Code Review ──► Merge to main/develop   │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      GITHUB ACTIONS (CI)                             │
├─────────────────────────────────────────────────────────────────────┤
│  1. Lint & Format Check                                              │
│  2. Unit Tests                                                       │
│  3. Integration Tests                                                │
│  4. Security Scan (SAST, Dependency Check)                          │
│  5. Build Docker Image                                               │
│  6. Scan Image (Trivy/Grype)                                        │
│  7. Tag & Push to Registry                                           │
│  8. Update GitOps Repo (Image Tag)                                  │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      GITOPS REPOSITORY                               │
├─────────────────────────────────────────────────────────────────────┤
│  helm/                                                               │
│  ├── nexo-be/values-{env}.yaml    ← Image tags por ambiente         │
│  ├── nexo-fe/values-{env}.yaml                                      │
│  └── nexo-auth/values-{env}.yaml                                    │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      ARGOCD (CD)                                     │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │  DEVELOP    │  │     QA      │  │   STAGING   │  │ PRODUCTION │ │
│  │ Auto-Sync   │  │ Auto-Sync   │  │ Manual Sync │  │Manual+Apprv│ │
│  │ 5min poll   │  │ 10min poll  │  │ On-Demand   │  │  + Checks  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      KUBERNETES CLUSTERS                             │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │   DEV       │  │     QA      │  │   STAGING   │  │    PROD    │ │
│  │  k8s-dev    │  │   k8s-qa    │  │  k8s-stg    │  │  k8s-prod  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## 🌲 Estratégia de Branches: Trunk-Based Development

### Decisão: Trunk-Based + Release Branches

**Escolha**: Trunk-Based Development (TBD) com release branches para produção

**Justificativa**:

1. **Velocidade**: Netflix e Spotify usam TBD para permitir múltiplos deploys/dia
2. **Redução de merge conflicts**: PRs pequenos e frequentes
3. **Feature flags**: Funcionalidades incompletas ficam desabilitadas, não em branches
4. **Hotfix rápido**: Fix no main, cherry-pick para release branch se necessário

**Alternativa descartada**: GitFlow

- ❌ Complexidade desnecessária para CD
- ❌ Branches de longa duração geram conflitos
- ❌ Release branches permanentes atrasam entrega
- ✅ Útil apenas para software on-premise com múltiplas versões ativas

### Mapeamento Branch → Ambiente

```
┌────────────────┐
│  feature/*     │  ← Desenvolvimento local + CI checks
└────────────────┘
        │
        ▼ (PR + Review)
┌────────────────┐
│     main       │  ← Fonte da verdade, sempre deployable
└────────────────┘
        │
        ├─────────────► DEVELOP  (auto-deploy)
        │
        └─────────────► QA       (auto-deploy após develop OK)
                │
                └─────► STAGING  (manual promotion)
                        │
                        └───────► PRODUCTION (manual + approval)
```

### Fluxo de Código

```bash
# 1. Developer cria feature branch
git checkout -b feature/add-payment-method

# 2. Commits pequenos, CI roda em cada push
git push origin feature/add-payment-method

# 3. Abre PR, aguarda aprovação (CODEOWNERS, testes passam)
# 4. Merge para main (squash ou rebase)
# 5. CI roda novamente, gera nova imagem: v1.2.3
# 6. GitHub Actions atualiza values-develop.yaml com v1.2.3
# 7. ArgoCD detecta mudança, sincroniza com develop
# 8. Após validação, promoção manual para QA (mesma imagem v1.2.3)
# 9. Staging e Prod seguem processo de promoção com aprovações
```

## 🏷️ Versionamento Semântico

### Estratégia: CalVer + Build Number (Estilo Spotify)

```
YYYY.MM.BUILD[-COMMIT]

Exemplos:
- 2026.02.1                    ← Primeiro build de fevereiro
- 2026.02.1-a3f2b1c           ← Com commit SHA
- 2026.02.15-hotfix-auth      ← Hotfix identificado
```

**Justificativa**:

- ✅ Timestamp natural facilita troubleshooting
- ✅ Build incremental evita conflitos
- ✅ Commit SHA garante rastreabilidade
- ✅ Suporta hotfix sem quebrar ordem

### Tags Docker

```yaml
# Cada imagem tem múltiplas tags
ghcr.io/org/nexo-be:2026.02.1
ghcr.io/org/nexo-be:2026.02.1-a3f2b1c
ghcr.io/org/nexo-be:develop            # Ambiente-specific
ghcr.io/org/nexo-be:sha-a3f2b1c        # Para debug
ghcr.io/org/nexo-be:pr-123             # Para preview environments
```

## 🔄 Estratégia de Promoção Entre Ambientes

### Filosofia: "Promote Artifacts, Not Code"

```
┌─────────────────────────────────────────────────────────────────────┐
│                     IMAGE IMMUTABILITY                               │
├─────────────────────────────────────────────────────────────────────┤
│  A mesma imagem Docker é promovida entre ambientes                  │
│  Apenas configurações (Helm values) mudam                           │
│  Garante: "Se funciona em staging, funcionará em prod"              │
└─────────────────────────────────────────────────────────────────────┘
```

### Promoção Automática vs Manual

| Ambiente    | Trigger      | Aprovação | Rollback | Sync Policy  |
| ----------- | ------------ | --------- | -------- | ------------ |
| **develop** | Push to main | ❌ Auto   | Auto     | Auto (5min)  |
| **qa**      | Develop OK   | ❌ Auto   | Auto     | Auto (10min) |
| **staging** | Manual       | ✅ Yes    | Manual   | Manual Sync  |
| **prod**    | Manual       | ✅✅ Yes  | Manual   | Manual Sync  |

### Processo de Promoção

```bash
# Promoção develop → qa (automatizada via GHA)
gh workflow run promote.yml \
  -f environment=qa \
  -f service=nexo-be \
  -f version=2026.02.1

# Promoção staging → production (requer aprovação)
# 1. Abrir PR no GitOps repo
# 2. Update values-prod.yaml com versão validada
# 3. Aguardar aprovação de 2+ aprovadores (CODEOWNERS)
# 4. Merge PR
# 5. Engenheiro executa sync manual no ArgoCD UI/CLI
# 6. Monitoramento ativo por 30min
```

## 📦 Estrutura de Repositórios

### Padrão: Monorepo + Separate GitOps Repo

```
nexo/                                    ← Application Code (este repo)
├── apps/
│   ├── nexo-be/
│   ├── nexo-fe/
│   └── nexo-auth/
├── .github/
│   └── workflows/
│       ├── ci-nexo-be.yml
│       ├── ci-nexo-fe.yml
│       ├── ci-nexo-auth.yml
│       ├── promote.yml
│       └── _reusable-ci.yml         ← DRY workflows
└── ...

nexo-gitops/                             ← GitOps Repo (separado)
├── helm/
│   ├── nexo-be/
│   │   ├── Chart.yaml
│   │   ├── values.yaml              ← Defaults
│   │   ├── values-develop.yaml      ← Env-specific
│   │   ├── values-qa.yaml
│   │   ├── values-staging.yaml
│   │   └── values-prod.yaml
│   ├── nexo-fe/...
│   └── nexo-auth/...
├── argocd/
│   ├── projects/
│   │   └── nexo.yaml
│   └── applicationsets/
│       └── nexo-apps.yaml
└── README.md
```

**Por que separar GitOps?**

1. ✅ **Segurança**: Permissões granulares (CI só escreve tags, não código)
2. ✅ **Auditoria**: Histórico de deploys isolado
3. ✅ **Blast radius**: Mudanças de infra não afetam código
4. ✅ **Padrão Netflix/Uber**: Separação clara de responsabilidades

## 🔐 Segurança Enterprise

### Princípios

1. **Zero Secrets em Git**: External Secrets Operator + AWS Secrets Manager/Vault
2. **OIDC**: GitHub Actions → AWS/GCP sem access keys
3. **Least Privilege**: RBAC granular no ArgoCD e K8s
4. **Immutable Artifacts**: Images são read-only após build
5. **Provenance**: SLSA attestation, SBOM gerado

### Exemplo de Autenticação OIDC

```yaml
# GitHub Actions → AWS
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
    aws-region: us-east-1
    # Sem AWS_ACCESS_KEY_ID hardcoded ✅
```

## 📊 Observabilidade

### Três Pilares

1. **Logs**: Structured logging (JSON), Loki/CloudWatch
2. **Metrics**: Prometheus, custom application metrics
3. **Traces**: OpenTelemetry, Jaeger

### Auditoria de Deploy

```json
{
  "event": "deployment",
  "service": "nexo-be",
  "version": "2026.02.1",
  "environment": "production",
  "initiator": "alice@company.com",
  "approval_by": ["bob@company.com", "charlie@company.com"],
  "timestamp": "2026-02-01T10:30:00Z",
  "argocd_sync_id": "abc123",
  "rollback": false
}
```

## ⚙️ Health Checks & Rollback

### Critérios de Saúde

```yaml
# ArgoCD Health Assessment
health:
  - deployment.status.availableReplicas >= deployment.spec.replicas
  - pod.status.phase == "Running"
  - readinessProbe success > 90%
  - no crashloop in last 10min
  - custom metric: error_rate < 1%
```

### Rollback Automático

```yaml
# ArgoCD Sync Policy
automated:
  prune: true
  selfHeal: true # Reverte mudanças manuais
  allowEmpty: false

rollback:
  onFailure: true # Rollback se health check falhar
  timeout: 5m
  healthCheckPeriod: 30s
```

## 🎯 Deployment Strategies

| Ambiente   | Strategy      | Justificativa                         |
| ---------- | ------------- | ------------------------------------- |
| develop    | RollingUpdate | Rápido, downtime aceitável            |
| qa         | RollingUpdate | Validação rápida                      |
| staging    | Blue/Green    | Validação smoke tests antes de switch |
| production | Blue/Green    | Zero-downtime, rollback instantâneo   |

## 🚦 Approval Gates

### Produção: Multi-Stage Approval

```yaml
# GitHub Environment Protection Rules
production:
  required_reviewers: 2
  reviewers:
    - platform-team
    - sre-team
  wait_timer: 30 # 30min soak time após staging
  deployment_branches:
    - main
```

## 📋 Próximos Documentos

1. [GitHub Actions Workflows](01-github-actions-workflows.md)
2. [ArgoCD Configuration](02-argocd-configuration.md)
3. [Versioning & Promotion](03-versioning-promotion.md)
4. [Security & Secrets](04-security-secrets.md)
5. [Observability](05-observability.md)
6. [Production Checklist](06-production-checklist.md)

---

**Revisado por**: Staff Platform Engineering Team  
**Última atualização**: 2026-02-01  
**Versão**: 1.0.0
