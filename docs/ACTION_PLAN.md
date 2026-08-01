# Plano de Ação — Benchmark REST/gRPC/GraphQL

**Atualizado**: 2026-07-31
**Objetivo**: tornar os resultados deste benchmark defensáveis — hoje eles não são.

> Substitui o plano de 2026-07-29, que assumia que os resultados existentes
> eram válidos e estimava 8-11 horas de trabalho. A auditoria abaixo mostra que
> a premissa estava errada.

---

## Diagnóstico que originou este plano

| Problema | Evidência |
|---|---|
| A metodologia documentada nunca foi executada | `docs/BENCHMARK_METHODOLOGY.md` promete 5×60s, warm-up de 30s e ordem randomizada; `run_all_benchmarks.py:94` executa **1×5s** com warm-up de 2s, ordem alfabética |
| O gerador de carga era o gargalo | job wrk com `limits.cpu: 1`, no mesmo nó do SUT, cluster de 1 nó |
| Implementações não são comparáveis | Go REST usa `pgx.Conn` (**sem pool**) e "vence" o teste de DB; outras usam pool de 10 ou 25 |
| Workers desiguais | Flask/Django com gunicorn `4 workers × 2 threads`, FastAPI com uvicorn `1 worker` — origem do falso insight "Flask bate FastAPI" |
| Payload `/json` divergente | Go: 154 B/item com 16 KB de CSPRNG por request; Node: 106 B/item sem aleatoriedade. **45% mais bytes no Go** |
| Três perfis de recursos conflitantes | metodologia (1 CPU) × `deploy/k3s/base` (250m/2 CPU, 1 réplica) × `src/*/k8s` (100m/500m, 5 réplicas — **este foi o usado**) |
| Tabelas de resultados inconsistentes | `/json`: FastAPI 110 em 7º acima de 871; `/cache`: Ktor 16.261 em 4º abaixo de 14.869; `/health`: 27.210 na tabela vs 19.562 no resumo |
| Contagem irreal | README diz 101 impls; `config/implementations.yaml` tem 99, das quais 57 marcadas `planned` |
| Credenciais em repositório público | 135 arquivos + histórico do Git |

---

## Topologia decidida

```
Workstation Windows              VM .51 — K3s (SUT)          VM .52 — PostgreSQL
  bombardier / oha / k6   ──>      8 vCPU / 16 GiB              8 vCPU / 16 GiB
  ghz (gRPC)             NIC        ├ sistema ... 1 CPU
                        1 GbE       └ pod SUT ... 7 CPU  ──>   Redis (externo)
```

| Camada | CPU | Memória |
|---|---:|---:|
| VM `.51` total | 8 | 16 GiB |
| K3s + SO (`--system-reserved` + `--kube-reserved`) | 1,0 | 2 GiB |
| **Pod SUT** (`requests == limits`, QoS Guaranteed) | **7** | **12 GiB** |

`--cpu-manager-policy=static` + requests inteiros + Guaranteed → cores
exclusivos, sem CFS throttling. É o que torna "100% do hardware" repetível.

### Consequência da rede de 1 GbE

Teto útil ≈ 941 Mbps ≈ 117,6 MB/s. Por cenário:

| Cenário | Corpo | Teto de rede | Gargalo esperado | Veredito |
|---|---:|---:|---|---|
| `/health` | ~100 B | ~390k rps | **PPS/cliente** ~50-150k | ⚠️ topo comprimido |
| `/json` n=1000 | 106-154 KB | **~750-1.100 rps** | **rede** | ❌ inviável p/ throughput |
| `/db/simple` | ~130 B | ~356k rps | PostgreSQL | ✅ válido |
| `/db/complex` | ~13 KB (`LIMIT 100`) | ~8.900 rps | PostgreSQL | ✅ válido |
| `/cache` | ~150 B | ~336k rps | Redis / PPS | ✅ válido |

Três dos cinco cenários sobrevivem intactos. Números a confirmar na Fase 0.

---

## Fase 0 — Congelar e medir os tetos `[~1,5 dia]`

Nenhum resultado de framework tem significado antes destes números.

1. Marcar `BENCHMARK_RESULTS_K3S.md` e `docs/*RESULTS*.md` como `INVALID`
   (preservar, não apagar).
2. Rodar `scripts/measure-ceilings.ps1` na workstation: `iperf3` (não assumir
   1 GbE), teto de PPS com nginx, tamanho real de cada payload.
3. Rodar `scripts/measure-ceilings-server.sh` no `.51`: inventário de hardware,
   CPU steal do host Proxmox, `pgbench -S`, `redis-benchmark`.
4. Preencher `docs/K3S_ENVIRONMENT.md` (hoje é template vazio).
5. Descobrir onde está o Redis — `redis.home.arpa:30379` é porta de NodePort,
   pode estar dentro de outro cluster e ser um confounder.

**Saída**: `docs/BASELINE_CEILINGS.md`.
**Critério**: o teto efetivo de cada cenário é conhecido e igual ao **menor**
entre rede, PPS, PostgreSQL e Redis.

---

## Fase 1 — Segurança `[árvore de trabalho CONCLUÍDA]`

- [x] 135 arquivos purgados por `scripts/purge-credentials.py` — credenciais
      só vêm do ambiente, variável ausente aborta o processo
- [x] `kubernetes/secrets.yaml` removido do rastreamento
- [x] `credential-scan.yml` virou gate real (`trufflehog --fail`, árvore +
      histórico); `*.md` saiu da lista de exclusão
- [ ] **Rotacionar** senhas do PostgreSQL e Redis — *ação do responsável*
- [ ] **Reescrever o histórico** do Git (`git filter-repo`) e `--force` push

Runbook completo: `docs/SECURITY_REMEDIATION.md`.

> A limpeza da árvore não protege nada enquanto a senha não for rotacionada:
> o valor segue recuperável em qualquer commit anterior a 2026-07-31.

---

## Fase 2 — Topologia de teste `[~1 dia]`

**No `.51`:**
```
--system-reserved=cpu=500m,memory=1Gi
--kube-reserved=cpu=500m,memory=1Gi
--cpu-manager-policy=static
--disable traefik --disable servicelb
```
Governor `performance` no host Proxmox; sem ballooning; confirmar que os
8 vCPU são dedicados (overcommit torna o "100%" fictício).

**Na workstation (gerador de carga):**

| Protocolo | Ferramenta | Motivo |
|---|---|---|
| REST throughput | `bombardier` | Go, nativo Windows, keep-alive por padrão |
| REST latência a taxa fixa | `oha` | Rust, nativo, rate-limit sem coordinated omission |
| GraphQL | `k6` | binário nativo |
| gRPC | `ghz` | Go, nativo |

`wrk`/`wrk2` não têm build nativo para Windows. WSL2 descartado: o NAT
adiciona latência e variância à medição.

```powershell
netsh int ipv4 set dynamicport tcp start=10000 num=55000
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" TcpTimedWaitDelay 30
powercfg /setactive SCHEME_MIN
```
Mais: exclusão do Defender para o processo gerador, Wi-Fi desligado (forçar
cabo), sem VPN ativa, keep-alive sempre ligado. Caminho de rede: NodePort
uniforme, sem Ingress.

---

## Fase 3 — Paridade entre implementações `[EM ANDAMENTO — ~5-8 dias]`

**Fundação concluída** (contrato + gate + implementação de referência):

- [x] `contracts/rest/canonical-payloads.md` — payload normativo, alinhado a
      `benchmark.proto` e `schema.graphql`
- [x] `scripts/validate-parity.py` — gate por SHA-256 de JSON normalizado
- [x] `deploy/k3s/base/configmap.yaml` — `BENCH_CPUS`, `DB_POOL_MAX`,
      `REDIS_POOL_MAX`, `LOG_LEVEL=error`
- [x] `deploy/k3s/base/deployment.yaml` — perfil Guaranteed 7 CPU / 12 GiB
- [x] **`src/go/fiber` como referência**: payload canônico, `?n=`, sem
      `crypto/rand`, `GOMAXPROCS` de `BENCH_CPUS`, `pgxpool` com `DB_POOL_MAX`,
      modelos e envelopes alinhados ao proto, teste de regressão do contrato

**Implementações convertidas** (36/36 REST).

Cada linha registra o nível de evidência realmente obtido — não confundir
"módulo canônico verificado" com "serviço verificado de ponta a ponta". O
gate `scripts/validate-parity.py --url` contra o serviço rodando ainda não
foi executado para nenhuma: isso é a Fase 6, depois do rebuild.

| Ambiente | Implementações | Evidência obtida |
|---|---|---|
| Go | fiber, chi, echo, gin | `go build` + `go vet` + `go test` e cross-check contra a referência Python |
| Python | flask, fastapi, django | função extraída por AST e executada; cross-check |
| Node.js | express, fastify, nestjs | executada com Node; cross-check |
| Bun | bun_serve, elysia, hono | executada com Bun; cross-check |
| Rust | axum, actix-web, rocket, warp | `cargo check` limpo nos 4 crates + `cargo test` do módulo `canonical`; vetores do teste conferidos contra a referência Python |
| Deno | deno_serve, fresh, hono, oak | módulo `canonical.ts` executado (via Bun — **não há runtime Deno nesta máquina**); cross-check. O servidor em si não foi executado |
| C# | Controllers, FastEndpoints, MinimalApi | `dotnet build` limpo nos 3 projetos + `Canonical` executado e cross-check |
| Java | spring, micronaut, quarkus | `Canonical.java` compilado com `javac`, executado e cross-check. **Sem Maven/Gradle nesta máquina — os projetos não foram compilados inteiros** |
| Kotlin | spring, ktor, http4k | **nenhuma — não há `kotlinc` nesta máquina**. Código espelha o `Canonical.java` já verificado |
| GraalVM | spring, gspring, micronaut, gmicronaut, helidon, vertx | mesmo `Canonical.java` verificado; projetos não compilados (sem Maven/Gradle) |
| Dart | vaden | **nenhuma — não há SDK Dart nesta máquina** |

Os 4 crates Rust não compilavam antes desta passada. Além do payload, foi
preciso corrigir: `Cargo.toml` do axum com `profile-rustflags` instável
(quebrava o parse do manifesto inteiro), `StatusCode`/`Deserialize` sem
import, `EnvFilter` sem a feature `env-filter`, `if let Some(x): T = ...`
(sintaxe inválida) em axum e rocket, `rocket::Shield` (movido para
`rocket::shield::Shield`) e os macros `sqlx::query!`/`query_as!`, que exigem
`DATABASE_URL` **em tempo de build** — algo que nem o repositório nem o
Dockerfile fornecem.

Divergências encontradas ao converter — cada uma invalidava o ranking `/json`:

| Implementação | Divergência |
|---|---|
| `go/fiber` | `crypto/rand` por item; `string(rune(id))` |
| `go/chi,echo,gin` | `time.Now()` dentro do laço (1000 leituras de relógio/req) |
| `python/flask` | **dois `uuid4()` por item** = 2000 UUIDs/req |
| `python/django` | `utcnow()` dentro do laço |
| `nodejs/fastify` | `uuidv4()` por item; schema de resposta filtrava campos |
| `nodejs/nestjs` | ids a partir de 1; envelope sem `timestamp`; **rotas sob `/api`** enquanto o runner batia na raiz; porta 3000 |
| `bun/*` (todas) | ids a partir de 1; `pino-pretty` ligado por request |
| `bun/elysia` | **retornava um array cru, sem envelope algum** |
| `bun/bun_serve` | porta padrão 3000, não 8080 |
| `rust/actix-web` | **dois `uuid::Uuid::new_v4()` por item** = 2000 UUIDs/req |
| `rust/axum,rocket,warp` | 1 UUID v4 + 1 `Utc::now().to_rfc3339()` por item |
| `deno/*` | dois `crypto.randomUUID()` por item = 2000 UUIDs/req |
| `csharp/*` (todas) | **1000 itens pré-construídos num construtor estático** e servidos de um array cacheado: mediam só a serialização, enquanto todas as outras também construíam os itens — e `?n=` era ignorado, então n=10/n=100/n=1000 devolviam sempre 1000 |
| `csharp/MinimalApi` | envelope só com `items`, sem `count` nem `timestamp` |
| `java,graalvm/{spring,micronaut}` | `{id,name,email,timestamp}`; `Map.of` tem ordem de iteração não especificada, então duas execuções da mesma implementação geravam bytes diferentes |
| `java/quarkus` | `{id,name,description,timestamp,random}` com `Instant.now()` e `UUID.randomUUID()` por item |
| `graalvm/helidon` | `Instant.now()` dentro do laço = 1000 leituras de relógio/req |
| `graalvm/vertx` | **array cru, sem envelope**; ids a partir de 1; `{id,name,value,timestamp}` |
| `kotlin/spring` | `{id,name,email,active,tags}` — com uma lista de 3 strings por item, inflando o payload |
| `kotlin/ktor` | JSON concatenado à mão num `StringBuilder` — media construção de string, não o serializador pelo qual todas as outras eram medidas — mais um `UUID.randomUUID()` por item |
| `kotlin/http4k` | interpolava um `Map` do Kotlin numa string: saía `{id=0, name=User 0}`, **que não é JSON** |
| `dart/vaden` | ids a partir de 1; `uuid-0001-…` (não é um UUID); `DateTime.now()` em `createdAt`; `isActive` era `i % 10 != 0` |
| Python (todas) | workers desiguais (Flask 4×2, FastAPI 1); porta 8000 |
| Node/Bun (todas) | single-thread — usariam 1 dos 7 cores |
| Rust (sqlx) | pool no default 10 do sqlx, não `DB_POOL_MAX` |
| JVM (7 configs) | porta 3000 em vez de 8080; host do Postgres **fixo no código** (`spsql.home.arpa`) em quarkus e kotlin/spring; pool 25/5 ou não configurado; log em INFO |

### `kotlin/http4k` não é uma implementação — é um stub

`/db/simple` devolvia 200 com um usuário inventado, `/db/complex` devolvia
`{"orders":[]}` e `/cache` devolvia um acerto de cache fabricado. O projeto
**não declara nenhuma dependência de PostgreSQL ou Redis** e não tem como
falar com nenhum dos dois. Aqueles números não mediam coisa alguma e, ao lado
de implementações que de fato executam a query, apareceriam como vitória.

Nesta passada os três endpoints passaram a responder **501 Not Implemented**,
para que o runner registre "não implementado" em vez de um resultado
fabricado. Implementar a camada de dados do http4k continua pendente.

### Divergência conhecida ainda aberta

`src/rust/actix-web` usa um **único client `tokio_postgres`**, sem pool — a
mesma classe de problema do `pgx.Conn` do Go fiber. Corrigir exige trocar o
driver (sqlx ou deadpool-postgres) e reescrever todos os pontos de query, o
que não cabe na mesma passada da conversão de payload. Enquanto isso, os
resultados de `/db/*` do actix-web não são comparáveis.

### `/db/*` e `/cache` ainda não têm paridade de envelope

O contrato exige `/db/simple` → objeto do usuário achatado em camelCase,
`/db/complex` → `{periodDays, totalUsers, data}` e `/cache` →
`{key, value, cached, ttl, timestamp}`. Nesta passada isso foi alinhado só
onde o arquivo já estava aberto (axum e rocket, que também tiveram a SQL
corrigida: o `INTERVAL '%s days'` era um placeholder no estilo C que o
Postgres lê como a string literal `"%s days"`, e o `ORDER BY` sem desempate
tornava a resposta irreprodutível). As demais ainda emitem `period_days` /
`total_users` / `source`, ou snake_case nos campos do usuário — helidon é um
exemplo. Alinhar as 30 restantes é o próximo item da Fase 3.

**Pendente na Fase 3**: envelopes de `/db/*` e `/cache` nas 30 implementações
restantes; camada de dados do `kotlin/http4k`; pool do `rust/actix-web`;
depois gRPC (31) e GraphQL (32). O gate falha até que todas passem.


### 3.1 Paralelismo = 7 cores, via `BENCH_CPUS` no ConfigMap

| Runtime | Mecanismo | Nota |
|---|---|---|
| Go | `GOMAXPROCS` | **obrigatório** — Go lê CPUs do host, não a quota do cgroup |
| Rust (tokio) | `worker_threads` | fixar explicitamente |
| JVM / Kotlin | `-XX:ActiveProcessorCount` | + GC uniforme entre todos |
| .NET | `DOTNET_PROCESSOR_COUNT` | + `ThreadPool.SetMinThreads` |
| Node.js | `cluster` com N workers | hoje 1 thread — usa 1/7 do hardware |
| Bun / Deno | N processos + `reusePort` | |
| Python | `--workers N` | hoje: Flask 4×2, FastAPI 1 |

Heap uniforme para JVM/Kotlin/GraalVM: `-Xms8g -Xmx8g`.

### 3.2 Pool de conexões uniforme

`DB_POOL_MAX` único, dimensionado ao teto do PG medido na Fase 0 (sugestão:
32/pod, `max_connections` ≥ 200). Mesma regra para Redis. Corrigir o
`pgx.Conn` sem pool do Go REST.

### 3.3 Payload canônico `[BLOQUEANTE]`

- Schema único por cenário definido em `contracts/`, idêntico em todas as
  linguagens, **verificado por SHA-256 do corpo** no `make smoke`.
- Sem PRNG por request (remover o `crypto/rand` do Go); timestamp só no
  envelope, nunca dentro dos itens.
- Corrigir `string(rune(id))` em `src/go/fiber/internal/models/*.go` — converte
  o inteiro em code point Unicode, não no texto do número (deveria ser
  `strconv.Itoa`). Afeta `json_item.go`, `user.go`, `complex_order_result.go`.
- `/json` parametrizado por `?n=`, rodando em **n = 10, 100, 1000**.

Mapeamento de cenários entre protocolos (contrato único):

| # | Cenário | REST | gRPC | GraphQL |
|---|---|---|---|---|
| 1 | Health | `/health` | `Health` | `{ health }` |
| 2 | JSON | `/json?n=` | `GetJsonItems` | `{ jsonItems }` |
| 3 | DB Simple | `/db/simple?id=1` | `GetUser` | `{ user(id:1) }` |
| 4 | DB Complex | `/db/complex?days=30` | `GetComplexOrders` | `{ complexOrders }` |
| 5 | Cache | `/cache?key=bench` | `GetCacheValue` | `{ cache }` |

### 3.4 Nivelamento de execução

Porta 8080 em todos (Python sobe em 8000 contra `PORT: "8080"` do ConfigMap);
`LOG_LEVEL` desligado; builds release/AOT verificados; mesma query SQL literal.

### 3.5 Tuning do PostgreSQL (8 vCPU / 16 GiB)

`shared_buffers=4GB`, `effective_cache_size=12GB`, `max_connections=300`,
`work_mem=16MB`, `random_page_cost=1.1`, huge pages.

**Critério de saída**: `scripts/validate-parity.sh` falha se qualquer
implementação divergir em porta, pool, workers, log level ou hash de payload.

---

## Fase 4 — Unificar o deploy `[~1-2 dias]`

1. **Eliminar `src/*/k8s/`** (101 diretórios) — conflitam com os 99 overlays
   Kustomize e foram o que de fato rodou.
2. Perfil Guaranteed: `requests == limits == 7 CPU / 12 GiB`.
3. Modo A (ranking primário) = **1 réplica** com o nó inteiro. Modos B e C em
   overlays separados, nunca misturados no ranking.
4. Reconciliar `config/implementations.yaml` (99) com README (101) e com os
   101 diretórios; `maturity` refletindo a realidade.
5. `make inventory|build|deploy|smoke|benchmark` como único caminho —
   aposentar `run_all_benchmarks.py`, `deploy_grpc.py`, `fix_*.py`.

---

## Fase 5 — Runner que honra a metodologia `[~3-4 dias]`

| Item | Hoje | Alvo |
|---|---|---|
| Warm-up | 2s | 30s (60s para JVM/GraalVM) |
| Medição | 5s | 60s |
| Repetições | 1 | 5 → mediana + IC 95% |
| Ordem | alfabética | randomizada |
| Isolamento | 53 pods simultâneos | 1 implementação por vez |
| Saída | Markdown manual | JSON conforme `docs/RESULTS_SCHEMA.md` |

**Métrica A — throughput máximo**: varredura de concorrência (1, 8, 32, 64,
128, 256, 512) até o joelho da curva. Válido só se CPU do SUT ≥ 90%, rede
< 80% do teto, DB < 70%.

**Métrica B — custo de CPU por requisição** (primária onde há teto de infra):
a taxa fixa abaixo do teto, medir `cpu_seconds_do_pod / requests × 1e6`.
É independente da rede e do cliente, e sobrevive à topologia de 1 GbE.

**Classificação automática**, calculada pelo runner, nunca escrita à mão:

| Flag | Condição |
|---|---|
| `FRAMEWORK_BOUND` | CPU ≥ 90%, rede < 80%, DB < 70% → entra no ranking de throughput |
| `NET_BOUND` | bytes/s ≥ 80% da banda medida |
| `PPS_BOUND` | req/s ≥ 80% do teto de PPS |
| `CLIENT_BOUND` | CPU da workstation ≥ 90% |
| `DB_BOUND` | PostgreSQL ou Redis ≥ 85% |

Rejeitar runs com erro > 0,1%, throttling > 0, ou desvio-padrão > 5%.
Saída em `results/raw/<run-id>/<impl>/<scenario>/<mode>/c<conc>.json`.

---

## Fase 6 — Reconstrução e re-execução `[~4-6 dias]`

### 6.1 As 46 implementações que não buildam

| Ambiente | Frameworks | Problema típico |
|---|---|---|
| Rust gRPC | volo, grpcio | breaking changes de API |
| Go gRPC | connectrpc, kitex | `go.sum` / genproto |
| Java gRPC | armeria, quarkus | naming de classes do proto |
| Kotlin gRPC | grpc-kotlin, spring, armeria | Gradle wrapper |
| GraalVM gRPC | quarkus, micronaut, grpc-java | build nativo Maven |
| Dart gRPC | grpc-dart | versão do protobuf |
| Rust GraphQL | async-graphql, juniper | deps do Cargo |
| C# GraphQL | hotchocolate, graphql-dotnet | ciclos de NuGet |
| Dart GraphQL | graphql-server2, angel3, leto | versão do shelf_router |
| GraalVM GraphQL | smallrye, spring, micronaut | build nativo |
| Go REST | gin, fiber | `go.sum` incompleto |

Paralelizável por ambiente.

### 6.2 Execução

- Gate: `make smoke` com validação de contrato + hash de payload antes de a
  implementação entrar na matriz.
- Matriz: ~99 impls × 5 cenários × 5 repetições × 60s ≈ **~45h de máquina**.
  Rodar por protocolo, com checkpoint e retomada.

---

## Fase 7 — Publicação honesta `[~1 dia]`

1. Um único `docs/RESULTS_<data>.md` **gerado** a partir dos JSONs.
2. Cada linha com `% do teto de infra` e a flag de gargalo.
3. Atualizar `docs/KNOWN_LIMITATIONS.md:37` — ainda afirma "no real benchmark
   has been executed yet", contradizendo 5 documentos de resultados.
4. Consolidar os 9 documentos de resultados sobrepostos e os ~15
   `*_SUMMARY.md` / `*_README.md` da raiz.

---

## Caminho crítico

```
Fase 1 (segurança) ──────────────┐  árvore concluída; rotação pendente
Fase 0 (tetos) → Fase 2 → Fase 3 → Fase 5 → Fase 6 → Fase 7
                            └→ Fase 4 ──────┘
```

**Estimativa total**: ~3 semanas de trabalho focado. Fases 3 e 6 concentram
cerca de 70% do esforço.
