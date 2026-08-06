# K3s Topology Runbook — Fase 2

**Pré-requisito**: Fase 0 concluída (ver `docs/BASELINE_CEILINGS.md`).
**Estado**: parcialmente aplicado em 2026-08-06. Os passos que exigem root no
nó estão marcados `[PRECISA ROOT]` e requerem execução manual.

Este runbook aplica a topologia decidida para o cluster, recalculada contra os
números medidos na Fase 0 (48 vCPU / 62 GiB, rede ~95 Mbps, Redis in-cluster).

---

## Pré-requisitos

- Acesso SSH ao nó: `ssh k8s1@192.168.1.51` (chave, sem senha)
- Acesso **root** ao nó (para `/etc/rancher/k3s/config.yaml` e `systemctl`)
- O namespace `benchmark` deve estar vazio (uma impl roda por vez)

---

## Passo 1 — Limpar o namespace benchmark `[APLICADO 2026-08-06]`

```bash
ssh k8s1@192.168.1.51 <<'EOF'
# Scale all deployments to 0
for dep in $(kubectl get deploy -n benchmark -o jsonpath='{.items[*].metadata.name}'); do
  kubectl scale deploy "$dep" -n benchmark --replicas=0
done

# Delete orphan pods (completed, unknown, jobs)
kubectl delete pods -n benchmark --field-selector=status.phase!=Running --force --grace-period=0
kubectl delete jobs -n benchmark --all
EOF
```

**Conferir**: `kubectl get pods -n benchmark` deve retornar 0 pods.

---

## Passo 2 — Aplicar o config.yaml do K3s `[PRECISA ROOT]`

Este passo reserva CPU/memória para K3s+SO e ativa o cpu-manager-policy=static,
que dá ao pod SUT cores exclusivos (sem CFS throttling). **Exige root** — o
usuário `k8s1` não tem sudo passwordless.

```bash
# No nó .51, como root:
ssh k8s1@192.168.1.51

# Tornar-se root (senha necessária)
sudo -i

# Backup do estado atual
cp /etc/rancher/k3s/config.yaml /etc/rancher/k3s/config.yaml.bak 2>/dev/null || true

# Copiar o config versionado (do repositório, que está em ~/benchmark/ no nó)
cp ~/benchmark/deploy/k3s/config.yaml /etc/rancher/k3s/config.yaml

# Conferir o conteúdo
cat /etc/rancher/k3s/config.yaml

# Restart do K3s (derruba brevemente argocd e redis; voltam em ~30s)
systemctl restart k3s

# Aguardar o nó ficar Ready
kubectl wait --for=condition=ready node/k8s1 --timeout=120s
```

### Conferir que funcionou

```bash
# cpu-manager-policy = static
cat /var/lib/kubelet/cpu_manager_policy

# Allocatable reduzido (deve mostrar ~44 CPU ao invés de 48)
kubectl describe node k8s1 | grep -A6 Allocatable

# Traefik e ServiceLB desabilitados
kubectl get pods -A | grep -E 'traefik|svclb'
# (deve retornar vazio)
```

### Reservas aplicadas

| Parâmetro | Valor | Efeito |
|---|---|---|
| `system-reserved` | cpu=2000m, memory=2Gi | OS + daemons |
| `kube-reserved` | cpu=2000m, memory=2Gi | K3s + kubelet + containerd |
| `cpu-manager-policy` | static | pods Guaranteed com requests inteiros recebem cores exclusivos |
| `eviction-hard` | memory<1Gi, nodefs<5% | evita OOM sob medição |
| `disable` | traefik, servicelb, metrics-server | remove competição de CPU |

**Allocatable esperado**: ~44 CPU, ~58 GiB (de 48 / 62).

> **Atenção**: o `metrics-server` foi desabilitado porque o runner
> (`run-benchmark-suite.py`) o usa para `pod_cpu_seconds`. Se essa métrica for
> necessária, remova `metrics-server` da lista `disable` e reabra-o.

---

## Passo 3 — Dimensionamento do pod SUT `[APLICADO NO REPO]`

O `deploy/k3s/base/deployment.yaml` agora pede **40 CPU / 40 GiB**
(anteriormente 7 CPU / 12 GiB). Com 44 CPU allocatable, isso deixa 4 CPU para
argocd + redis (que consomem ~130m medidos).

O `ConfigMap` (`deploy/k3s/base/configmap.yaml`) tem `BENCH_CPUS=40` para
alinhamento com os runtimes que leem o cgroup via env.

**Conferir**:
```bash
grep -A2 'resources:' deploy/k3s/base/deployment.yaml | head -6
grep 'BENCH_CPUS' deploy/k3s/base/configmap.yaml
```

---

## Passo 4 — Validar isolamento com pod de teste `[PRECISA PASSO 2]`

Após o config.yaml aplicado:

```bash
ssh k8s1@192.168.1.51 <<'EOF'
# Deploy de um pod de teste Guaranteed (40 CPU)
cat <<YAML | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: isolation-test
  namespace: benchmark
  labels:
    app: isolation-test
spec:
  restartPolicy: Never
  containers:
    - name: test
      image: busybox
      command: ["sleep", "300"]
      resources:
        requests: { cpu: "40", memory: "40Gi" }
        limits:   { cpu: "40", memory: "40Gi" }
YAML

# Aguardar
kubectl wait --for=condition=ready pod/isolation-test -n benchmark --timeout=60s

# Conferir QoS = Guaranteed
kubectl get pod isolation-test -n benchmark -o jsonpath='{.status.qosClass}'

# Conferir cores exclusivos (cgroup)
kubectl exec isolation-test -n benchmark -- cat /sys/fs/cgroup/cpu.stat

# Sob carga, verificar zero throttling
kubectl exec isolation-test -n benchmark -- sh -c \
  'cat /sys/fs/cgroup/cpu.stat | grep nr_throttled'
# nr_throttled deve ser 0
EOF
```

---

## Passo 5 — Workstation tuning `[PARCIALMENTE APLICADO]`

| Setting | Status | Valor |
|---|---|---|
| Portas efêmeras | ❌ precisa admin | atual: 49152-65535 (16384); recomendado: 10000-64999 (55000) |
| Power plan | ✅ aplicado | Alto desempenho (SCHEME_MIN) |
| TcpTimedWaitDelay | ❌ precisa admin | atual: default 240s; recomendado: 30s |

**Para aplicar os pendentes** (rodar como administrador):
```powershell
netsh int ipv4 set dynamicport tcp start=10000 num=55000
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpTimedWaitDelay /t REG_DWORD /d 30 /f
```

---

## Passo 6 — Versões das ferramentas `[REGISTRADO]`

| Ferramenta | Versão | Instalado via |
|---|---|---|
| iperf3 | 3.21 (Cygwin) | `winget ar51an.iPerf3` |
| **bombardier** | **2.0.2** | download direto → `C:\Users\mathe\bin\bombardier.exe` |
| curl | 8.21.0 | Windows built-in |
| ssh | OpenSSH 10.3p1 | Windows built-in |
| go | 1.26.2 | (pré-instalado) |
| rust | 1.95.0 | (pré-instalado) |
| node | v24.14.1 | (pré-instalado) |
| python | 3.12.10 | (pré-instalado) |
| **oha** | **PENDENTE** | Fase 2.4 |
| **k6** | **PENDENTE** | Fase 2.4 |
| **ghz** | **PENDENTE** | Fase 2.4 |

> `bombardier` (o gerador primário do runner) está instalado. `oha`, `k6` e
> `ghz` ainda pendem — `oha` é métrica de latência de reserva, `k6` é
> alternativo para REST/GraphQL, `ghz` é necessário para gRPC.

---

## Problemas conhecidos

1. **`k8s1` não tem sudo passwordless** — o config.yaml do K3s exige root.
   Solução: execução manual do Passo 2 por alguém com acesso root ao Proxmox/nó.

2. **Redis compartilha o nó do SUT** — o namespace `redis` roda no mesmo nó.
   Com 40 CPU para o SUT e ~4 reservados para vizinhos, o Redis (61m CPU
   medido) cabe na folga. Mas `/cache` sob carga de escrita pode competir.
   Se isso se provar um confounder, o Redis precisa sair do nó.

3. **`metrics-server` desabilitado** — o runner usa `pod_cpu_seconds` da API de
   métricas. Se essa métrica for necessária, remova `metrics-server` da lista
   `disable` do config.yaml.
