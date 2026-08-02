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

## Fase 3 — Paridade entre implementações `[CONCLUÍDA, exceto http4k]`

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

**Implementações convertidas** (37/37 REST — a contagem de 36 usada até aqui
estava errada: `graalvm` tem 6 implementações REST, não 5).

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

### Pool do `rust/actix-web` — fechada

`src/rust/actix-web` mantinha um **único client `tokio_postgres` atrás de um
`Arc<Mutex<_>>`**: com 7 cores e centenas de conexões simultâneas, todo request
de `/db/*` entrava em fila atrás de um mutex, enquanto todas as outras
implementações usavam pool. Aqueles números mediam contenção de lock, não o
framework. Agora usa `deadpool-postgres` dimensionado por `DB_POOL_MAX`.

### `/db/*` e `/cache`: 37/37 REST no contrato

Todas as implementações REST respondem `/db/simple` com o objeto do usuário
achatado em camelCase, `/db/complex` com `{periodDays, totalUsers, data}` e
`/cache` com `{key, value, cached, ttl, timestamp}`. O contrato agora fixa
também **a SQL** — uma implementação que roda outra query não está medindo a
mesma coisa, por mais parecido que o JSON seja.

Três erros de SQL recorrentes, corrigidos em todas:

| Erro | Onde |
|---|---|
| `ORDER BY` sem desempate — linhas com agregados iguais voltavam em ordem arbitrária, resposta irreprodutível entre execuções | praticamente todas |
| Intervalo não parametrizado: `INTERVAL '%s days'` (o `%s` está **dentro** das aspas, o Postgres lê a string literal), `INTERVAL '${days} days'`, f-string, `String.format` | flask, django, express, fastify, bun ×3, deno ×4, java/spring, java/micronaut, kotlin/spring, dart, vertx |
| JOIN em `order_items` agregando `quantity * price` — query materialmente mais pesada que somar `o.total_amount` | chi, echo, gin, csharp ×3, graalvm ×4, dart |

### Duas implementações que não implementavam nada

`kotlin/http4k` respondia 200 em `/db/simple`, `/db/complex` e `/cache` com
literais fixos, sem declarar dependência de PostgreSQL ou Redis. Agora
respondem **501**, para o runner registrar "não implementado" em vez de uma
vitória fabricada. A camada de dados continua pendente.

`graalvm/vertx` **não rodava Vert.x**. O `pom.xml` aponta `main.class` para
`com.benchmark.vertx.Main`, que era um segundo servidor em
`com.sun.net.httpserver.HttpServer`: `/health` dizia "connected" sem tocar em
nada, `/db/simple` devolvia um usuário inventado, `/db/complex` devolvia
`data: []` e `/cache` um valor fabricado. O servidor Vert.x real ao lado
— `VertxServer`, router, handlers e services — nunca era iniciado. O `Main`
agora é um launcher dele.

### Trabalho no caminho medido que não devia estar lá

| Implementação | O quê |
|---|---|
| `csharp` (3) | `await Task.Delay(50)` em todo miss de `/cache` — teto de ~20 req/s por conexão |
| `graalvm/gmicronaut` | três chamadas a `getOrSet` por request (três idas ao Redis) para inferir um booleano |
| `kotlin/ktor` | `/db/simple` e `/db/complex` concatenavam JSON à mão, contornando o serializador pelo qual todas as outras eram medidas |
| `graalvm/vertx` | puxava 100 linhas de pedido e somava/mediava em Java; agora o banco agrega |

E dois endpoints que reportavam o oposto do que acontecia: em C# `cached` era
`value.Contains("Cached value")` — verdadeiro exatamente quando o valor
**acabara de ser gerado**; em `graalvm/gspring`, inferido por conter a data de
hoje.

### gRPC e GraphQL: 64/64 no payload canônico

As 32 implementações gRPC e as 32 GraphQL passaram a construir os itens a
partir de um módulo `Canonical` por linguagem, conferido contra a mesma
referência que o gate REST usa. As divergências eram as mesmas de sempre —
`UUID.randomUUID()`/`crypto.randomUUID()`/`Uuid::new_v4()` por item, relógio
por item, ids a partir de 1, `@example.com` — mais algumas próprias:

| Implementação | Divergência |
|---|---|
| `go/graphql` (3) | `time.Now().UnixNano()` por item para montar um "uuid-n-nanos" que não é UUID |
| `rust/grpc/tonic` | `isActive` era `i % 10 != 0` |
| `java/dgs`, `kotlin/dgs`, `ariadne`, `graphene`, `dart/leto` | `isActive` era `i % 3 != 0` |
| `dart/grpc-dart` | itens de um `Random` com semente; `user_3@benchmark.dev` |
| `bun,deno/graphql/hono` | uma **segunda cópia** de todos os resolvers dentro de `server.js`/`server.ts`, com gerador próprio |
| C# (3 gRPC), Python (3 gRPC) | itens nomeados `User_3`/`user_3` |

SQL de `/db/complex` nos gRPC/GraphQL: agregavam `o.total` ou `o.amount`,
colunas que **não existem no schema** (a query falharia em runtime), passavam
o intervalo como string, não tinham desempate no `ORDER BY` e, em gqlgen,
graphene, strawberry, ariadne e nos dois `async-graphql`, **não tinham LIMIT
nenhum** — devolviam todos os usuários em vez dos 100 do contrato.

Erros de compilação pré-existentes corrigidos de passagem: campo `Cache`
colidindo com o método `Cache` no `gqlgen` e `graphql-go`; conversão de tipos
`*db.User` no `graphql-go`; `Decimal: FromSql` nos dois `async-graphql`;
parâmetro opcional antes de obrigatório no HotChocolate;
`IDatabase.TimeToLiveAsync`, que não existe — o nome é `KeyTimeToLiveAsync`.

`java/grpc/grpc-js` contém **apenas um diretório `k8s/`**: sem código, sem
build. É um diretório que entra na contagem de implementações e nunca foi uma.

**Pendente na Fase 3**: camada de dados do `kotlin/http4k`. O gate só fecha de
verdade na Fase 6, contra os serviços rodando.


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

## Fase 4 — Deploy unificado `[CONCLUÍDA]`

Havia **duas** fontes de configuração de deploy, e a que de fato rodou era a
errada: `src/*/k8s` (101 diretórios) com 5 réplicas a 100m/500m, contra
`deploy/k3s/base` com 1 réplica a 7 CPU em QoS Guaranteed — e a metodologia
descrevendo um terceiro perfil. Os 101 diretórios foram removidos;
`deploy/k3s` é a fonte única.

Os overlays passaram a ser **gerados** a partir de `src/`, com
`scripts/generate-overlays.py`, e a relação implementação↔overlay virou 1:1,
verificável em CI:

```
python scripts/generate-overlays.py --check
```

Isso expôs o que a manutenção manual havia deixado para trás:

| | |
|---|---|
| **10 overlays órfãos** | todas as variantes `graalvm-*-native` nos três protocolos, sem nenhuma fonte; mais `csharp-rest-minimal-api`, cujo diretório é `MinimalApi` |
| **11 implementações sem overlay** | `graalvm/{micronaut,spring,gmicronaut,gspring}`, `csharp/MinimalApi` e as 6 de gRPC/GraphQL do graalvm — nunca poderiam ter sido medidas |

**A contagem real é de 100 implementações, não 101.** `src/java/grpc/grpc-js`
contém apenas um diretório `k8s/`: sem código, sem Dockerfile, sem nada para
construir. O gerador o ignora e diz por quê, em vez de contá-lo.

Também foram aposentados 18 scripts da topologia antiga (`deploy.sh`,
`deploy-k8s.sh`, `undeploy*.sh`, `run-benchmark.sh`, `run-all-benchmarks.sh`
e os `benchmark-wrk-*.sh`, que apontavam o wrk para o DNS interno do cluster).

---

## Fase 5 — Runner `[CONCLUÍDA]`

`run_all_benchmarks.py` foi aposentado. Ele produziu todos os números
publicados e não é defensável por razões independentes entre si:

- **uma amostra de 5 s** por implementação/cenário, com warm-up de 2 s, contra
  uma metodologia que pedia 5×60 s com warm-up de 30 s — uma amostra única não
  tem barra de erro
- **ordem alfabética**, concentrando deriva térmica e temporal em quem ficasse
  por último
- **o gerador rodava dentro do mesmo cluster de um nó**, limitado a 1 CPU,
  disputando os mesmos 8 cores com o sujeito
- lista **fixa de 23 implementações** de 37, sem registro de quem ficou de fora
- **sem gate de paridade**: implementações servindo payloads diferentes eram
  ranqueadas entre si

O substituto é `scripts/run-benchmark-suite.py`:

| | |
|---|---|
| Gerador | `bombardier` na workstation, contra o NodePort 30080 |
| Descoberta | a partir dos overlays, não de lista fixa |
| Ordem | randomizada, **com a semente registrada** na saída |
| Gate | roda `validate-parity.py` antes de medir; fora do contrato é **pulado**, não ranqueado |
| Isolamento | aborta se sobrou pod da implementação anterior |
| Medição | 5×60 s, warm-up 30 s, mediana **com o desvio** |
| Métrica de reserva | CPU por 1000 req, que ainda discrimina quando a rede satura |
| Acesso | apenas chave SSH — o antigo lia senha de variável de ambiente |

O `Service` base virou **NodePort 30080** (era ClusterIP, que a topologia
escolhida não alcança de fora). Porta fixa é seguro porque só uma
implementação roda por vez.

`docs/BENCHMARK_METHODOLOGY.md` foi reescrito para descrever o que de fato se
faz. A versão anterior exigia o gerador "em um nó diferente do servidor" num
cluster de um nó, e definia quatro perfis de recursos, nenhum dos quais era o
que rodava. **O Mode C (5 réplicas) foi registrado como inexecutável aqui**:
5 pods a 7 CPU exigem 35 cores e o nó tem 8.

### Resultados publicados marcados como inválidos

Os 9 documentos de resultados receberam um aviso no topo. Foram preservados
para rastreabilidade, não apagados — mas o repositório é público e eles
estavam ali como se significassem algo.

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
