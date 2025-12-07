# API Endpoints Documentation

## Overview

Todos os serviços implementam os mesmos 5 endpoints obrigatórios para garantir comparações justas entre linguagens.

## Endpoints

### 1. GET /health

Health check simples para verificar se o serviço está funcionando.

**Request:**
```http
GET /health
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "timestamp": "2025-12-07T10:00:00.000Z"
}
```

**Use Case:**
- Kubernetes health checks
- Load balancer probes
- Service discovery

---

### 2. GET /json

Retorna um array de 1000 objetos JSON serializados.

**Request:**
```http
GET /json
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "name": "User 1",
      "email": "user1@example.com",
      "createdAt": "2024-12-07T10:00:00.000Z",
      "isActive": true
    },
    {
      "id": 2,
      "uuid": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
      "name": "User 2",
      "email": "user2@example.com",
      "createdAt": "2024-12-06T10:00:00.000Z",
      "isActive": false
    }
    // ... 998 more items
  ]
}
```

**Use Case:**
- Testar performance de serialização JSON
- Medir throughput com payload fixo
- Verificar memory allocation

**Metrics:**
- Tamanho da resposta: ~150KB
- Tempo de serialização
- GC pressure

---

### 3. GET /db/simple?id={id}

Busca um usuário específico no banco de dados por ID.

**Request:**
```http
GET /db/simple?id=1
```

**Parameters:**
- `id` (required, integer): ID do usuário (1-10000)

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "John Smith",
  "email": "user1@example.com",
  "createdAt": "2024-01-15T08:30:00.000Z",
  "isActive": true
}
```

**Response (400 Bad Request):**
```json
{
  "error": "Invalid id parameter"
}
```

**Response (404 Not Found):**
```json
{
  "error": "User with id 99999 not found"
}
```

**Use Case:**
- Testar connection pooling
- Medir query performance (SELECT por PK)
- Verificar transaction overhead

**Database Query:**
```sql
SELECT id, email, first_name, last_name, age, created_at
FROM users
WHERE id = @Id;
```

**Metrics:**
- Query time
- Connection acquisition time
- Row count: 1

---

### 4. GET /db/complex?days=30

Query complexa com JOIN entre 3 tabelas e agregação.

**Request:**
```http
GET /db/complex?days=30
```

**Parameters:**
- `days` (optional, integer): Período em dias (1-365, default: 30)

**Response (200 OK):**
```json
{
  "period_days": 30,
  "total_users": 100,
  "data": [
    {
      "userId": 1,
      "userName": "John Smith",
      "totalOrders": 15,
      "totalValue": 1250.50,
      "averageOrderValue": 83.37
    },
    {
      "userId": 2,
      "userName": "Jane Doe",
      "totalOrders": 12,
      "totalValue": 980.25,
      "averageOrderValue": 81.69
    }
    // ... top 100 users
  ]
}
```

**Response (400 Bad Request):**
```json
{
  "error": "Days must be between 1 and 365"
}
```

**Use Case:**
- Testar JOIN performance
- Medir aggregation overhead
- Verificar index usage

**Database Query:**
```sql
SELECT
    u.id as UserId,
    CONCAT(u.first_name, ' ', u.last_name) as UserName,
    COUNT(DISTINCT o.id) as TotalOrders,
    COALESCE(SUM(oi.quantity * oi.price), 0) as TotalValue,
    COALESCE(AVG(oi.quantity * oi.price), 0) as AverageOrderValue
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
    AND o.created_at >= CURRENT_DATE - INTERVAL '@Days days'
    AND o.status = 'completed'
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY u.id, u.first_name, u.last_name
ORDER BY TotalValue DESC
LIMIT 100;
```

**Metrics:**
- Query time
- Rows scanned
- Rows returned: 100
- Join performance

---

### 5. GET /cache?key={key}

Busca dados do Redis com fallback para geração dinâmica.

**Request:**
```http
GET /cache?key=test
```

**Parameters:**
- `key` (required, string): Chave para buscar no cache

**Response (200 OK):**
```json
{
  "key": "test",
  "value": "Cached value for test at 2025-12-07T10:00:00.000Z",
  "cached": true,
  "timestamp": "2025-12-07T10:00:00.000Z"
}
```

**Response (400 Bad Request):**
```json
{
  "error": "Key parameter is required"
}
```

**Use Case:**
- Testar Redis connectivity
- Medir cache hit/miss performance
- Verificar TTL handling

**Behavior:**
- **Cache Hit**: Retorna valor do Redis (TTL: 5 minutos)
- **Cache Miss**: Gera valor dinamicamente + armazena no cache
- Simula 50ms de processamento

**Metrics:**
- Cache hit rate
- Redis latency
- Fallback time

---

## Error Handling

Todos os endpoints seguem padrão consistente:

- **200 OK**: Success
- **400 Bad Request**: Invalid parameters
- **404 Not Found**: Resource not found
- **500 Internal Server Error**: Server errors

**Error Response Format:**
```json
{
  "error": "Descriptive error message"
}
```

## Performance Characteristics

| Endpoint | DB Queries | Cache | CPU | Memory |
|----------|------------|-------|-----|--------|
| /health | 0 | No | Very Low | Very Low |
| /json | 0 | No | Low | Medium |
| /db/simple | 1 SELECT | No | Low | Low |
| /db/complex | 1 JOIN | No | High | Medium |
| /cache | 0-1 | Yes | Low | Low |

## Rate Limiting

Por padrão, não há rate limiting configurado.
Os benchmarks são executados com alta concorrência para medir limites reais.

## Timeouts

- **Request Timeout**: 30 segundos (configurável)
- **Database Timeout**: 30 segundos
- **Redis Timeout**: 5 segundos

## Logging

Logs estruturados em JSON para todos os endpoints:

```json
{
  "timestamp": "2025-12-07T10:00:00.000Z",
  "level": "INFO",
  "logger": "BenchmarkApi",
  "message": "Request completed",
  "requestId": "req-123",
  "method": "GET",
  "path": "/db/simple",
  "query": {"id": "1"},
  "statusCode": 200,
  "durationMs": 12.5,
  "userId": 1
}
```

## Health Checks

### /healthz

Kubernetes-compatible health endpoint (detailed)

### /health

Simple health check (for load balancers)

## Testing

### Manual Testing
```bash
# Health check
curl http://localhost:8080/health

# JSON endpoint
curl http://localhost:8080/json | jq

# Simple DB query
curl http://localhost:8080/db/simple?id=1 | jq

# Complex query
curl http://localhost:8080/db/complex?days=30 | jq

# Cache test
curl http://localhost:8080/cache?key=test | jq
```

### Load Testing
```bash
# wrk
wrk -t8 -c200 -d30s --latency http://localhost:8080/health

# k6
k6 run --vus 50 --duration 60s scripts/k6-benchmark.js
```

## Observability

### Metrics Endpoint
Configurar Prometheus scraping em `/metrics` (se disponível)

### Distributed Tracing
Headers de tracing devem ser preservados:
- `X-Request-ID`
- `X-Trace-ID`
- `X-Span-ID`

### OpenAPI/Swagger

Swagger UI disponível em `/swagger` (development only)

```bash
# Access Swagger UI
open http://localhost:8080/swagger
```

## Security

### Authentication
Não implementado (benchmark focado em performance)

### Authorization
Não implementado

### Input Validation
- IDs: integer > 0
- Days: 1-365
- Keys: string (non-empty)

### SQL Injection Prevention
- Parameterized queries (Dapper)
- No string concatenation
- ORM-safe patterns

### CORS
Configured para permitir todas as origens em development
