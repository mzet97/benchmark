# Execution Plan — Benchmark Defensável

**Criado**: 2026-08-06
**Base**: ACTION_PLAN v3 + 9 commits de remediação nesta sessão
**Objetivo**: produzir o primeiro resultado de benchmark deste repositório que
alguém pode citar sem ressalva.

> Este plano é o que falta. O que já está feito está no `ACTION_PLAN.md` (Fase 0,
> Fase 8, Fase 6.1, Fase 6.2–6.9, Fase 7.5/7.7) e em `docs/BUILD_MATRIX.md`
> (56/56 implementações compilando limpo).

---

## Estado atual (2026-08-06, fim da sessão)

| Métrica | Valor |
|---|---|
| Implementações compilando (E2) | **56/56 medidas = 100%** |
| Implementações sem medir | **44** (sem toolchain: Dart 5, Deno 10, Java 8, Kotlin 9, GraalVM 12) |
| Tetos de infra medidos | ✅ rede ~95 Mbps, PG 25k TPS, Redis ~30k ops/s |
| Topologia aplicada | ⚠️ manifestos prontos (40 CPU); config K3s precisa root |
| Dívida estrutural | ✅ resolvida (Fase 8) |
| Gates de CI | ✅ `generate-overlays`, `generate-implementations`, `validate-parity` |
| Ferramentas instaladas | ✅ bombardier, oha, k6, ghz, protoc, iperf3 |

---

## O que falta — 3 trilhas

```
Trilha A — executável agora (sem root, sem cluster)
  A1: 3.R1 (--gc=G1 nos 6 GraalVM)          ~30 min
  A2: instalar toolchains (Maven, Gradle,    ~1 h
      Dart, Deno)
  A3: medir E2 das 44 pendentes (6.7–6.9)    ~2-3 h
  A4: 7.9 (consolidar 20 .md da raiz)        ~1 h
  A5: 7.6 (consolidar 11 docs INVALID)       ~30 min

Trilha B — bloqueada por root no .51
  B1: 2.1 (aplicar config.yaml do K3s)       ~15 min + reboot
  B2: 2.5 (validar QoS Guaranteed)           ~15 min
  B3: 2.3-restante (portas efêmeras WS)      ~5 min

Trilha C — bloqueada por B1+B2 (precisa cluster configurado)
  C1: 6.10 (build + push das 100 imagens)    ~4-6 h
  C2: 6.11 (primeiro E4 — validate-parity    ~2-3 h
      contra serviço rodando, 100 impls)
  C3: 6.12 (make smoke com gate)             ~1 h
  C4: 6.13 (executar a matriz, ~45 h)        ~2 dias calendário
  C5: 6.14 (sanidade da corrida)             ~1 h
  C6: 7.1–7.4, 7.8 (publicação honesta)      ~1 dia

Paralela — ação humana externa
  D1: 1.1 (rotacionar senhas PG + Redis)
  D2: 1.2 (git filter-repo + force push)
  D3: 1.3 (confirmar credential-scan falha)
```

---

## Trilha A — executável agora

### A1: 3.R1 — `--gc=G1` nos 6 Dockerfiles GraalVM nativos `[~30 min]`

**Problema**: as 6 imagens nativas do GraalVM usam Serial GC (default); as JVM
usam G1 (via `JAVA_TOOL_OPTIONS`). Comparar `graalvm/spring` (Serial) com
`graalvm/gspring` (G1) mede principalmente o coletor, não AOT vs JIT.

**Os 6 Dockerfiles** (todos têm `Xmx8g` no ENTRYPOINT/CMD, nenhum passa `--gc=G1`):

| Dockerfile | Framework | Build |
|---|---|---|
| `src/graalvm/spring/Dockerfile` | Spring Native | `mvn -Pnative` |
| `src/graalvm/graphql/spring/Dockerfile` | Spring GraphQL Native | `./mvnw -Pnative` |
| `src/graalvm/graphql/micronaut/Dockerfile` | Micronaut GraphQL Native | `mvn -Dpackager=native-image` |
| `src/graalvm/graphql/smallrye/Dockerfile` | Quarkus GraphQL Native | `mvn -Dnative` |
| `src/graalvm/grpc/micronaut/Dockerfile` | Micronaut gRPC Native | `mvn -Dpackaging=native-image` |
| `src/graalvm/grpc/quarkus/Dockerfile` | Quarkus gRPC Native | `mvn -Dnative` |

**Fix**: adicionar `--gc=G1` aos args de `native-image` em tempo de build:

| Framework | Onde adicionar |
|---|---|
| Spring (`-Pnative`) | `-Dspring.native.buildargs=--gc=G1` ou `-Dnative.buildtools.args=--gc=G1` |
| Quarkus (`-Dnative`) | `-Dquarkus.native.additional-build-args=--gc=G1` |
| Micronaut (`-Dpackager=native-image`) | `-Dmicronaut.native.buildargs=--gc=G1` |

**Critério de saída**: `grep gc=G1` retorna nos 6 Dockerfiles, ou a diferença
de coletor declarada em toda linha de resultado.

### A2: instalar toolchains para as 44 pendentes `[~1 h]`

Instalar no `/tmp` (padrão desta sessão, como o ACTION_PLAN prevê):

| Toolchain | Como | Impls |
|---|---|---|
| Maven 3.9.9 | download tarball → `/tmp/maven` | Java 8 + GraalVM 12 |
| Gradle 8.5 | download zip → `/tmp/gradle` | Kotlin 9 |
| Dart SDK | download zip → `/tmp/dart` | Dart 5 |
| Deno runtime | `winget DenoLand.Deno` | Deno 10 |

**Nota**: Java 25 já está instalado (mas os projetos podem precisar de JDK 17/21
para Gradle wrapper — verificar na hora).

### A3: medir E2 das 44 pendentes (6.7–6.9) `[~2-3 h]`

Após A2, executar build matrix para cada ambiente (paralelizável):

| Ambiente | Comando | Impls |
|---|---|---|
| Java (8) | `mvn package` ou `./mvnw package` por projeto | 8 |
| Kotlin (9) | `gradle build` ou `./gradlew build` por projeto | 9 |
| GraalVM (12) | `mvn package` (JIT, não native) | 12 |
| Dart (5) | `dart analyze` + `dart compile` | 5 |
| Deno (10) | `deno check` + `deno cache` | 10 |

**Critério de saída**: `docs/BUILD_MATRIX.md` com 100 linhas (não 56). Cada uma
com ✅/❌ + mensagem de erro real + nível E2.

**Erros já conhecidos a investigar** (se manifestarem):
- `kotlin/grpc/spring-grpc` (6.2): `io.grpc:grpc-spring-boot-starter` não existe → `net.devh:`
- `kotlin/grpc/armeria` (6.3): `protoc` aborta em `generateProto`
- `kotlin/grpc/grpc-kotlin` (6.4): toolchain Java 17 não passa
- `java/quarkus` (6.5): `ReadOnlyFileSystemException` (testar em disco local)
- `graalvm/vertx` (6.6): `CorsHandler` duplicado, `Redis.createClient` errado

### A4: 7.9 — Consolidar os 20 `.md` da raiz `[~1 h]`

**Os 20 arquivos**:
```
BENCHMARK_RESULTS_K3S.md    BENCHMARK_SUMMARY.md       DOCKER_BUILD_FIX.md
FINAL_SUMMARY.md            GO_IMPLEMENTATION_SUMMARY.md  GO_README.md
IMPLEMENTACAO_STATUS.md     JAVA_IMPLEMENTATION_SUMMARY.md  JAVA_README.md
K8S_REVIEW.md               KOTLIN_IMPLEMENTATION_SUMMARY.md  KOTLIN_README.md
KUBERNETES_README.md        KUBERNETES_TUTORIAL.md     NODEJS_IMPLEMENTATION_SUMMARY.md
NODEJS_README.md            PROJECT_PROGRESS.md        RUST_IMPLEMENTATION_SUMMARY.md
RUST_README.md
```

**Ação**:
1. Mover conteúdo útil para `docs/` (ex: `docs/FRAMEWORK_GUIDES.md` consolidando os `*_README.md`)
2. Remover duplicatas e informações desatualizadas
3. Raiz fica só com `README.md`

### A5: 7.6 — Consolidar os 11 docs de resultados INVALID `[~30 min]`

**Os 11** (9 em `docs/` + `BENCHMARK_RESULTS_K3S.md` + 1 implícito):
```
docs/BENCHMARK_RESULTS.md          docs/FINAL_BENCHMARK_RESULTS.md
docs/BENCHMARK_RESULTS_EXTERNAL_PG.md  docs/FINAL_RESULTS.md
docs/COMPLETE_ALL_RESULTS.md       docs/HIGH_CONCURRENCY_RESULTS.md
docs/COMPLETE_BENCHMARK_RESULTS.md docs/MULTI_SCENARIO_RESULTS.md
BENCHMARK_RESULTS_K3S.md           (+ docs/BENCHMARK_SUMMARY.md, docs/PROJECT_PROGRESS.md)
```

**Ação**:
1. Mover todos para `docs/archive/INVALID_RESULTS_2026-07/`
2. Criar `docs/archive/INVALID_RESULTS_2026-07/README.md` explicando por que são inválidos (link para ACTION_PLAN Anexo A)

---

## Trilha B — bloqueada por root no `.51`

### B1: 2.1 — Aplicar config.yaml do K3s `[~15 min + reboot]`

**Comando** (precisa root, descrito em `docs/K3S_TOPOLOGY_RUNBOOK.md`):
```bash
ssh k8s1@192.168.1.51
sudo cp ~/benchmark/deploy/k3s/config.yaml /etc/rancher/k3s/config.yaml
sudo systemctl restart k3s
```

**Validar**:
```bash
cat /var/lib/kubelet/cpu_manager_policy  # deve mostrar static
kubectl describe node k8s1 | grep -A6 Allocatable  # deve mostrar ~44 CPU
kubectl get pods -A | grep traefik  # deve estar vazio
```

### B2: 2.5 — Validar QoS Guaranteed `[~15 min]`

Deploy de pod de teste 40 CPU Guaranteed, verificar `nr_throttled=0` sob carga.
Script pronto no runbook (`docs/K3S_TOPOLOGY_RUNBOOK.md` Passo 4).

### B3: 2.3-restante — Portas efêmeras workstation `[~5 min]`

```powershell
# Como administrador:
netsh int ipv4 set dynamicport tcp start=10000 num=55000
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpTimedWaitDelay /t REG_DWORD /d 30 /f
```

---

## Trilha C — bloqueada por B1+B2 (cluster configurado)

### C1: 6.10 — Build + push das imagens Docker `[~4-6 h]`

Para cada uma das ~100 implementações que chegaram a E2 (após A3):
```bash
# No .51 (tem Docker):
for impl in $(python scripts/generate-implementations.py | grep -oE '<env>-<proto>-<fw>'); do
  docker build -t benchmark/$impl:latest -f src/<path>/Dockerfile src/<path>
  # ou via make: make build IMPL=$impl
done
```

**Critério**: imagem no registry com tag rastreável ao commit (`:$(git rev-parse --short HEAD)`).

### C2: 6.11 — Primeiro E4 `[~2-3 h]`

O nível de evidência que falta: serviço rodando + `validate-parity.py --url` passando.
```bash
# Para cada implementação (uma por vez):
make deploy IMPL=rust-rest-actix-web
# esperar rollout
python scripts/validate-parity.py --url http://192.168.1.51:30080
make undeploy IMPL=rust-rest-actix-web
```

**Critério**: hash do payload confere nos 5 cenários e em n=10/100/1000 para
todas as implementações que passaram E2. Implementação que falha em E4 é
registrada com o motivo.

### C3: 6.12 — `make smoke` com gate `[~1 h]`

Integrar `validate-parity.py` no target `smoke` do Makefile como porta de entrada
da matriz. Implementação fora do contrato é pulada, não ranqueada.

### C4: 6.13 — Executar a matriz `[~2 dias calendário]`

```bash
python scripts/run-benchmark-suite.py --host 192.168.1.51 --user k8s1
```

- ~100 impls × 7 cenários × 5 repetições × 60 s ≈ **~45 h de máquina**
- Semente randomizada registrada no JSON
- Checkpoint por implementação (retomável)

### C5: 6.14 — Sanidade da corrida `[~1 h]`

Nenhum resultado acima do teto da Fase 0; desvio entre as 5 repetições dentro
do aceitável. Resultado que viole o teto = bug de medição.

### C6: 7.1–7.4, 7.8 — Publicação honesta `[~1 dia]`

| # | Tarefa |
|---|---|
| 7.1 | `docs/RESULTS_<data>.md` gerado a partir dos JSONs, nunca editado à mão |
| 7.2 | Cada linha com % do teto de infra + flag de gargalo |
| 7.3 | Cenários não ranqueáveis (`json-n1000`) rotulados |
| 7.4 | Implementações excluídas listadas com motivo |
| 7.8 | `docs/REPRODUCIBILITY.md` com semente, versões, commit, config |

---

## Trilha D — ação humana externa (paralela a tudo)

| # | Tarefa | Ordem |
|---|---|---|
| 1.1 | **Rotacionar** senhas do PostgreSQL e Redis | primeiro |
| 1.2 | **Reescrever histórico** (`git filter-repo`), force push | depois de 1.1 |
| 1.3 | Confirmar `credential-scan.yml` falha com credencial sintética | anytime |

---

## Sequência recomendada

```
Hoje (sem root):
  A1 (3.R1 GraalVM G1)     ──── 30 min
  A2 (instalar toolchains) ──── 1 h
  A3 (medir 44 pendentes)  ──── 2-3 h  ← maior impacto: 56→100 impls medidas
  A4 (consolidar .md raiz) ──── 1 h
  A5 (consolidar INVALID)  ──── 30 min
  D1-D3 (segurança)        ──── ação humana paralela

Quando root disponível:
  B1 (config K3s)          ──── 15 min + reboot
  B2 (validar Guaranteed)  ──── 15 min
  B3 (portas WS)           ──── 5 min

Cluster pronto:
  C1 (build imagens)       ──── 4-6 h
  C2 (primeiro E4)         ──── 2-3 h  ← primeiro resultado real do repo
  C3 (make smoke gate)     ──── 1 h
  C4 (matriz 45h)          ──── 2 dias
  C5 (sanidade)            ──── 1 h
  C6 (publicação)          ──── 1 dia
```

**Total**: ~3 dias de trabalho ativo + ~2 dias de calendário para C4.
