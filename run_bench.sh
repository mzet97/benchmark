#!/bin/bash
# Benchmark ALL 23 REST implementations x 5 scenarios on K3s.
# wrk -t2 -c50 -d5s --latency. Short job names (<=25 chars). Wait 10s. Parse Requests/sec.
NS=benchmark
RESULTS=/tmp/bench_results.txt
: > "$RESULTS"

IMPLS='bun-rest-bun-serve bun-rest-elysia bun-rest-hono csharp-rest-controllers csharp-rest-minimal-api deno-rest-deno-serve deno-rest-fresh deno-rest-hono deno-rest-oak go-rest-echo go-rest-fiber go-rest-gin graalvm-rest-vertx kotlin-rest-ktor nodejs-rest-express nodejs-rest-fastify nodejs-rest-nestjs python-rest-django python-rest-fastapi python-rest-flask rust-rest-actix-web rust-rest-axum rust-rest-rocket'

# scenario: path
declare -a SCEN=(health json db-simple db-complex cache)
declare -A PATHS=( [health]="/health" [json]="/json" [db-simple]="/db/simple?id=3" [db-complex]="/db/complex?days=30" [cache]="/cache?key=benchmark" )

run_one() {
  local impl="$1" scen="$2" path="$3"
  # short job name: hash impl->short + scen. Keep <=25 chars, lowercase, [a-z0-9-]
  local short=$(echo -n "$impl" | md5sum | cut -c1-8)
  local jobname="w-${short}-${scen}"
  # ensure <=25 chars
  jobname="${jobname:0:25}"
  local url="http://${impl}.${NS}.svc.cluster.local${path}"

  # delete any existing
  kubectl -n "$NS" delete job "$jobname" --ignore-not-found --timeout=10s >/dev/null 2>&1

  # create job yaml and apply
  cat <<YAML | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata:
  name: ${jobname}
  namespace: ${NS}
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: w
        image: williamyeh/wrk:latest
        command: ["/bin/sh","-c"]
        args: ["wrk -t2 -c50 -d5s --latency ${url}"]
      resources:
        requests: {cpu: "500m", memory: "128Mi"}
        limits: {cpu: "1", memory: "256Mi"}
YAML

  sleep 10
  local logs
  logs=$(kubectl -n "$NS" logs "job/${jobname}" 2>/dev/null)
  # parse Requests/sec
  local rps
  rps=$(echo "$logs" | grep -oE 'Requests/sec:[[:space:]]+[0-9.]+' | grep -oE '[0-9.]+' | head -1)
  [ -z "$rps" ] && rps="0"

  echo "${impl}|${scen}|${rps}" | tee -a "$RESULTS"

  # cleanup
  kubectl -n "$NS" delete job "$jobname" --ignore-not-found --timeout=10s >/dev/null 2>&1
}

total=$(( ${#SCEN[@]} * 23 ))
i=0
for impl in $IMPLS; do
  for scen in "${SCEN[@]}"; do
    i=$((i+1))
    echo "[$i/$total] $impl $scen ..." >&2
    run_one "$impl" "$scen" "${PATHS[$scen]}"
  done
done

echo "BENCH_COMPLETE" >&2
echo "=== RESULTS ==="
cat "$RESULTS"
