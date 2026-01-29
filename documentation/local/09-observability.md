# 09 - Observability

Métricas, logs e monitoramento.

---

## 📊 Stack de Observabilidade

| Ferramenta     | Função            | URL                    |
| -------------- | ----------------- | ---------------------- |
| **Prometheus** | Métricas          | http://localhost:30090 |
| **Grafana**    | Dashboards        | http://localhost:30030 |
| **Loki**       | Agregação de logs | (via Grafana)          |
| **Promtail**   | Coleta de logs    | (daemon)               |

---

## 📈 Prometheus

### Acessar

```bash
open http://localhost:30090
```

### Queries Úteis

```promql
# CPU por namespace
sum(rate(container_cpu_usage_seconds_total{namespace="nexo-develop"}[5m])) by (pod)

# Memória por pod
container_memory_usage_bytes{namespace="nexo-develop"}

# Requisições HTTP por status
sum(rate(http_requests_total{namespace="nexo-develop"}[5m])) by (status)

# Latência P95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace="nexo-develop"}[5m]))

# Pods em CrashLoopBackOff
kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"}

# Pods não Ready
kube_pod_status_ready{condition="false"}
```

### Targets

Acesse **Status → Targets** para ver quais endpoints estão sendo monitorados.

---

## 📉 Grafana

### Acessar

```bash
open http://localhost:30030
```

**Credenciais:** admin / admin123

### Dashboards Disponíveis

| Dashboard       | Descrição                          |
| --------------- | ---------------------------------- |
| Kubernetes Pods | CPU, memória, restart por pod      |
| Node Exporter   | Métricas do host (CPU, RAM, disco) |
| Traefik         | Requisições, latência, erros       |
| PostgreSQL      | Conexões, queries, cache           |
| Application     | Métricas customizadas da aplicação |

### Criar Dashboard

1. **+ → Create Dashboard**
2. **Add visualization**
3. Selecionar data source (Prometheus)
4. Escrever query
5. Configurar visualização
6. Save

### Importar Dashboard

1. **+ → Import dashboard**
2. Colar JSON ou ID do Grafana.com
3. IDs úteis:
   - 315 (Kubernetes Pods)
   - 1860 (Node Exporter)
   - 12740 (K8s All-in-One)

---

## 📝 Loki (Logs)

### Acessar via Grafana

1. Abrir Grafana (http://localhost:30030)
2. **Explore** (ícone de bússola)
3. Data source: **Loki**

### Queries LogQL

```logql
# Todos os logs de um namespace
{namespace="nexo-develop"}

# Logs de um pod específico
{namespace="nexo-develop", pod="nexo-be-xxx"}

# Logs de um container
{namespace="nexo-develop", container="nexo-be"}

# Filtrar por texto
{namespace="nexo-develop"} |= "error"

# Regex
{namespace="nexo-develop"} |~ "error|warn"

# Excluir pattern
{namespace="nexo-develop"} != "healthcheck"

# JSON parsing
{namespace="nexo-develop"} | json | level="error"

# Contar erros por minuto
count_over_time({namespace="nexo-develop"} |= "error" [1m])
```

---

## 🚨 Alertas

### Configurar Alertas no Grafana

1. Ir no Dashboard
2. Editar painel
3. Aba **Alert**
4. **Create Alert Rule**
5. Configurar condições
6. Definir notificações

### Exemplo de Alerta

**CPU Alta:**

```yaml
# Quando CPU > 80% por 5 minutos
- alert: HighCPU
  expr: |
    (sum(rate(container_cpu_usage_seconds_total{namespace="nexo-develop"}[5m])) 
    / sum(kube_pod_container_resource_limits{resource="cpu",namespace="nexo-develop"})) > 0.8
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High CPU usage in nexo-develop"
```

**Pod CrashLoop:**

```yaml
- alert: PodCrashLooping
  expr: rate(kube_pod_container_status_restarts_total{namespace=~"nexo-.*"}[10m]) > 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Pod {{ $labels.pod }} is crash looping"
```

---

## 🔍 Métricas da Aplicação

### Backend (NestJS)

O backend expõe métricas em `/metrics`:

```bash
curl http://develop.api.nexo.local/metrics
```

**Métricas disponíveis:**

| Métrica                         | Tipo      | Descrição               |
| ------------------------------- | --------- | ----------------------- |
| `http_requests_total`           | Counter   | Total de requisições    |
| `http_request_duration_seconds` | Histogram | Duração das requisições |
| `nodejs_heap_size_total_bytes`  | Gauge     | Memória heap Node.js    |
| `prisma_pool_connections`       | Gauge     | Conexões do pool Prisma |

### Adicionar Métrica Custom

```typescript
// apps/nexo-be/src/metrics.service.ts
import { Injectable } from "@nestjs/common";
import { Counter, Histogram } from "prom-client";

@Injectable()
export class MetricsService {
  private ordersCounter: Counter;

  constructor() {
    this.ordersCounter = new Counter({
      name: "orders_created_total",
      help: "Total orders created",
      labelNames: ["status"],
    });
  }

  incrementOrders(status: string) {
    this.ordersCounter.inc({ status });
  }
}
```

---

## 📋 Logs Estruturados

### Backend (NestJS)

```typescript
// Usar logger estruturado
import { Logger } from "@nestjs/common";

@Injectable()
export class UserService {
  private readonly logger = new Logger(UserService.name);

  async createUser(data: CreateUserDto) {
    this.logger.log({
      message: "Creating user",
      email: data.email,
      timestamp: new Date().toISOString(),
    });

    try {
      const user = await this.prisma.user.create({ data });
      this.logger.log({
        message: "User created",
        userId: user.id,
      });
      return user;
    } catch (error) {
      this.logger.error({
        message: "Failed to create user",
        error: error.message,
        stack: error.stack,
      });
      throw error;
    }
  }
}
```

---

## 📊 Dashboards Customizados

### Criar Dashboard para Nexo

```json
{
  "title": "Nexo Application",
  "panels": [
    {
      "title": "Request Rate",
      "type": "graph",
      "targets": [
        {
          "expr": "sum(rate(http_requests_total{namespace='nexo-develop'}[5m])) by (path)"
        }
      ]
    },
    {
      "title": "Error Rate",
      "type": "stat",
      "targets": [
        {
          "expr": "sum(rate(http_requests_total{namespace='nexo-develop',status=~'5..'}[5m]))"
        }
      ]
    },
    {
      "title": "P95 Latency",
      "type": "gauge",
      "targets": [
        {
          "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))"
        }
      ]
    }
  ]
}
```

### Aplicar Dashboard

```bash
cd local
./scripts/apply-dashboards.sh
```

---

## 🔧 Troubleshooting Observabilidade

### Prometheus não coleta métricas

```bash
# Verificar ServiceMonitor
kubectl get servicemonitor -A

# Verificar se endpoint está acessível
kubectl port-forward svc/nexo-be 3333:3333 -n nexo-develop
curl http://localhost:3333/metrics
```

### Loki não mostra logs

```bash
# Verificar Promtail
kubectl get pods -n monitoring -l app=promtail

# Ver logs do Promtail
kubectl logs -n monitoring -l app=promtail

# Verificar se está coletando
kubectl logs -n monitoring -l app=promtail | grep nexo
```

### Grafana não conecta

```bash
# Verificar pod
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Verificar datasources
kubectl exec -n monitoring deploy/grafana -- grafana-cli plugins ls
```

---

## 🔗 Links Rápidos

| Serviço            | URL                            | Uso                  |
| ------------------ | ------------------------------ | -------------------- |
| Prometheus         | http://localhost:30090         | Queries              |
| Prometheus Targets | http://localhost:30090/targets | Status de coleta     |
| Grafana            | http://localhost:30030         | Dashboards           |
| Grafana Explore    | http://localhost:30030/explore | Logs/Métricas ad-hoc |

---

## ➡️ Próximos Passos

- [10-troubleshooting.md](10-troubleshooting.md) - Resolução de problemas
- [07-development.md](07-development.md) - Voltar ao desenvolvimento
