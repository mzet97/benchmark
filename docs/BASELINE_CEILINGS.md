# Baseline Ceilings — Fase 0

**Atualizado**: 2026-08-06
**Medido em**: 2026-08-06, via SSH para `.51` (k8s1@192.168.1.51, chave) e
workstation Windows na mesma LAN.
**Evidência**: E5 (medições executadas nesta data, não assumidas)

> Este documento substitui as estimativas que o `docs/ACTION_PLAN.md` carregava.
> Os números abaixo são **medidos**, com o método e o comando ao lado de cada um.
> A topologia documentada antes desta data assumia 8 vCPU / 16 GiB / 1 GbE; a
> realidade medida é diferente e está em §"Topologia real".

---

## Topologia real (medida, não assumida)

```
Workstation Windows              VM .51 — K3s (SUT)          VM .52 — PostgreSQL
  Intel I211 1 Gbps NIC   ──>      KVM/Proxmox VM              KVM/Proxmox VM
  bombardier / iperf3     NIC        48 vCPU / 62 GiB            8 vCPU (presumido)
  (workstation)          ~95 Mbps   ├ K3s + SO + argocd + redis  PostgreSQL 18.3
                                   └ pod SUT                  ← .52:5432
                                     Redis (in-cluster) ←──── redis-master-nodeport:30379
```

| Camada | CPU | Memória | Fonte |
|---|---:|---:|---|
| VM `.51` total | **48** vCPU | **62 GiB** | `nproc`; `free -h` |
| Hypervisor | KVM (Proxmox) | — | `systemd-detect-virt` = `kvm` |
| CPU steal | **0%** (idle e sob carga) | — | `vmstat`, 5 amostras |
| VM `.52` | não acessível por SSH | — | `Permission denied` (só via `.51`) |

> **Isto muda o plano.** A topologia assumida (8 vCPU / 16 GiB / 1 GbE útil)
> não corresponde à realidade. A Fase 2 precisa ser refeita contra estes números.

---

## 0.1 — Teto de rede

### Workstation ↔ `.51`

| Direção | Método | Throughput | Converge? |
|---|---|---|---|
| Uplink (WS→`.51`) | iperf3 TCP, 1 stream, 10s | **95 Mbps** | — |
| Uplink (WS→`.51`) | iperf3 TCP, 8 streams, 10s | **95 Mbps** | sim (não é limite de janela) |
| Downlink (`.51`→WS) | iperf3 TCP, 8 streams, -R, 10s | **95 Mbps** | simétrico |
| Uplink | iperf3 UDP, -b 2G, 5s | **96 Mbps**, 0% perda, 0.14 ms jitter | — |
| Downlink | HTTP curl, 100 MB | **90 Mbps** (11.25 MB/s) | confirma via método independente |

**Teto de rede medido: ~95 Mbps = ~11.9 MB/s.**

O link físico da workstation é Intel I211 a 1 Gbps (`Get-NetAdapter` confirma),
mas o throughput sustentado é ~9,5% disso. A NIC `ens18` da VM é virtio e reporta
`Speed: Unknown`. O gargalo está no caminho (NIC virtual, virtio, ou switch path),
não no link físico da workstation. **Não assumir 1 GbE útil.**

### Loopback interno da VM `.51`

| Método | Throughput |
|---|---|
| iperf3 TCP, 4 streams, 127.0.0.1 | **53.8 Gbps** |

O caminho interno é irrelevante como gargalo: o limite é a rede física.

---

## 0.2 — Teto de PPS

| Método | rps | Corpo |
|---|---|---|
| nginx servindo 79 B estáticos, wrk 4t/50c, 10s, **localhost** | **68.614 rps** | `/health.json` |

> Este é o teto **interno** (localhost). O teto **de rede** é muito menor: a
> ~95 Mbps e ~130 B/resposta (header + corpo), o PPS útil pela rede é
> ~90.000 — mas cada request de benchmark é mais caro que um arquivo estático.
> O PPS de rede real será medido na Fase 6.13 com o gerador na workstation.

---

## 0.3 — Tamanho dos payloads canônicos

Medido por `python scripts/validate-parity.py --reference`:

| `n` | bytes/item | Tamanho da resposta `/json` |
|---|---:|---:|
| 10 | 155 | ~1,8 KB |
| 100 | 157 | ~16 KB |
| 1000 | 160 | ~160 KB |

### Consequência para o teto de rede (~95 Mbps = 11,9 MB/s)

| Cenário | Corpo | Teto de rede @ 95 Mbps | Gargalo |
|---|---:|---:|---|
| `/health` | ~100 B | ~117k rps | **PPS** (provável, a confirmar em 6.13) |
| `/json` n=10 | ~1,8 KB | ~6.400 rps | PPS/transição |
| **`/json` n=100** | ~16 KB | **~725 rps** | **rede** |
| `/json` n=1000 | ~160 KB | **~72 rps** | **rede** (cenário destruído) |
| `/db/simple` | ~130 B | ~89k rps | PostgreSQL (25k TPS) |
| `/db/complex` | ~13 KB | ~893 rps | PostgreSQL + rede |
| `/cache` | ~150 B | ~77k rps | Redis (30k ops/s) |

> O cenário `/json` n=1000 é **completamente inviável** a 95 Mbps: ~72 rps é
> puramente custo de transmissão. Mesmo n=100 fica perto do teto (~725 rps).
> O cenário de ranking primário continua sendo `json-n100`, mas o intervalo
> onde o framework é o gargalo é muito mais estreito que o assumido.

---

## 0.4 — PostgreSQL

| Item | Valor | Método |
|---|---|---|
| Host | `192.168.1.52:5432` (DNS `spsql.home.arpa`) | `benchmark-secrets` |
| Versão | **18.3** (Ubuntu) | `pgbench` reportou server version |
| Database | `benchmark_api` | secret |
| `max_connections` | **100** | `SHOW max_connections` |
| `shared_buffers` | **4 GB** | `SHOW shared_buffers` |
| Tabela `users` | 10.000 linhas | `SELECT count(*)` |
| **TPS (query do contrato)** | **25.436** | pgbench custom, 32 clients, 20s |

### Query medida (a do contrato `/db/simple`)

```sql
SELECT id, email, first_name AS "firstName", last_name AS "lastName",
       age, created_at AS "createdAt"
FROM users WHERE id = :id   -- :id = random(1, 10000)
```

```
latency average = 1.258 ms
tps = 25.435,962 (without initial connection time)
```

> `max_connections=100` comporta `DB_POOL_MAX=32` com folga (uma impl por vez).
> Mas a Fase 2.6 pede `max_connections=300` — hoje são 100. Se nada mais mudar,
> 100 é suficiente; se houver paralelismo de impls, precisa subir.

---

## 0.5 — Topologia do Redis

**O Redis não é externo ao cluster — roda dentro dele.**

| Item | Valor |
|---|---|
| Namespace | `redis` |
| Serviço | `redis-master-nodeport` (NodePort) |
| Porta interna | `redis-master.redis.svc.cluster.local:6379` |
| Porta externa (NodePort) | `192.168.1.51:30379` |
| Senha | `Admin@123` |
| Cluster? | Sim — `redis-master` + `redis-replica-headless`, 112 dias |
| Serviços relacionados | `redis-master-lb` (LoadBalancer 192.168.1.51:30806), `redis-commander`, `redis-cluster` |

> O benchmark aponta para `redis.home.arpa:30379`, que resolve para `.51`. É o
> NodePort do master. O `ConfigMap` (`benchmark-secrets`) aponta para
> `redis-master.redis.svc.cluster.local:6379` (ClusterIP interno). **Os dois
> caminhos chegam ao mesmo master**, mas o caminho interno é mais curto.
>
> **Isso é um confounder declarado**: o Redis compartilha o nó do SUT. Se o
> `/cache` for CPU-bound no Redis, o SUT compete com ele. A Fase 2 precisa
> reservar CPU para o Redis OU declarar que o `/cache` carrega vizinhança.

---

## 0.6 — Teto do Redis

Medido via `redis-benchmark` contra o NodePort `127.0.0.1:30379` (o caminho
externo que o benchmark usa), 50 clients, 100k ops:

| Operação | ops/s | p50 latência |
|---|---|---|
| `PING_INLINE` | **30.656** | 0.831 ms |
| `SET` | **30.367** | 1.183 ms |
| `GET` | **28.580** | 0.887 ms |

> O caminho via DNS interno (`redis-master.redis.svc`) não resolveu de dentro do
> container de benchmark em modo `--network host`; o NodePort funcionou. Os
> ~30k ops/s são o teto do master único neste caminho. O `/cache` do contrato
> faz 1 SET + 1 GET por miss, então o teto de miss/s é ~15k — acima do que a
> rede permite.

---

## 0.7 — Inventário de hardware e CPU steal

| Item | Valor |
|---|---|
| Virtualização | **KVM** (Proxmox host) |
| CPU | QEMU Virtual CPU version 2.5+, 2 sockets × 24 cores = **48 vCPU** |
| Threads/core | 1 (cores reais, não hyperthreads) |
| Memória | **62 GiB** (44 GiB livres no momento da medição) |
| Disco | virtio (não rotacional) |
| **CPU steal** | **0%** — medido em idle e sob carga (5 amostras `vmstat`, delta de `/proc/stat`) |
| Hypervisor steal acumulado | 9.689 jiffies em 139.848.834 totais = 0,007% (residual histórico) |

> Steal ≈ 0 confirma que o "100% do hardware" é repetível: o Proxmox não está
> roubando ciclos. Mas a VM tem 48 cores, não 8 — o dimensionamento do pod SUT
> (7 CPU no `deployment.yaml`) subutiliza o nó.

---

## Síntese — teto efetivo por cenário

Para cada cenário, o teto é o **menor** entre rede, PPS, PostgreSQL e Redis:

| Cenário | Teto de rede | Teto de DB/Redis | **Teto efetivo** | Fonte do limite | Ranqueável? |
|---|---:|---:|---:|---|---|
| `/health` | ~117k rps | — | ~68k rps (PPS interno) | PPS | ⚠️ limitado |
| `/json` n=10 | ~6.400 rps | — | ~6.400 rps | rede/PPS | ⚠️ limitado |
| **`/json` n=100** | **~725 rps** | — | **~725 rps** | **rede** | **sim (primário)** |
| `/json` n=1000 | ~72 rps | — | ~72 rps | rede | ❌ não ranquear |
| `/db/simple` | ~89k rps | 25.436 TPS | **25.436 rps** | **PostgreSQL** | ✅ |
| `/db/complex` | ~893 rps | < 25k (query pesada) | ~893 rps | rede/DB | ⚠️ verificar |
| `/cache` | ~77k rps | ~28.5k ops/s | **~28.5k rps** | **Redis** | ✅ |

### O que muda no plano

1. **A rede é ~10× pior que o assumido.** O plano estimava 1 GbE útil (~117
   MB/s); a medição mostra ~12 MB/s. Todos os cenários `/json` são mais
   limitados por rede que o previsto. `/json` n=1000 é inviável.

2. **A VM é 6× maior que o assumido.** 48 cores / 62 GiB, não 8/16. O pod SUT
   com 7 CPU usa 15% do nó. O `--system-reserved`/`--kube-reserved` da Fase 2
   precisa ser recalculado.

3. **PostgreSQL e Redis rodam dentro/nas proximidades do cluster**, não
   "externos". O Redis compartilha o nó do SUT — confounder para `/cache`.

4. **PostgreSQL 18.3** (não 16 como os services containers do smoke test). E
   `max_connections=100`, não os 300 que a Fase 2.6 planeja — hoje não é
   problema, mas é divergência.

Estas quatro mudanças exigem que a **Fase 2 (topologia)** seja refeita contra
os números reais antes de qualquer medição.
