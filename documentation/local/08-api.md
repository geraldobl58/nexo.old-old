# 08 - API

Documentação da API do Backend.

---

## 🌐 Base URLs

| Ambiente    | URL                           |
| ----------- | ----------------------------- |
| Local (dev) | http://localhost:3333         |
| Develop     | http://develop.api.nexo.local |
| QA          | http://qa.api.nexo.local      |
| Staging     | http://staging.api.nexo.local |
| Prod        | http://prod.api.nexo.local    |

---

## 📖 Swagger/OpenAPI

Documentação interativa disponível em:

```
{BASE_URL}/api
```

Exemplos:

- http://localhost:3333/api
- http://develop.api.nexo.local/api

---

## 🔐 Autenticação

A API usa autenticação via Keycloak (OpenID Connect).

### Obter Token

```bash
# Request
POST {KEYCLOAK_URL}/realms/nexo/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=password
client_id=nexo-app
username={email}
password={senha}
```

```bash
# Exemplo com cURL
curl -X POST "http://develop.auth.nexo.local/realms/nexo/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=nexo-app" \
  -d "username=user@example.com" \
  -d "password=senha123"
```

### Response

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer"
}
```

### Usar Token

```bash
# Em todas as requisições autenticadas
Authorization: Bearer {access_token}
```

---

## 🏥 Health Check

### GET /health

Verifica se a API está funcionando.

```bash
curl http://develop.api.nexo.local/health
```

**Response:**

```json
{
  "status": "ok",
  "info": {
    "database": { "status": "up" }
  }
}
```

---

## 📊 Métricas

### GET /metrics

Retorna métricas no formato Prometheus.

```bash
curl http://develop.api.nexo.local/metrics
```

**Response:**

```
# HELP nodejs_version_info Node.js version info.
# TYPE nodejs_version_info gauge
nodejs_version_info{version="v20.10.0"} 1

# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",path="/health",status="200"} 42
```

---

## 👤 Endpoints de Usuários

### GET /users

Lista todos os usuários (requer autenticação).

```bash
curl -X GET "http://develop.api.nexo.local/users" \
  -H "Authorization: Bearer {token}"
```

**Response:**

```json
{
  "data": [
    {
      "id": "cuid_abc123",
      "email": "user@example.com",
      "name": "João Silva",
      "createdAt": "2024-01-15T10:30:00.000Z"
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 10
}
```

### GET /users/:id

Busca usuário por ID.

```bash
curl -X GET "http://develop.api.nexo.local/users/cuid_abc123" \
  -H "Authorization: Bearer {token}"
```

### POST /users

Cria novo usuário.

```bash
curl -X POST "http://develop.api.nexo.local/users" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "novo@example.com",
    "name": "Novo Usuário",
    "password": "senha123"
  }'
```

### PATCH /users/:id

Atualiza usuário.

```bash
curl -X PATCH "http://develop.api.nexo.local/users/cuid_abc123" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nome Atualizado"
  }'
```

### DELETE /users/:id

Remove usuário.

```bash
curl -X DELETE "http://develop.api.nexo.local/users/cuid_abc123" \
  -H "Authorization: Bearer {token}"
```

---

## 📝 Padrões de Resposta

### Sucesso (2xx)

```json
{
  "data": { ... },
  "message": "Operação realizada com sucesso"
}
```

### Lista com Paginação

```json
{
  "data": [ ... ],
  "total": 100,
  "page": 1,
  "limit": 10,
  "totalPages": 10
}
```

### Erro (4xx/5xx)

```json
{
  "statusCode": 400,
  "message": "Descrição do erro",
  "error": "Bad Request",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "path": "/users"
}
```

---

## 🔍 Query Parameters

### Paginação

| Param | Tipo   | Default | Descrição        |
| ----- | ------ | ------- | ---------------- |
| page  | number | 1       | Número da página |
| limit | number | 10      | Itens por página |

```bash
GET /users?page=2&limit=20
```

### Ordenação

| Param  | Tipo   | Default   | Descrição          |
| ------ | ------ | --------- | ------------------ |
| sortBy | string | createdAt | Campo para ordenar |
| order  | string | desc      | asc ou desc        |

```bash
GET /users?sortBy=name&order=asc
```

### Filtros

| Param         | Tipo   | Descrição                 |
| ------------- | ------ | ------------------------- |
| search        | string | Busca em múltiplos campos |
| filter[campo] | string | Filtro específico         |

```bash
GET /users?search=joao
GET /users?filter[email]=user@example.com
```

---

## 🔒 Códigos HTTP

| Código | Significado                               |
| ------ | ----------------------------------------- |
| 200    | OK - Requisição bem sucedida              |
| 201    | Created - Recurso criado                  |
| 204    | No Content - Sem conteúdo (DELETE)        |
| 400    | Bad Request - Dados inválidos             |
| 401    | Unauthorized - Não autenticado            |
| 403    | Forbidden - Sem permissão                 |
| 404    | Not Found - Recurso não encontrado        |
| 409    | Conflict - Conflito (ex: email duplicado) |
| 422    | Unprocessable Entity - Validação falhou   |
| 500    | Internal Server Error - Erro do servidor  |

---

## 🧪 Testando API

### cURL

```bash
# Health check
curl http://develop.api.nexo.local/health

# Com autenticação
TOKEN=$(curl -s -X POST "http://develop.auth.nexo.local/realms/nexo/protocol/openid-connect/token" \
  -d "grant_type=password&client_id=nexo-app&username=admin&password=admin" \
  | jq -r '.access_token')

curl http://develop.api.nexo.local/users \
  -H "Authorization: Bearer $TOKEN"
```

### HTTPie

```bash
# Instalar
brew install httpie

# Usar
http GET http://develop.api.nexo.local/health
http GET http://develop.api.nexo.local/users Authorization:"Bearer $TOKEN"
```

### VS Code REST Client

Crie arquivo `api.http`:

```http
### Health
GET http://develop.api.nexo.local/health

### Login
# @name login
POST http://develop.auth.nexo.local/realms/nexo/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=password&client_id=nexo-app&username=admin&password=admin

### List Users
GET http://develop.api.nexo.local/users
Authorization: Bearer {{login.response.body.access_token}}
```

---

## ➡️ Próximos Passos

- [09-observability.md](09-observability.md) - Métricas e logs
- [10-troubleshooting.md](10-troubleshooting.md) - Resolução de problemas
