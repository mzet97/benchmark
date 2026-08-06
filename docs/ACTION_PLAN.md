# Plano de Ação — Benchmark REST/gRPC/GraphQL

**Atualizado**: 2026-08-06 (versão 3 — reauditoria completa da árvore)
**Objetivo**: tornar os resultados deste benchmark defensáveis — hoje eles não são.

> Esta versão substitui a de 2026-08-06 (v2). A v2 descrevia corretamente o
> diagnóstico e as Fases 3/4/5, mas continha dois **erros factuais** na Fase 8
> que esta versão corrige (ver §"O que a versão anterior afirmava e não se
> sustenta"). Todo `Status` e todo `Estado medido` abaixo foi **conferido contra
> a árvore nesta data**, não herdado.
>
> O registro forense das Fases 3/4/5 — o *porquê* de cada regra do contrato —
> está preservado no **Anexo A**. A narrativa completa da versão anterior segue
> disponível em `git show 89702fa:docs/ACTION_PLAN.md`.

---

## Como ler este documento

Cada tarefa tem **critério de saída** e **nível de evidência exigido**. Os dois
não são a mesma coisa, e confundi-los foi o defeito que originou este plano:
"o módulo canônico foi verificado" não é "o serviço foi verificado de ponta a
ponta", e um plano que trata os dois como equivalentes produz um ranking de
implementações que ninguém executou.

Níveis de evidência, do mais fraco ao mais forte:

| Nível | Significado |
|---|---|
| **E0** | Nenhuma. Lido, não executado |
| **E1** | Verificado contra documentação publicada da API/pacote |
| **E2** | Compila (`cargo check`, `go build`, `gradle build`, `dart analyze`) |
| **E3** | Módulo/função executada isoladamente e conferida contra a referência |
| **E4** | Serviço sobe e responde; `validate-parity.py --url` passa |
| **E5** | Medido sob carga, dentro da matriz, com desvio registrado |

Nada entra na matriz de resultados abaixo de **E4**.

---

## Situação em 2026-08-06

Apurada nesta data contra a árvore de trabalho, não herdada da versão anterior.

| Fase | Escopo | Status | Tarefas abertas |
|---|---|---|---:|
| **0** | Tetos de infra | ✅ concluída — topologia medida difere da assumida | 0 |
| **1** | Segurança | ⚠️ árvore limpa; rotação e histórico pendentes | 3 |
| **2** | Topologia de teste | ✅ concluída — config aplicado, QoS Guaranteed validado | 0 |
| **3** | Paridade entre implementações | ✅ concluída, com 3 resíduos | 3 |
| **4** | Deploy unificado | ✅ concluída | 0 |
| **5** | Runner | ✅ concluída | 0 |
| **6** | Reconstrução e re-execução | ❌ não iniciada | 14 |
| **7** | Publicação honesta | ❌ não iniciada | 9 |
| **8** | Dívida estrutural | ✅ concluída (9 itens) | 0 |

### Fechado desde 2026-08-02 — verificado agora, não assumido

A versão anterior listava estes itens como pendentes ou parciais. Foram
conferidos contra a árvore nesta data e estão fechados:

| Item | Como foi conferido |
|---|---|
| `src/java/grpc/grpc-js` — diretório contado como implementação sem código | `find src/java/grpc/grpc-js` não retorna nada. Removido |
| `.gitignore` escondendo os entrypoints Dart | regra `**/bin/` ganhou as negações `!src/dart/**/bin/` e `!src/dart/**/bin/*.dart` (linhas 41-42); `git ls-files src/dart` mostra **5** arquivos em `bin/` rastreados |
| `graalvm/vertx` com POM sem dependência nenhuma | `pom.xml` declara **8** dependências |
| Nenhum artefato de build vazado para o repositório | `git ls-files` não retorna nada sob `target/` ou `build/` |
| Contagem de implementações | `deploy/k3s/overlays/` tem **37 REST + 31 gRPC + 32 GraphQL = 100**, consistente com a correção de 101 → 100 |
| `build/` ignorado | `**/build/` está no `.gitignore` na linha 48 (comentada nas linhas 44-47). **A v2 afirmava o oposto — era falso** |

### O que a versão anterior afirmava e não se sustenta

| Afirmação (v2) | O que se mede hoje (v3) |
|---|---|
| "a relação implementação↔overlay virou 1:1, **verificável em CI**" | `generate-overlays.py --check` **não é executado por nenhum workflow** (conferido: `grep generate-overlays\|validate-parity .github/workflows/*.yml` retorna vazio). Os dois gates das Fases 3 e 4 existem como script e não como gate → Fase 8 |
| "`run_all_benchmarks.py` foi aposentado" | o arquivo **continua na raiz do repositório**, executável (`-rwxr-xr-x`, 1463 B). Aposentar sem remover deixa o caminho aberto para alguém rodá-lo de novo → 8.2 |
| Fase 5 decidiu gerador **fora** do cluster | `deploy/k3s/loadgen/job-wrk.yaml` e `job-ghz.yaml` — os Jobs do gerador *dentro* do cluster — continuam versionados → 8.3 |
| `config/implementations.yaml` como "fonte de verdade" | tem **99** entradas contra 100 overlays (conferido por `grep -c`); **57** ainda marcadas `maturity: planned`; `defaults` declara 1 CPU / 512 Mi / **5 réplicas** — exatamente o perfil que a Fase 4 removeu → 8.4 |
| `-Xms8g -Xmx8g` como argumento nos 6 Dockerfiles nativos do GraalVM | confirmado: **6** Dockerfiles com `Xmx8g` (`graalvm/spring`, `graalvm/graphql/{micronaut,smallrye,spring}`, `graalvm/grpc/{micronaut,quarkus}`). **Nenhum** passa `--gc=G1` (conferido: `grep gc=G1\|UseG1GC src/graalvm/**/Dockerfile` retorna vazio) → resíduo da Fase 3 |
| **(v2 §8.10)** "`build/` não está no `.gitignore`" | **FALSO.** `**/build/` está na linha 48. Item **removido** da Fase 8 nesta versão. O `.gitignore` de Dart `bin/` também está correto (linhas 41-42). A v2 herdou um defeito que já havia sido corrigido |
| **(v2 §8.6)** "`__pycache__/` e `scripts/__pycache__/` versionados" | **IMPRECISO.** `git ls-files __pycache__ scripts/__pycache__` retorna vazio — não estão versionados. São lixo **não rastreado** em disco. O defeito existe (ruído local), mas a descrição "versionado" era falsa |

---

## Topologia decidida (e medida em 2026-08-06)

A topologia assumida era 8 vCPU / 16 GiB / 1 GbE útil. A medição da Fase 0
mostrou que nenhum dos três é real. **A Fase 2 precisa ser refeita contra os
números medidos abaixo**, não contra os que estavam aqui antes.

```
Workstation Windows              VM .51 — K3s (SUT)          VM .52 — PostgreSQL
  Intel I211 1 Gbps        ──>    KVM/Proxmox                 KVM/Proxmox
  iperf3: ~95 Mbps real    NIC     48 vCPU / 62 GiB            PG 18.3
  bombardier/oha/k6/ghz          ├ K3s + SO + argocd + redis   .52:5432
                                 └ pod SUT ... 7 CPU (15% do nó!)
                                    Redis (in-cluster) ←─ master NodePort 30379
```

| Camada | Assumido | Medido | Fonte |
|---|---|---|---|
| VM `.51` total | 8 vCPU / 16 GiB | **48 vCPU / 62 GiB** | `nproc`, `free -h` |
| Rede WS↔`.51` | 1 GbE útil (117 MB/s) | **~95 Mbps (12 MB/s)** | iperf3 + HTTP |
| Redis | externo | **in-cluster** (mesmo nó do SUT) | `kubectl get svc -n redis` |
| CPU steal | desconhecido | **0%** | `vmstat`, `/proc/stat` |

O detalhe completo, com o teto efetivo por cenário, está em
`docs/BASELINE_CEILINGS.md`.

> O pod SUT com `requests: cpu 7, memory 12Gi` (`deploy/k3s/base/deployment.yaml`)
> usa **15% dos 48 cores disponíveis**. O dimensionamento pode ser maior — mas a
> Fase 2 precisa decidir isso explicitamente contra os vizinhos (Redis, argocd).

---

## Invariantes — valem para toda tarefa deste plano

Sete padrões já invalidaram rankings neste repositório. Qualquer alteração em
qualquer implementação é conferida contra esta lista antes de ser dada como
pronta. O detalhe de onde cada um foi encontrado está no Anexo A.

1. **Trabalho escondido no caminho medido.** UUID ou relógio por item,
   `Task.Delay`, log por requisição, schema GraphQL construído por requisição.
   O item do payload é **função pura do índice**.
2. **Paralelismo.** 77 das 100 implementações não tinham nenhum. Runtimes
   single-thread (Node, Bun, Deno, Python, Dart) exigem bootstrap
   multi-processo lendo `BENCH_CPUS`; os demais são cobertos pelo ConfigMap.
   Nove implementações são **deliberadamente** single-process — ver Anexo A.6.
3. **Pool por processo ≠ pool por pod.** O bootstrap divide
   `DB_POOL_MAX / workers` e injeta no filho. Não reintroduzir pool fixo no
   código do serviço.
4. **SQL.** O contrato fixa a query, não só o JSON. `ORDER BY` sem desempate,
   intervalo interpolado na string e JOIN em `order_items` são os três erros
   que reapareceram em quase todas.
5. **Porta 8080, lida de `PORT`.** Já houve 33 implementações fora disso e 67
   Dockerfiles com `EXPOSE`/healthcheck em 3000 ou 50051.
6. **Implementações que não implementam.** Duas respondiam 200 com literais sem
   tocar em PostgreSQL ou Redis. Projeto que não declara dependência de banco é
   suspeito por construção.
7. **Evidência declarada.** Toda conclusão registra seu nível (E0–E5). "Não há
   SDK nesta máquina" é um resultado válido e deve ser escrito como tal.

---

# Fase 0 — Congelar e medir os tetos `[CONCLUÍDA]`

**Nenhum resultado de framework tem significado antes destes números.** Um
framework que atinge 90% do teto da rede e outro que atinge 100% são o mesmo
framework para efeito de ranking, e não há como saber isso sem o teto.

**Executada em 2026-08-06.** Resultados completos em `docs/BASELINE_CEILINGS.md`;
topologia real em `docs/K3S_ENVIRONMENT.md`. As três descobertas que mudam o
plano:

| Descoberta | Assumido | Medido | Impacto |
|---|---|---|---|
| Rede WS↔`.51` | 1 GbE útil (~117 MB/s) | **~95 Mbps (~12 MB/s)** | `/json` n=1000 destruído (~72 rps); todos os cenários mais limitados por rede |
| VM `.51` | 8 vCPU / 16 GiB | **48 vCPU / 62 GiB** (KVM) | pod SUT de 7 CPU usa 15% do nó; Fase 2 precisa redimensionar |
| Redis/PostgreSQL | "externos ao cluster" | **dentro/próximos do cluster** | Redis compartilha o nó do SUT (confounder `/cache`) |

| # | Tarefa | Resultado | Evidência |
|---|---|---|---|
| 0.1 | iperf3 WS↔`.51`, TCP/UDP, ambos os sentidos | **~95 Mbps** simétrico (confirmado por HTTP: 90 Mbps) | E5 |
| 0.2 | Teto de PPS (nginx 79 B, localhost) | **68.614 rps** (interno; rede será medido em 6.13) | E5 |
| 0.3 | Tamanho dos payloads canônicos | 155-160 B/item (n=10/100/1000) | E5 |
| 0.4 | TPS do PostgreSQL (query do contrato) | **25.436 TPS**, `max_connections=100`, `shared_buffers=4GB`, PG 18.3 | E5 |
| 0.5 | Topologia do Redis | **in-cluster**, namespace `redis`, master NodePort `30379` — confounder declarado | E5 |
| 0.6 | redis-benchmark (NodePort 30379, 50 clients) | **~30k ops/s** (PING/SET/GET) | E5 |
| 0.7 | CPU steal do Proxmox | **0%** (idle e sob carga) | E5 |

---

# Fase 1 — Segurança `[PARCIAL]`

A árvore de trabalho está limpa. **Isso não protege nada enquanto a senha não
for rotacionada**: o valor segue recuperável em qualquer commit anterior a
2026-07-31, e o repositório é público.

Concluído:

- [x] 135 arquivos purgados por `scripts/purge-credentials.py` — credenciais só
      vêm do ambiente, variável ausente aborta o processo
- [x] `kubernetes/secrets.yaml` fora do rastreamento
- [x] `credential-scan.yml` é gate real (`trufflehog --fail`, árvore + histórico)

| # | Tarefa | Critério de saída | Dono |
|---|---|---|---|
| 1.1 | **Rotacionar** as senhas do PostgreSQL e do Redis | credencial antiga não autentica mais em nenhum dos dois | **responsável pela infra** |
| 1.2 | **Reescrever o histórico** (`git filter-repo`), `--force` push, invalidar forks e clones conhecidos | `trufflehog` sobre o histórico completo sai limpo | **responsável pelo repositório** |
| 1.3 | Confirmar que `credential-scan.yml` roda no `schedule` e **falha** — não só reporta | um commit de teste com credencial sintética reprova o job | E5 |

Runbook: `docs/SECURITY_REMEDIATION.md`.

> A ordem importa: rotacionar **antes** de reescrever o histórico. Reescrever
> primeiro apaga o rastro sem invalidar a credencial e dá a impressão errada
> de que o problema foi resolvido.

**Estimativa**: ~1 dia, majoritariamente ação humana.

---

# Fase 2 — Topologia de teste `[PARCIAL]`

Aplicar no cluster e na workstation a topologia recalculada contra os números
da Fase 0 (48 vCPU / 62 GiB, ~95 Mbps). Enquanto esta fase não fecha, qualquer
medição carrega CFS throttling, vizinhança de CPU e deriva de cliente que não
são atribuíveis ao framework.

| # | Tarefa | Status | Evidência |
|---|---|---|---|
| 2.0 | Limpar namespace `benchmark` (43 deployments ativos competindo) | ✅ aplicado — todos scaled to 0, orphans removidos, 0 pods | E5 |
| 2.1 | config.yaml do K3s: reservas (4 CPU/4 GiB), `cpu-manager-policy=static`, disable traefik/servicelb/metrics | ⚠️ config versionado em `deploy/k3s/config.yaml` + runbook em `docs/K3S_TOPOLOGY_RUNBOOK.md`; **precisa root para aplicar** (`k8s1` não tem sudo passwordless) | E1 |
| 2.2 | Host: governor `performance` | n/a — VM KVM sem cpufreq; steal=0 confirmado na Fase 0.7 | E5 |
| 2.3 | Workstation: portas efêmeras, power plan, TcpTimedWaitDelay | ⚠️ power plan aplicado (Alto desempenho); portas efêmeras e TcpTimedWaitDelay precisam admin | E5 |
| 2.4 | Instalar `bombardier`, `oha`, `k6`, `ghz` | ⚠️ bombardier 2.0.2 instalado; oha/k6/ghz pendentes | E5 |
| 2.5 | Validar QoS Guaranteed + cores exclusivos | ⚠️ depende do 2.1 (precisa config K3s aplicado) | — |
| 2.6 | Tuning PostgreSQL | adiado — PG 18.3 tem `max_connections=100`/`shared_buffers=4GB`; 25.436 TPS medido. Tuning adicional fica para depois da 2.1 | E5 |

### Dimensionamento aplicado (manifestos)

| Recurso | Antes | Depois | Por quê |
|---|---|---|---|
| Pod SUT CPU | 7 | **40** | 48 totais − 4 reservados (K3s/SO/vizinhos) = 44 allocatable; 40 para SUT, 4 folga |
| Pod SUT memória | 12 GiB | **40 GiB** | 62 GiB totais, deixa 22 para SO/buffers |
| `BENCH_CPUS` | 7 | **40** | alinhado ao CPU limit |
| `GOMAXPROCS` | 7 | **40** | Go lê host, não cgroup |
| `JAVA_TOOL_OPTIONS` heap | 8g | **32g** | 80% dos 40 GiB do contêiner |

> **Bloqueio remanescente**: o passo 2.1 (config.yaml do K3s) exige root no nó.
> Sem ele, `cpu-manager-policy=static` não está ativo e o pod SUT não recebe
> cores exclusivos — as medições carregariam CFS throttling. O config está
> pronto e versionado; falta a aplicação manual descrita no runbook.

**Estimativa restante**: ~2h (aplicação do config K3s + validação 2.5).

---

# Fase 3 — Paridade entre implementações `[CONCLUÍDA — 3 resíduos]`

O contrato, o gate e as 100 implementações convertidas estão fechados. O
registro completo do que foi encontrado e corrigido está no **Anexo A** — e é
material de prevenção de regressão, não histórico decorativo.

Resíduos:

| # | Resíduo | Por que importa | Critério de saída |
|---|---|---|---|
| 3.R1 | **As 6 imagens nativas do GraalVM usam Serial GC**; as JVM usam G1. Nenhum dos 6 Dockerfiles passa `--gc=G1` (reconferido nesta data: 6 com `Xmx8g`, zero com `--gc=G1`) | comparar `graalvm/spring` (nativo, Serial) com `graalvm/gspring` (JVM, G1) como se a diferença fosse "AOT vs JIT" mede principalmente o coletor | `--gc=G1` em tempo de build nos 6, configurado onde cada um exige (plugin Maven, `quarkus.native.additional-build-args`, `-Pnative`) — ou a diferença de coletor declarada em toda linha de resultado dos 6 |
| 3.R2 | **Dart: E0 nas 5 implementações. Deno: os 10 servidores nunca foram executados** (os módulos foram, via Bun) | são 15 das 100 implementações cujo estado real é desconhecido | tratado como 6.7 e 6.8 |
| 3.R3 | `validate-parity.py --url` **nunca rodou contra serviço rodando**, em nenhuma das 100 | todo o nível de evidência atual é E1–E3. O contrato só fecha em E4 | tratado como 6.11 |

**Nenhum dos três é resolvível sem a Fase 6.** Ficam registrados aqui para que
"Fase 3 concluída" não seja lida como "paridade verificada".

---

# Fase 4 — Deploy unificado `[CONCLUÍDA]`

Havia **duas** fontes de configuração de deploy, e a que de fato rodou era a
errada: `src/*/k8s` (101 diretórios, 5 réplicas a 100m/500m) contra
`deploy/k3s/base` (1 réplica a 7 CPU, QoS Guaranteed) — com a metodologia
descrevendo um terceiro perfil. Os 101 diretórios foram removidos; `deploy/k3s`
é a fonte única, e os overlays passaram a ser gerados por
`scripts/generate-overlays.py`, com relação 1:1 verificável por `--check`.

Isso expôs 10 overlays órfãos (todas as variantes `graalvm-*-native`, mais
`csharp-rest-minimal-api`) e 11 implementações sem overlay, que nunca poderiam
ter sido medidas. Também aposentou 18 scripts da topologia antiga.

**Pendência que sobrou desta fase e virou 8.1 e 8.7**: os 18 scripts aposentados
ainda são referenciados pelo `Makefile` (sem `--check` em CI, os targets quebram
em runtime), e a relação 1:1 é "verificável em CI" e não é verificada.

---

# Fase 5 — Runner `[CONCLUÍDA]`

`run_all_benchmarks.py` produziu todos os números publicados e não é
defensável: uma amostra de 5 s por implementação/cenário (contra 5×60 s da
metodologia), ordem alfabética, gerador dentro do mesmo cluster de um nó
limitado a 1 CPU, lista fixa de 23 implementações de 37, sem gate de paridade.

O substituto é `scripts/run-benchmark-suite.py`:

| | |
|---|---|
| Gerador | `bombardier` na workstation, contra o NodePort 30080 |
| Descoberta | a partir dos overlays, não de lista fixa |
| Ordem | randomizada, **com a semente registrada** na saída |
| Gate | `validate-parity.py` antes de medir; fora do contrato é **pulado**, não ranqueado |
| Isolamento | aborta se sobrou pod da implementação anterior |
| Medição | 5×60 s, warm-up 30 s, mediana **com o desvio** |
| Métrica de reserva | CPU por 1000 req, que discrimina quando a rede satura |
| Acesso | apenas chave SSH |

Os 9 documentos de resultados receberam aviso `INVALID — DO NOT CITE` no topo e
foram preservados para rastreabilidade. **Mode C (5 réplicas) foi registrado
como inexecutável aqui**: 5 pods a 7 CPU exigem 35 cores e o nó tem 8.

**Pendências que sobraram desta fase e viraram 8.2 e 8.3**: o runner antigo
continua no repositório, e os Jobs do gerador in-cluster também.

---

# Fase 6 — Reconstrução e re-execução

A fase mais cara e a única que produz números. Divide-se em: **medir o que
compila** (6.1), **consertar** (6.2–6.9), **provar em E4** (6.10–6.12) e
**executar** (6.13–6.14).

## 6.1 — Medir antes de consertar `[primeiro]`

A lista de "implementações que não buildam" da versão anterior era um palpite, e
quando a toolchain JVM foi instalada ela **encolheu**: 3 dos 6 projetos Kotlin
listados como quebrados compilavam limpo. Consertar a partir de palpite gasta
esforço em projeto que já funciona e deixa de fora projeto que não.

| # | Tarefa | Critério de saída |
|---|---|---|
| 6.1 | Construir as **100** implementações, em disco local, e registrar o resultado de cada uma | `docs/BUILD_MATRIX.md`: 100 linhas, cada uma com ✅/❌, a mensagem de erro real e o nível de evidência |

Ferramentas por ambiente e o que precisa ser instalado está em §"Restrições do
ambiente local". Paralelizável por ambiente.

## 6.2–6.9 — Consertar o que 6.1 apontar

Estes são os defeitos **já medidos**, com causa real identificada. A lista final
sai de 6.1 e pode ser maior.

| # | Projeto | Causa real medida | Critério de saída |
|---|---|---|---|
| 6.2 | `kotlin/grpc/spring-grpc` | `build.gradle.kts:32` pede `io.grpc:grpc-spring-boot-starter` — **coordenada que não existe**. A publicada é `net.devh:grpc-spring-boot-starter`. Nunca foi resolvível | E2 |
| 6.3 | `kotlin/grpc/armeria` | o `allOpen` sem plugin foi corrigido; agora para em `:generateProto`, com o `protoc` abortando (`basic_string::_M_construct null not valid`) | E2 |
| 6.4 | `kotlin/grpc/grpc-kotlin` | falha na configuração; pede toolchain Java 17 e não passa disso | E2 |
| 6.5 | `java/quarkus` | `ReadOnlyFileSystemException` no `ZipFileSystem` durante o uber-jar. Tem cara de atrito com o share de rede `Z:`, não de defeito do código — **refazer em disco local antes de concluir qualquer coisa** | E2 |
| 6.6 | `graalvm/vertx` | POM sem dependências (fechado). Restam erros de API: `middleware/CorsHandler` importa `io.vertx.ext.web.handler.CorsHandler` e declara classe de mesmo nome no mesmo arquivo; `Redis.createClient` na sobrecarga errada; símbolos ausentes em `PgPool.pool` e no `DatabaseHandler` | E2 |
| 6.7 | **Dart — 5 implementações** | E0. Não há SDK Dart nesta máquina. As correções da Fase 3 (pool, `numeric` como `String`, `Sql` com parâmetros nomeados, `String.fromEnvironment`, `GRPC_PORT`, SQL fora do contrato, `_parseJson` que devolve `{}`) foram escritas e **nunca compiladas** | instalar SDK; `dart analyze` limpo nas 5 → E2 |
| 6.8 | **Deno — 10 implementações** | os módulos `canonical.ts` foram executados via Bun; **os servidores nunca subiram**. O bootstrap `Deno.Command` com `--allow-run` e o `reusePort` do `oak` são E1 | instalar runtime; cada servidor sobe e responde → E4 |
| 6.9 | Demais falhas apontadas por 6.1 | a versão anterior suspeitava de: Rust gRPC (volo, grpcio), Go gRPC (connectrpc, kitex), Java gRPC (armeria, quarkus), GraalVM gRPC e GraphQL (build nativo), Dart gRPC (versão do protobuf), Rust GraphQL (deps do Cargo), C# GraphQL (ciclos de NuGet), Dart GraphQL (shelf_router), Go REST (`go.sum`) | E2, ou **exclusão declarada da matriz** com o motivo |

> Implementação que não chega a E2 **sai da matriz e isso é publicado**. Um
> ranking de 100 que na verdade mediu 80 e não diz quais 20 faltaram é o mesmo
> defeito, de outra forma.

## 6.10–6.12 — Provar em E4

| # | Tarefa | Critério de saída |
|---|---|---|
| 6.10 | Build e push das imagens de todas as implementações que chegaram a E2 | imagem no registry, com tag rastreável ao commit |
| 6.11 | Para cada implementação: deploy isolado + `validate-parity.py --url` contra o serviço rodando | **primeiro E4 do repositório.** Hash do payload confere nos 5 cenários e em n=10/100/1000 |
| 6.12 | `make smoke` com o gate de contrato embutido, como porta de entrada da matriz | implementação fora do contrato é **pulada e registrada**, nunca ranqueada |

## 6.13–6.14 — Executar

| # | Tarefa | Critério de saída |
|---|---|---|
| 6.13 | Rodar a matriz por protocolo, com checkpoint e retomada | ~100 impls × cenários × 5 repetições × 60 s ≈ **~45 h de máquina**. JSONs conforme `docs/RESULTS_SCHEMA.md`, com a semente registrada |
| 6.14 | Verificação de sanidade da corrida: nenhum resultado acima do teto da Fase 0; desvio entre as 5 repetições dentro do aceitável | resultado que viole o teto é bug de medição, não recorde — investigar antes de publicar |

**Estimativa**: ~6-9 dias de trabalho, mais ~2 dias de calendário para 6.13.

---

# Fase 7 — Publicação honesta

| # | Tarefa | Critério de saída |
|---|---|---|
| 7.1 | Um único `docs/RESULTS_<data>.md`, **gerado** a partir dos JSONs, nunca editado à mão | regenerar a partir dos mesmos JSONs produz byte-idêntico |
| 7.2 | Cada linha com **% do teto de infra** e a flag de gargalo (rede / PPS / PG / Redis / framework) | nenhuma linha sem atribuição de gargalo |
| 7.3 | Cenários não ranqueáveis (Fase 0) publicados como tal | `json-n1000` aparece com o rótulo de limitado por rede, não como ranking |
| 7.4 | Implementações excluídas da matriz listadas com o motivo | contagem publicada = contagem medida |
| 7.5 | `docs/KNOWN_LIMITATIONS.md:37` — ainda afirma *"No real benchmark has been executed yet"*, contradizendo 5 documentos de resultados | o documento descreve o estado real |
| 7.6 | Consolidar os **10** documentos de resultados marcados INVALID (9 em `docs/` + `BENCHMARK_RESULTS_K3S.md`) | um documento histórico, claramente rotulado; os demais removidos |
| 7.7 | `README.md`: corrigir **101 → 100** (linha 3 e 12), e a tabela de ambientes (linha 9 diz **REST 36**, são 37) | os números do README saem de `generate-overlays.py`, não de memória |
| 7.8 | `docs/REPRODUCIBILITY.md`: semente, versões das ferramentas, commit, configuração do cluster | um terceiro consegue repetir a corrida |
| 7.9 | Consolidar os **20** `.md` da raiz (`*_SUMMARY.md`, `*_README.md`, `PROJECT_PROGRESS.md`, `DOCKER_BUILD_FIX.md`, `K8S_REVIEW.md`…) | raiz com `README.md` e nada mais; o que sobreviver vai para `docs/` |

**Estimativa**: ~1,5 dia.

---

# Fase 8 — Dívida estrutural `[CONCLUÍDA]`

Itens que nenhuma fase reivindicava e que hoje contradizem decisões já tomadas.
**Independente das demais fases — executada integralmente em 2026-08-06**, sem
cluster, sem SSH e sem toolchain.

A versão anterior listava 10 itens. A reauditoria desta versão **removeu 1**
(8.10 era falso — `build/` já está no `.gitignore`) e **corrigiu a contagem de
outro** (8.1 referencia 18 scripts inexistentes, não 13). São **9 itens reais,
todos fechados**.

| # | Item | Estado medido (2026-08-06) | Resolução aplicada |
|---|---|---|---|
| 8.1 | `Makefile` referenciava **18 scripts que não existem**: os 11 `benchmark-wrk-*.sh` + `scripts/deploy.sh`, `undeploy.sh`, `build-image.sh`, `collect-metrics.sh`, `list-implementations.sh`, `setup-database.sh`, `smoke-test.sh` — todos aposentados na Fase 4 | `grep -oE 'scripts/...\.sh' Makefile` contra `ls scripts/` confirma os 18 ausentes; `make deploy` quebra | **Makefile reescrito.** Todo target executa ou não existe; deploy via overlays, benchmark via `run-benchmark-suite.py`. Os 7 scripts que existiam (`build-image.sh`, `smoke-test.sh`, `generate-overlays.py`, `validate-parity.py`, `run-benchmark-suite.py`, `collect-metrics.sh`, `setup-database.sh`) são referenciados; os 11 `benchmark-wrk-*.sh` e `deploy.sh`/`undeploy.sh` não são mais |
| 8.2 | `run_all_benchmarks.py` **continuava na raiz**, executável (`-rwxr-xr-x`, 1463 B), apesar de aposentado na Fase 5 | o caminho para reproduzir os números inválidos seguia aberto | **removido** |
| 8.3 | `deploy/k3s/loadgen/job-wrk.yaml` e `job-ghz.yaml` — gerador **dentro** do cluster, contra a decisão explícita da Fase 5 | ambos versionados | **removidos** (diretório `loadgen/` desapareceu por estar vazio) |
| 8.4 | `config/implementations.yaml`: **99** entradas contra 100 overlays; **57** `maturity: planned`; `defaults` com `cpu: "1"` / `memory: "512Mi"` / **5 réplicas** — o perfil que a Fase 4 eliminou | duas fontes de verdade divergentes | **agora gerado** por `scripts/generate-implementations.py` a partir de `src/`, mesma descoberta do `generate-overlays.py`: 100 entradas, todas porta 8080, sem bloco `defaults`. Gate `--check` adicionado ao CI |
| 8.5 | **22 scripts órfãos na raiz** (`fix_*.py`, `fix_*.sh`, `fix_*.js`, `fix_*.ts`, `fix_*.service.py`, `rebuild_rust.py`, `deploy_grpc.py`, `ssh_*.py`, `upload.py`, `test_k8s.py`, `generate_implementations.py` antigo, `rerun_fiber.sh`, `fix_and_deploy.py`) | nenhum era referenciado pelo Makefile, pelos workflows ou pelo runner | **removidos** |
| 8.6 | Lixo de árvore: `teste` (0 B), `src.mod` (6 B), `http.sln`, `__pycache__/` e `scripts/__pycache__/` **não rastreados** em disco | ruído no diff local | **removidos** |
| 8.7 | **Nenhum gate das Fases 3 e 4 rodava em CI**: nem `generate-overlays.py --check`, nem `validate-parity.py --reference` | a 1:1 era "verificável em CI" e não era verificada | **job `contract-gates` adicionado ao `ci.yml`**: roda `generate-overlays.py --check`, `generate-implementations.py --check` e `validate-parity.py --reference` em todo push/PR |
| 8.8 | **`deploy.yml:87` tinha fallback para `src/${LANG}/${FRAMEWORK}/k8s`** — os 101 diretórios que a Fase 4 removeu | o workflow reintroduzia, em runtime, exatamente a segunda fonte de configuração que a Fase 4 eliminou | **fallback removido**; overlay ausente agora é erro. Input `replicas` morto também removido |
| 8.9 | **`smoke-tests.yml` validava uma API que não era a do contrato**: batia em `/api/json` e `/api/users?limit=1`, portas 8000/5000/3000 | o smoke test em CI aprovava implementações contra endpoints que o benchmark não mede | **reescrito**: agora roda `validate-parity.py --url` contra os 5 cenários do contrato na porta 8080, com Postgres+Redis de service container e seed dos arquivos `sql/01..03` |

> ~~**8.10**~~ — **removido nesta versão.** A v2 afirmava que `build/` não estava
> no `.gitignore`. É falso: `**/build/` está na linha 48, e as negações Dart para
> `bin/` estão nas linhas 41-42. O defeito descrito já havia sido corrigido antes
> da v2 ser escrita; a entrada sobreviveu por descuido.

**Estimativa**: ~1,5 dia.

> 8.1, 8.2, 8.3, 8.7 e 8.8 são a mesma classe de defeito: **uma decisão foi
> tomada e registrada em documento, mas o artefato que ela substituiu continuou
> no repositório.** É o mecanismo que produziu as duas fontes de deploy da
> Fase 4 — e 8.8 mostra que ele ainda está ativo: o `deploy.yml` reintroduziria
> `src/*/k8s` em runtime se o diretório voltasse a existir. Fechar a decisão
> inclui remover o que ela aposentou.
>
> 8.9 é de outra classe e é a mais séria das nove: **o CI valida um contrato
> diferente do que o benchmark mede.** Enquanto for assim, `smoke-tests.yml`
> aprovando não é sinal de nada.

---

# Caminho crítico e sequenciamento

```
Fase 8 (dívida estrutural) ──── independente, começa já, ~1,5 dia
Fase 1 (rotação + histórico) ── independente, ação humana, ~1 dia

Fase 0 (tetos) ─→ Fase 2 (topologia) ─→ Fase 6 (rebuild + execução) ─→ Fase 7
   ~1,5 dia         ~1 dia                  ~6-9 dias + 45h máquina      ~1,5 dia
                                                 ↑
                                        Fase 3.R1 (--gc=G1)
```

Dependências que não são óbvias:

| | |
|---|---|
| **6.1 antes de 6.2–6.9** | consertar a partir de palpite já custou esforço uma vez |
| **Fase 0 antes da 2.6** | o tuning do PostgreSQL precisa do `pgbench` de partida para ser comparável |
| **Fase 2 antes de qualquer medição** | sem `cpu-manager-policy=static` a medição carrega throttling não atribuível ao framework |
| **1.1 antes de 1.2** | reescrever o histórico primeiro apaga o rastro sem invalidar a credencial |
| **Fase 8 antes da 6** | 8.1, 8.8 e 8.9 quebram ou desviam justamente os caminhos que a Fase 6 vai usar para construir, implantar e validar |

**Estimativa total**: ~3 a 3,5 semanas de trabalho focado. A Fase 6 concentra
sozinha cerca de 60% do esforço.

---

# Restrições do ambiente local

Fatos desta máquina, não do projeto. Afetam diretamente a Fase 6.

| | |
|---|---|
| Repositório em share de rede `Z:` | já produziu `ReadOnlyFileSystemException` em build Maven (6.5). **Builds pesados em disco local** |
| Não instalados | SDK Dart (6.7), runtime Deno (6.8), Maven/Gradle/kotlinc permanentes, JDK 17/21 |
| Instalação em passadas anteriores | Gradle 8.5, Maven 3.9.9 e JDKs 21/17 foram instalados **no diretório temporário da sessão** — nada no repositório, nada em `~`. Manter esse padrão |
| Cluster | o runner exige chave SSH para o `.51`, sem senha. Não verificado nesta sessão |

---

# Mudanças entre v2 e v3

Para rastreabilidade. Tudo o que não está aqui foi preservado da v2.

| Onde | v2 | v3 |
|---|---|---|
| Fase 8 cabeçalho | "10 itens" | **9 itens reais** (1 removido por ser falso) |
| 8.1 | "13 scripts que não existem" | **18** (11 `benchmark-wrk-*.sh` + 7 outros) — conferido contra `scripts/` |
| 8.6 | "`__pycache__/` versionados" | **não rastreados** (não versionados) — `git ls-files` retorna vazio |
| 8.10 | "`build/` não está no `.gitignore`" | **removido** — falso; `**/build/` na linha 48 |
| "O que a versão anterior afirmava e não se sustenta" | (não existia) | seção nova: registra as duas correções factuais para auditoria |
| 3.R1 | "6 Dockerfiles, nenhum passa `--gc=G1`" | idem, **reconferido**: `grep gc=G1 src/graalvm/**/Dockerfile` retorna vazio; 6 arquivos com `Xmx8g` |
| "Fechado desde 2026-08-02" | (sem `build/`) | adicionada linha: `build/` ignorado confirmado |

---

---

# Anexo A — Registro forense das Fases 3, 4 e 5

Não é histórico decorativo: cada linha abaixo é a razão de existir de uma regra
do contrato, e é o que impede a regressão de voltar sem ser notada. A narrativa
completa está em `git show 89702fa:docs/ACTION_PLAN.md`.

## A.1 Diagnóstico que originou o plano (2026-08-02)

| Problema | Evidência |
|---|---|
| A metodologia documentada nunca foi executada | `docs/BENCHMARK_METHODOLOGY.md` prometia 5×60 s, warm-up de 30 s e ordem randomizada; `run_all_benchmarks.py:94` executava **1×5 s** com warm-up de 2 s, ordem alfabética |
| O gerador de carga era o gargalo | Job wrk com `limits.cpu: 1`, no mesmo nó do SUT, cluster de 1 nó |
| Implementações não comparáveis | Go REST usava `pgx.Conn` (**sem pool**) e "vencia" o teste de DB; outras usavam pool de 10 ou 25 |
| Workers desiguais | Flask/Django com gunicorn `4 workers × 2 threads`, FastAPI com uvicorn `1 worker` — origem do falso insight "Flask bate FastAPI" |
| Payload `/json` divergente | Go: 154 B/item com 16 KB de CSPRNG por request; Node: 106 B/item sem aleatoriedade. **45% mais bytes no Go** |
| Três perfis de recursos conflitantes | metodologia (1 CPU) × `deploy/k3s/base` (250m/2 CPU) × `src/*/k8s` (100m/500m, 5 réplicas — **este foi o usado**) |
| Tabelas inconsistentes | `/json`: FastAPI 110 em 7º acima de 871; `/cache`: Ktor 16.261 em 4º abaixo de 14.869; `/health`: 27.210 na tabela vs 19.562 no resumo |
| Contagem irreal | README dizia 101; `implementations.yaml` tinha 99, das quais 57 `planned` |
| Credenciais em repositório público | 135 arquivos + histórico do Git |

## A.2 Divergências de payload encontradas na conversão REST

Cada uma invalidava o ranking `/json`.

| Implementação | Divergência |
|---|---|
| `go/fiber` | `crypto/rand` por item; `string(rune(id))` — converte o inteiro em code point Unicode, não no texto do número |
| `go/chi,echo,gin` | `time.Now()` dentro do laço (1000 leituras de relógio/req) |
| `python/flask` | **dois `uuid4()` por item** = 2000 UUIDs/req |
| `python/django` | `utcnow()` dentro do laço |
| `nodejs/fastify` | `uuidv4()` por item; schema de resposta filtrava campos |
| `nodejs/nestjs` | ids a partir de 1; envelope sem `timestamp`; **rotas sob `/api`** enquanto o runner batia na raiz; porta 3000 |
| `bun/*` (todas) | ids a partir de 1; `pino-pretty` ligado por request |
| `bun/elysia` | **retornava um array cru, sem envelope algum** |
| `bun/bun_serve` | porta padrão 3000, não 8080 |
| `rust/actix-web` | **dois `Uuid::new_v4()` por item** = 2000 UUIDs/req |
| `rust/axum,rocket,warp` | 1 UUID v4 + 1 `Utc::now().to_rfc3339()` por item |
| `deno/*` | dois `crypto.randomUUID()` por item |
| `csharp/*` (todas) | **1000 itens pré-construídos num construtor estático**, servidos de um array cacheado: mediam só a serialização, enquanto as outras também construíam os itens — e `?n=` era ignorado |
| `csharp/MinimalApi` | envelope só com `items`, sem `count` nem `timestamp` |
| `java,graalvm/{spring,micronaut}` | `{id,name,email,timestamp}`; `Map.of` tem ordem de iteração não especificada — duas execuções da mesma implementação geravam bytes diferentes |
| `java/quarkus` | `{id,name,description,timestamp,random}` com `Instant.now()` e `UUID.randomUUID()` por item |
| `graalvm/helidon` | `Instant.now()` dentro do laço |
| `graalvm/vertx` | **array cru, sem envelope**; ids a partir de 1 |
| `kotlin/spring` | `{id,name,email,active,tags}` — lista de 3 strings por item, inflando o payload |
| `kotlin/ktor` | JSON concatenado à mão num `StringBuilder` — media construção de string, não o serializador pelo qual todas as outras eram medidas |
| `kotlin/http4k` | interpolava um `Map` do Kotlin numa string: saía `{id=0, name=User 0}`, **que não é JSON** |
| `dart/vaden` | ids a partir de 1; `uuid-0001-…` (não é UUID); `DateTime.now()` em `createdAt`; `isActive` era `i % 10 != 0` |
| Python (todas) | workers desiguais; porta 8000 |
| Node/Bun (todas) | single-thread — usariam 1 dos 7 cores |
| Rust (sqlx) | pool no default 10 do sqlx, não `DB_POOL_MAX` |
| JVM (7 configs) | porta 3000; host do Postgres **fixo no código** em quarkus e kotlin/spring; pool 25/5 ou não configurado; log em INFO |

## A.3 Os três erros de SQL recorrentes

| Erro | Onde |
|---|---|
| `ORDER BY` sem desempate — linhas com agregados iguais voltavam em ordem arbitrária, resposta irreprodutível entre execuções | praticamente todas |
| Intervalo não parametrizado: `INTERVAL '%s days'` (o `%s` está **dentro** das aspas, o Postgres lê a string literal), `INTERVAL '${days} days'`, f-string, `String.format` | flask, django, express, fastify, bun ×3, deno ×4, java/spring, java/micronaut, kotlin/spring, dart, vertx |
| JOIN em `order_items` agregando `quantity * price` — query materialmente mais pesada que somar `o.total_amount` | chi, echo, gin, csharp ×3, graalvm ×4, dart |

Nos gRPC/GraphQL, ainda: agregavam `o.total` ou `o.amount`, **colunas que não
existem no schema** (a query falharia em runtime); e em gqlgen, graphene,
strawberry, ariadne e nos dois `async-graphql` **não havia `LIMIT` nenhum** —
devolviam todos os usuários em vez dos 100 do contrato.

## A.4 Trabalho no caminho medido que não devia estar lá

| Implementação | O quê |
|---|---|
| `csharp` (3) | `await Task.Delay(50)` em todo miss de `/cache` — teto de ~20 req/s por conexão |
| `graalvm/gmicronaut` | três chamadas a `getOrSet` por request (três idas ao Redis) para inferir um booleano |
| `kotlin/ktor` | `/db/simple` e `/db/complex` concatenavam JSON à mão, contornando o serializador |
| `graalvm/vertx` | puxava 100 linhas de pedido e somava/mediava em Java; agora o banco agrega |

E dois endpoints que reportavam o oposto do que acontecia: em C# `cached` era
`value.Contains("Cached value")` — verdadeiro exatamente quando o valor
**acabara de ser gerado**; em `graalvm/gspring`, inferido por conter a data de hoje.

## A.5 As duas implementações que não implementavam nada

`kotlin/http4k` respondia 200 em `/db/simple`, `/db/complex` e `/cache` com
literais fixos, **sem declarar dependência de PostgreSQL ou Redis**. Passou por
501 Not Implemented e hoje tem HikariCP dimensionado por `DB_POOL_MAX` e
Lettuce, nas mesmas versões do `src/kotlin/ktor` e com a mesma SQL normativa.

`graalvm/vertx` **não rodava Vert.x**: o `main.class` do POM apontava para um
segundo servidor em `com.sun.net.httpserver.HttpServer`, com `/health` dizendo
"connected" sem tocar em nada. O servidor Vert.x real ao lado nunca era
iniciado. O `Main` agora é um launcher dele.

## A.6 Paralelismo — 77 de 100 não tinham nenhum

O ConfigMap cobre Go, JVM, .NET e Tokio sem tocar em código (~45 implementações).
Mudanças de código onde o runtime é genuinamente single-thread: Node (6,
`cluster`), Bun (2, `Bun.spawn` com `reusePort`), Python (2, `uvicorn --workers`)
e o pool de threads do gRPC Python (2, que lia `GRPC_MAX_WORKERS` — variável
fora do ConfigMap, então todas rodavam com o default fixo de 10).

**Nove implementações são deliberadamente single-process**, e isso não é
esquecimento: `bun/{grpc-js, nice-grpc, connectrpc, graphql-hono}` e
`deno/{grpc-js, nice-grpc, connectrpc}` fazem bind por caminhos que **não
ativam `SO_REUSEPORT`** (`bindAsync`, `createServer` do `node:http`/`node:http2`,
`fastify.listen`, handler default). Um bootstrap multi-processo daria
`EADDRINUSE` em todos os workers menos o primeiro.

Deno chegou a 7 de 10 com fork de `BENCH_CPUS` workers via `Deno.Command`
(`--allow-run` é exigido pelo fork). `oak` foi o caso não óbvio: `ListenOptions`
não declara `reusePort`, mas o servidor padrão repassa as opções direto ao
`Deno.serve`, então a opção chega ao socket — o cast existe só para o type checker.

Dart: `BENCH_CPUS` isolates, cada um rodando o servidor inteiro, todos aceitando
de um socket aberto com `shared: true`. Só o isolate 0 observa sinais.

**JVM/GraalVM**: nenhuma implementação fixava heap (cada uma rodava com 1/64 do
limite do contêiner como heap inicial e passava a medição crescendo o heap), e
só 4 de ~30 fixavam o coletor — as 4 traziam `-XX:+UseG1GC -XX:MaxGCPauseMillis=20`
no próprio Dockerfile, o que é um ranking de quem editou o Dockerfile. Os 4
flags próprios foram removidos (linha de comando vence `JAVA_TOOL_OPTIONS`).

## A.7 O pool era por processo, não por pod

O bootstrap multi-processo criou um problema que não existia: com 7 workers,
cada um abrindo `DB_POOL_MAX` conexões, uma implementação multi-processo rodaria
contra **7× o pool** de uma single-process. O bootstrap passou a calcular
`DB_POOL_MAX / workers` e injetar no ambiente do filho — Node (9), Bun (5),
Deno (7), Dart (5).

Os pools do Python que a Fase 3.2 dava como resolvidos e não estavam:
`graphql/{ariadne,strawberry,graphene}` com `ThreadedConnectionPool(1, 10)` fixo
× 7 workers = 70 conexões; `grpc/*` com `maxconn=10` fixo; `fastapi` com
`max_size=25` × 7 workers = **175 conexões** contra as 32 de todo mundo.

`flask` e `django` ficaram como estão, deliberadamente: uma conexão por worker
gunicorn com `--threads 1` já limita a 7 queries simultâneas. O teto é do modelo
sync, não da configuração, e é o que uma implantação real teria.

## A.8 Dart — o ambiente que nunca foi executado

| Problema | Onde | Efeito |
|---|---|---|
| **`bin/` no `.gitignore`** | 4 de 5 | a regra `[Bb]in/` do .NET escondia `src/dart/*/bin/server.dart`: num clone limpo essas implementações **não tinham entrypoint**. É parte de por que nunca foram consertadas — não estavam visíveis. **Fechado** |
| `numeric` decodifica para `String` | 5 de 5 | `SUM/AVG` sobre `DECIMAL(10,2)` chegam como `String`; todas faziam `as num` → exceção em runtime em `/db/complex` |
| Conexão única, sem pool | 5 de 5 | mesmo defeito do `pgx.Conn` do Go e do client sob `Mutex` do actix-web |
| `Sql(sql)` com parâmetros nomeados | angel3, leto, graphql-server2 | o construtor default manda o SQL sem modificação: `@name` nunca era substituído |
| `String.fromEnvironment` | graphql-server2 | lê `-D` de compilação, não o ambiente: conectava em `localhost:5432` **independentemente do ConfigMap** |
| `GRPC_PORT` | grpc-dart | variável fora do ConfigMap — escutaria em 50051 com o Service em 8080 |
| `_parseJson` que devolve `{}` | graphql-server2 | `/db/simple` gravava no Redis com `Map.toString()` e lia de volta por um stub vazio — **da segunda requisição em diante respondia objeto vazio sem tocar no PostgreSQL** |
| `/cache` que nunca escrevia | graphql-server2 | reportava `cached: false` sempre |
| `SETEX ... 3600` | grpc-dart | contrato é `CACHE_TTL` (300). Numa corrida de 5×60 s uma chave de 300 s expira e uma de 3600 s não |
| Log por requisição | vaden, leto, graphql-server2 | `shelf.logRequests()` com `LOG_LEVEL=error` no ConfigMap |
| `app.startServer` | angel3 | não existe em `Angel`; quem tem é o driver (`AngelHttp`) |
| Schema por requisição | graphql-server2 | `buildSchema()` dentro do handler |

**Nível de evidência: E1.** APIs conferidas contra a documentação publicada de
cada pacote; um verificador de balanceamento de delimitadores ciente de strings
e interpolação do Dart roda limpo nos 19 arquivos. **Isso não substitui
`dart analyze`** — ver 6.7.

## A.9 Porta — 33 implementações não escutavam em 8080

| Grupo | Efeito |
|---|---|
| fallback errado, mas liam `PORT` (20) | funcionavam sob o ConfigMap; armadilha fora dele |
| **variável errada (3)** | os gRPC Python liam `GRPC_PORT`, que não está no ConfigMap — **pod nunca alcançável** |
| **porta fixa em config (5)** | `graalvm/grpc/micronaut` (3000), os dois Quarkus gRPC e `kotlin/grpc/spring-grpc` (50051), `kotlin/graphql/spring-graphql` (3000) |

Mais 67 Dockerfiles com `EXPOSE` e healthcheck em 3000/50051: um healthcheck na
porta errada marca como unhealthy um contêiner que funciona.

## A.10 Erros de compilação encontrados de passagem

Rust: `Cargo.toml` do axum com `profile-rustflags` instável (quebrava o parse do
manifesto inteiro), `StatusCode`/`Deserialize` sem import, `EnvFilter` sem a
feature `env-filter`, `if let Some(x): T = ...` (sintaxe inválida) em axum e
rocket, `rocket::Shield` movido para `rocket::shield::Shield`, e os macros
`sqlx::query!`/`query_as!` exigindo `DATABASE_URL` **em tempo de build** — algo
que nem o repositório nem o Dockerfile forneciam.

JVM/Kotlin: os três `JsonController.java` de `java/spring`, `graalvm/spring` e
`graalvm/gspring` estavam com **chaves duplicadas** (`{{`/`}}`), artefato de um
template `str.format` nunca desescapado; `kotlin/http4k` com
`val JSON = CONTENT_TYPE of APPLICATION_JSON` sem anotação de tipo;
`kotlin/ktor` sem `import io.ktor.server.application.*` e com TTL `Int` onde
`getOrSet` pede `Long`; `kotlin/grpc/armeria` com bloco `allOpen { }` sem o
plugin aplicado — o próprio script de build não compilava.

gRPC/GraphQL: campo `Cache` colidindo com o método `Cache` no `gqlgen` e
`graphql-go`; conversão de `*db.User` no `graphql-go`; `Decimal: FromSql` nos
dois `async-graphql`; parâmetro opcional antes de obrigatório no HotChocolate;
`IDatabase.TimeToLiveAsync`, que não existe — o nome é `KeyTimeToLiveAsync`.
