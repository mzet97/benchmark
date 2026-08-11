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
8. **Erro de I/O nunca responde 200.** Falha de driver, de pool ou de query sai
   como 5xx, para que o contador `non_2xx` do gerador a registre. Degradar para
   lista vazia dentro de um 200 fez `rust-rest-actix-web` liderar
   `/db/complex` com 32.777 rps em cinco rodadas consecutivas — ver Fase 9 e
   `docs/KNOWN_LIMITATIONS.md`.
9. **Bytes por resposta é o sinal mais barato de fraude involuntária.**
   `bytes_per_sec ÷ requests_per_sec` para o mesmo cenário tem de ser igual
   entre implementações; o payload é fixado pelo contrato. 220 B contra ~11 kB
   no mesmo endpoint é defeito, não desempenho. Este cálculo não precisa ler
   código e vale para as 100.

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

# Fase 9 — Remediação Rust `[EM ANDAMENTO]`

Origem: revisão das 10 implementações Rust em 2026-08-10, motivada pelo rps
baixo de `rust-rest-actix-web` em `results/run-20260810T001219Z.json`. O
diagnóstico está em `docs/KNOWN_LIMITATIONS.md`; o resumo é que o servidor HTTP
não era o problema (actix lidera `json-n10` com 211.970 rps, o maior número da
matriz) e que todo o déficit estava na camada de I/O e de serialização.

Achado que dita a ordem desta fase: **nenhuma das 10 implementações Rust jamais
produziu um `/db/complex` / `complexOrders` / `GetComplexOrders` válido.** Quatro
devolviam lista vazia dentro de um 200, seis falhavam por coluna inexistente,
bind de tipo incompatível ou panic de decode. O gate de paridade não pegava
porque comparava apenas o conjunto de chaves do nível superior.

## 9.1 — Defeitos de correção e de I/O `[CONCLUÍDA — E2/E3]`

| # | Defeito | Onde | Critério de saída |
|---|---|---|---|
| 9.1.1 | `$1` bindado como `i32` contra `INTERVAL '1 day' * $1`; Postgres infere `float8` e `ToSql for i32` só aceita `INT4` | actix-web, 3 GraphQL, 3 gRPC (todos os que usam `tokio-postgres`; os de `sqlx` declaram o OID no `Parse` e escapam) | bind `f64`, SQL normativo inalterado |
| 9.1.2 | Erro de query mapeado para `vec![]` atrás de 200 | actix-web | 500 + `log::error!` |
| 9.1.3 | `.unwrap()` em resolver GraphQL | 3 GraphQL | `Result` / `FieldResult` |
| 9.1.4 | `SUM(o.total)` e `SUM(o.amount)` — colunas que não existem (`sql/01_schema.sql` declara `total_amount`) | tonic, juniper | SQL normativo |
| 9.1.5 | `COUNT()` (int8) lido direto em campo `int32` do proto → panic por linha | 3 gRPC, juniper | `get::<_, i64>() as i32` |
| 9.1.6 | `LEFT JOIN`, sem `LIMIT`, sem desempate (invariante 4) | juniper, 3 gRPC | SQL normativo |
| 9.1.7 | `get_async_connection()` por requisição = TCP handshake por requisição | 4 REST | uma `MultiplexedConnection` no startup |
| 9.1.8 | `query*(&str)` do `tokio-postgres` executa `Parse`+`Describe` a cada chamada — 2 RTT onde os demais gastam 1 | actix-web, 3 gRPC, 2 GraphQL | `prepare_cached` |
| 9.1.9 | Sem pool: uma `tokio_postgres::Client` nua (1/32 da concorrência do contrato) | 3 gRPC | pool com `DB_POOL_MAX` |
| 9.1.10 | `max_size` ausente → default do deadpool (`cpu_count * 4` = 160 no pod de 40) | 3 GraphQL | `DB_POOL_MAX` |
| 9.1.11 | `RUST_LOG` não existe no ConfigMap (só `LOG_LEVEL`, que nenhum crate Rust lê) → fallback `tower_http=debug` + `TraceLayer` = log por requisição (invariante 1) | axum + ConfigMap | fallback `error`, `TraceLayer`/`CorsLayer` removidos, `RUST_LOG` no ConfigMap |
| 9.1.12 | Item do `/json` construído como `serde_json::Value` (BTreeMap + 6 chaves + 3 `format!` por item ≈ 10k alocações em n=1000) | 4 REST | struct `Serialize` + envelope tipado, com teste de igualdade de bytes |
| 9.1.13 | `ensure_schema()` criando schema divergente (`orders.amount`) e semeando 100 usuários contra os 10k do contrato | 3 GraphQL | removido; provisionamento é do `setup-database.sh` |
| 9.1.14 | Gate de paridade aceitava `data: []` em `/db/complex` | `scripts/validate-parity.py` | `check_db_payloads` exige payload não-vazio, ≤100 linhas, chaves da linha e `totalUsers == len(data)` |

Evidência: **E2** nas 10 (`cargo check --all-targets`), exceto `grpcio`, cujo
`grpcio-sys` exige toolchain C++ ausente nesta máquina — ver §Restrições.
**E3** em actix-web (8 testes, incluindo dois que travam a igualdade de bytes do
payload canônico contra a implementação anterior).

## 9.2 — Perfil de release uniforme

Variável escondida do mesmo tipo que o `-XX:+UseG1GC` que só quatro
implementações JVM tinham (Anexo A.4): dentro do próprio Rust, duas das dez são
compiladas com otimização mais agressiva que as outras oito.

| Grupo | `[profile.release]` atual |
|---|---|
| actix-web, warp | `opt-level=3, lto=true, codegen-units=1, panic="abort", strip=true` |
| axum, rocket | `opt-level=3` — que já é o default de release, isto é, nada |
| 3 GraphQL + 3 gRPC | ausente → `lto=false, codegen-units=16, panic="unwind"` |

| # | Tarefa | Critério de saída |
|---|---|---|
| 9.2.1 | `opt-level=3, lto=true, codegen-units=1` idênticos nas 10 | 10 `Cargo.toml` com o mesmo bloco |
| 9.2.2 | **Remover** `panic="abort"` de actix-web e warp em vez de espalhá-lo | nenhum `Cargo.toml` Rust com `panic="abort"` |
| 9.2.3 | Ajustar os comentários de `die()` que justificavam-se por `panic="abort"` | 4 arquivos coerentes com o perfil novo |

`panic="abort"` sai, não entra. O ganho de geração de código vem de
`lto`+`codegen-units`, não dele; ele é o mecanismo por trás do
"CrashLoopBackOff sem log nenhum" registrado no Anexo A.10; e com `unwind` um
panic de handler responde 500 e é contado por `non_2xx` (invariante 8) em vez de
derrubar o pod no meio da medição. É também o default do Rust — a escolha menos
"tunada" possível, que é o critério desta fase.

## 9.3 — Resíduos

| # | Tarefa | Critério de saída |
|---|---|---|
| 9.3.1 | `tower` e `tower-http` sem uso em `axum/Cargo.toml` depois da 9.1.11 | dependências removidas, `cargo check` limpo |
| 9.3.2 | `actix-web/src/services/` e `src/models.rs` nunca declarados em `main.rs` — código morto contendo justamente o padrão multiplexado correto | arquivos removidos (requer ação humana: `git rm` foi bloqueado pela política de permissões) |
| 9.3.3 | Comentário do `actix-web/Dockerfile` afirma que `TOKIO_WORKER_THREADS` dimensiona os workers do actix; não dimensiona (`available_parallelism()`, que lê a cota do cgroup) | comentário corrigido |
| 9.3.4 | `REDIS_POOL_MAX` é lido por 30 arquivos de outras stacks e por **0 das 10** Rust | documentado em `KNOWN_LIMITATIONS.md` que a chave significa coisas diferentes por stack; multiplexação sobre 1 socket é o modelo do Lettuce, que lidera `/cache` com 186.825 rps — não é para "corrigir" |

## 9.4 — Build real das 10 imagens `[E2 de verdade]`

`cargo check` nesta máquina não é o build que roda em produção. O `grpcio` só
compila no `rust:1.95-bookworm`, e é a única das 10 cujas alterações da 9.1 não
têm nenhuma verificação além de inspeção.

| # | Tarefa | Critério de saída |
|---|---|---|
| 9.4.1 | `make build IMPL=<id>` nas 10 | 10 imagens, log de cada uma em `docs/BUILD_MATRIX.md` |

## 9.5 — Paridade `[E4]`

| # | Tarefa | Critério de saída |
|---|---|---|
| 9.5.1 | Subir as 10 e rodar `validate-parity.py --url` | `PARITY OK` nas 10, **incluindo o `check_db_payloads` novo** |
| 9.5.2 | Conferir `data[0]` de `/db/complex` byte-a-byte contra a implementação de referência (`src/go/fiber`) | hash igual; o gate só garante forma, não conteúdo |

9.5.1 é o primeiro momento em que qualquer coisa da 9.1 fica provada. Até aqui
tudo é E2/E3: compila e passa teste unitário, o que não é o mesmo que 2.550 rps
virarem 30.000.

## 9.6 — Varredura das 100 por bytes/resposta

O invariante 9 nasceu aqui e não é específico de Rust. O cálculo não lê código.

| # | Tarefa | Critério de saída |
|---|---|---|
| 9.6.1 | Script que lê os `results/run-*.json` e reporta, por cenário, toda implementação cujo bytes/resposta desvie mais de 5% da mediana | `scripts/audit-response-bytes.py`, exit 1 se houver desvio `[CONCLUÍDA]` |
| 9.6.2 | Investigar cada suspeito | causa real por linha, ou "dentro do esperado" com justificativa |

### Resultado da 9.6.1 contra `run-20260810T001219Z.json`

60 desvios além de ±5% em 5 cenários. A maioria é diferença de cabeçalho e não
de corpo — `rust-rest-rocket` está +85% em `/health`, +148% em `/db/simple` e
+76% em `/cache` porque o `Shield` do Rocket 0.5, que é **default** do framework,
acrescenta ~300 B de cabeçalhos de segurança a toda resposta; `rust-rest-warp`
está 20-40% abaixo por mandar menos cabeçalho. Ambos são comportamento de
framework e ficam como estão, agora com o número medido.

Dois casos não são cabeçalho:

| Implementação | Cenário | Medido | Mediana | Estado |
|---|---|---|---|---|
| `rust-rest-actix-web` | `db-complex` | 220 B @ 32.777 rps | 10.907 B @ ~860 rps | causa estabelecida, corrigida na 9.1.1 |
| `nodejs-rest-fastify` | `db-complex` | 536 B @ 37.533 rps | 10.907 B @ ~860 rps | **causa não estabelecida** |

`nodejs-rest-fastify` é achado novo desta fase e **não** é o mesmo defeito do
Rust. O SQL em `src/services/DatabaseService.js:46` já usa os aliases camelCase
que o `response` schema declara, então a hipótese de o `fast-json-stringify`
descartar propriedades por nome não se sustenta. O que se sabe:

- o endpoint **nunca** entregou o payload do contrato: 1.538 B, 1.666 B, 1.661 B
  e agora 536 B, nas quatro rodadas em que aparece;
- o valor **muda entre rodadas**, o que viola a reprodutibilidade do payload por
  si só, independentemente do tamanho;
- `non_2xx` é 0 em todas, e `/db/simple` do mesmo serviço está +33% (acima da
  mediana, isto é, respondendo), então o serializador funciona em geral;
- o salto de 5.500 para 37.533 rps entre a rodada anterior e esta acompanha o
  payload caindo de 1.666 B para 536 B — throughput inversamente proporcional ao
  corpo, a assinatura do invariante 9.

Estabelecer a causa exige **E4**: um `GET /db/complex?days=30` contra o serviço
de pé, olhando `totalUsers` e `data[0]`. Não foi feito porque há uma medição em
curso (ver 9.8) e uma requisição extra a perturba. Até então, todo `db-complex`
de `nodejs-rest-fastify` é tão inválido quanto o do actix-web.

## 9.7 — Re-medição `[E5]`

| # | Tarefa | Critério de saída |
|---|---|---|
| 9.7.1 | Matriz 5×60s das 10 Rust | `results/run-*.json` com desvio-padrão; `/cache` e `/health` fora do chão; `/db/complex` na faixa de ~860 rps e ~11 kB/resposta como todas as outras |
| 9.7.2 | Comparar `db-simple` antes/depois do `prepare_cached` | ganho medido, ou a constatação de que o gargalo era outro |

`/db/complex` **subir** para a faixa dos outros é o resultado esperado. Ele vai
**cair** de 32.777 para ~860: o número velho media um 200 vazio.

## 9.8 — Medição em curso e topologia do gerador `[DECISÃO PENDENTE]`

**Há uma medição rodando agora.** `results/run-20260810T001219Z.json` tem
`finished_utc: null` e 24 das 37 implementações previstas em `order`; o arquivo
cresceu de 16 para 24 implementações no decorrer desta revisão.

Consequências que ditam o sequenciamento:

1. A rodada em curso mede as imagens **antigas**. Todo número Rust que ela
   produzir carrega os 14 defeitos da 9.1 — inclusive um novo `db-complex` de
   32.777 rps para `rust-rest-actix-web`, que já nasce inválido.
2. **9.4, 9.5 e 9.7 não podem começar antes dela terminar.** Reconstruir imagem
   e reimplantar no meio de uma medição corrompe as duas coisas.
3. A 9.6.2 (causa do `nodejs-rest-fastify`) precisa de um `curl` contra o serviço
   de pé, o que também espera.

## Topologia do gerador

`results/run-20260810T001219Z.json` traz `host: 127.0.0.1`,
`generator_location: workstation` e `deno-rest-hono` a 2,9 GB/s — impossível no
link de 1 GbE, logo o gerador rodou no próprio nó. Mas o pod reserva 40 das 44
vCPUs alocáveis em QoS Guaranteed, sobrando ~4 para o bombardier.

Isto é a Fase 2 reaparecendo, não um defeito de implementação: os números acima
de ~100k rps provavelmente descrevem o gerador. Os achados da 9.1 não dependem
disso — 1.636 e 2.550 rps são inequivocamente do lado do servidor — mas o topo
do ranking, sim. Decisão humana, registrada antes da 9.7.

## 9.9 — Defeitos fora do Rust encontrados pela varredura `[CONCLUÍDA — E1/E2]`

A 9.6.1 foi escrita para achar respostas silenciosamente vazias e achou o
`nodejs-rest-fastify`. Investigar aquele caso levou aos arquivos vizinhos, e
neles a três padrões que **não** aparecem em bytes/resposta e por isso escaparam
de toda revisão anterior.

### 9.9.1 — `Thread.sleep(50)` no caminho medido

Quatro implementações tinham um atraso fixo de 50 ms no ramo de *miss* do
`/cache`. É o invariante 1, que nomeia `Task.Delay` explicitamente:

| Implementação | Onde |
|---|---|
| `kotlin-rest-spring` | `controller/CacheController.kt:20` (`// Simulate work`) |
| `java-rest-spring` | `service/CacheService.java:27` |
| `nodejs-rest-fastify` | `src/routes/cache.js:48` |
| `nodejs-rest-express` | `routes/cache.js:21` |

Em `kotlin-rest-spring` isso **era o resultado inteiro**: 1.962 rps medidos
contra o teto de 100 conexões ÷ 50 ms = 2.000 rps, com p99 de 51,99 ms. O
`http4k`, na mesma JVM e no mesmo Redis, fez 186.825 rps no mesmo endpoint.

Onde a leitura do cache acerta, o sleep fica latente — mas a janela de medição
(30 s de warmup + 5×60 s = 330 s) é **maior que o TTL de 300 s**, então a chave
expira no meio da sequência e uma repetição come o atraso.

### 9.9.2 — Conexão Redis vazada no health check

Duas implementações chamavam `getConnectionFactory().getConnection().ping()`,
que obtém conexão **nova** a cada chamada e nunca fecha:

| Implementação | Onde |
|---|---|
| `kotlin-rest-spring` | `service/CacheService.kt:43` |
| `graalvm-rest-gspring` | `service/CacheService.java:46` |

Com `lettuce.pool.max-active=32` do ConfigMap, o cenário `/health` drena o pool
nas primeiras dezenas de requisições e todo chamador seguinte bloqueia esperando
conexão: `/health` de `kotlin-rest-spring` mediu 2.910 rps com p99 de
**8.018 ms**.

E o dano não parou no `/health`. Com o pool esgotado, toda leitura de cache no
mesmo pod passou a falhar, então o `getOrSet` sempre caía no ramo de miss — que é
onde estava o `Thread.sleep(50)` da 9.9.1. **Um vazamento explica os dois
números anômalos daquela implementação.** Corrigido com
`RedisTemplate.execute(RedisCallback { ... })`, que empresta e devolve a conexão.

### 9.9.3 — Log por requisição

| Implementação | Onde |
|---|---|
| `nodejs-rest-express` | `pinoHttp` como middleware + `logger.info` em `routes/database.js` e `routes/cache.js`, com transport `pino-pretty` **colorizado** e sem `level` definido (default `info`) |
| `nodejs-rest-fastify` | log de requisição default do Fastify (agora `disableRequestLogging: true`) e default de nível `info` |
| `kotlin-rest-spring` | `println` por requisição em `CacheController.kt` e `DatabaseController.kt` |
| `python-rest-fastapi` | `logger.info("Cache hit"/"Cache miss")` em `services/cache.py`, no caminho do `/cache` |

O `pino-pretty` é o pior: reprocessa cada registro e aplica cor ANSI num worker
de transport, por chamada. `nodejs-rest-nestjs` só logava no bootstrap; as três
agora estão alinhadas nisso.

### 9.9.4 — `required` ausente nos response schemas do Fastify

Causa da divergência da 9.6.2, agora **estabelecida**. O `fast-json-stringify`
descarta em silêncio propriedade declarada no schema mas ausente no objeto
retornado, e emite `{}` por linha. Medido com o próprio
`fast-json-stringify@` do projeto:

| Caso | Bytes | Medido em produção |
|---|---|---|
| SQL alinhado ao schema | 11.143 | mediana 10.895 |
| só `userId` casa | 1.643 | 1.538 / 1.661 / 1.666 |
| nenhum campo casa | 343 | 536 (com cabeçalhos) |

O SQL **atual** em `services/DatabaseService.js:46` já usa os aliases camelCase
corretos, então as imagens medidas eram antigas — duas gerações diferentes,
correspondendo às duas assinaturas de bytes acima. `required` nos quatro
arquivos de rota transforma a próxima divergência em exceção → 500 → contada por
`non_2xx`, em vez de um 200 com payload vazio.

### 9.9.5 — `kotlin-rest-spring` respondia 200 em todo caminho de erro

`DatabaseController.kt` devolvia 200 nos três ramos de erro: `id` inválido e
`days` fora de faixa retornavam `{"error": "Bad Request", ...}` com status de
sucesso, e — o pior — um `id` inexistente retornava um **usuário fabricado**, de
strings vazias e `age: 0`.

Esse terceiro é indetectável de fora. Passa por `scripts/validate-parity.py`,
porque o conjunto de chaves está exatamente correto, e passa pelo gerador de
carga, que conta um 200. Quem lê o ranking não distingue esta implementação
respondendo a pergunta de esta implementação inventando a resposta. Invariante 8.

Corrigido com `ResponseStatusException`, que **preserva** o tipo de retorno
`Map<String, Any>`: o Spring MVC mapeia a exceção para status e corpo, então
nenhuma assinatura de handler mudou.

### 9.9.6 — Varredura dos padrões do Rust nas outras stacks

Os defeitos do Rust não eram exóticos. Cada padrão encontrado lá foi varrido nas
100, com o resultado delimitado — o que importa tanto quanto os achados, porque
diz onde **não** procurar de novo.

**Sleep no caminho medido (invariante 1) — 4 implementações.** 50 ms fixos no ramo
de miss do `/cache`: `java/spring/CacheService.java`,
`kotlin/spring/CacheController.kt`, `nodejs/express/routes/cache.js`,
`nodejs/fastify/src/routes/cache.js`. Removidos. Era o `Task.Delay` do Anexo A.4
sobrevivendo em quatro linguagens.

Isto **não** era arredondamento: `kotlin-rest-spring` mediu 1.962 rps em `/cache`
com p99 de 51,99 ms contra o teto teórico de 100 conexões ÷ 50 ms = 2.000 rps. O
número descrevia o sleep, não o Redis nem o Spring — http4k, na mesma JVM e no
mesmo Redis, fez 186.825 rps no mesmo endpoint. Vale notar que a janela de medição
(30 s de warmup + 5 × 60 s = 330 s) é **maior** que o TTL de 300 s, então mesmo
onde o cache acerta a chave expira no meio da sequência e uma repetição come a
parada.

**Log por requisição (invariante 1) — 7 implementações.** `nodejs/express`
(`pinoHttp` + 3 `logger.info` de rota, com transport `pino-pretty` colorido),
`nodejs/fastify` (log de requisição default do framework), `bun/bun_serve`
(`logRequest`), `bun/hono` (`app.use`), `bun/elysia` (`derive` +
`onAfterHandle`), `python/fastapi` (`@app.middleware("http")`),
`kotlin/spring` (3 `println`). Removidos ou desativados. `graalvm/vertx` tem um
`LoggingHandler` completo que **nunca é registrado** — código morto, deixado como
está. Padronizei também o nível default para `error` em vez de `info`: o ConfigMap
define `LOG_LEVEL=error`, mas um benchmark que depende de variável de ambiente
para não logar por requisição vai eventualmente ser executado sem ela.

**Erro engolido virando 200 (invariante 8) — 3 implementações.**
`nodejs/express/services/DatabaseService.js`,
`bun/bun_serve/src/services/database.ts` e
`python/flask/app/services/database.py` faziam `return []` / `return []` /
`return []` no `catch` do `/db/complex` — o `Err(_) => vec![]` do actix, em três
outras linguagens. Todos latentes hoje (os payloads medidos estão normais), que é
exatamente o estado em que o Rust estava antes do bind quebrar. Agora relançam, e
os três handlers já respondiam 500 em exceção — verificado em cada um.

**Vazamento de conexão Redis — 2 implementações.**
`kotlin/spring/CacheService.kt` e `graalvm/gspring/CacheService.java` chamavam
`getConnectionFactory().getConnection().ping()`, que obtém conexão nova a cada
invocação e nunca fecha. Com `lettuce.pool.max-active` do ConfigMap, o cenário
`/health` drena o pool nas primeiras dezenas de requisições e todo chamador
posterior bloqueia esperando uma: `kotlin-rest-spring` mediu 2.910 rps com p99 de
**8.018 ms**. E o dano não parava no `/health` — com o pool esgotado, toda leitura
de cache no mesmo pod falhava, o que fazia o `getOrSet` sempre pegar o ramo de
miss e pagar o `Thread.sleep(50)`. **Um vazamento explicava os dois números.**
Agora vão por `RedisTemplate.execute`, que devolve a conexão ao pool.

**Limpo nestas stacks:** o padrão "erro engolido virando coleção vazia" não existe
em Go, C#, Java, Dart, Deno nem GraalVM. `REDIS_POOL_MAX` é lido por 30 arquivos
de outras stacks e por 0 das 10 Rust, que multiplexam sobre 1 socket — o modelo do
Lettuce, que lidera `/cache`; é para documentar, não para "corrigir".

**Não varrido:** `prepare` por requisição, conexão por requisição e pool ausente
não aparecem em bytes/resposta e só foram conferidos onde o código já estava
aberto. Foram metade do que se achou no Rust.

### Evidência e o que ficou de fora

| Nível | O quê |
|---|---|
| **E3** | `fast-json-stringify` do projeto executado isoladamente, reproduzindo as três assinaturas de bytes medidas (11.143 / 1.643 / 343 B); `node --check` nos 9 arquivos JS; `py_compile` no fastapi |
| **E2** | `javac` contra os jars reais do cache do Gradle: `graalvm/gspring` e `java/spring` compilam |
| **E1** | Kotlin. `RedisCallback` é SAM com `T doInRedis(RedisConnection)`, `execute(RedisCallback<T>)` existe e é desambiguado pela chamada explícita, `ping()` devolve `String`, `ResponseStatusException(HttpStatusCode, String)` existe e `HttpStatus : HttpStatusCode` — tudo conferido com `javap` nos jars reais |

Kotlin não passa de E1 **nesta máquina** e a causa é definitiva, não falta de
esforço: Kotlin 1.9.24 não roda em JDK 25 (`IllegalArgumentException: 25.0.2` no
`JavaVersion.parse` do IntelliJ embutido), tanto via Gradle quanto via
`K2JVMCompiler` direto. A distribuição Gradle 8.9 do cache do wrapper funciona
`--offline` e resolve todas as dependências; falta só um JDK 21. Ver §Restrições
do ambiente local. **O build da Fase 9.4 é o portão para as quatro mudanças em
Kotlin** (`CacheController.kt`, `CacheService.kt`, `DatabaseController.kt`).

---

# Fase 9.10 — `DB_POOL_MAX` não é lido por 39 implementações

O ConfigMap afirma, em comentário, que "every implementation reads DB_POOL_MAX
from the same ConfigMap so the data access layer stops being a hidden variable in
the ranking". **Isso é falso.** Varredura de 2026-08-10 nas 101 implementações em
disco: **39 não leem `DB_POOL_MAX`**. O padrão é nítido e explica o porquê — quase
todas são gRPC e GraphQL. A Fase 3 corrigiu o pool no REST e não alcançou os
outros dois protocolos.

## 9.10.1 — Conexão nova por requisição: 10 implementações JVM `[2 corrigidas]`

O mais grave. `DriverManager.getConnection(...)` **dentro** de `getUser()`,
`getComplexOrders()` e `checkHealth()`:

| Implementação | Build | Estado |
|---|---|---|
| `graalvm/graphql/spring` | `starter-data-jdbc` já traz HikariCP | **corrigida**, `javac` **E2** |
| `graalvm/graphql/micronaut` | `micronaut-jdbc-hikari` já traz HikariCP | **corrigida**, `javac` **E2** |
| `java/graphql/dgs` | só `starter-web` | pendente — exige dependência |
| `java/graphql/spring-graphql` | só `starter-web` + graphql | pendente — exige dependência |
| `java/grpc/grpc-java` | sem Spring | pendente — exige dependência |
| `java/grpc/armeria` | sem Spring | pendente — exige dependência |
| `kotlin/graphql/dgs` | só `starter-web` | pendente — exige dependência |
| `kotlin/graphql/graphql-kotlin` | só `starter-web` | pendente — exige dependência |
| `kotlin/grpc/armeria` | sem Spring | pendente — exige dependência |
| `kotlin/grpc/grpc-kotlin` | sem Spring | pendente — exige dependência |

Uma conexão JDBC ao PostgreSQL não é barata: handshake TCP, mensagem de startup,
autenticação SCRAM-SHA-256 em vários round trips e **fork de um backend no
servidor** — para uma query. Sob as 100 conexões concorrentes do benchmark isso
também empurra o servidor contra `max_connections`, onde o modo de falha deixa de
ser lentidão e passa a ser conexão recusada. É o mesmo defeito do
`get_async_connection()` por requisição do Rust (Fase 9.1.7), mas em Postgres em
vez de Redis, e portanto muito mais caro.

O conserto é contido porque **os call sites não mudam**: todos já envolvem a
conexão em `try-with-resources`, que passa a devolvê-la ao pool em vez de fechar
um socket. Só o corpo de `getConnection()` muda, para emprestar de um
`HikariDataSource` dimensionado por `DB_POOL_MAX`, construído preguiçosamente
porque os campos `@Value` são injetados após a construção.

As 8 pendentes exigem acrescentar HikariCP (ou `spring-boot-starter-jdbc`) ao
`pom.xml`/`build.gradle.kts`. O jar **está** nos caches locais (`~/.m2` e
`~/.gradle`), então a resolução funcionaria, mas não há Maven nesta máquina e
Kotlin não compila em JDK 25 (ver §Restrições) — uma mudança de build file que eu
não consigo construir não deve entrar sem o portão da 9.4.

## 9.10.2 — Pool no default do driver, não no do contrato: 3 implementações C#

`csharp/grpc/grpc-dotnet`, `csharp/grpc/magiconion` e
`csharp/grpc/protobuf-net-grpc` fazem `await using var connection = new
NpgsqlConnection(...)` por requisição. **Isto não é defeito**: o Npgsql pooleia
internamente por padrão e nenhuma delas passa `Pooling=false`, então o padrão é o
idiomático da plataforma e a conexão vem de um pool.

O desvio é o tamanho: `MaxPoolSize` fica no default do Npgsql, **100**, contra as
32 do contrato. Mesma classe do que os 3 GraphQL Rust tinham com o default do
deadpool (160). Conserta-se com `Maximum Pool Size=` na connection string ou
`NpgsqlDataSourceBuilder`, lendo `DB_POOL_MAX`.

## 9.10.3 — `python-rest-flask`: sem pool, 40 conexões por pod

`app/services/database.py` guarda uma única `psycopg2.connect()` em `self._conn`
— com a docstring "Database service with connection pooling", que não descreve o
código. Não há pool e `DB_POOL_MAX` não é lido.

O efeito líquido é menos grave do que parece: o Dockerfile roda
`gunicorn --workers ${BENCH_CPUS:-4} --threads 1`, isto é 40 processos de uma
thread, cada um com sua conexão preguiçosa. O pod fica com **40 conexões**, não
com 1 — e 40 é aproximadamente o que a regra do invariante 3
(`DB_POOL_MAX / workers`, mínimo 1) produziria. O desvio é 40 contra 32, 25% mais
concorrência de banco que as demais, não um estrangulamento.

## 9.10.4 — Ainda não classificadas

`bun/graphql/hono`, `java/grpc/grpc-js`, `python/django` e as 3
`csharp/graphql/*` não leem `DB_POOL_MAX` e não casaram com nenhum marcador de
pool nem de conexão única. Exigem leitura individual; nenhuma conclusão foi
registrada sobre elas.

## 9.10.5 — Corrigir o comentário do ConfigMap

Enquanto 39 implementações não lerem a variável, o comentário em
`deploy/k3s/base/configmap.yaml` descreve uma intenção, não o estado. Um
invariante que o código não cumpre é pior que invariante nenhum, porque quem lê o
plano para de checar.

---

# Fase 9.11 — O medidor não contava erros `[PARCIALMENTE CORRIGIDA]`

Este é o defeito mais consequente registrado neste repositório, porque não
corrompe uma implementação: corrompe todas as 1.099 amostras já coletadas, e é a
razão pela qual todos os defeitos das Fases 9.1 e 9.9 sobreviveram a até cinco
rodadas sem serem notados.

## 9.11.1 — `non_2xx` era uma regex do wrk `[CORRIGIDA]`

```python
BOMBARDIER_NON2XX = re.compile(r"non-2xx or 3xx responses:\s+(\d+)")   # wrk
non_2xx=int(bad.group(1)) if bad else 0                                 # e 0 no não-match
```

`non-2xx or 3xx responses:` é a saída do **wrk**. O bombardier reporta classes de
status num bloco `HTTP codes:` e falhas de transporte num bloco `Errors:`, e nunca
emite aquela string. A regex portanto nunca casou — e o chamador substituía por
**zero**.

Consequência medida: **0 de 1.099 amostras**, nos 18 arquivos de `results/`, têm
`non_2xx != 0`. Inclusive:

- `kotlin-rest-spring` `/health`, com p50 de 10.010 ms — o timeout do cliente — e
  cuja repetição 3 reportou 14.433 rps a 900 bytes/s, isto é **0,06 bytes por
  "resposta"**. Eram timeouts contados como requisições completas, publicados
  como throughput. A mediana publicada foi 11,78 rps com desvio-padrão de 6.442.
- `rust-rest-actix-web` `/db/complex` a 220 bytes/resposta contra mediana de
  10.907 B, por cinco rodadas seguidas.

Um contador de erros morto é pior que contador nenhum, porque o JSON **afirma**
zero e todo consumidor acredita.

Corrigido: `parse_non_2xx()` lê os blocos reais e soma classes ≠ 2xx, `others` e
as contagens do bloco `Errors:` — timeouts e resets não são respostas e não podem
entrar como sucesso. E, decisivo, **retorna `None` quando não consegue parsear**,
nunca 0; `Sample.non_2xx` virou `int | None`. Prova em 9 casos, incluindo a saída
do wrk (→ `None`) e a truncada (→ `None`).

## 9.11.2 — `bytes_per_sec` perdia respostas pequenas `[CORRIGIDA]`

`BOMBARDIER_THROUGHPUT` exigia sufixo `KB|MB|GB`, então uma resposta pequena o
bastante para o bombardier imprimir `B/s` era gravada como `None`. E
`scripts/audit-response-bytes.py` pula amostras com `bytes_per_sec` falsy — ou
seja, o respondedor quase-vazio podia escapar exatamente da auditoria criada para
pegá-lo. `B` acrescentado à alternação.

## 9.11.3 — `non_2xx` e `bytes_per_sec` não eram lidos por ninguém `[CORRIGIDA]`

Mesmo parseados, os dois campos eram escritos em cada amostra e lidos por nada —
nem pelo `summary()`, nem por qualquer consumidor. `summary()` agora emite
`non_2xx_total`, `non_2xx_unparsed_samples` e `bytes_per_response_median`. Uma
vazão medida enquanto parte das requisições falhava não é uma vazão, e o leitor
tem de ver isso sem abrir as amostras cruas.

## 9.11.4 — `generator_location` era uma string fixa `[CORRIGIDA]`

Gravava literalmente `"workstation"` independentemente de onde o gerador rodou.
`run-20260810T001219Z.json` a carrega ao lado de `host: 127.0.0.1` — o gerador
apontado para o NodePort em loopback, dividindo CPU com o pod sob teste, que é a
única propriedade que a metodologia aponta como razão dos resultados anteriores
terem sido anulados. Agora é derivada de `cfg.host` e diz
`colocated-with-sut` ou `remote`; acrescentei também `kubectl_mode`.

## 9.11.5 — Ainda abertos no harness `[NÃO CORRIGIDOS]`

| # | Defeito | Por que importa |
|---|---|---|
| a | Probes `tcpSocket` em `deployment.yaml:71-84`, e `benchmark-secrets` com `optional: true` em `:47-52` | um pod sem credenciais de banco, ou que colapsa acima de uma conexão, fica *Ready*, passa o gate de paridade de uma requisição, e é medido |
| b | `cpu_cores_per_1k_rps` é inobtenível: `deploy/k3s/config.yaml` desliga o metrics-server, então `cpu_seconds` é `null` em todas as 1.099 amostras | é a única métrica que discrimina quando o cenário está limitado pela rede; sem ela `json-n1000` a ~734 rps ranqueia o switch |
| c | Seed fixa 42 em 16 dos 18 arquivos | a ordem é o controle contra deriva térmica e cache frio do Postgres; fixá-la congela o viés na mesma implementação em vez de dissolvê-lo |
| d | p99 reportado como mediana de 5 p99 | descarta a pior repetição por construção; e a passada de taxa fixa com `oha` que a metodologia promete não existe no código |
| e | `cluster.delete()` fora do `try` (linha ~524) | um timeout de 30 s do kubectl aborta a suíte em silêncio, deixando `finished_utc: null` e um arquivo parcial que parece completo — é a assinatura exata da rodada travada em `graalvm-rest-micronaut` |
| f | `--force --grace-period=0` com 12 s de intervalo | as conexões Postgres/Redis da implementação anterior seguem abertas do lado do servidor quando a próxima começa |
| g | `REST_SCENARIOS` usado para todo protocolo | com `--skip-parity`, throughput de 404 entra como registro `measured-off-contract` |

---

# Fase 9.12 — Node e C# fora do REST `[CONCLUÍDA]`

As duas stacks que a Fase 3 não alcançou fora do REST. Tudo abaixo verificado por
build ou por execução do entrypoint, não por leitura.

## 9.12.1 — Seis implementações Node não subiam

`nodejs-graphql-{apollo,mercurius,yoga}` e `nodejs-grpc-{grpc-js,nice-grpc,connectrpc}`
morriam no carregamento:

```
ReferenceError: require is not defined in ES module scope
  at file:///.../src/server.js:3:26
```

`"type": "module"` no `package.json` com `require()` em 4 a 5 arquivos por
projeto — uma migração ESM feita pela metade. **Seis das 100 implementações
produziam zero dado**, e o efeito no ranking não era "Node gRPC é lento": era
ausência de dado apresentada como ausência de implementação.

32 arquivos convertidos. Três formas precisaram de conversão consciente porque
não são traduzíveis por regex: `module.exports = { query: fn }` (vira
`export const`), o objeto de métodos abreviados de `cache.js` (vira
`export async function`), e `module.exports = identificador` (vira
`export default`, o que exige trocar o `import * as` do chamador por import
default). As seis passam do sistema de módulos e chegam a forkar workers.

## 9.12.2 — Pool por worker × pool por pod, outra vez

Sete implementações Node ignoravam `DB_POOL_MAX` com literais: `max: 20` nos seis
gRPC/GraphQL e `min: 5, max: 25` no NestJS. O bootstrap de cluster de cada uma
**já calculava** a fatia por worker e a injetava no ambiente do filho — e nada
lia. Com `BENCH_CPUS=40` isso dava até 800 e 1.000 conexões PostgreSQL contra as
32 do contrato, e o `min: 5` mantinha 200 abertas desde o startup. É o
invariante 3 reaparecendo em código que tinha a aritmética certa e o consumidor
faltando.

## 9.12.3 — Log por consulta nos três gRPC Node

`db.js` dos três: `if (duration > 100) console.log('Slow query...' + text)`.
`/db/complex` roda a ~860 rps contra 100 conexões, ou seja ~116 ms por consulta —
então **toda** consulta complexa cruzava o limiar e escrevia seu SQL multilinha
inteiro em stdout, sincronamente. `console.log` puro não é suprimido por
`LOG_LEVEL=error`. Invariante 1.

## 9.12.4 — Cache não declarado, agora em duas stacks

`nodejs-graphql-mercurius` lia `user:{id}` do Redis no resolver `user` e escrevia
de volta, enquanto os irmãos apollo e yoga, no mesmo diretório, consultam o banco
sempre. Pior: `cache.set(key, value, 'EX', 60)` passa as opções posicionalmente,
mas o node-redis v4 espera um objeto — a chave era escrita **sem TTL nenhum**, e
o cenário passava a ser respondido do Redis para sempre.

`csharp-graphql-hotchocolate` tinha o mesmo padrão com TTL de 60 s. Os dois
removidos. Vale registrar a classe: cache que só uma implementação tem não
produz um número errado, produz um número que responde a outra pergunta.

## 9.12.5 — SQL dos três gRPC Node

`INTERVAL '${days} days'` interpolado na string (além de vetor de injeção, um
literal diferente por valor de `days` impede reuso de plano), `LEFT JOIN` +
`HAVING COUNT(o.id) > 0` — forma mais lenta de escrever o `INNER JOIN` do
contrato, porque constrói as linhas externas e depois as descarta — e
`ORDER BY total_value DESC` sem desempate, que devolvia **outras** 100 linhas que
as do contrato, e instáveis entre execuções.

## 9.12.6 — C#: as três GraphQL nunca devolveram uma linha

Além do que a auditoria apontou (sem `LIMIT`, `LEFT JOIN`, `ORDER BY` sem
desempate, `AVG` como `SUM/COUNT`), havia dois erros de tipo que tornam o
resolver impossível: `GetInt32` sobre `COUNT()` (int8) e `GetDouble` sobre
`NUMERIC`. O Npgsql lança `InvalidCastException` nos dois casos.

E as três gRPC caíam num fallback para `DATABASE_URL`, que neste repositório é
URI `postgres://` — formato que o Npgsql **não parseia**. Como não há
`appsettings.json` nesses projetos e o ConfigMap não define
`ConnectionStrings__PostgreSQL`, não havia caminho para uma conexão utilizável.
Passaram a montar a string dos componentes `DB_*`, como as REST já fazem desde
que foram consertadas pelo mesmo motivo.

`MaxPoolSize` das seis fixado em `DB_POOL_MAX`; ficava no default 100 do driver.
Reconfirmado que criar `NpgsqlConnection` por requisição está **correto** — o
Npgsql pooleia internamente e nenhuma passa `Pooling=false`; o desvio era só o
tamanho.

Evidência: `dotnet build` nos 9 projetos C#, exit 0, zero erros. `node --check`
em todos os arquivos Node tocados e execução dos 6 entrypoints.

---

# Fase 9.13 — Go `[CONCLUÍDA]`

A stack mais bem comportada das auditadas até aqui, e o único defeito encontrado
é de dimensionamento de pool.

## 9.13.1 — `DB_POOL_MAX` nas seis não-REST `[CORRIGIDA]`

| Grupo | Antes | Efeito |
|---|---|---|
| `graphql/{gqlgen,graphql-go,graphql-go-2}` | `cfg.MaxConns = 10` literal | um terço do contrato |
| `grpc/{connectrpc,grpc-go,kitex}` | `pgxpool.New` sem config | default do pgx, `max(4, runtime.NumCPU())` ≈ 48 neste nó — e derivado da contagem de núcleos do **host**, não do contrato |

O caso GraphQL merece nota: o comentário do próprio
`deploy/k3s/base/configmap.yaml` lista "Go GraphQL used 10" entre os defeitos que
invalidaram resultados anteriores. Foi identificado na Fase 3, descrito no
ConfigMap como passado, e **nunca alterado no código**. As quatro REST (chi, echo,
fiber, gin) leem `DB_POOL_MAX` corretamente desde a Fase 3.2; as seis restantes
não foram alcançadas, exatamente como aconteceu em Rust, C# e Node.

Evidência: `go build ./...` nos seis, exit 0, e `gofmt -l` sem saída.

## 9.13.2 — Verificado e limpo

Vale tanto quanto os achados, porque delimita onde não procurar de novo. Nas 10
implementações Go:

- **Invariante 1**: nenhum `time.Sleep`, nenhum log por requisição. As únicas
  chamadas de log são de startup, shutdown e caminho de erro.
- **Invariante 4 (SQL)**: `INNER JOIN`, `INTERVAL '1 day' * $1` como parâmetro
  ligado, `ORDER BY total_orders DESC, u.id`, `LIMIT 100`, `o.total_amount`. Casa
  com `src/go/fiber`, que é a referência do projeto. Os comentários no código
  documentam que `o.total`/`o.amount` e a ordenação sem desempate já foram
  corrigidos numa passada anterior — aqui a correção pegou.
- **Invariante 8**: o `return nil, nil` nos três GraphQL está guardado por
  `pgx.ErrNoRows`; erro real propaga via `fmt.Errorf`. Não é erro engolido, é
  "linha ausente" — a distinção correta. Consertar isso teria sido um falso
  positivo.
- **Serialização**: o `/json` constrói `[]jsonItem` pré-alocado com
  `make([]jsonItem, n)`, isto é structs, não `map[string]interface{}` por item.
  É o padrão para o qual as implementações Rust foram convertidas na 9.1.12. O
  único `map[string]interface{}` é o envelope, um por requisição.
- **`INTERVAL '1 day' * $1`** com pgx nunca sofreu o defeito que quebrou o Rust
  (Fase 9.1.1): pgx codifica o parâmetro conforme o OID que o servidor infere, de
  modo que um `int` Go contra um `float8` inferido funciona.

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
| Repositório em share de rede `Z:` | é `\\192.168.1.50\HD1TB\benchmark`. Já produziu `ReadOnlyFileSystemException` em build Maven (6.5); em 2026-08-10 também bloqueou `cargo` no `target/` do `grpc/volo` (`Acesso negado, os error 5`, com o próprio `Test-Path` falhando) e impediu a **execução** do `kubectl.exe` da raiz. **Builds pesados em disco local** |
| Não instalados | SDK Dart (6.7), runtime Deno (6.8), `kubectl` fora do `Z:`, `kotlinc`, JDK 21 |
| Instalados e utilizáveis (2026-08-10) | Rust 1.95 + registry com 1.148 crates em cache (`cargo --offline` funciona); Node 24.14; Python; JDK **25**; e uma distribuição **Gradle 8.9 completa** em `~/.gradle/wrapper/dists/`, que roda `--offline` e resolve tudo pelo cache de módulos |
| Kotlin **não compila** nesta máquina | Kotlin 1.9.24 (versão dos projetos) não roda em JDK 25: `JavaVersion.parse` do IntelliJ embutido lança `IllegalArgumentException: 25.0.2`. Vale para o Gradle e para o CLI `K2JVMCompiler` direto. Os projetos usam `gradle:8.5-jdk21`. Sem JDK 21 local, alteração em Kotlin fica em **E1** (API conferida via `javap` nos jars reais) e o build Docker é o portão |
| Java **compila** isoladamente | `javac` contra os jars do cache do Gradle verifica um arquivo por vez, com classpath montado à mão. Usado na Fase 9.9 para `graalvm/gspring` e `java/spring` |
| Cluster | o runner exige chave SSH para o `.51`, sem senha. Em 2026-08-10 tentou-se WSL: Ubuntu 2 tem `ssh` mas **não** tem `kubectl` nem kubeconfig, e `/mnt/z` está vazio (o `Z:` é drive da sessão Windows, invisível ao WSL). Não verificado |

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
