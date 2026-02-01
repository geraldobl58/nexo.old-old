# Implementation Roadmap - Enterprise CI/CD Pipeline

## 📅 Timeline Completo: 9 Semanas

```
┌─────────────────────────────────────────────────────────────────────┐
│                        IMPLEMENTATION TIMELINE                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Week 1-2  │  Week 3-4  │  Week 5-6  │  Week 7-8  │  Week 9        │
│  Foundation│Observability│  Security  │ Validation │  Go-Live       │
│            │             │            │            │                │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Fase 1: Foundation (Semanas 1-2)

### Objetivos

- Setup de infraestrutura base
- CI/CD funcionando end-to-end
- Deploy automatizado em develop

### Semana 1: GitHub Actions

**Dia 1-2: Setup Repositório GitOps**

```bash
# Criar novo repo
gh repo create nexo-gitops --private --description "GitOps manifests"

# Estrutura inicial
mkdir -p nexo-gitops/{argocd,helm}
cd nexo-gitops

# Helm charts
mkdir -p helm/{nexo-be,nexo-fe,nexo-auth}

# Copiar templates base
cp -r templates/helm/* helm/nexo-be/
# Adaptar para cada serviço
```

**Dia 3-5: GitHub Actions Workflows**

Criar:

1. `.github/workflows/_reusable-ci.yml` (base CI)
2. `.github/workflows/ci-nexo-be.yml` (caller)
3. `.github/workflows/promote.yml` (promotion)

Testar:

```bash
# Trigger manual
gh workflow run ci-nexo-be.yml

# Verificar output
gh run list --workflow=ci-nexo-be.yml
gh run view <run-id>
```

**Entregáveis Semana 1**:

- ✅ Repositório GitOps criado
- ✅ Reusable workflow funcionando
- ✅ Build de imagem Docker OK
- ✅ Push para GHCR OK

### Semana 2: ArgoCD

**Dia 1-2: Install ArgoCD**

```bash
# Criar namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Expor UI (dev)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
argocd admin initial-password -n argocd

# Login
argocd login localhost:8080
```

**Dia 3-4: Configure ApplicationSets**

```bash
# Criar AppProject
kubectl apply -f argocd/projects/nexo-platform.yaml

# Criar ApplicationSet
kubectl apply -f argocd/applicationsets/nexo-apps.yaml

# Verificar Applications geradas
argocd app list
```

**Dia 5: Primeiro Deploy**

```bash
# Commit image tag no GitOps
cd nexo-gitops
yq eval '.image.tag = "2026.02.1"' -i helm/nexo-be/values-develop.yaml
git add helm/nexo-be/values-develop.yaml
git commit -m "chore(nexo-be): initial deploy develop"
git push origin main

# ArgoCD sincroniza
argocd app sync nexo-be-develop

# Validar
kubectl get pods -n nexo-develop -l app=nexo-be
```

**Entregáveis Semana 2**:

- ✅ ArgoCD instalado e configurado
- ✅ ApplicationSet gerando 12 applications
- ✅ Deploy funcionando em develop
- ✅ Auto-sync configurado

---

## 📊 Fase 2: Observability (Semanas 3-4)

### Objetivos

- Métricas, logs e traces coletados
- Dashboards básicos criados
- Alerting configurado

### Semana 3: Prometheus + Grafana

**Dia 1-2: Install Prometheus Stack**

```bash
# Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values local/observability/prometheus/values.yaml

# Verificar
kubectl get pods -n monitoring
```

**Dia 3: ServiceMonitors**

```bash
# Aplicar ServiceMonitors para cada app
kubectl apply -f helm/nexo-be/templates/servicemonitor.yaml -n nexo-develop
kubectl apply -f helm/nexo-fe/templates/servicemonitor.yaml -n nexo-develop
kubectl apply -f helm/nexo-auth/templates/servicemonitor.yaml -n nexo-develop

# Verificar targets
# Prometheus UI → Status → Targets
```

**Dia 4-5: Grafana Dashboards**

```bash
# Import dashboards
# 1. Nexo BE Overview
# 2. Nexo FE Overview
# 3. Infrastructure Overview
# 4. DORA Metrics

# Grafana → Dashboards → Import
```

**Entregáveis Semana 3**:

- ✅ Prometheus coletando métricas
- ✅ ServiceMonitors configurados
- ✅ 4 dashboards básicos criados
- ✅ PrometheusRules com alerts

### Semana 4: Loki + Jaeger

**Dia 1-2: Install Loki**

```bash
# Helm install
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values local/observability/loki/values.yaml

# Verificar
kubectl get pods -n monitoring -l app=loki
```

**Dia 3: Structured Logging**

```typescript
// Implementar StructuredLogger em cada app
// Ver: 05-observability.md

// Test
kubectl logs -n nexo-develop -l app=nexo-be --tail=10
// Output deve ser JSON
```

**Dia 4-5: Install Jaeger**

```bash
# Jaeger Operator
kubectl create namespace observability
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.51.0/jaeger-operator.yaml

# Jaeger instance
kubectl apply -f local/observability/jaeger/jaeger.yaml

# Verificar
kubectl get pods -n observability
```

**Entregáveis Semana 4**:

- ✅ Loki coletando logs estruturados
- ✅ Jaeger coletando traces
- ✅ OpenTelemetry instrumentação configurada
- ✅ Logs/traces linkados

---

## 🔐 Fase 3: Security (Semanas 5-6)

### Objetivos

- Zero secrets em Git
- OIDC configurado
- Image signing implementado
- Network policies aplicadas

### Semana 5: External Secrets + OIDC

**Dia 1-2: Install External Secrets Operator**

```bash
# Helm install
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets-system \
  --create-namespace \
  --set installCRDs=true

# Verificar
kubectl get pods -n external-secrets-system
```

**Dia 2-3: Configure AWS Secrets Manager**

```bash
# Criar secrets no AWS
aws secretsmanager create-secret \
  --name nexo/develop/database \
  --secret-string '{"username":"nexo","password":"xxx","host":"db.example.com"}'

# SecretStore
kubectl apply -f k8s/base/secretstore-aws.yaml

# ExternalSecret
kubectl apply -f helm/nexo-be/templates/externalsecret-db.yaml

# Verificar secret criado
kubectl get secret nexo-be-db-credentials -n nexo-develop
```

**Dia 4-5: Configure OIDC (GitHub → AWS)**

```bash
# Ver: 04-security-secrets.md#oidc-github-actions--cloud

# 1. Criar OIDC provider na AWS
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com

# 2. Criar IAM Role com trust policy
# 3. Update GitHub Actions workflow
# 4. Testar
gh workflow run ci-nexo-be.yml
```

**Entregáveis Semana 5**:

- ✅ External Secrets Operator funcionando
- ✅ Secrets em AWS Secrets Manager
- ✅ OIDC configurado (zero static tokens)
- ✅ CI usando OIDC

### Semana 6: Image Signing + Network Policies

**Dia 1-2: Image Signing com Cosign**

```bash
# Gerar keypair
cosign generate-key-pair

# Add to GitHub Secrets
# COSIGN_PRIVATE_KEY, COSIGN_PASSWORD

# Update workflow para assinar imagens
# Ver: 04-security-secrets.md#image-signing--verification

# Testar
gh workflow run ci-nexo-be.yml
cosign verify --key cosign.pub ghcr.io/nexo-org/nexo-be:2026.02.1
```

**Dia 3-4: Network Policies**

```bash
# Aplicar NetworkPolicies
kubectl apply -f helm/nexo-be/templates/networkpolicy.yaml -n nexo-develop
kubectl apply -f helm/nexo-fe/templates/networkpolicy.yaml -n nexo-develop
kubectl apply -f helm/nexo-auth/templates/networkpolicy.yaml -n nexo-develop

# Testar conectividade
kubectl exec -it <nexo-be-pod> -n nexo-develop -- curl nexo-fe:3000
# Deve falhar (policy block)

kubectl exec -it <nexo-fe-pod> -n nexo-develop -- curl nexo-be:8080
# Deve funcionar (policy allow)
```

**Dia 5: Security Audit**

```bash
# Run security scans
trivy image ghcr.io/nexo-org/nexo-be:2026.02.1
semgrep --config=auto apps/nexo-be/src

# Fix vulnerabilities encontradas
```

**Entregáveis Semana 6**:

- ✅ Imagens assinadas (Cosign)
- ✅ SBOM gerado para cada build
- ✅ Network Policies aplicadas
- ✅ Security audit completo

---

## ✅ Fase 4: Validation (Semanas 7-8)

### Objetivos

- Load testing executado
- DR drill realizado
- Runbooks validados
- Time treinado

### Semana 7: Testing & DR

**Dia 1-2: Load Testing**

```bash
# Install k6
brew install k6

# Rodar load test
k6 run \
  --vus 100 \
  --duration 30m \
  scripts/load-test.js

# Analisar resultados
# - Latency (p95, p99)
# - Error rate
# - Throughput
```

**Dia 3-4: Disaster Recovery Drill**

```bash
# Simular perda de cluster
k3d cluster delete nexo-dev

# Restore do zero
k3d cluster create nexo-dev --config local/k3d/config.yaml
./local/scripts/setup.sh

# Aplicar ArgoCD root app
kubectl apply -f argocd/root-app.yaml

# Verificar que tudo volta
argocd app sync -l argocd.argoproj.io/instance=root
kubectl get pods --all-namespaces

# Medir RTO (Recovery Time Objective)
# Target: < 30 minutos
```

**Dia 5: Runbooks Validation**

```bash
# Executar cada runbook
# 1. High error rate → Rollback
# 2. High latency → Scale up
# 3. Pod crash loop → Debug
# 4. Database connection → Fix

# Atualizar runbooks com learnings
```

**Entregáveis Semana 7**:

- ✅ Load test: 1000 RPS sustentado
- ✅ DR drill: RTO < 30min
- ✅ Runbooks validados
- ✅ Bottlenecks identificados e corrigidos

### Semana 8: Training & Documentation

**Dia 1-2: Developer Training**

```markdown
# Workshop: CI/CD para Developers

- Como funciona a pipeline
- Como fazer deploy
- Como debugar falhas
- Como promover entre ambientes
- Feature flags usage
```

**Dia 3: Platform Engineer Training**

```markdown
# Workshop: ArgoCD & Helm

- Avançado em Helm templating
- Troubleshooting ArgoCD sync
- Custom health checks
- Secrets management
```

**Dia 4: SRE Training**

```markdown
# Workshop: Incident Response

- Runbooks walkthrough
- Rollback procedures
- Disaster recovery
- Performance tuning
```

**Dia 5: Documentation Review**

```bash
# Revisar toda documentação
# - Typos, links quebrados
# - Comandos testados
# - Screenshots atualizados
```

**Entregáveis Semana 8**:

- ✅ 20+ pessoas treinadas
- ✅ Documentation 100% revisada
- ✅ Feedback incorporado
- ✅ Sign-off de stakeholders

---

## 🚀 Fase 5: Go-Live (Semana 9)

### Objetivos

- Deploy piloto em produção
- Monitoramento intensivo
- Rollout completo

### Dia 1: Production Pilot (1 serviço)

```bash
# Escolher serviço menos crítico para piloto
# Exemplo: nexo-auth

# 1. Promover para staging
cd nexo-gitops
yq eval '.image.tag = "2026.02.1"' -i helm/nexo-auth/values-staging.yaml
# PR + approval + merge

# 2. Soak time (30 minutos)
# 3. Promover para produção
yq eval '.image.tag = "2026.02.1"' -i helm/nexo-auth/values-prod.yaml
# PR + 2 SRE approvals + merge

# 4. Sync manual
argocd app sync nexo-auth-production

# 5. Monitor INTENSIVAMENTE por 2 horas
watch -n 10 'argocd app get nexo-auth-production'
# Grafana dashboard aberto
# Logs streaming
```

### Dia 2-3: Monitor & Validate

```bash
# Métricas a observar:
# - Error rate (deve ser < 0.1%)
# - Latency (p95 < 100ms)
# - Throughput (requests/sec)
# - Resource usage (CPU, memory)

# Se tudo OK por 48h → continuar rollout
```

### Dia 4-5: Rollout Completo

```bash
# nexo-fe
cd nexo-gitops
yq eval '.image.tag = "2026.02.1"' -i helm/nexo-fe/values-prod.yaml
# PR + approvals + deploy

# nexo-be (mais crítico, último)
yq eval '.image.tag = "2026.02.1"' -i helm/nexo-be/values-prod.yaml
# PR + approvals + deploy

# ✅ PIPELINE 100% EM PRODUÇÃO!
```

### Dia 5: Celebration & Retrospective

```markdown
# Retrospective Meeting

## What went well?

- Documentação ajudou muito
- Training foi efetivo
- DR drill nos preparou

## What could be better?

- Load testing poderia ser mais cedo
- Alguns runbooks precisam de screenshots

## Action items

- [ ] Update runbooks com screenshots
- [ ] Adicionar mais dashboards
- [ ] Documentar lessons learned
```

---

## 📊 Success Criteria (Pós Go-Live)

### Semana 10-12: Monitoramento

Validar métricas após 30 dias em produção:

```
Target Metrics:
✅ Deployment Frequency: > 1/dia (atual: ___)
✅ Lead Time: < 1h (atual: ___)
✅ MTTR: < 30min (atual: ___)
✅ Change Failure Rate: < 5% (atual: ___)
✅ CI Success Rate: > 95% (atual: ___)
✅ Zero secrets vazados (atual: ___)
```

### Ajustes Finos

```bash
# Tune HPA
# Tune resource limits
# Optimize Docker images
# Refine alerting rules
# Add more dashboards
```

---

## 🎯 Milestones & Gates

| Milestone             | Gate Criteria                 | Owner            |
| --------------------- | ----------------------------- | ---------------- |
| **Fase 1 Complete**   | CI/CD básico funcionando      | Platform Lead    |
| **Fase 2 Complete**   | Observability 100%            | SRE Lead         |
| **Fase 3 Complete**   | Security audit pass           | Security Officer |
| **Fase 4 Complete**   | All tests pass, training done | Platform Lead    |
| **Go-Live Approval**  | Stakeholder sign-off          | VP Engineering   |
| **Production Stable** | 30 dias sem incidentes        | SRE Lead         |

---

## 💰 Budget & Resources

### Time Investment

| Role                    | Weeks | Dedication | FTE          |
| ----------------------- | ----- | ---------- | ------------ |
| Staff Platform Engineer | 9     | 100%       | 1.0          |
| Senior SRE              | 4     | 50%        | 0.5          |
| Security Engineer       | 2     | 50%        | 0.25         |
| **Total**               |       |            | **1.75 FTE** |

### Tooling Costs

| Tool                   | Cost          | Notes                |
| ---------------------- | ------------- | -------------------- |
| GitHub Actions         | $0            | Free tier suficiente |
| ArgoCD                 | $0            | Open-source          |
| Prometheus/Loki/Jaeger | $0            | Open-source          |
| AWS Secrets Manager    | ~$40/mês      | 10 secrets           |
| **Total**              | **~$500/ano** |                      |

**ROI**: 10x em 12 meses (economia de 4000h engenharia/ano)

---

## 📞 Contacts & Support

### Implementation Team

- **Platform Lead**: alice@nexo.com
- **SRE Lead**: bob@nexo.com
- **Security**: charlie@nexo.com

### Escalation

- **Blockers**: #platform-team
- **Technical Questions**: #eng-platform-help
- **Approvals**: VP Engineering

---

## 📝 Change Log

| Version | Date       | Author              | Changes         |
| ------- | ---------- | ------------------- | --------------- |
| 1.0.0   | 2026-02-01 | Staff Platform Team | Initial roadmap |

---

**Status**: 📘 Roadmap Approved, Ready to Execute  
**Next Review**: End of Week 2 (Foundation complete)
