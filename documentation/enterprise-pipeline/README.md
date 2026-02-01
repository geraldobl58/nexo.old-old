# Enterprise CI/CD Pipeline - Nexo Platform

> **Documentação completa de uma pipeline enterprise-grade seguindo práticas de Netflix, Spotify e Uber**

## 🎯 Visão Geral

Esta documentação descreve uma pipeline de deploy profissional, end-to-end, para a plataforma Nexo, contemplando:

- ✅ **CI/CD completo**: GitHub Actions + ArgoCD (GitOps)
- ✅ **Múltiplos ambientes**: develop, qa, staging, production
- ✅ **Segurança enterprise**: Zero secrets em Git, OIDC, RBAC, image signing
- ✅ **Observabilidade completa**: Logs, métricas, tracing, auditoria
- ✅ **Deployment strategies**: Rolling, Blue/Green, Canary
- ✅ **Promoção controlada**: Auto-promotion (dev/qa), manual (staging/prod)

## 🎯 Integração com K3D

> **⚠️ IMPORTANTE**: Este projeto usa **K3D** como ambiente local que espelha produção.
>
> 👉 **Comece aqui**: [00-k3d-integration.md](00-k3d-integration.md) para entender como a pipeline enterprise se integra com a infraestrutura K3D existente.

**Infraestrutura local**: `/local` (Helm charts, ArgoCD, K3D configs, scripts)  
**Docs operacionais**: `/documentation/local` (Quick start, troubleshooting, CI/CD)

---

## 📚 Índice de Documentação

### 🏗️ Integração & Setup

0. **[Integração K3D](00-k3d-integration.md)** (📍 **COMECE AQUI** - Específico para este projeto)
   - Como a pipeline enterprise funciona com K3D
   - Diferenças entre cloud e local
   - Estratégia de versionamento adaptada
   - Migração futura para cloud

### 📖 Documentos Principais

1. **[Overview & Arquitetura](00-overview.md)** (Arquitetura geral enterprise)
   - Visão geral da arquitetura
   - Estratégia de branches (Trunk-Based Development)
   - Versionamento CalVer
   - Fluxo de deploy end-to-end
   - Princípios e decisões técnicas

2. **[GitHub Actions Workflows](01-github-actions-workflows.md)**
   - Reusable workflows (DRY)
   - CI completo (lint, test, build, scan)
   - Versionamento automático
   - Security scanning (SAST, dependency, container)
   - Image building e push
   - GitOps repo update

3. **[ArgoCD Configuration](02-argocd-configuration.md)**
   - AppProject e ApplicationSets
   - Sync policies por ambiente
   - Health checks customizados
   - Rollback automático
   - RBAC e permissões
   - Notifications e alerting

4. **[Versioning & Promotion](03-versioning-promotion.md)**
   - CalVer vs SemVer (justificativa)
   - Estratégia de tags Docker
   - Promoção de artefatos imutáveis
   - Auto-promotion (develop → qa)
   - Manual promotion (staging → prod)
   - Auditoria de deploys

5. **[Security & Secrets](04-security-secrets.md)**
   - External Secrets Operator
   - OIDC (GitHub → AWS/GCP)
   - RBAC (Kubernetes + ArgoCD)
   - Image signing (Cosign)
   - SBOM e vulnerability scanning
   - Network policies
   - Secrets rotation

6. **[Observability & Governance](05-observability.md)**
   - Prometheus + Grafana (métricas)
   - Loki + Promtail (logs estruturados)
   - OpenTelemetry + Jaeger (tracing)
   - Auditoria de deploys
   - DORA metrics
   - Incident management
   - Runbooks

7. **[Production Checklist](06-production-checklist.md)** (✅ ANTES DE GO-LIVE)
   - Checklist completo de validações
   - Common pitfalls a evitar
   - Success metrics (DORA)
   - Disaster recovery
   - Team readiness
   - Sign-off process

### 📋 Recursos Adicionais

- **[Executive Summary](EXECUTIVE-SUMMARY.md)** - Visão executiva para stakeholders, ROI analysis
- **[Implementation Roadmap](IMPLEMENTATION-ROADMAP.md)** - Plano de implementação de 9 semanas com fases e marcos
- **[Diagrams](diagrams.md)** - Diagramas visuais de fluxo (commit → production, observability stack)
- **[Playbook](playbook.md)** - Cenários práticos e comandos operacionais

### 📚 Documentação Operacional Existente

Em `/documentation/local` - Setup e operação do K3D:

- **[Quick Start](../local/01-quick-start.md)** - Setup K3D em 5 minutos
- **[Arquitetura](../local/02-architecture.md)** - Visão técnica do sistema
- **[Ambientes](../local/03-environment.md)** - Setup Kubernetes local
- **[GitHub Setup](../local/04-github-setup.md)** - Secrets, Variables e Environments
- **[CI/CD Pipeline](../local/05-cicd.md)** - GitHub Actions + ArgoCD (implementação atual)
- **[Git Workflow](../local/06-git-workflow.md)** - Branches e fluxo de trabalho
- **[Desenvolvimento](../local/07-development.md)** - Guia do dia a dia
- **[Observabilidade](../local/09-observability.md)** - Métricas, Logs e Alertas (K3D)
- **[Troubleshooting](../local/10-troubleshooting.md)** - Solução de problemas K3D

## 🚀 Quick Start

### 🎯 Para Começar AGORA (K3D Local)

```bash
# 1. Setup cluster K3D (5 minutos)
cd /Users/geraldoluiz/Development/fullstack/nexo/local
./scripts/setup.sh

# 2. Configurar /etc/hosts
sudo tee -a /etc/hosts <<EOF
127.0.0.1 develop.nexo.local develop.api.nexo.local develop.auth.nexo.local
127.0.0.1 qa.nexo.local qa.api.nexo.local qa.auth.nexo.local
127.0.0.1 staging.nexo.local staging.api.nexo.local staging.auth.nexo.local
127.0.0.1 prod.nexo.local prod.api.nexo.local prod.auth.nexo.local
EOF

# 3. Verificar status
cd local && ./scripts/status.sh

# 4. Acessar serviços
open http://develop.nexo.local           # Frontend
open http://develop.api.nexo.local       # Backend API
open http://localhost:30080              # ArgoCD
open http://localhost:30030              # Grafana
```

**Próximos passos**: Leia [00-k3d-integration.md](00-k3d-integration.md) para entender a integração.

### Para Desenvolvedores

```bash
# 1. Clone o repo
git clone https://github.com/nexo-org/nexo.git
cd nexo

# 2. Crie uma feature branch
git checkout -b feature/minha-feature

# 3. Faça suas mudanças e commit
git add .
git commit -m "feat(nexo-be): adiciona endpoint de pagamentos"

# 4. Push e abra PR
git push origin feature/minha-feature
gh pr create

# 5. Após merge para main:
#    - CI roda automaticamente
#    - Imagem é buildada e tagged (ex: 2026.02.1)
#    - GitOps repo é atualizado
#    - ArgoCD deploya em develop automaticamente
```

### Para Platform Engineers

```bash
# Promover de staging → production
cd nexo-gitops
git checkout -b promote/nexo-be-prod-2026.02.1

# Atualizar version
yq eval '.image.tag = "2026.02.1"' -i helm/nexo-be/values-prod.yaml

# Commit e PR
git add helm/nexo-be/values-prod.yaml
git commit -m "promote(nexo-be): production → 2026.02.1"
gh pr create --reviewer @nexo-sre-team

# Após aprovação e merge, sync manual no ArgoCD
argocd app sync nexo-be-production
```

## 🏗️ Arquitetura de Alto Nível

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CODE REPOSITORY                              │
│                       github.com/nexo/nexo                           │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                    Push to main   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      GITHUB ACTIONS (CI)                             │
│  • Lint & Test                                                       │
│  • Security Scan                                                     │
│  • Build Docker Image                                                │
│  • Tag: 2026.02.1, 2026.02.1-a3f2b1c, develop                       │
│  • Push to GHCR                                                      │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                    Update tag     │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      GITOPS REPOSITORY                               │
│                    github.com/nexo/nexo-gitops                       │
│  helm/nexo-be/values-develop.yaml  ← image.tag: "2026.02.1"         │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                    Pull changes   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         ARGOCD (CD)                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │ DEVELOP  │  │    QA    │  │ STAGING  │  │   PROD   │            │
│  │ Auto-Sync│  │Auto-Sync │  │  Manual  │  │  Manual  │            │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘            │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                    Apply manifests│
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      KUBERNETES CLUSTERS                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │   DEV    │  │    QA    │  │ STAGING  │  │   PROD   │            │
│  │ Namespace│  │Namespace │  │Namespace │  │Namespace │            │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘            │
└─────────────────────────────────────────────────────────────────────┘
```

## 🎓 Decisões Técnicas Principais

### Por que Trunk-Based Development?

- ✅ **Velocidade**: Múltiplos deploys/dia (Netflix faz 1000+/dia)
- ✅ **Simplicidade**: Menos branches = menos merge conflicts
- ✅ **CI/CD friendly**: Feature flags > long-lived branches
- ❌ GitFlow: Complexo demais para CD moderno

### Por que CalVer ao invés de SemVer?

- ✅ **Rastreabilidade temporal**: "Quando deployamos isso?" → "Em fevereiro/2026"
- ✅ **Múltiplos serviços**: Todos sincronizados temporalmente
- ✅ **Troubleshooting**: Timestamp natural facilita correlação
- ❌ SemVer: Melhor para bibliotecas públicas, não para SaaS interno

### Por que Helm ao invés de Kustomize?

- ✅ **Templating avançado**: Lógica condicional, loops, funções
- ✅ **DRY**: values-{env}.yaml compartilham base template
- ✅ **Ecosystem**: Ampla adoção, charts de terceiros
- ❌ Kustomize: Patches simples, sem lógica complexa

### Por que repositório GitOps separado?

- ✅ **Segurança**: Permissões granulares (CI escreve tags, não código)
- ✅ **Auditoria**: Histórico de deploys isolado
- ✅ **Blast radius**: Mudanças de infra não afetam código
- ✅ **Padrão Netflix/Uber**: Separação clara de responsabilidades

## 📊 Métricas de Sucesso (DORA)

| Métrica                     | Target  | Elite Performers |
| --------------------------- | ------- | ---------------- |
| **Deployment Frequency**    | > 1/dia | Múltiplos/dia    |
| **Lead Time for Changes**   | < 1h    | < 1h             |
| **Time to Restore Service** | < 1h    | < 1h             |
| **Change Failure Rate**     | < 5%    | < 5%             |

## 🛡️ Princípios de Segurança

1. **Zero Secrets in Git**: External Secrets Operator + AWS Secrets Manager/Vault
2. **Zero Long-Lived Tokens**: OIDC (GitHub Actions ↔ Cloud)
3. **Least Privilege**: RBAC granular (K8s + ArgoCD)
4. **Immutable Artifacts**: Signed images, SBOM, provenance
5. **Defense in Depth**: Network policies, admission control
6. **Audit Everything**: Logs estruturados, Git history

## 🚨 Anti-Patterns a Evitar

❌ **Auto-sync em produção** → Manual sync + approvals  
❌ **Secrets em Git** → External Secrets Operator  
❌ **Imagens `:latest`** → Versão explícita (CalVer)  
❌ **Sem resource limits** → Sempre definir requests/limits  
❌ **Log de secrets** → Redact sensitive data  
❌ **Rollback não testado** → Testa mensalmente  
❌ **Sem health checks** → Sempre configurar probes  
❌ **Monorepo sem path filters** → Path filters por serviço

## 📞 Suporte & Recursos

### Links Úteis

- **ArgoCD UI**: https://argocd.nexo.com
- **Grafana**: https://grafana.nexo.com
- **Jaeger**: https://jaeger.nexo.com
- **GitHub Repo (Código)**: https://github.com/nexo-org/nexo
- **GitHub Repo (GitOps)**: https://github.com/nexo-org/nexo-gitops

### Slack Channels

- `#platform-team` - Dúvidas sobre pipeline
- `#sre-team` - Incidentes e produção
- `#deployments` - Notificações de deploy
- `#incidents` - Gestão de incidentes

### Oncall

- **PagerDuty**: https://nexo.pagerduty.com
- **Runbooks**: https://runbooks.nexo.com

## 🎯 Roadmap Futuro

### Q1 2026

- [ ] Canary deployments (Flagger)
- [ ] Progressive delivery
- [ ] Chaos engineering (Litmus)

### Q2 2026

- [ ] Multi-region deployments
- [ ] Service mesh (Istio)
- [ ] Advanced traffic management

### Q3 2026

- [ ] AI-powered anomaly detection
- [ ] Self-healing automations
- [ ] Predictive scaling

## 🤝 Contribuindo

Esta documentação é viva e deve ser atualizada conforme a pipeline evolui.

Para sugerir melhorias:

1. Abra uma issue no GitHub
2. Ou crie um PR diretamente
3. Tag `@platform-team` para review

## 📝 Change Log

| Versão | Data       | Autor                      | Mudanças                |
| ------ | ---------- | -------------------------- | ----------------------- |
| 1.0.0  | 2026-02-01 | Staff Platform Engineering | Versão inicial completa |

---

**Mantido por**: Platform Engineering Team  
**Última revisão**: 2026-02-01  
**Próxima revisão**: 2026-05-01 (trimestral)

---

> 💡 **Dica**: Comece pelo [Overview](00-overview.md) para entender a visão geral, depois navegue pelos documentos específicos conforme necessário.
