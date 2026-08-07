# E4 Validation Status

**Atualizado**: 2026-08-07 (pós DB config + percent-decode + port fixes)

## Resumo

| Status | Qtd | Implementações |
|---|---|---|
| ✅ **E4 PASS (7/7)** | **6** | go-rest-fiber, go-rest-chi, go-rest-echo, go-rest-gin, nodejs-rest-fastify, kotlin-rest-http4k |
| ⚠️ Parcial (sobe, 1-6 checks fail) | ~20 | ver detalhe abaixo |
| ❌ TIMEOUT | ~6 | graalvm-rest-vertx, deno-rest-{oak,deno-serve,fresh,hono}, csharp-rest-minimalapi |

## E4 PASS (7/7) — 6 implementações

Todas passam no parity gate completo: /json (n=10/100/1000), /health,
/db/simple, /db/complex, /cache.

## Parciais (sobem e respondem, mas com divergências de payload)

| Impl | ok/7 | Falhas |
|---|---|---|
| rust-rest-warp | 6/7 | /db/simple |
| java-rest-spring | 6/7 | 1 check |
| graalvm-rest-gspring | 6/7 | 1 check |
| kotlin-rest-ktor | 6/7 | 1 check |
| python-rest-flask | 6/7 | 1 check |
| nodejs-rest-express | 6/7 | /health version |
| nodejs-rest-nestjs | 6/7 | /cache |
| bun-rest-elysia | 6/7 | /cache |
| kotlin-rest-spring | 5/7 | /db/* |
| graalvm-rest-helidon | 5/7 | 2 checks |
| rust-rest-actix-web | 4/7 | /json payload |
| java-rest-quarkus | 4/7 | /health, /db/* |
| python-rest-fastapi | 4/7 | 3 checks |
| csharp-rest-controllers | 3/7 | /health, /db/* |
| csharp-rest-fastendpoints | 3/7 | /health, /db/* |
| dart-rest-vaden | 3/7 | /health, /db/* |
| python-rest-django | 0/7 | connection refused (WSGI path?) |
| java-rest-micronaut | 0/7 | connection refused |
| graalvm-rest-micronaut | 0/7 | connection refused |
| rust-rest-axum | 1/7 | /json payload |
| rust-rest-rocket | 1/7 | /json payload |

## Causas raiz restantes

1. **Payload /json divergente** (Rust axum/rocket/actix): possível regressão dos fixes de compilação
2. **/health sem version** (node-express): já corrigido em código, imagem pode ser stale
3. **/cache sem ttl/cached** (bun/elysia, node/nestjs): campo faltante
4. **/db/* falhando** (csharp, dart, java-quarkus, kotlin-spring): query ou conexão DB
5. **Connection refused em 3 impls** (django, java-micronaut, graalvm-micronaut): pode ser startup lento ou crash após deploy

## Próximos passos

1. Fixar os defeitos de payload das ~20 parciais (1-3 checks cada)
2. Investigar os 3 "0 ok" (django, java-micronaut, graalvm-micronaut)
3. Fixar Deno Dockerfile/bootstrap (4 TIMEOUTs)
4. Com 6+ impls PASS, já dá para iniciar a matriz de benchmark parcial
