# 🌐 APIs e Serviços

Documentação completa das APIs, endpoints e serviços do projeto Nexo.

## 🎯 Arquitetura de Serviços

```
┌─────────────────────────────────────────────────┐
│                   Cliente                       │
│            (Browser / Mobile App)               │
└──────────────────┬──────────────────────────────┘
                   │
        ┌──────────▼───────────┐
        │   NGINX Ingress      │
        │   (Load Balancer)    │
        └──┬─────────────┬────┘
           │             │
    ┌──────▼─────┐  ┌───▼────────┐
    │  nexo-fe   │  │  nexo-be   │
    │ (Next.js)  │  │ (NestJS)   │
    │  Port 3000 │  │  Port 3333 │
    └──────┬─────┘  └───┬────────┘
           │            │
           │      ┌─────▼────────┐
           │      │  PostgreSQL  │
           │      │   (Prisma)   │
           │      └──────────────┘
           │
     ┌─────▼──────┐
     │ nexo-auth  │
     │ (Keycloak) │
     │  Port 8080 │
     └────────────┘
```

## 📡 nexo-be (Backend API)

**Stack:** NestJS + Prisma + PostgreSQL  
**Porta:** 3333  
**Base URL:** `http://api.nexo.local`

### Health & Metrics

#### GET /health

Status da aplicação

**Request:**

```bash
curl http://api.nexo.local/health
```

**Response:**

```json
{
  "status": "ok",
  "info": {
    "database": {
      "status": "up"
    },
    "memory_heap": {
      "status": "up"
    }
  },
  "error": {},
  "details": {
    "database": {
      "status": "up"
    },
    "memory_heap": {
      "status": "up",
      "used": 50000000,
      "total": 100000000
    }
  }
}
```

#### GET /metrics

Métricas Prometheus

**Request:**

```bash
curl http://api.nexo.local/metrics
```

**Response:**

```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/health",status="200"} 42

# HELP http_request_duration_seconds HTTP request duration
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.1"} 35
```

### API Endpoints (v1)

Base: `/api/v1`

#### Users

##### GET /api/v1/users

Lista todos os usuários

**Headers:**

```
Authorization: Bearer <token>
```

**Query Params:**

- `page` (number) - Página (default: 1)
- `limit` (number) - Items por página (default: 10)
- `search` (string) - Busca por nome/email

**Request:**

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://api.nexo.local/api/v1/users?page=1&limit=10&search=john"
```

**Response:**

```json
{
  "data": [
    {
      "id": "uuid-123",
      "email": "john@example.com",
      "name": "John Doe",
      "role": "user",
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 10,
    "total": 42,
    "totalPages": 5
  }
}
```

##### GET /api/v1/users/:id

Busca usuário por ID

**Request:**

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://api.nexo.local/api/v1/users/uuid-123
```

**Response:**

```json
{
  "id": "uuid-123",
  "email": "john@example.com",
  "name": "John Doe",
  "role": "user",
  "profile": {
    "avatar": "https://...",
    "bio": "Developer"
  },
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

##### POST /api/v1/users

Cria novo usuário

**Request:**

```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "jane@example.com",
    "name": "Jane Doe",
    "password": "SecurePass123!"
  }' \
  http://api.nexo.local/api/v1/users
```

**Response:**

```json
{
  "id": "uuid-456",
  "email": "jane@example.com",
  "name": "Jane Doe",
  "role": "user",
  "createdAt": "2024-01-15T11:00:00Z"
}
```

##### PATCH /api/v1/users/:id

Atualiza usuário

**Request:**

```bash
curl -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Smith",
    "profile": {
      "bio": "Full Stack Developer"
    }
  }' \
  http://api.nexo.local/api/v1/users/uuid-456
```

**Response:**

```json
{
  "id": "uuid-456",
  "email": "jane@example.com",
  "name": "Jane Smith",
  "profile": {
    "bio": "Full Stack Developer"
  },
  "updatedAt": "2024-01-15T12:00:00Z"
}
```

##### DELETE /api/v1/users/:id

Remove usuário

**Request:**

```bash
curl -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  http://api.nexo.local/api/v1/users/uuid-456
```

**Response:**

```
204 No Content
```

#### Auth

##### POST /api/v1/auth/login

Login com email/senha

**Request:**

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass123!"
  }' \
  http://api.nexo.local/api/v1/auth/login
```

**Response:**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600,
  "user": {
    "id": "uuid-123",
    "email": "john@example.com",
    "name": "John Doe",
    "role": "user"
  }
}
```

##### POST /api/v1/auth/refresh

Renova access token

**Request:**

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }' \
  http://api.nexo.local/api/v1/auth/refresh
```

**Response:**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600
}
```

##### POST /api/v1/auth/logout

Logout (invalida tokens)

**Request:**

```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  http://api.nexo.local/api/v1/auth/logout
```

**Response:**

```json
{
  "message": "Logout successful"
}
```

### Error Responses

Todas as APIs retornam erros no formato padrão:

```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "error": "Bad Request",
  "details": [
    {
      "field": "email",
      "message": "Email must be valid"
    }
  ]
}
```

**Status Codes:**

- `200` - OK
- `201` - Created
- `204` - No Content
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `409` - Conflict
- `422` - Unprocessable Entity
- `500` - Internal Server Error

## 🖥️ nexo-fe (Frontend)

**Stack:** Next.js 14 + React + TypeScript  
**Porta:** 3000  
**Base URL:** `http://nexo.local`

### Pages

#### / (Home)

Landing page

#### /dashboard

Dashboard principal (auth required)

#### /login

Página de login

#### /register

Página de registro

#### /users

Lista de usuários (auth + role admin required)

### API Routes

#### GET /api/health

Health check do frontend

**Response:**

```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Environment Variables

```bash
# .env.local
NEXT_PUBLIC_API_URL=http://api.nexo.local
NEXT_PUBLIC_AUTH_URL=http://auth.nexo.local
NEXT_PUBLIC_WS_URL=ws://api.nexo.local
```

## 🔐 nexo-auth (Authentication)

**Stack:** Keycloak 23  
**Porta:** 8080  
**Base URL:** `http://auth.nexo.local`

### Admin Console

```
URL: http://auth.nexo.local/admin
User: admin
Pass: admin
```

### Realms

#### nexo (Realm principal)

**Clients:**

- `nexo-fe` - Frontend (public client)
- `nexo-be` - Backend (confidential client)

**Roles:**

- `admin` - Administrador
- `user` - Usuário comum
- `moderator` - Moderador

### OAuth2 / OpenID Connect

#### Authorization Code Flow

1. **Authorize:**

```
GET http://auth.nexo.local/realms/nexo/protocol/openid-connect/auth
  ?client_id=nexo-fe
  &redirect_uri=http://nexo.local/callback
  &response_type=code
  &scope=openid profile email
```

2. **Token Exchange:**

```bash
curl -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=AUTH_CODE" \
  -d "client_id=nexo-fe" \
  -d "client_secret=SECRET" \
  -d "redirect_uri=http://nexo.local/callback" \
  http://auth.nexo.local/realms/nexo/protocol/openid-connect/token
```

**Response:**

```json
{
  "access_token": "eyJhbGc...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "refresh_token": "eyJhbGc...",
  "token_type": "Bearer",
  "id_token": "eyJhbGc...",
  "scope": "openid profile email"
}
```

#### Client Credentials Flow

```bash
curl -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=nexo-be" \
  -d "client_secret=SECRET" \
  http://auth.nexo.local/realms/nexo/protocol/openid-connect/token
```

### User Info

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://auth.nexo.local/realms/nexo/protocol/openid-connect/userinfo
```

**Response:**

```json
{
  "sub": "uuid-123",
  "email": "john@example.com",
  "email_verified": true,
  "name": "John Doe",
  "preferred_username": "john",
  "given_name": "John",
  "family_name": "Doe",
  "roles": ["user"]
}
```

## 🔌 Integrações

### PostgreSQL

**Conexão:**

```
Host: postgres.nexo-develop.svc.cluster.local
Port: 5432
Database: nexo
User: nexo
Password: [via secret]
```

**Connection String:**

```
DATABASE_URL="postgresql://nexo:password@postgres:5432/nexo?schema=public"
```

### Prisma

**Schema:**

```prisma
// schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(uuid())
  email     String   @unique
  name      String
  password  String
  role      Role     @default(USER)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("users")
}

enum Role {
  USER
  ADMIN
  MODERATOR
}
```

**Comandos:**

```bash
# Generate client
pnpm prisma generate

# Run migrations
pnpm prisma migrate dev

# Open studio
pnpm prisma studio
```

## 📊 Monitoramento de APIs

### Prometheus Metrics

```bash
# Requisições por endpoint
http_requests_total{method="GET", route="/api/v1/users", status="200"}

# Latência
http_request_duration_seconds{route="/api/v1/users", quantile="0.95"}

# Erros
http_requests_total{status=~"5.."}

# Active connections
http_active_connections

# Database queries
db_query_duration_seconds
db_connections_active
db_connections_idle
```

### Grafana Dashboards

1. **API Overview**
   - Request rate
   - Error rate
   - Latency (p50, p95, p99)

2. **Database**
   - Query duration
   - Connection pool
   - Slow queries

3. **Business Metrics**
   - User registrations
   - Login attempts
   - API usage per client

## 🧪 Testes de API

### Curl

```bash
# Health check
curl http://api.nexo.local/health

# Com autenticação
export TOKEN="eyJhbGc..."
curl -H "Authorization: Bearer $TOKEN" \
  http://api.nexo.local/api/v1/users

# POST com JSON
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}' \
  http://api.nexo.local/api/v1/users
```

### HTTPie

```bash
# Instalar
brew install httpie

# GET
http http://api.nexo.local/api/v1/users \
  Authorization:"Bearer $TOKEN"

# POST
http POST http://api.nexo.local/api/v1/users \
  Authorization:"Bearer $TOKEN" \
  name="Test User" \
  email="test@example.com"
```

### Postman

Importar collection:

```json
{
  "info": {
    "name": "Nexo API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Health",
      "request": {
        "method": "GET",
        "url": "{{API_URL}}/health"
      }
    },
    {
      "name": "List Users",
      "request": {
        "method": "GET",
        "url": "{{API_URL}}/api/v1/users",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{TOKEN}}"
          }
        ]
      }
    }
  ]
}
```

### K6 (Load Testing)

```javascript
// load-test.js
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "30s", target: 20 },
    { duration: "1m", target: 20 },
    { duration: "30s", target: 0 },
  ],
};

export default function () {
  const res = http.get("http://api.nexo.local/health");

  check(res, {
    "status is 200": (r) => r.status === 200,
    "response time < 200ms": (r) => r.timings.duration < 200,
  });

  sleep(1);
}
```

```bash
# Executar
k6 run load-test.js
```

## 🔒 Segurança

### Rate Limiting

```typescript
// Backend
@UseGuards(ThrottlerGuard)
@Throttle(10, 60) // 10 requests por minuto
@Get('users')
async findAll() {
  // ...
}
```

### CORS

```typescript
// main.ts
app.enableCors({
  origin: ["http://nexo.local", "http://nexo-dev.local"],
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE"],
});
```

### API Keys (Future)

```bash
# Header
X-API-Key: sk_live_...

# Query param
?api_key=sk_live_...
```

## 📝 OpenAPI / Swagger

### Geração Automática

```typescript
// Backend
import { SwaggerModule, DocumentBuilder } from "@nestjs/swagger";

const config = new DocumentBuilder()
  .setTitle("Nexo API")
  .setDescription("API documentation")
  .setVersion("1.0")
  .addBearerAuth()
  .build();

const document = SwaggerModule.createDocument(app, config);
SwaggerModule.setup("docs", app, document);
```

### Acessar Docs

```
http://api.nexo.local/docs
```

## 📚 SDK / Client Libraries

### TypeScript/JavaScript

```typescript
// nexo-client.ts
import axios from "axios";

export class NexoClient {
  private api = axios.create({
    baseURL: "http://api.nexo.local",
  });

  setAuth(token: string) {
    this.api.defaults.headers.common["Authorization"] = `Bearer ${token}`;
  }

  async getUsers() {
    const { data } = await this.api.get("/api/v1/users");
    return data;
  }

  async createUser(user: CreateUserDto) {
    const { data } = await this.api.post("/api/v1/users", user);
    return data;
  }
}

// Uso
const client = new NexoClient();
client.setAuth(token);
const users = await client.getUsers();
```

## 💡 Boas Práticas

1. **Sempre use HTTPS em produção**
2. **Valide entrada em todos os endpoints**
3. **Use rate limiting**
4. **Log de requisições (sem dados sensíveis)**
5. **Implemente circuit breakers**
6. **Cache de respostas frequentes**
7. **Timeout em requisições**
8. **Retry com backoff exponencial**
9. **Health checks em dependências**
10. **Monitoramento e alertas**

---

[← Git Workflow](./05-git-workflow.md) | [Voltar](./README.md) | [Próximo: CI/CD Pipeline →](./07-cicd-pipeline.md)
