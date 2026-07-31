#!/bin/bash
set -e
B=/home/k8s1/benchmark/src/csharp

fix_cache() {
  local f="$1"
  [ -f "$f" ] || { echo "MISSING $f"; return 0; }
  python3 - "$f" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old='''        // Parse redis://:password@host:port to StackExchange.Redis format
        var lastAt = redisUrl.LastIndexOf('@');
        var schemeEnd = redisUrl.IndexOf("://");
        var password = redisUrl.Substring(schemeEnd + 4, lastAt - schemeEnd - 4); // skip ://:
        var hostPort = redisUrl.Substring(lastAt + 1);
        var host = hostPort.Split(':')[0];
        var port = hostPort.Contains(':') ? hostPort.Split(':')[1] : "6379";

        var redisConfig = $"{host}:{port},password={password},abortConnect=false";
        var connection = ConnectionMultiplexer.Connect(redisConfig);'''
new='''        // If already in StackExchange.Redis format (contains comma), use directly
        string redisConfig;
        if (redisUrl.Contains(",") || !redisUrl.Contains("://"))
        {
            redisConfig = redisUrl.Contains("://") ? redisUrl : redisUrl + ",abortConnect=false";
        }
        else
        {
            // Parse redis://:password@host:port to StackExchange.Redis format
            var lastAt = redisUrl.LastIndexOf('@');
            var schemeEnd = redisUrl.IndexOf("://");
            var password = lastAt > schemeEnd ? redisUrl.Substring(schemeEnd + 4, lastAt - schemeEnd - 4) : "";
            var hostPort = lastAt > schemeEnd ? redisUrl.Substring(lastAt + 1) : redisUrl.Substring(schemeEnd + 3);
            var host = hostPort.Split(':')[0];
            var port = hostPort.Contains(':') ? hostPort.Split(':')[1].Split('/')[0] : "6379";
            redisConfig = $"{host}:{port},password={password},abortConnect=false";
        }
        var connection = ConnectionMultiplexer.Connect(redisConfig);'''
if old in s:
    s=s.replace(old,new); open(p,'w').write(s); print('patched',p)
else:
    print('PATTERN NOT FOUND in',p)
PY
}
fix_cache "$B/MinimalApi/Services/CacheService.cs"
fix_cache "$B/Controllers/Services/CacheService.cs"

# Also fix appsettings to point at the right redis + db (env override is preferred but appsettings is fallback)
for d in MinimalApi Controllers; do
  ap="$B/$d/appsettings.json"
  [ -f "$ap" ] && python3 - "$ap" <<'PY'
import sys,json
p=sys.argv[1]
try:
    d=json.load(open(p))
    d.setdefault("ConnectionStrings",{})["DefaultConnection"]="Host=192.168.1.52;Port=5432;Database=benchmark_api;Username=db_admin;Password=Admin@123;Maximum Pool Size=25;Timeout=30;"
    d.setdefault("Redis",{})["ConnectionString"]="redis-master.redis.svc.cluster.local:6379,password=Admin@123,defaultDatabase=0,ssl=False,abortConnect=false"
    json.dump(d,open(p,'w'),indent=2)
    print('appsettings fixed',p)
except Exception as e:
    print('appsettings err',p,e)
PY
done

echo '### rebuild csharp MinimalApi ###'
cd "$B/MinimalApi"
docker build -t benchmark/csharp-rest-minimal-api:fixed . 2>&1 | tail -3
docker save benchmark/csharp-rest-minimal-api:fixed -o /tmp/csmin.tar
sudo -S k3s ctr images import --no-unpack /tmp/csmin.tar <<< 'Admin@123' 2>&1 | tail -1

echo '### rebuild csharp Controllers ###'
cd "$B/Controllers"
docker build -t benchmark/csharp-rest-controllers:fixed . 2>&1 | tail -3
docker save benchmark/csharp-rest-controllers:fixed -o /tmp/csctrl.tar
sudo -S k3s ctr images import --no-unpack /tmp/csctrl.tar <<< 'Admin@123' 2>&1 | tail -1

echo '### deploy csharp with env ###'
for spec in "csharp-rest-minimal-api benchmark/csharp-rest-minimal-api:fixed" "csharp-rest-controllers benchmark/csharp-rest-controllers:fixed"; do
  impl=$(echo $spec | cut -d' ' -f1); img=$(echo $spec | cut -d' ' -f2)
  PATCH=$(python3 -c "
import json
env=[{'name':'DATABASE_URL','value':'postgresql://db_admin:Admin%40123@192.168.1.52:5432/benchmark_api?sslmode=disable'},{'name':'REDIS_URL','value':'redis://:Admin%40123@redis-master.redis.svc.cluster.local:6379'}]
print(json.dumps({'spec':{'template':{'spec':{'containers':[{'name':'app','image':'$img','env':env,'imagePullPolicy':'Never'}]}}}}))
")
  kubectl -n benchmark patch deploy "$impl" --type=strategic -p "$PATCH" 2>&1 | head -1
  kubectl -n benchmark rollout status deploy/"$impl" --timeout=180s >/dev/null 2>&1 && echo "OK $impl" || echo "FAIL $impl"
done
sleep 4
echo '### test csharp ###'
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata: {name: cstest, namespace: benchmark}
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
        args: ["for impl in csharp-rest-minimal-api csharp-rest-controllers; do for p in /health /json /db/simple?id=3 /db/complex?days=30 /cache?key=benchmark; do code=$(curl -s -o /dev/null -w '%{http_code}' -m 8 http://$impl.benchmark.svc.cluster.local$p); echo \"$impl $p -> $code\"; done; done"]
YAML
sleep 3; kubectl wait --for=condition=complete job/cstest -n benchmark --timeout=90s; kubectl logs job/cstest -n benchmark; kubectl delete job cstest -n benchmark --ignore-not-found
echo 'FIX_CSHARP_DONE'
