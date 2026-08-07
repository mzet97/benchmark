# E4 Validation Status

**Atualizado**: 2026-08-07

## Resumo

| Status | Qtd | Implementações |
|---|---|---|
| ✅ **E4 PASS (7/7)** | **5** | go-rest-fiber, go-rest-chi, go-rest-echo, go-rest-gin, nodejs-rest-fastify |
| ⚠️ Parcial (sobe, alguns checks fail) | 3 | rust-rest-warp (6/7), java-rest-spring (6/7), rust-rest-actix-web (4/7) |
| ❌ TIMEOUT (não sobe) | ~29 | ver detalhe abaixo |

## Causas raiz dos TIMEOUTs (identificadas)

### Resolvidas (impls agora passam ou estão parciais)
- **Porta hardcoded :3000** em go/chi, go/echo, go/gin → corrigido para ler `PORT`
- **DB config ausente** em java/spring → application.properties criado
- **Pool min_size > max_size** em python/fastapi → divisão corrigida (ainda falha por senha)
- **Percent-decode de senha** em rust/actix-web → `Config::from_str` (funciona, mas outros defeitos restam)
- **Rust Dockerfile 1.82** → block-buffer parse error → atualizado para 1.95

### Pendentes (impls ainda em TIMEOUT)
- **rust-rest-axum**: provavelmente mesmo percent-decode bug (precisa rebuild)
- **rust-rest-rocket**: provavelmente mesmo percent-decode bug
- **python-rest-fastapi**: `password authentication failed` — mesmo percent-decode bug da senha
- **python-rest-flask**: `App failed to load` — erro de import/path
- **python-rest-django**: `No module named 'app.wsgi'` — path WSGI errado
- **deno-rest-oak**: Redis connection ainda falhando (percent-decode pode não ter pego)
- **JVM (kotlin×3, graalvm×4, java×2)**: todos CrashLoopBackOff — DB config (HikariPool/Hibernate não leem env vars)
- **deno×3**: deno image base não existe (`denoland/deno:2.0-slim`)

### Padrão dominante
**Percent-decode da senha** — `Admin@123` encoded como `Admin%40123` no DATABASE_URL/REDIS_URL.
Muitas implementações fazem parse manual da URL e não decodificam o `%40`. O fix é
usar o parser nativo da biblioteca em vez de `split()`.

**DB config em JVM** — Spring/Micronaut/Quarkus/Hibernate não mapeiam `DB_HOST`/`DB_PASSWORD`
para suas propriedades nativas. Cada framework precisa de config explícita.

## Próximos passos

1. **Percent-decode fix generalizado** para python (flask, django, fastapi) e rust (axum, rocket)
2. **JVM DB config** para kotlin×3, graalvm×4, java×2 (cada framework precisa de mapping)
3. **Python WSGI path** para flask e django
4. **Deno Dockerfile** fix (imagem base `2.0-slim` não existe)
5. Re-run E4 batch com todas as correções
