#!/bin/bash
set -e
B=/home/k8s1/benchmark/src

echo '### patch go-echo port ###'
sed -i 's#e.Logger.Fatal(e.Start(":3000"))#e.Logger.Fatal(e.Start(":" + portStr))#' "$B/go/echo/main.go"
# insert port read after imports - add near top of main
python3 - "$B/go/echo/main.go" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
s=s.replace('func main() {\n\tdb, err := sql.Open',
            'func main() {\n\tportStr := os.Getenv("PORT")\n\tif portStr == "" {\n\t\tportStr = "8080"\n\t}\n\tdb, err := sql.Open')
open(p,'w').write(s)
PY
grep -n "portStr\|e.Start" "$B/go/echo/main.go"

echo '### patch go-gin port ###'
sed -i 's#r.Run(":3000")#r.Run(":" + portStr)#' "$B/go/gin/main.go"
python3 - "$B/go/gin/main.go" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
s=s.replace('func main() {\n\tdb, err := sql.Open',
            'func main() {\n\tportStr := os.Getenv("PORT")\n\tif portStr == "" {\n\t\tportStr = "8080"\n\t}\n\tdb, err := sql.Open')
open(p,'w').write(s)
PY
grep -n "portStr\|r.Run" "$B/go/gin/main.go"

echo '### rebuild go-echo:fixed2 ###'
cd "$B/go/echo"
docker build -t benchmark/go-rest-echo:fixed2 . 2>&1 | tail -3
docker save benchmark/go-rest-echo:fixed2 -o /tmp/goecho2.tar
sudo -S k3s ctr images import --no-unpack /tmp/goecho2.tar <<< 'Admin@123' 2>&1 | tail -1

echo '### rebuild go-gin:fixed2 ###'
cd "$B/go/gin"
docker build -t benchmark/go-rest-gin:fixed2 . 2>&1 | tail -3
docker save benchmark/go-rest-gin:fixed2 -o /tmp/gogin2.tar
sudo -S k3s ctr images import --no-unpack /tmp/gogin2.tar <<< 'Admin@123' 2>&1 | tail -1

echo '### deploy ###'
for spec in "go-rest-echo benchmark/go-rest-echo:fixed2" "go-rest-gin benchmark/go-rest-gin:fixed2"; do
  impl=$(echo $spec | cut -d' ' -f1)
  img=$(echo $spec | cut -d' ' -f2)
  PATCH=$(python3 -c "
import json
env=[{'name':'DATABASE_URL','value':'postgresql://db_admin:Admin%40123@192.168.1.52:5432/benchmark_api?sslmode=disable'},{'name':'REDIS_ADDR','value':'redis-master.redis.svc.cluster.local:6379'},{'name':'REDIS_PASSWORD','value':'Admin@123'},{'name':'REDIS_URL','value':'redis://:Admin%40123@redis-master.redis.svc.cluster.local:6379'},{'name':'PORT','value':'8080'}]
print(json.dumps({'spec':{'template':{'spec':{'containers':[{'name':'app','image':'$img','env':env,'imagePullPolicy':'Never'}]}}}}))
")
  kubectl -n benchmark patch deploy "$impl" --type=strategic -p "$PATCH" 2>&1 | head -1
  kubectl -n benchmark rollout status deploy/"$impl" --timeout=150s >/dev/null 2>&1 && echo "OK $impl" || echo "FAIL $impl"
done
sleep 4
echo '### test ###'
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata: {name: gotest2, namespace: benchmark}
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
        args: ["for impl in go-rest-echo go-rest-gin; do for p in /health /db/simple?id=3 /db/complex?days=30 /cache?key=benchmark; do code=$(curl -s -o /dev/null -w '%{http_code}' -m 8 http://$impl.benchmark.svc.cluster.local$p); echo \"$impl $p -> $code\"; done; done"]
YAML
sleep 3; kubectl wait --for=condition=complete job/gotest2 -n benchmark --timeout=60s; kubectl logs job/gotest2 -n benchmark; kubectl delete job gotest2 -n benchmark --ignore-not-found
echo 'FIX_GO_PORT_DONE'
