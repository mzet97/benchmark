#!/bin/bash
set -e
B=/home/k8s1/benchmark/src

echo '############ FIX GO-ECHO main.go ############'
# Replace hardcoded DB URL and redis addr with env-var-driven values
python3 - "$B/go/echo/main.go" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
s=s.replace(
  'sql.Open("postgres", "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api")',
  'sql.Open("postgres", os.Getenv("DATABASE_URL"))'
)
# add "os" import if missing
if '"os"' not in s:
    s=s.replace('import (\n\t"database/sql"', 'import (\n\t"database/sql"\n\t"os"')
# redis from env
s=s.replace(
  'Addr:     "redis.home.arpa:30379",\n\t\tPassword: "Admin@123",',
  'Addr:     os.Getenv("REDIS_ADDR"),\n\t\tPassword: os.Getenv("REDIS_PASSWORD"),'
)
open(p,'w').write(s)
print('echo patched')
PY
grep -n "sql.Open\|os.Getenv\|REDIS_ADDR" "$B/go/echo/main.go"

echo '############ FIX GO-GIN main.go ############'
python3 - "$B/go/gin/main.go" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
s=s.replace(
  'sql.Open("postgres", "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api")',
  'sql.Open("postgres", os.Getenv("DATABASE_URL"))'
)
if '"os"' not in s:
    s=s.replace('import (\n\t"database/sql"', 'import (\n\t"database/sql"\n\t"os"')
s=s.replace(
  'Addr:     "redis.home.arpa:30379",\n\t\tPassword: "Admin@123",',
  'Addr:     os.Getenv("REDIS_ADDR"),\n\t\tPassword: os.Getenv("REDIS_PASSWORD"),'
)
open(p,'w').write(s)
print('gin patched')
PY
grep -n "sql.Open\|os.Getenv\|REDIS_ADDR" "$B/go/gin/main.go"

echo '############ FIX NESTJS prefix ############'
sed -i "/app.setGlobalPrefix('api');/d" "$B/nodejs/nestjs/src/main.ts"
grep -n "setGlobalPrefix\|listen" "$B/nodejs/nestjs/src/main.ts" || echo "(prefix removed)"

echo '############ REBUILD go-echo ############'
cd "$B/go/echo"
docker build -t benchmark/go-rest-echo:fixed . 2>&1 | tail -3
docker save benchmark/go-rest-echo:fixed -o /tmp/goecho.tar
sudo -S k3s ctr images import --no-unpack /tmp/goecho.tar <<< 'Admin@123' 2>&1 | tail -1

echo '############ REBUILD go-gin ############'
cd "$B/go/gin"
docker build -t benchmark/go-rest-gin:fixed . 2>&1 | tail -3
docker save benchmark/go-rest-gin:fixed -o /tmp/gogin.tar
sudo -S k3s ctr images import --no-unpack /tmp/gogin.tar <<< 'Admin@123' 2>&1 | tail -1

echo '############ REBUILD nestjs ############'
cd "$B/nodejs/nestjs"
docker build -t benchmark/nodejs-rest-nestjs:fixed . 2>&1 | tail -3
docker save benchmark/nodejs-rest-nestjs:fixed -o /tmp/nestjs.tar
sudo -S k3s ctr images import --no-unpack /tmp/nestjs.tar <<< 'Admin@123' 2>&1 | tail -1

echo '############ DEPLOY with env ############'
# REDIS_ADDR for go (redis host:port). DATABASE_URL already in secret.
for spec in "go-rest-echo benchmark/go-rest-echo:fixed" "go-rest-gin benchmark/go-rest-gin:fixed" "nodejs-rest-nestjs benchmark/nodejs-rest-nestjs:fixed"; do
  impl=$(echo $spec | cut -d' ' -f1)
  img=$(echo $spec | cut -d' ' -f2)
  PATCH=$(python3 -c "
import json
env=[{'name':'DATABASE_URL','value':'postgresql://db_admin:Admin%40123@192.168.1.52:5432/benchmark_api?sslmode=disable'},{'name':'REDIS_ADDR','value':'redis-master.redis.svc.cluster.local:6379'},{'name':'REDIS_PASSWORD','value':'Admin@123'},{'name':'REDIS_URL','value':'redis://:Admin%40123@redis-master.redis.svc.cluster.local:6379'}]
print(json.dumps({'spec':{'template':{'spec':{'containers':[{'name':'app','image':'$img','env':env,'imagePullPolicy':'Never'}]}}}}))
")
  kubectl -n benchmark patch deploy "$impl" --type=strategic -p "$PATCH" 2>&1 | head -1
done
for impl in go-rest-echo go-rest-gin nodejs-rest-nestjs; do
  kubectl -n benchmark rollout status deploy/"$impl" --timeout=180s >/dev/null 2>&1 && echo "OK $impl" || echo "FAIL $impl"
done
sleep 4
echo '############ TEST ############'
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata: {name: fixtest, namespace: benchmark}
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 60
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: c
        image: curlimages/curl:latest
        command: ["/bin/sh","-c"]
        args: ["for impl in go-rest-echo go-rest-gin nodejs-rest-nestjs; do for p in /health /json /db/simple?id=3 /db/complex?days=30 /cache?key=benchmark; do code=$(curl -s -o /dev/null -w '%{http_code}' -m 8 http://$impl.benchmark.svc.cluster.local$p); echo \"$impl $p -> $code\"; done; done"]
YAML
sleep 3; kubectl wait --for=condition=complete job/fixtest -n benchmark --timeout=90s; kubectl logs job/fixtest -n benchmark; kubectl delete job fixtest -n benchmark --ignore-not-found
echo 'FIX_GO_NESTJS_DONE'
