# Production Readiness Checklist

## 📋 Visão Geral

Este documento consolida **todas as validações necessárias** antes de considerar a pipeline pronta para produção. Inspirado em checklists de Netflix, Spotify, Uber e práticas CNCF.

---

## 🎯 Checklist Executivo

| Categoria                               | Status | Prioridade |
| --------------------------------------- | ------ | ---------- |
| [CI/CD Pipeline](#cicd-pipeline)        | ⬜     | P0         |
| [GitOps & ArgoCD](#gitops--argocd)      | ⬜     | P0         |
| [Security](#security)                   | ⬜     | P0         |
| [Observability](#observability)         | ⬜     | P0         |
| [Disaster Recovery](#disaster-recovery) | ⬜     | P1         |
| [Performance](#performance)             | ⬜     | P1         |
| [Documentation](#documentation)         | ⬜     | P1         |
| [Team Readiness](#team-readiness)       | ⬜     | P1         |

---

## 🔧 CI/CD Pipeline

### GitHub Actions

- [ ] **Reusable workflows implementados**
  - `_reusable-ci.yml` para linting, testing, build
  - `_reusable-security.yml` para scanning
  - `_reusable-gitops-update.yml` para atualização de manifests

- [ ] **Versionamento CalVer configurado**
  - Build number incrementa corretamente
  - Múltiplas tags geradas (version, SHA, environment)
  - Git tags criadas para releases

- [ ] **Build otimizado**
  - Docker layer caching habilitado (`cache-from: type=gha`)
  - Multi-stage builds (builder + runtime)
  - Imagens < 500MB (idealmente < 200MB)
  - Build time < 5 minutos

- [ ] **Testing pipeline**
  - [ ] Unit tests (cobertura > 80%)
  - [ ] Integration tests (ambientes críticos)
  - [ ] E2E tests (smoke tests obrigatórios)
  - [ ] Performance tests (benchmarks)
  - [ ] Tests rodando em paralelo

- [ ] **Security scanning**
  - [ ] SAST (Semgrep/SonarCloud)
  - [ ] Dependency check (npm audit, Snyk)
  - [ ] Container scanning (Trivy/Grype)
  - [ ] SBOM gerado (Syft)
  - [ ] Imagens assinadas (Cosign)

- [ ] **Secrets management**
  - [ ] Zero secrets em código
  - [ ] OIDC configurado (GitHub → AWS/GCP)
  - [ ] Secrets Manager integrado
  - [ ] Secrets rotation policy definida

- [ ] **Environments configurados**
  - [ ] `develop`: Auto-deploy, 0 approvals
  - [ ] `qa`: Auto-deploy, 0 approvals
  - [ ] `staging`: Manual, 1 approval
  - [ ] `production`: Manual, 2+ approvals, soak time 30min

- [ ] **Notificações**
  - [ ] Slack/Teams integrado
  - [ ] Falhas notificam imediatamente
  - [ ] Deploys em produção notificam stakeholders

---

## 🚀 GitOps & ArgoCD

### Estrutura

- [ ] **Repositório GitOps separado**
  - Separado do código da aplicação
  - Permissões granulares (CI escreve tags, não código)
  - CODEOWNERS configurado

- [ ] **Helm charts estruturados**
  - [ ] Chart.yaml com versão e dependencies
  - [ ] values.yaml com defaults sensatos
  - [ ] values-{env}.yaml para cada ambiente
  - [ ] Templates com resource limits/requests
  - [ ] Templates com health checks (liveness, readiness)

- [ ] **AppProject configurado**
  - Source repos whitelisted
  - Destination clusters/namespaces definidos
  - RBAC policies aplicadas
  - Sync windows configuradas (prod: horário comercial)

- [ ] **ApplicationSet**
  - Gera Applications para todos serviços/ambientes
  - Usa generator `list` (explícito, não git/cluster)
  - Configurações por ambiente documentadas

### Sync Policies

- [ ] **Auto-sync configurado corretamente**
  - develop/qa: `automated: true`, `selfHeal: true`, `prune: true`
  - staging/prod: `automated: false` (manual sync)

- [ ] **Retry policy**
  - Backoff exponencial configurado
  - Limite de retries (5x recomendado)
  - Timeout adequado (5min max)

- [ ] **Health checks customizados**
  - Deployment: replicas disponíveis
  - Service: endpoints prontos
  - Custom resources com Lua scripts

- [ ] **Rollback automático**
  - Habilitado em develop/qa
  - Desabilitado em staging/prod (manual)
  - Timeout configurado (5min)

### Observability

- [ ] **ArgoCD Notifications**
  - Deployment success → Slack
  - Health degraded → PagerDuty/Slack
  - Sync failed → Email + Slack

- [ ] **Métricas expostas**
  - Prometheus ServiceMonitor configurado
  - ArgoCD metrics scraped
  - Dashboards no Grafana

---

## 🔐 Security

### Secrets Management

- [ ] **External Secrets Operator instalado**
  - SecretStore configurado (AWS/Vault)
  - ExternalSecrets para cada serviço
  - Refresh interval adequado (15min - 1h)

- [ ] **Secrets em produção**
  - [ ] Database credentials
  - [ ] API keys (Stripe, SendGrid, etc.)
  - [ ] TLS certificates
  - [ ] OAuth client secrets

- [ ] **RBAC Kubernetes**
  - ServiceAccount por serviço
  - Least privilege (apenas recursos necessários)
  - NetworkPolicies aplicadas

- [ ] **RBAC ArgoCD**
  - Developers: read-only + sync dev/qa
  - Platform Engineers: full access exceto prod
  - SRE: full access

### Container Security

- [ ] **Image scanning**
  - Trivy/Grype no CI
  - Bloqueio de CRITICAL/HIGH vulnerabilities
  - Scan diário de imagens em registry

- [ ] **Image signing**
  - Cosign configurado
  - Imagens assinadas no CI
  - Admission controller verificando assinaturas

- [ ] **Runtime security**
  - [ ] runAsNonRoot: true
  - [ ] readOnlyRootFilesystem: true
  - [ ] allowPrivilegeEscalation: false
  - [ ] seccompProfile: RuntimeDefault

- [ ] **Network policies**
  - Ingress: apenas do ingress controller
  - Egress: whitelist (DNS, DB, external APIs)
  - Deny all como default

### Authentication

- [ ] **OIDC configurado**
  - GitHub Actions → Cloud (zero static tokens)
  - Roles com least privilege
  - Audit trail habilitado

- [ ] **Certificate management**
  - cert-manager instalado
  - Let's Encrypt para TLS
  - Auto-renewal configurado

---

## 📊 Observability

### Metrics

- [ ] **Prometheus stack**
  - Prometheus Operator instalado
  - ServiceMonitors para cada serviço
  - Alerting rules configuradas
  - PersistentVolume para retenção (30 dias)

- [ ] **Golden Signals implementados**
  - [ ] Latency (histogram)
  - [ ] Traffic (counter)
  - [ ] Errors (counter)
  - [ ] Saturation (gauge)

- [ ] **Business metrics**
  - User signups, transactions, revenue
  - Custom metrics por domínio

- [ ] **Grafana dashboards**
  - [ ] Overview por serviço
  - [ ] Infrastructure overview
  - [ ] Executive summary (DORA metrics)
  - [ ] Incident response dashboard

### Logs

- [ ] **Loki stack instalado**
  - Promtail coletando logs
  - Retenção configurada (90 dias)
  - Storage adequado

- [ ] **Structured logging**
  - JSON format
  - Correlation IDs (trace_id, request_id)
  - Levels corretos (DEBUG, INFO, WARN, ERROR)

- [ ] **Log queries preparadas**
  - Busca por erro
  - Trace de requisição
  - Top erros
  - Logs por usuário

### Tracing

- [ ] **OpenTelemetry configurado**
  - Jaeger/Tempo backend
  - Auto-instrumentation ativada
  - Sampling configurado (10% dev, 1% prod)

- [ ] **Spans customizados**
  - Database queries
  - External API calls
  - Business operations críticas

### Alerting

- [ ] **PrometheusRules configuradas**
  - [ ] High error rate (> 1%)
  - [ ] High latency (p95 > 1s)
  - [ ] Pod crash loop
  - [ ] Memory/CPU saturation (> 80%)
  - [ ] Disk usage (> 85%)

- [ ] **Alertmanager configurado**
  - Routes por severity
  - Inhibition rules (evita spam)
  - Silences documentadas

- [ ] **Oncall rotation**
  - PagerDuty/Opsgenie integrado
  - Escalation policy definida
  - Runbooks linkados nos alerts

### Audit

- [ ] **Deployment audit**
  - Logs estruturados salvos (DB + S3)
  - Retention: 7 anos (compliance)
  - Query API disponível

- [ ] **DORA metrics coletadas**
  - Deployment frequency
  - Lead time for changes
  - Time to restore service
  - Change failure rate

---

## 🛡️ Disaster Recovery

### Backup

- [ ] **Cluster state**
  - [ ] ArgoCD Applications (Git como fonte)
  - [ ] Kubernetes secrets (Velero)
  - [ ] PersistentVolumes (Velero)
  - [ ] etcd snapshots (daily)

- [ ] **Databases**
  - [ ] Automated backups (daily)
  - [ ] Point-in-time recovery testado
  - [ ] Cross-region replication (prod)
  - [ ] Backup retention: 30 dias

- [ ] **GitOps repos**
  - [ ] GitHub backup (automated)
  - [ ] Commit history preservado
  - [ ] Branch protection ativada

### Recovery Procedures

- [ ] **Runbooks documentados**
  - [ ] Cluster recovery
  - [ ] Database restore
  - [ ] Full disaster recovery
  - [ ] Network partition

- [ ] **RTO/RPO definidos**
  - Production: RTO < 4h, RPO < 1h
  - Staging: RTO < 8h, RPO < 24h
  - Develop: Best effort

- [ ] **DR drills**
  - Simulação trimestral
  - Incidentes documentados
  - Post-mortems conduzidos

### Rollback

- [ ] **Rollback testado**
  - [ ] Via ArgoCD (CLI e UI)
  - [ ] Via GitOps (revert PR)
  - [ ] Blue/Green switch (prod)
  - [ ] Database migrations (reversível)

- [ ] **Rollback time**
  - Develop: < 2 min
  - QA: < 2 min
  - Staging: < 5 min
  - Production: < 10 min

---

## ⚡ Performance

### Resource Management

- [ ] **Resource requests/limits definidos**

  ```yaml
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
  ```

- [ ] **HPA configurado**
  - Min: 2 replicas (prod)
  - Max: 10 replicas
  - Target CPU: 70%
  - Target Memory: 80%

- [ ] **PDB configurado**
  - minAvailable: 1 (prod)
  - Protege contra disruptions voluntárias

### Load Testing

- [ ] **Baseline estabelecido**
  - Requests per second (RPS)
  - Latency (p50, p95, p99)
  - Error rate

- [ ] **Load tests executados**
  - [ ] Sustained load (1h, RPS esperado)
  - [ ] Spike test (3x RPS, 5min)
  - [ ] Soak test (24h, RPS normal)

- [ ] **Bottlenecks identificados**
  - Database connection pool
  - External API rate limits
  - Memory leaks

---

## 📚 Documentation

### Pipeline Docs

- [x] **Arquitetura geral** (00-overview.md)
- [x] **GitHub Actions workflows** (01-github-actions-workflows.md)
- [x] **ArgoCD configuration** (02-argocd-configuration.md)
- [x] **Versioning & promotion** (03-versioning-promotion.md)
- [x] **Security & secrets** (04-security-secrets.md)
- [x] **Observability** (05-observability.md)
- [x] **Production checklist** (06-production-checklist.md)

### Operational Docs

- [ ] **Runbooks**
  - [ ] High error rate
  - [ ] High latency
  - [ ] Pod crash loop
  - [ ] Database connection issues
  - [ ] Disk full

- [ ] **Deployment procedures**
  - [ ] Hotfix process
  - [ ] Emergency rollback
  - [ ] Manual promotion (staging → prod)
  - [ ] Feature flag deployment

- [ ] **Troubleshooting guides**
  - [ ] Common CI failures
  - [ ] ArgoCD sync failures
  - [ ] Image pull errors
  - [ ] Secrets not found

### Team Documentation

- [ ] **Onboarding guide**
  - Setup local environment
  - Acesso aos sistemas (ArgoCD, Grafana, etc.)
  - Como fazer primeiro deploy

- [ ] **Architecture Decision Records (ADRs)**
  - [ ] Por que CalVer?
  - [ ] Por que Helm ao invés de Kustomize?
  - [ ] Por que Trunk-Based Development?
  - [ ] Por que repositório GitOps separado?

---

## 👥 Team Readiness

### Training

- [ ] **Desenvolvedores treinados**
  - [ ] Fluxo de CI/CD
  - [ ] Como debugar pipeline failures
  - [ ] Como promover entre ambientes
  - [ ] Feature flags usage

- [ ] **Platform Engineers treinados**
  - [ ] ArgoCD avançado
  - [ ] Helm templating
  - [ ] Kubernetes troubleshooting
  - [ ] Security scanning

- [ ] **SREs treinados**
  - [ ] Incident response
  - [ ] Runbooks
  - [ ] Disaster recovery procedures
  - [ ] Performance tuning

### Processes

- [ ] **Deployment calendar**
  - Freeze periods documentados (Black Friday, etc.)
  - Change Advisory Board (CAB) meetings

- [ ] **Incident management**
  - [ ] Severity levels definidos (P0-P4)
  - [ ] Escalation policy
  - [ ] Post-mortem template
  - [ ] Blameless culture

- [ ] **Change management**
  - [ ] PR template
  - [ ] Code review checklist
  - [ ] Deployment approval process

---

## 🚨 Common Pitfalls a Evitar

### ❌ Anti-Patterns

1. **Auto-sync em produção**

   ```yaml
   # ❌ NUNCA
   production:
     autoSync: true
     selfHeal: true
   ```

   **Por quê**: Deploy acidental pode derrubar produção.
   **Solução**: Manual sync + approvals.

2. **Secrets em Git**

   ```yaml
   # ❌ NUNCA
   apiVersion: v1
   kind: Secret
   data:
     password: cGFzc3dvcmQ= # Base64 ≠ encryption!
   ```

   **Por quê**: Qualquer pessoa com acesso ao repo vê os secrets.
   **Solução**: External Secrets Operator.

3. **Imagens com tag `:latest`**

   ```yaml
   # ❌ EVITE
   image: nexo-be:latest
   ```

   **Por quê**: Não é reproducível, quebra rollback.
   **Solução**: Versão explícita (CalVer).

4. **Sem resource limits**

   ```yaml
   # ❌ PERIGOSO
   containers:
     - name: app
       # Sem resources definidos
   ```

   **Por quê**: Um pod pode consumir todos os recursos do node.
   **Solução**: Sempre definir requests e limits.

5. **Log de secrets**

   ```typescript
   // ❌ NUNCA
   console.log("DB_PASSWORD:", process.env.DB_PASSWORD);
   ```

   **Por quê**: Secrets vazam para logs centralizados.
   **Solução**: Redact sensitive data.

6. **Rollback não testado**

   ```bash
   # ❌ "Deve funcionar..."
   # Nunca testou rollback antes do incidente
   ```

   **Por quê**: Descobre problemas durante incidente.
   **Solução**: Testa rollback mensalmente.

7. **Sem health checks**

   ```yaml
   # ❌ Deployment sem probes
   spec:
     containers:
       - name: app
         # Sem livenessProbe/readinessProbe
   ```

   **Por quê**: Pods quebrados recebem tráfego.
   **Solução**: Sempre configurar probes.

8. **Monorepo sem path filters**
   ```yaml
   # ❌ Build todo repo para qualquer mudança
   on:
     push:
       # Sem paths definidos
   ```
   **Por quê**: CI roda desnecessariamente, custos aumentam.
   **Solução**: Path filters por serviço.

---

## 📈 Success Metrics

### Targets (após 3 meses em produção)

| Metric                      | Target  | Current | Status |
| --------------------------- | ------- | ------- | ------ |
| Deployment Frequency        | > 1/dia | -       | ⬜     |
| Lead Time for Changes       | < 1h    | -       | ⬜     |
| Time to Restore Service     | < 1h    | -       | ⬜     |
| Change Failure Rate         | < 5%    | -       | ⬜     |
| CI Success Rate             | > 95%   | -       | ⬜     |
| Deployment Success Rate     | > 99%   | -       | ⬜     |
| Mean Time to Detect (MTTD)  | < 5min  | -       | ⬜     |
| Mean Time to Resolve (MTTR) | < 30min | -       | ⬜     |

### Business Impact

- **Developer Velocity**: Tempo médio de feature → produção
  - Baseline: ? dias
  - Target: < 3 dias (70% redução)

- **Operational Efficiency**: Tempo gasto em deploys manuais
  - Baseline: ? h/semana
  - Target: < 2h/semana (80% redução)

- **Reliability**: Incidentes causados por deploys
  - Baseline: ? por mês
  - Target: < 1 por mês (90% redução)

---

## 🎓 Próximos Passos

### Fase 1: Foundation (Semanas 1-2)

- [ ] Setup GitHub Actions workflows
- [ ] Setup ArgoCD ApplicationSets
- [ ] Configure OIDC (GitHub → Cloud)
- [ ] Install External Secrets Operator

### Fase 2: Observability (Semanas 3-4)

- [ ] Deploy Prometheus stack
- [ ] Deploy Loki stack
- [ ] Implement structured logging
- [ ] Create Grafana dashboards

### Fase 3: Security Hardening (Semanas 5-6)

- [ ] Implement image signing
- [ ] Configure Network Policies
- [ ] Setup admission controller
- [ ] Security audit

### Fase 4: Production Validation (Semanas 7-8)

- [ ] Load testing
- [ ] DR drill
- [ ] Runbooks validation
- [ ] Team training

### Fase 5: Go-Live (Semana 9)

- [ ] Production pilot (1 serviço)
- [ ] Monitor intensivamente (1 semana)
- [ ] Rollout completo

---

## 📞 Support & Escalation

### Contacts

| Role              | Primary   | Secondary | Slack          |
| ----------------- | --------- | --------- | -------------- |
| **Platform Lead** | @alice    | @bob      | #platform-team |
| **SRE Lead**      | @charlie  | @dave     | #sre-team      |
| **Security**      | @eve      | @frank    | #security      |
| **Oncall**        | PagerDuty | -         | #incidents     |

### Resources

- **ArgoCD UI**: https://argocd.nexo.com
- **Grafana**: https://grafana.nexo.com
- **Jaeger**: https://jaeger.nexo.com
- **Documentation**: https://docs.nexo.com
- **Runbooks**: https://runbooks.nexo.com

---

## ✅ Sign-Off

Antes de aprovar para produção, os seguintes stakeholders devem revisar e aprovar:

- [ ] **Platform Engineering Lead**: **********\_********** (Data: **\_\_**)
- [ ] **SRE Lead**: **********\_********** (Data: **\_\_**)
- [ ] **Security Officer**: **********\_********** (Data: **\_\_**)
- [ ] **CTO/VP Engineering**: **********\_********** (Data: **\_\_**)

**Aprovação Final**: ⬜ APROVADO | ⬜ APROVADO COM RESTRIÇÕES | ⬜ REJEITADO

**Comentários**:

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

**Versão**: 1.0.0  
**Última Atualização**: 2026-02-01  
**Próxima Revisão**: 2026-05-01 (trimestral)
