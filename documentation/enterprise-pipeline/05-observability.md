# Observability & Governance

## 📋 Visão Geral

Observabilidade enterprise não é apenas monitoramento - é a capacidade de **entender o estado interno do sistema através de suas saídas externas**. Governança garante que processos sejam seguidos e auditáveis.

## 🎯 Os Três Pilares + Auditoria

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OBSERVABILITY STACK                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  📊 METRICS          📝 LOGS              🔍 TRACES      📋 AUDIT   │
│  (Prometheus)        (Loki)               (Jaeger)      (Git+DB)    │
│       │                 │                    │              │        │
│       ├─ Golden Signals ├─ Structured JSON  ├─ Spans      ├─ Who   │
│       ├─ Business KPIs  ├─ Correlation IDs  ├─ Context    ├─ What  │
│       └─ SLIs/SLOs      └─ Error tracking   └─ Latency    └─ When  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Metrics: Prometheus + Grafana

### Golden Signals (Google SRE)

```yaml
# Métricas obrigatórias para cada serviço
golden_signals:
  latency: # Tempo de resposta
    - http_request_duration_seconds
    - grpc_request_duration_seconds

  traffic: # Volume de requisições
    - http_requests_total
    - grpc_requests_total

  errors: # Taxa de erro
    - http_requests_errors_total
    - grpc_requests_errors_total

  saturation: # Utilização de recursos
    - container_cpu_usage_seconds_total
    - container_memory_working_set_bytes
    - http_request_queue_depth
```

### ServiceMonitor (Prometheus Operator)

```yaml
# helm/nexo-be/templates/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: { { include "nexo-be.fullname" . } }
  namespace: { { .Release.Namespace } }
  labels:
    app: { { include "nexo-be.name" . } }
    release: prometheus
spec:
  selector:
    matchLabels:
      app: { { include "nexo-be.name" . } }

  endpoints:
    - port: metrics
      path: /metrics
      interval: 30s
      scrapeTimeout: 10s

      # Relabeling para adicionar metadata
      relabelings:
        - sourceLabels: [__meta_kubernetes_namespace]
          targetLabel: namespace
        - sourceLabels: [__meta_kubernetes_pod_name]
          targetLabel: pod
        - sourceLabels: [__meta_kubernetes_pod_label_version]
          targetLabel: version
```

### Application Metrics (NestJS)

```typescript
// apps/nexo-be/src/metrics.service.ts
import { Injectable } from "@nestjs/common";
import { Registry, Counter, Histogram, Gauge } from "prom-client";

@Injectable()
export class MetricsService {
  private readonly registry: Registry;

  // Golden Signals
  public readonly httpRequestDuration: Histogram;
  public readonly httpRequestsTotal: Counter;
  public readonly httpRequestsErrors: Counter;

  // Business Metrics
  public readonly userSignups: Counter;
  public readonly activeUsers: Gauge;
  public readonly paymentTransactions: Counter;

  constructor() {
    this.registry = new Registry();

    // HTTP Request Duration (latency)
    this.httpRequestDuration = new Histogram({
      name: "http_request_duration_seconds",
      help: "Duration of HTTP requests in seconds",
      labelNames: ["method", "route", "status_code"],
      buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5],
      registers: [this.registry],
    });

    // HTTP Requests Total (traffic)
    this.httpRequestsTotal = new Counter({
      name: "http_requests_total",
      help: "Total number of HTTP requests",
      labelNames: ["method", "route", "status_code"],
      registers: [this.registry],
    });

    // HTTP Errors (errors)
    this.httpRequestsErrors = new Counter({
      name: "http_requests_errors_total",
      help: "Total number of HTTP errors",
      labelNames: ["method", "route", "status_code", "error_type"],
      registers: [this.registry],
    });

    // Business metrics
    this.userSignups = new Counter({
      name: "user_signups_total",
      help: "Total number of user signups",
      labelNames: ["plan", "source"],
      registers: [this.registry],
    });

    this.activeUsers = new Gauge({
      name: "active_users",
      help: "Number of currently active users",
      registers: [this.registry],
    });

    this.paymentTransactions = new Counter({
      name: "payment_transactions_total",
      help: "Total payment transactions",
      labelNames: ["status", "currency"],
      registers: [this.registry],
    });
  }

  getMetrics(): Promise<string> {
    return this.registry.metrics();
  }
}

// Middleware para instrumentação automática
@Injectable()
export class MetricsMiddleware implements NestMiddleware {
  constructor(private readonly metrics: MetricsService) {}

  use(req: Request, res: Response, next: NextFunction) {
    const start = Date.now();

    res.on("finish", () => {
      const duration = (Date.now() - start) / 1000;
      const route = req.route?.path || req.path;

      // Record metrics
      this.metrics.httpRequestDuration
        .labels(req.method, route, res.statusCode.toString())
        .observe(duration);

      this.metrics.httpRequestsTotal
        .labels(req.method, route, res.statusCode.toString())
        .inc();

      if (res.statusCode >= 400) {
        this.metrics.httpRequestsErrors
          .labels(req.method, route, res.statusCode.toString(), "http_error")
          .inc();
      }
    });

    next();
  }
}
```

### Grafana Dashboards

**Dashboard: Nexo BE Overview**

```json
{
  "dashboard": {
    "title": "Nexo BE - Production",
    "tags": ["nexo", "backend", "production"],
    "panels": [
      {
        "title": "Request Rate (RPS)",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{namespace=\"nexo-production\",app=\"nexo-be\"}[5m]))"
          }
        ]
      },
      {
        "title": "Latency (p50, p95, p99)",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "p50"
          },
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "p95"
          },
          {
            "expr": "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "p99"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_errors_total[5m])) / sum(rate(http_requests_total[5m])) * 100"
          }
        ],
        "alert": {
          "conditions": [
            {
              "evaluator": { "type": "gt", "params": [1] },
              "query": { "params": ["A", "5m", "now"] }
            }
          ]
        }
      }
    ]
  }
}
```

### PrometheusRule (Alerting)

```yaml
# k8s/monitoring/prometheusrule-nexo-be.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: nexo-be-alerts
  namespace: monitoring
spec:
  groups:
    - name: nexo-be
      interval: 30s
      rules:
        # High error rate
        - alert: NexoBEHighErrorRate
          expr: |
            sum(rate(http_requests_errors_total{namespace="nexo-production",app="nexo-be"}[5m]))
            /
            sum(rate(http_requests_total{namespace="nexo-production",app="nexo-be"}[5m]))
            > 0.01
          for: 5m
          labels:
            severity: critical
            service: nexo-be
            environment: production
          annotations:
            summary: "nexo-be error rate > 1%"
            description: "Error rate is {{ $value | humanizePercentage }}"
            runbook_url: "https://docs.nexo.com/runbooks/high-error-rate"

        # High latency
        - alert: NexoBEHighLatency
          expr: |
            histogram_quantile(0.95,
              sum(rate(http_request_duration_seconds_bucket{namespace="nexo-production",app="nexo-be"}[5m])) by (le)
            ) > 1
          for: 10m
          labels:
            severity: warning
            service: nexo-be
            environment: production
          annotations:
            summary: "nexo-be p95 latency > 1s"
            description: "P95 latency is {{ $value }}s"

        # Pod restarts
        - alert: NexoBEPodCrashLoop
          expr: |
            rate(kube_pod_container_status_restarts_total{namespace="nexo-production",pod=~"nexo-be-.*"}[15m]) > 0
          for: 5m
          labels:
            severity: critical
            service: nexo-be
            environment: production
          annotations:
            summary: "nexo-be pod restarting"
            description: "Pod {{ $labels.pod }} is crash looping"
```

---

## 📝 Logs: Loki + Promtail

### Structured Logging (NestJS)

```typescript
// apps/nexo-be/src/logger.service.ts
import { Injectable, LoggerService } from "@nestjs/common";

interface LogContext {
  traceId?: string;
  userId?: string;
  requestId?: string;
  [key: string]: any;
}

@Injectable()
export class StructuredLogger implements LoggerService {
  private serviceName = "nexo-be";
  private environment = process.env.NODE_ENV || "development";

  log(message: string, context?: LogContext) {
    this.writeLog("info", message, context);
  }

  error(message: string, trace?: string, context?: LogContext) {
    this.writeLog("error", message, { ...context, trace });
  }

  warn(message: string, context?: LogContext) {
    this.writeLog("warn", message, context);
  }

  debug(message: string, context?: LogContext) {
    this.writeLog("debug", message, context);
  }

  private writeLog(level: string, message: string, context?: LogContext) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level,
      service: this.serviceName,
      environment: this.environment,
      message,
      ...context,
    };

    // JSON structured log
    console.log(JSON.stringify(logEntry));
  }
}

// Usage
@Controller("users")
export class UsersController {
  constructor(private readonly logger: StructuredLogger) {}

  @Post()
  async createUser(@Body() dto: CreateUserDto, @Request() req) {
    const traceId = req.headers["x-trace-id"];

    this.logger.log("Creating user", {
      traceId,
      email: dto.email,
      action: "user_creation",
    });

    try {
      const user = await this.usersService.create(dto);

      this.logger.log("User created successfully", {
        traceId,
        userId: user.id,
        action: "user_creation_success",
      });

      return user;
    } catch (error) {
      this.logger.error("Failed to create user", error.stack, {
        traceId,
        email: dto.email,
        error: error.message,
        action: "user_creation_error",
      });

      throw error;
    }
  }
}
```

### Promtail Configuration

```yaml
# local/observability/promtail/values.yaml
config:
  clients:
    - url: http://loki:3100/loki/api/v1/push

  snippets:
    pipelineStages:
      - docker: {}

      # Parse JSON logs
      - json:
          expressions:
            timestamp: timestamp
            level: level
            service: service
            environment: environment
            message: message
            trace_id: traceId
            user_id: userId

      # Extract labels
      - labels:
          level:
          service:
          environment:
          trace_id:

      # Add metadata
      - timestamp:
          source: timestamp
          format: RFC3339

      # Output apenas structured logs
      - output:
          source: message
```

### Loki Queries (LogQL)

```logql
# Buscar erros nos últimos 5 minutos
{namespace="nexo-production", service="nexo-be"}
  |= "level=\"error\""
  | json
  | line_format "{{.timestamp}} [{{.level}}] {{.message}}"

# Trace de uma requisição específica
{namespace="nexo-production"}
  | json
  | trace_id="abc123xyz"
  | line_format "{{.service}} | {{.message}}"

# Erros agrupados por tipo
sum by (error) (
  count_over_time(
    {namespace="nexo-production", level="error"}
    | json
    [5m]
  )
)

# Top 10 usuários com mais erros
topk(10,
  sum by (user_id) (
    count_over_time(
      {namespace="nexo-production", level="error"}
      | json
      [1h]
    )
  )
)
```

---

## 🔍 Tracing: OpenTelemetry + Jaeger

### OpenTelemetry Setup (NestJS)

```typescript
// apps/nexo-be/src/tracing.ts
import { NodeSDK } from "@opentelemetry/sdk-node";
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";
import { JaegerExporter } from "@opentelemetry/exporter-jaeger";
import { Resource } from "@opentelemetry/resources";
import { SemanticResourceAttributes } from "@opentelemetry/semantic-conventions";

const jaegerExporter = new JaegerExporter({
  endpoint:
    process.env.JAEGER_ENDPOINT || "http://jaeger-collector:14268/api/traces",
});

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: "nexo-be",
    [SemanticResourceAttributes.SERVICE_VERSION]:
      process.env.APP_VERSION || "0.0.0",
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]:
      process.env.NODE_ENV || "development",
  }),
  traceExporter: jaegerExporter,
  instrumentations: [
    getNodeAutoInstrumentations({
      "@opentelemetry/instrumentation-http": {
        requestHook: (span, request) => {
          span.setAttribute("http.user_agent", request.headers["user-agent"]);
        },
      },
      "@opentelemetry/instrumentation-express": { enabled: true },
      "@opentelemetry/instrumentation-pg": { enabled: true },
      "@opentelemetry/instrumentation-redis": { enabled: true },
    }),
  ],
});

sdk.start();

// Graceful shutdown
process.on("SIGTERM", () => {
  sdk
    .shutdown()
    .then(() => console.log("Tracing terminated"))
    .catch((error) => console.log("Error terminating tracing", error))
    .finally(() => process.exit(0));
});

export default sdk;
```

```typescript
// apps/nexo-be/src/main.ts
import "./tracing"; // MUST be first import!
import { NestFactory } from "@nestjs/core";
// ... resto do código
```

### Custom Spans

```typescript
// apps/nexo-be/src/users/users.service.ts
import { Injectable } from "@nestjs/common";
import { trace } from "@opentelemetry/api";

@Injectable()
export class UsersService {
  private tracer = trace.getTracer("nexo-be-users-service");

  async createUser(dto: CreateUserDto): Promise<User> {
    // Create custom span
    return await this.tracer.startActiveSpan("users.create", async (span) => {
      try {
        span.setAttribute("user.email", dto.email);
        span.setAttribute("user.plan", dto.plan);

        // Child span: validate
        const isValid = await this.tracer.startActiveSpan(
          "users.validate",
          async (validateSpan) => {
            const result = await this.validateUser(dto);
            validateSpan.setStatus({ code: 1 }); // OK
            validateSpan.end();
            return result;
          },
        );

        if (!isValid) {
          span.setStatus({ code: 2, message: "Validation failed" }); // ERROR
          throw new Error("Invalid user data");
        }

        // Child span: database insert
        const user = await this.tracer.startActiveSpan(
          "users.db.insert",
          async (dbSpan) => {
            dbSpan.setAttribute("db.operation", "INSERT");
            dbSpan.setAttribute("db.table", "users");

            const result = await this.prisma.user.create({ data: dto });

            dbSpan.setStatus({ code: 1 });
            dbSpan.end();
            return result;
          },
        );

        span.setAttribute("user.id", user.id);
        span.setStatus({ code: 1 });
        span.end();

        return user;
      } catch (error) {
        span.setStatus({ code: 2, message: error.message });
        span.recordException(error);
        span.end();
        throw error;
      }
    });
  }
}
```

---

## 📋 Auditoria de Deploy

### Audit Log Structure

```typescript
// GitOps repo: scripts/audit-logger.ts
interface DeploymentAudit {
  event: "deployment" | "rollback" | "promotion";
  timestamp: string;
  service: string;
  version: string;
  from_environment?: string;
  to_environment: string;
  initiator: string;
  approvers: string[];
  pr_url?: string;
  argocd_sync_id?: string;
  argocd_revision?: number;
  success: boolean;
  duration_seconds?: number;
  validation_results?: {
    smoke_tests?: "passed" | "failed";
    health_check?: "passed" | "failed";
    rollback?: "passed" | "failed";
  };
  metadata?: Record<string, any>;
}

async function logDeployment(audit: DeploymentAudit) {
  // 1. Save to database
  await prisma.deploymentAudit.create({ data: audit });

  // 2. Save to S3 (immutable audit trail)
  const key = `audit-logs/${audit.service}/${audit.timestamp.split("T")[0]}/${audit.timestamp}.json`;
  await s3.putObject({
    Bucket: "nexo-audit-logs",
    Key: key,
    Body: JSON.stringify(audit, null, 2),
    ServerSideEncryption: "AES256",
  });

  // 3. Publish to SNS (real-time alerting)
  await sns.publish({
    TopicArn: "arn:aws:sns:us-east-1:123456789012:deployment-events",
    Message: JSON.stringify(audit),
    Subject: `Deployment: ${audit.service} → ${audit.to_environment}`,
  });
}
```

### ArgoCD Event Webhook

```yaml
# argocd/notifications/webhook-audit.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.webhook.audit-logger: |
    url: https://audit-api.nexo.com/api/v1/deployments
    headers:
      - name: Authorization
        value: Bearer $webhook-token

  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [audit-logger]

  template.audit-logger: |
    webhook:
      audit-logger:
        method: POST
        body: |
          {
            "event": "deployment",
            "timestamp": "{{.app.status.operationState.finishedAt}}",
            "service": "{{.app.metadata.labels.service}}",
            "version": "{{.app.status.sync.revision}}",
            "to_environment": "{{.app.metadata.labels.environment}}",
            "argocd_sync_id": "{{.app.status.operationState.syncResult.revision}}",
            "success": true
          }
```

---

## 🎯 DORA Metrics

### Implementação

```typescript
// scripts/calculate-dora-metrics.ts
interface DORAMetrics {
  deployment_frequency: number; // Deploys por dia
  lead_time_for_changes: number; // Minutos: commit → produção
  time_to_restore_service: number; // Minutos: incidente → resolução
  change_failure_rate: number; // % de deploys que requerem rollback
}

async function calculateDORA(
  service: string,
  environment: string,
  startDate: Date,
  endDate: Date,
): Promise<DORAMetrics> {
  // 1. Deployment Frequency
  const deployments = await prisma.deploymentAudit.count({
    where: {
      service,
      to_environment: environment,
      timestamp: { gte: startDate, lte: endDate },
      success: true,
    },
  });

  const days =
    (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24);
  const deployment_frequency = deployments / days;

  // 2. Lead Time for Changes
  const leadTimes = await prisma.$queryRaw`
    SELECT AVG(
      EXTRACT(EPOCH FROM (d.timestamp - c.timestamp)) / 60
    ) as avg_lead_time_minutes
    FROM deployment_audit d
    JOIN git_commits c ON d.version = c.sha
    WHERE d.service = ${service}
      AND d.to_environment = ${environment}
      AND d.timestamp BETWEEN ${startDate} AND ${endDate}
  `;

  const lead_time_for_changes = leadTimes[0].avg_lead_time_minutes;

  // 3. Time to Restore Service
  const incidents = await prisma.incident.findMany({
    where: {
      service,
      environment,
      created_at: { gte: startDate, lte: endDate },
      resolved_at: { not: null },
    },
  });

  const mttr =
    incidents.reduce((acc, inc) => {
      return acc + (inc.resolved_at.getTime() - inc.created_at.getTime());
    }, 0) /
    incidents.length /
    1000 /
    60; // minutos

  const time_to_restore_service = mttr;

  // 4. Change Failure Rate
  const totalDeploys = await prisma.deploymentAudit.count({
    where: {
      service,
      to_environment: environment,
      timestamp: { gte: startDate, lte: endDate },
    },
  });

  const failedDeploys = await prisma.deploymentAudit.count({
    where: {
      service,
      to_environment: environment,
      timestamp: { gte: startDate, lte: endDate },
      OR: [{ success: false }, { event: "rollback" }],
    },
  });

  const change_failure_rate = (failedDeploys / totalDeploys) * 100;

  return {
    deployment_frequency,
    lead_time_for_changes,
    time_to_restore_service,
    change_failure_rate,
  };
}

// DORA Performance Levels
function classifyPerformance(metrics: DORAMetrics): string {
  // Elite performers
  if (
    metrics.deployment_frequency > 1 && // Múltiplos deploys/dia
    metrics.lead_time_for_changes < 60 && // <1h
    metrics.time_to_restore_service < 60 && // <1h
    metrics.change_failure_rate < 5 // <5%
  ) {
    return "Elite";
  }

  // High performers
  if (
    metrics.deployment_frequency >= 1 / 7 && // 1x por semana
    metrics.lead_time_for_changes < 1440 && // <1 dia
    metrics.time_to_restore_service < 1440 && // <1 dia
    metrics.change_failure_rate < 10
  ) {
    return "High";
  }

  // Medium performers
  if (
    metrics.deployment_frequency >= 1 / 30 && // 1x por mês
    metrics.lead_time_for_changes < 10080 && // <1 semana
    metrics.time_to_restore_service < 10080 &&
    metrics.change_failure_rate < 15
  ) {
    return "Medium";
  }

  return "Low";
}
```

---

## 🚨 Incident Management

### Runbooks

````markdown
# Runbook: High Error Rate

## Severity: P1 (Critical)

### Symptoms

- Error rate > 1% for 5+ minutes
- Alert: `NexoBEHighErrorRate` firing

### Investigation Steps

1. **Check recent deployments**

   ```bash
   # Listar últimos deploys
   argocd app history nexo-be-production

   # Ver versão atual
   kubectl get deployment nexo-be -n nexo-production -o jsonpath='{.spec.template.spec.containers[0].image}'
   ```
````

2. **Check logs for errors**

   ```logql
   {namespace="nexo-production", service="nexo-be", level="error"}
   | json
   | line_format "{{.timestamp}} | {{.error}} | {{.trace_id}}"
   ```

3. **Check dependencies**

   ```bash
   # Database connectivity
   kubectl exec -it nexo-be-xxx -n nexo-production -- curl postgres:5432

   # Redis
   kubectl exec -it nexo-be-xxx -n nexo-production -- redis-cli -h redis ping
   ```

### Mitigation

**Option 1: Rollback (fastest)**

```bash
# Via ArgoCD
argocd app rollback nexo-be-production --revision <PREVIOUS_REVISION>

# Via GitOps (mais seguro)
cd nexo-gitops
git revert HEAD
git push
```

**Option 2: Scale down problematic pods**

```bash
kubectl scale deployment nexo-be -n nexo-production --replicas=2
```

### Communication

- Post in #incidents Slack channel
- Update status page: https://status.nexo.com
- Notify stakeholders if customer-facing

### Post-Mortem

- Create GitHub Issue: `incident/YYYY-MM-DD-high-error-rate`
- Schedule blameless post-mortem within 48h
- Update runbook with learnings

````

---

## 📊 Executive Dashboard

```yaml
# Grafana Dashboard: Executive Summary
panels:
  - title: "Deployment Velocity"
    metric: "DORA: Deployment Frequency"
    target: "> 1 per day"
    current: "2.3 per day"
    trend: "↗️ +15% vs last month"

  - title: "Lead Time"
    metric: "Commit to Production"
    target: "< 1 hour"
    current: "45 minutes (p95)"
    trend: "↘️ -10 min vs last month"

  - title: "Service Reliability"
    metric: "SLO Compliance (99.9%)"
    current: "99.95%"
    incidents_last_30d: 2
    mttr: "18 minutes"

  - title: "Security Posture"
    critical_vulns: 0
    high_vulns: 2
    images_signed: "100%"
    last_audit: "7 days ago"
````

---

**Próximo**: [Production Checklist & Best Practices](06-production-checklist.md)
