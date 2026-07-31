#!/usr/bin/env bash
# scripts/measure-ceilings-server.sh
#
# Fase 0 do plano de acao: lado servidor. Roda no no K3s (192.168.1.51) e mede
# a capacidade do PostgreSQL e do Redis, alem de inventariar o hardware real
# do no -- que hoje esta como template vazio em docs/K3S_ENVIRONMENT.md.
#
# Uso (no .51):
#   export DATABASE_URL='postgresql://app:<senha>@spsql.home.arpa:5432/benchmark_api'
#   export REDIS_URL='redis://:<senha>@redis.home.arpa:30379'
#   ./scripts/measure-ceilings-server.sh
#
# Credenciais vem SEMPRE do ambiente. Nenhum default.

set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"
: "${REDIS_URL:?REDIS_URL is required}"

OUT="${OUT:-docs/K3S_ENVIRONMENT_MEASURED.md}"

section() { printf '\n=== %s ===\n' "$1"; }

section "Inventario do no"
CPU_MODEL=$(lscpu | awk -F: '/Model name/ {gsub(/^ +/,"",$2); print $2; exit}')
CPU_COUNT=$(nproc)
MEM_TOTAL=$(free -g | awk '/^Mem:/ {print $2}')
KERNEL=$(uname -r)
echo "CPU      : $CPU_MODEL"
echo "vCPUs    : $CPU_COUNT"
echo "Memoria  : ${MEM_TOTAL} GiB"
echo "Kernel   : $KERNEL"

# Overcommit no host Proxmox falseia qualquer medicao de "100% do hardware".
if command -v dmesg >/dev/null 2>&1; then
  STEAL=$(awk '/^cpu / {print $8}' /proc/stat)
  echo "CPU steal: ${STEAL} ticks (>0 e crescente = vCPU disputada no host)"
fi

section "Cluster K3s"
if command -v kubectl >/dev/null 2>&1; then
  kubectl version --short 2>/dev/null | head -2 || true
  echo "--- nodes ---"
  kubectl get nodes -o wide --no-headers
  echo "--- alocavel ---"
  kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.allocatable.cpu}{"\t"}{.status.allocatable.memory}{"\n"}{end}'
  echo "--- workloads fora do namespace benchmark (ruido) ---"
  kubectl get pods -A --field-selector=status.phase=Running --no-headers \
    | awk '$1 != "benchmark" {print $1"/"$2}' | sort | uniq -c | sort -rn | head -15
else
  echo "kubectl nao encontrado"
fi

section "Teto do PostgreSQL (pgbench, somente leitura)"
if command -v pgbench >/dev/null 2>&1; then
  echo "Escala fixa: 8 clientes, 4 threads, 30s, -S (SELECT only)"
  pgbench "$DATABASE_URL" -S -c 8 -j 4 -T 30 -n 2>&1 | tail -6
  echo ""
  echo "Saturado: 64 clientes, 8 threads, 30s"
  pgbench "$DATABASE_URL" -S -c 64 -j 8 -T 30 -n 2>&1 | tail -6
else
  echo "pgbench nao encontrado. Instale: apt-get install postgresql-client-common postgresql-contrib"
fi

section "Teto do Redis"
if command -v redis-benchmark >/dev/null 2>&1; then
  # redis-benchmark nao aceita URL; extrai host/porta/senha do REDIS_URL.
  RHOST=$(printf '%s' "$REDIS_URL" | sed -E 's|redis://[^@]*@?([^:/]+):.*|\1|')
  RPORT=$(printf '%s' "$REDIS_URL" | sed -E 's|.*:([0-9]+).*|\1|')
  RPASS=$(printf '%s' "$REDIS_URL" | sed -E 's|redis://:([^@]*)@.*|\1|')
  if [ "$RPASS" = "$REDIS_URL" ]; then RPASS=""; fi
  if [ -n "$RPASS" ]; then
    redis-benchmark -h "$RHOST" -p "$RPORT" -a "$RPASS" -t get,set -c 50 -n 100000 -q
  else
    redis-benchmark -h "$RHOST" -p "$RPORT" -t get,set -c 50 -n 100000 -q
  fi
else
  echo "redis-benchmark nao encontrado. Instale: apt-get install redis-tools"
fi

section "Resumo"
cat <<EOF
Registre estes valores em docs/BASELINE_CEILINGS.md.

O teto efetivo de cada cenario e o MENOR entre:
  - teto de rede         (medido por scripts/measure-ceilings.ps1 na workstation)
  - teto de PPS/cliente  (idem)
  - teto de PostgreSQL   (pgbench acima, para /db/simple e /db/complex)
  - teto de Redis        (redis-benchmark acima, para /cache)

Alocacao alvo neste no ($CPU_COUNT vCPU, ${MEM_TOTAL} GiB):
  reservado ao sistema : 1 CPU / 2 GiB
  pod SUT (Guaranteed) : $((CPU_COUNT - 1)) CPU / $((MEM_TOTAL - 4)) GiB
  BENCH_CPUS           : $((CPU_COUNT - 1))
EOF
