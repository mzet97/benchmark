# K3s Environment

**Status**: MEDIDO em 2026-08-06 (Fase 0). Os valores abaixo são reais, não
template. Veja `docs/BASELINE_CEILINGS.md` para os tetos medidos.

## Cluster Information

| Item | Value |
|------|-------|
| K3s Version | `v1.34.6+k3s1` |
| Kubernetes Version | `v1.34.6` |
| Number of Nodes | **1** (`k8s1`, control-plane) |
| Architecture | `x86_64` |
| OS | Ubuntu 24.04.4 LTS (kernel 6.8.0-136-generic) |
| Container Runtime | containerd 2.2.2 |
| CNI | flannel (default) |
| CoreDNS | Built-in |
| kube-proxy | Built-in |
| Traefik | Built-in (Fase 2 planeja `--disable`) |
| ServiceLB | Built-in (Fase 2 planeja `--disable`) |
| metrics-server | Presente (o runner o usa para `pod_cpu_seconds`) |

## Node

| Node | Role | CPU | Memory | Hypervisor |
|------|------|-----|--------|------------|
| `k8s1` (192.168.1.51) | control-plane | **48 vCPU** (2×24, sem HT) | **62 GiB** | KVM/Proxmox |

CPU steal: **0%** (medido em idle e sob carga — ver BASELINE_CEILINGS.md §0.7).

> A topologia assumida no ACTION_PLAN (8 vCPU / 16 GiB) não corresponde à
> realidade. O dimensionamento do pod SUT (7 CPU) e o `--system-reserved` da
> Fase 2 precisam ser recalculados contra 48 cores.

## Image Registry

| Strategy | Status |
|----------|--------|
| containerd import via `docker` | ✅ Docker 29.4.0 no nó |
| GHCR | Configurado no `ci.yml` (`ghcr.io`) |
| Local registry | Não configurado |

## Data Services

### PostgreSQL

| Item | Value |
|------|-------|
| Host (real) | `192.168.1.52:5432` (DNS `spsql.home.arpa`) |
| Database | `benchmark_api` |
| User | `db_admin` |
| Versão | **18.3** (Ubuntu 18.3-1.pgdg24.04) |
| `max_connections` | **100** |
| `shared_buffers` | **4 GB** |
| Tabela `users` | 10.000 linhas |
| Tabela `orders` | 50.000 linhas |
| Tabela `order_items` | 200.000 linhas |
| **TPS (query `/db/simple`)** | **25.436** (32 clients, 1.26 ms/query) |

> Há também um pod `benchmark/postgres` (ClusterIP 10.43.143.47) com credenciais
> `benchmark/benchmark`, mas o secret do benchmark (`benchmark-secrets`) aponta
> para `.52` com `db_admin`. O SUT usa `.52`.

### Redis

| Item | Value |
|------|-------|
| Host (externo) | `192.168.1.51:30379` (DNS `redis.home.arpa`) |
| Host (interno) | `redis-master.redis.svc.cluster.local:6379` |
| Senha | `Admin@123` |
| Topologia | cluster in-cluster (master + replica), namespace `redis`, 112 dias |
| **Teto (PING/SET/GET)** | **~30k ops/s** (via NodePort, 50 clients) |

> **Confounder declarado**: o Redis roda no mesmo nó do SUT. O `/cache` pode
> carregar competição de CPU com o framework medido.

## Capacity

| Resource | Total | Disponível (medição) |
|----------|-------|----------------------|
| CPU (cores) | 48 | ~44 (K3s+SO+redis+argocd consomem ~4) |
| Memória | 62 GiB | ~50 GiB livres |

## Active Workloads (vizinhança no nó)

| Namespace | Workload | Impacto no benchmark |
|-----------|----------|----------------------|
| `redis` | redis-master + replica | compartilha CPU; confounder `/cache` |
| `argocd` | argocd + argocd-redis | CPU residual |
| `benchmark` | postgres (standby, não usado pelo SUT) | mínimo |

## Rede

| Camada | Throughput medido |
|--------|-------------------|
| Loopback VM `.51` | 53,8 Gbps |
| Workstation ↔ `.51` | **~95 Mbps** (TCP/UDP, simétrico, confirmado por HTTP) |
| NIC workstation | Intel I211, 1 Gbps link (mas throughput real ~95 Mbps) |
| NIC VM `ens18` | virtio, `Speed: Unknown` |

> O teto de rede é ~10× pior que o assumido (1 GbE útil ≈ 117 MB/s). Ver
> `BASELINE_CEILINGS.md` para o impacto por cenário.

---

**Last Updated**: 2026-08-06
**Status**: MEDIDO
