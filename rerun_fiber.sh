#!/bin/bash
# Re-run just go-rest-fiber health + json (pod had restarted during original run)
NS=benchmark
rerun() {
  local impl="$1" scen="$2" path="$3"
  local short=$(echo -n "$impl" | md5sum | cut -c1-8)
  local jobname="r-${short}-${scen}"; jobname="${jobname:0:25}"
  local url="http://${impl}.${NS}.svc.cluster.local${path}"
  kubectl -n "$NS" delete job "$jobname" --ignore-not-found --timeout=10s >/dev/null 2>&1
  cat <<YAML | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata: {name: ${jobname}, namespace: ${NS}}
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
YAML
  sleep 10
  local logs; logs=$(kubectl -n "$NS" logs "job/${jobname}" 2>/dev/null)
  local rps; rps=$(echo "$logs" | grep -oE 'Requests/sec:[[:space:]]+[0-9.]+' | grep -oE '[0-9.]+' | head -1)
  [ -z "$rps" ] && rps="0"
  echo "RERUN ${impl}|${scen}|${rps}"
  kubectl -n "$NS" delete job "$jobname" --ignore-not-found --timeout=10s >/dev/null 2>&1
}
rerun go-rest-fiber health /health
rerun go-rest-fiber json /json
echo "RERUN_DONE"
