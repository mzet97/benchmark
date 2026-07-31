#!/bin/bash
# Add generated column total_amount = total to orders table (non-destructive) so complex queries work.
# Also grant to db_admin (already owner). Run from hostNetwork pod.
cat <<'EOF' | kubectl apply -f - >/dev/null 2>&1
apiVersion: batch/v1
kind: Job
metadata:
  name: add-col
  namespace: benchmark
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 60
  template:
    spec:
      restartPolicy: Never
      hostNetwork: true
      containers:
      - name: pg
        image: postgres:16-alpine
        command: ["/bin/sh","-c"]
        args:
        - |
          export PGPASSWORD='Admin@123'
          echo '=== adding total_amount column if missing ==='
          psql -h 192.168.1.52 -U db_admin -d benchmark_api -v ON_ERROR_STOP=0 <<'SQL'
          ALTER TABLE orders ADD COLUMN IF NOT EXISTS total_amount numeric(10,2) GENERATED ALWAYS AS (total) STORED;
          COMMENT ON COLUMN orders.total_amount IS 'Alias of total for benchmark complex queries';
          \d orders
          SELECT count(*) AS orders_with_total_amount FROM orders;
          SELECT total, total_amount FROM orders LIMIT 3;
          SQL
EOF
sleep 3
kubectl wait --for=condition=complete job/add-col -n benchmark --timeout=60s
kubectl logs job/add-col -n benchmark
kubectl delete job add-col -n benchmark --ignore-not-found
