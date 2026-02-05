# 📊 Observabilidade

Guia completo sobre monitoramento, métricas, logs e alertas usando Prometheus, Grafana e stack de observabilidade.

## 🎯 Stack de Observabilidade

```
┌─────────────────────────────────────────────────┐
│              Aplicações (K3D)                   │
│  nexo-be | nexo-fe | nexo-auth                  │
│         /metrics endpoint                       │
└──────────────────┬──────────────────────────────┘
                   │
         ┌─────────▼──────────┐
         │    Prometheus      │
         │   (Scrape métricas)│
         │   :9090            │
         └─────────┬──────────┘
                   │
         ┌─────────▼──────────┐
         │     Grafana        │
         │  (Visualização)    │
         │   :3000            │
         └─────────┬──────────┘
                   │
         ┌─────────▼──────────┐
         │   Alertmanager     │
         │  (Alertas Discord) │
         │   :9093            │
         └────────────────────┘
```

## 🚀 Setup

### Instalação Automática

```bash
# Já incluso no setup
cd local
make setup

# Instala:
# - Prometheus (kube-prometheus-stack)
# - Grafana
# - Alertmanager
# - Node Exporter
# - Kube State Metrics
```

### Instalação Manual

```bash
# Add repo
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update

# Install
helm install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values local/observability/values.yaml
```

## 🔗 Acessar UIs

### Grafana

```bash
# Via Ingress
open http://grafana.local.nexo.app

# Via Port Forward
kubectl port-forward -n monitoring \
  svc/kube-prometheus-stack-grafana 3000:80

# Credenciais
User: admin
Pass: admin
```

### Prometheus

```bash
# Via Ingress
open http://prometheus.local.nexo.app

# Via Port Forward
kubectl port-forward -n monitoring \
  svc/kube-prometheus-stack-prometheus 9090:9090
```

### Alertmanager

```bash
# Via Ingress
open http://alertmanager.local.nexo.app

# Via Port Forward
kubectl port-forward -n monitoring \
  svc/kube-prometheus-stack-alertmanager 9093:9093
```

## 📊 Métricas

### Exportar Métricas das Aplicações

#### Backend (NestJS)

```typescript
// apps/nexo-be/src/metrics.service.ts
import { Injectable } from "@nestjs/common";
import { register, Counter, Histogram, Gauge } from "prom-client";

@Injectable()
export class MetricsService {
  private httpRequestsTotal: Counter;
  private httpRequestDuration: Histogram;
  private activeConnections: Gauge;

  constructor() {
    // Total de requisições
    this.httpRequestsTotal = new Counter({
      name: "http_requests_total",
      help: "Total de requisições HTTP",
      labelNames: ["method", "route", "status"],
    });

    // Duração de requisições
    this.httpRequestDuration = new Histogram({
      name: "http_request_duration_seconds",
      help: "Duração das requisições HTTP",
      labelNames: ["method", "route", "status"],
      buckets: [0.1, 0.5, 1, 2, 5],
    });

    // Conexões ativas
    this.activeConnections = new Gauge({
      name: "http_active_connections",
      help: "Número de conexões ativas",
    });
  }

  recordRequest(
    method: string,
    route: string,
    status: number,
    duration: number,
  ) {
    this.httpRequestsTotal.inc({ method, route, status });
    this.httpRequestDuration.observe({ method, route, status }, duration);
  }

  incrementActiveConnections() {
    this.activeConnections.inc();
  }

  decrementActiveConnections() {
    this.activeConnections.dec();
  }

  getMetrics() {
    return register.metrics();
  }
}

// apps/nexo-be/src/metrics.controller.ts
import { Controller, Get, Header } from "@nestjs/common";
import { MetricsService } from "./metrics.service";

@Controller("metrics")
export class MetricsController {
  constructor(private metricsService: MetricsService) {}

  @Get()
  @Header("Content-Type", "text/plain")
  async getMetrics() {
    return this.metricsService.getMetrics();
  }
}
```

### ServiceMonitor

```yaml
# local/helm/nexo-be/templates/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: { { include "nexo-be.fullname" . } }
  labels: { { - include "nexo-be.labels" . | nindent 4 } }
spec:
  selector:
    matchLabels: { { - include "nexo-be.selectorLabels" . | nindent 6 } }
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
      scrapeTimeout: 10s
```

### Métricas Disponíveis

#### Sistema (Node Exporter)

```promql
# CPU
node_cpu_seconds_total

# Memória
node_memory_MemAvailable_bytes
node_memory_MemTotal_bytes

# Disco
node_filesystem_avail_bytes
node_filesystem_size_bytes

# Network
node_network_receive_bytes_total
node_network_transmit_bytes_total
```

#### Kubernetes (Kube State Metrics)

```promql
# Pods
kube_pod_status_phase{namespace="nexo-develop"}
kube_pod_container_status_restarts_total

# Deployments
kube_deployment_status_replicas_available
kube_deployment_status_replicas_unavailable

# Nodes
kube_node_status_condition
```

#### Aplicação (Custom)

```promql
# Requisições HTTP
http_requests_total{namespace="nexo-develop",app="nexo-be"}

# Latência
http_request_duration_seconds{quantile="0.95"}

# Erros
rate(http_requests_total{status=~"5.."}[5m])

# Conexões
http_active_connections

# Database
db_query_duration_seconds
db_connections_active
```

## 📈 Queries Prometheus Úteis

### Performance

```promql
# Request rate (req/s)
rate(http_requests_total{namespace="nexo-develop"}[5m])

# Latência p95
histogram_quantile(0.95,
  rate(http_request_duration_seconds_bucket[5m])
)

# Error rate (%)
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
* 100

# Throughput
sum(rate(http_requests_total[5m])) by (app)
```

### Recursos

```promql
# CPU usage (%)
sum(rate(container_cpu_usage_seconds_total{namespace="nexo-develop"}[5m])) by (pod)
/
sum(container_spec_cpu_quota{namespace="nexo-develop"} / container_spec_cpu_period{namespace="nexo-develop"}) by (pod)
* 100

# Memory usage (%)
sum(container_memory_usage_bytes{namespace="nexo-develop"}) by (pod)
/
sum(container_spec_memory_limit_bytes{namespace="nexo-develop"}) by (pod)
* 100

# Disk usage
(node_filesystem_size_bytes - node_filesystem_avail_bytes)
/
node_filesystem_size_bytes
* 100
```

### Availability

```promql
# Pods running
kube_pod_status_phase{namespace="nexo-develop",phase="Running"}

# Pod restarts
sum(increase(kube_pod_container_status_restarts_total{namespace="nexo-develop"}[1h])) by (pod)

# Uptime
(time() - process_start_time_seconds) / 86400
```

## 📊 Dashboards Grafana

### Dashboard Principal

```json
{
  "title": "Nexo - Overview",
  "panels": [
    {
      "title": "Request Rate",
      "targets": [
        {
          "expr": "sum(rate(http_requests_total{namespace=~\"nexo-.*\"}[5m])) by (namespace)"
        }
      ]
    },
    {
      "title": "Error Rate",
      "targets": [
        {
          "expr": "sum(rate(http_requests_total{namespace=~\"nexo-.*\",status=~\"5..\"}[5m])) / sum(rate(http_requests_total{namespace=~\"nexo-.*\"}[5m])) * 100"
        }
      ]
    },
    {
      "title": "Latency p95",
      "targets": [
        {
          "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace=~\"nexo-.*\"}[5m]))"
        }
      ]
    },
    {
      "title": "Active Pods",
      "targets": [
        {
          "expr": "count(kube_pod_status_phase{namespace=~\"nexo-.*\",phase=\"Running\"}) by (namespace)"
        }
      ]
    }
  ]
}
```

### Importar Dashboards Prontos

```bash
# Kubernetes Cluster Monitoring
ID: 7249

# Node Exporter Full
ID: 1860

# ArgoCD
ID: 14584

# NGINX Ingress
ID: 9614
```

### Criar Dashboard Custom

```bash
# 1. Acessar Grafana
open http://grafana.local.nexo.app

# 2. Dashboards → New → New Dashboard

# 3. Add panel → Query
# - Data source: Prometheus
# - Query: sum(rate(http_requests_total[5m])) by (app)

# 4. Panel settings
# - Title: Request Rate
# - Unit: req/s
# - Legend: {{ app }}

# 5. Save dashboard
```

## 🚨 Alertas

### Configurar Alertmanager

```yaml
# local/observability/alertmanager-config.yaml
global:
  resolve_timeout: 5m

route:
  group_by: ["alertname", "namespace"]
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: "discord"

receivers:
  - name: "discord"
    webhook_configs:
      - url: "https://discord.com/api/webhooks/..."
        send_resolved: true

inhibit_rules:
  - source_match:
      severity: "critical"
    target_match:
      severity: "warning"
    equal: ["alertname", "namespace"]
```

### Regras de Alerta

```yaml
# local/observability/prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: nexo-alerts
  namespace: monitoring
spec:
  groups:
    - name: availability
      interval: 30s
      rules:
        - alert: PodDown
          expr: kube_pod_status_phase{namespace=~"nexo-.*",phase!="Running"} > 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Pod {{ $labels.pod }} não está rodando"
            description: "Pod em namespace {{ $labels.namespace }} está em fase {{ $labels.phase }} por mais de 5 minutos"

        - alert: HighRestartRate
          expr: increase(kube_pod_container_status_restarts_total{namespace=~"nexo-.*"}[1h]) > 3
          labels:
            severity: warning
          annotations:
            summary: "Pod {{ $labels.pod }} com muitos restarts"
            description: "{{ $value }} restarts na última hora"

    - name: performance
      interval: 30s
      rules:
        - alert: HighErrorRate
          expr: |
            sum(rate(http_requests_total{namespace=~"nexo-.*",status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total{namespace=~"nexo-.*"}[5m]))
            > 0.05
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Alta taxa de erros"
            description: "{{ $value | humanizePercentage }} de erros nos últimos 5 minutos"

        - alert: HighLatency
          expr: |
            histogram_quantile(0.95,
              rate(http_request_duration_seconds_bucket{namespace=~"nexo-.*"}[5m])
            ) > 2
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "Alta latência detectada"
            description: "P95 latency é {{ $value }}s"

    - name: resources
      interval: 30s
      rules:
        - alert: HighCPUUsage
          expr: |
            sum(rate(container_cpu_usage_seconds_total{namespace=~"nexo-.*"}[5m])) by (pod)
            /
            sum(container_spec_cpu_quota{namespace=~"nexo-.*"} / container_spec_cpu_period{namespace=~"nexo-.*"}) by (pod)
            > 0.8
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "Alto uso de CPU em {{ $labels.pod }}"
            description: "CPU usage é {{ $value | humanizePercentage }}"

        - alert: HighMemoryUsage
          expr: |
            sum(container_memory_usage_bytes{namespace=~"nexo-.*"}) by (pod)
            /
            sum(container_spec_memory_limit_bytes{namespace=~"nexo-.*"}) by (pod)
            > 0.9
          for: 10m
          labels:
            severity: critical
          annotations:
            summary: "Alto uso de memória em {{ $labels.pod }}"
            description: "Memory usage é {{ $value | humanizePercentage }}"

    - name: database
      interval: 30s
      rules:
        - alert: SlowQueries
          expr: db_query_duration_seconds{quantile="0.95"} > 1
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Queries lentas detectadas"
            description: "P95 query duration é {{ $value }}s"

        - alert: HighConnectionPool
          expr: db_connections_active / db_connections_max > 0.8
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Connection pool quase cheio"
            description: "{{ $value | humanizePercentage }} de conexões em uso"
```

### Testar Alertas

```bash
# Forçar alerta (scale to 0)
kubectl scale deployment nexo-be-develop --replicas=0 -n nexo-develop

# Verificar no Alertmanager
open http://alertmanager.local.nexo.app

# Verificar Discord
# Deve receber notificação em ~1 minuto

# Restaurar
kubectl scale deployment nexo-be-develop --replicas=1 -n nexo-develop
```

## 📝 Logs (Futuro: Loki)

### Instalar Loki Stack

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=10Gi
```

### Query Logs no Grafana

```logql
# Logs de um namespace
{namespace="nexo-develop"}

# Logs de uma app
{namespace="nexo-develop", app="nexo-be"}

# Logs com erro
{namespace="nexo-develop"} |= "error"

# Logs de um pod específico
{pod="nexo-be-abc123-xyz"}

# Aggregations
sum by (app) (
  rate({namespace="nexo-develop"} |= "error" [5m])
)
```

## 🔍 Tracing (Futuro: Jaeger/Tempo)

### Instrumentação

```typescript
// apps/nexo-be/src/tracing.ts
import { NodeSDK } from "@opentelemetry/sdk-node";
import { HttpInstrumentation } from "@opentelemetry/instrumentation-http";
import { JaegerExporter } from "@opentelemetry/exporter-jaeger";

const sdk = new NodeSDK({
  traceExporter: new JaegerExporter({
    endpoint: "http://jaeger-collector:14268/api/traces",
  }),
  instrumentations: [new HttpInstrumentation()],
});

sdk.start();
```

## 📊 SLIs e SLOs

### Service Level Indicators

```yaml
SLIs:
  - Availability: % de tempo que serviço está disponível
  - Latency: % de requests < 200ms
  - Error Rate: % de requests com erro
  - Throughput: Requests por segundo
```

### Service Level Objectives

```yaml
SLOs:
  # Availability
  - metric: availability
    target: 99.9%
    window: 30d

  # Latency
  - metric: latency_p95
    target: 200ms
    window: 7d

  # Error Rate
  - metric: error_rate
    target: 1%
    window: 1d

  # Throughput
  - metric: throughput
    target: 100 req/s
    window: 1h
```

### Recording Rules

```yaml
# local/observability/recording-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: nexo-slo-rules
  namespace: monitoring
spec:
  groups:
    - name: slo
      interval: 30s
      rules:
        # Availability SLI
        - record: sli:availability:ratio_rate5m
          expr: |
            sum(rate(http_requests_total{namespace=~"nexo-prod",status!~"5.."}[5m]))
            /
            sum(rate(http_requests_total{namespace=~"nexo-prod"}[5m]))

        # Latency SLI
        - record: sli:latency:ratio_rate5m
          expr: |
            histogram_quantile(0.95,
              rate(http_request_duration_seconds_bucket{namespace=~"nexo-prod"}[5m])
            ) < 0.2

        # Error Budget (30d)
        - record: slo:error_budget:30d
          expr: |
            1 - (
              (1 - sli:availability:ratio_rate5m)
              /
              (1 - 0.999)
            )
```

## 💡 Boas Práticas

### 1. Nomenclatura de Métricas

```
<namespace>_<subsystem>_<name>_<unit>

Exemplos:
- http_requests_total
- http_request_duration_seconds
- db_query_duration_seconds
- cache_hits_total
```

### 2. Labels Importantes

```promql
# Sempre incluir
- namespace
- app
- pod
- method
- route
- status

# Evitar
- user_id (alta cardinalidade)
- request_id (alta cardinalidade)
```

### 3. Alertas Acionáveis

```yaml
# ❌ Ruim
Alert: HighCPU
Desc: CPU alto

# ✅ Bom
Alert: HighCPUUsage
Desc: "CPU usage é {{ $value }}% em {{ $labels.pod }}"
Runbook: "https://docs.nexo.com/runbooks/high-cpu"
```

### 4. Dashboard por Audiência

```
- DevOps: Infra, K8s, resources
- Developers: Aplicação, APIs, erros
- Business: Users, conversões, revenue
```

## 🛠️ Troubleshooting

### Prometheus não scraping

```bash
# Ver targets
open http://prometheus.local.nexo.app/targets

# Ver service monitors
kubectl get servicemonitors -A

# Ver logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus -f
```

### Alertas não disparando

```bash
# Ver regras
open http://prometheus.local.nexo.app/rules

# Ver alertas ativos
open http://prometheus.local.nexo.app/alerts

# Testar regra
# Prometheus → Graph → PromQL query
```

### Grafana sem dados

```bash
# Verificar data source
# Grafana → Configuration → Data Sources → Prometheus
# Test → Should see "Data source is working"

# Verificar queries
# Panel → Edit → Query → Run query
```

## 📚 Recursos

- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [SRE Book](https://sre.google/books/)

---

[← Ambientes](./09-environments.md) | [Voltar](./README.md) | [Próximo: Troubleshooting →](./11-troubleshooting.md)
