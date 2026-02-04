import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

// Contadores de métricas
let httpRequestsTotal = 0;
let httpRequestDurationSeconds = 0;
const httpRequestsByStatus: Record<number, number> = {};

export async function GET(request: NextRequest) {
  const startTime = Date.now();

  // Coletar informações básicas
  const uptime = process.uptime();
  const memoryUsage = process.memoryUsage();

  // Atualizar contadores
  httpRequestsTotal++;
  
  // Gerar métricas no formato Prometheus
  const metrics = `# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",handler="/api/metrics"} ${httpRequestsTotal}

# HELP http_request_duration_seconds HTTP request duration in seconds
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_sum ${httpRequestDurationSeconds}
http_request_duration_seconds_count ${httpRequestsTotal}

# HELP process_uptime_seconds Process uptime in seconds
# TYPE process_uptime_seconds gauge
process_uptime_seconds ${uptime.toFixed(2)}

# HELP process_resident_memory_bytes Process resident memory in bytes
# TYPE process_resident_memory_bytes gauge
process_resident_memory_bytes ${memoryUsage.rss}

# HELP process_heap_bytes Process heap memory in bytes
# TYPE process_heap_bytes gauge
process_heap_bytes{type="used"} ${memoryUsage.heapUsed}
process_heap_bytes{type="total"} ${memoryUsage.heapTotal}

# HELP nodejs_version_info Node.js version info
# TYPE nodejs_version_info gauge
nodejs_version_info{version="${process.version}"} 1

# HELP nextjs_app_info Next.js application info
# TYPE nextjs_app_info gauge
nextjs_app_info{app="nexo-fe",environment="${process.env.NODE_ENV || 'development'}"} 1
`;

  // Atualizar duração
  const duration = (Date.now() - startTime) / 1000;
  httpRequestDurationSeconds += duration;

  return new NextResponse(metrics, {
    headers: {
      'Content-Type': 'text/plain; version=0.0.4; charset=utf-8',
    },
  });
}
