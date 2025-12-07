#!/bin/bash

# Collect system and database metrics
# Usage: ./collect-metrics.sh [output_dir]

set -e

OUTPUT_DIR=${1:-"results/metrics/$(date +%Y%m%d_%H%M%S)"}
mkdir -p "$OUTPUT_DIR"

echo "=================================="
echo "Collecting System Metrics"
echo "Output: $OUTPUT_DIR"
echo "=================================="
echo ""

# System information
echo "=== System Information ===" > "$OUTPUT_DIR/system-info.txt"
uname -a >> "$OUTPUT_DIR/system-info.txt"
cat /etc/os-release >> "$OUTPUT_DIR/system-info.txt"

# CPU information
echo "=== CPU Information ===" > "$OUTPUT_DIR/cpu.txt"
lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|Socket" >> "$OUTPUT_DIR/cpu.txt"
nproc >> "$OUTPUT_DIR/cpu.txt"

# Memory information
echo "=== Memory Information ===" > "$OUTPUT_DIR/memory.txt"
free -h >> "$OUTPUT_DIR/memory.txt"
cat /proc/meminfo | head -20 >> "$OUTPUT_DIR/memory.txt"

# Disk information
echo "=== Disk Information ===" > "$OUTPUT_DIR/disk.txt"
df -h >> "$OUTPUT_DIR/disk.txt"
lsblk >> "$OUTPUT_DIR/disk.txt"

# Network information
echo "=== Network Information ===" > "$OUTPUT_DIR/network.txt"
ip addr show >> "$OUTPUT_DIR/network.txt"

# Running processes (top 20 by CPU)
echo "=== Top Processes by CPU ===" > "$OUTPUT_DIR/top-processes-cpu.txt"
ps aux --sort=-%cpu | head -21 >> "$OUTPUT_DIR/top-processes-cpu.txt"

# Running processes (top 20 by Memory)
echo "=== Top Processes by Memory ===" > "$OUTPUT_DIR/top-processes-mem.txt"
ps aux --sort=-%mem | head -21 >> "$OUTPUT_DIR/top-processes-mem.txt"

# Database connection test
echo "=== Database Connection Test ===" > "$OUTPUT_DIR/database-test.txt"
echo "Testing PostgreSQL connection..." >> "$OUTPUT_DIR/database-test.txt"

# Use psql if available
if command -v psql &> /dev/null; then
    PGPASSWORD=Admin@123 psql -h spsql.home.arpa -p 5432 -U app -d benchmark_api -c "SELECT version();" >> "$OUTPUT_DIR/database-test.txt" 2>&1 || echo "PostgreSQL connection failed" >> "$OUTPUT_DIR/database-test.txt
else
    echo "psql not available" >> "$OUTPUT_DIR/database-test.txt"
fi

# Redis connection test
echo "=== Redis Connection Test ===" > "$OUTPUT_DIR/redis-test.txt"
echo "Testing Redis connection..." >> "$OUTPUT_DIR/redis-test.txt"

if command -v redis-cli &> /dev/null; then
    redis-cli -h redis.home.arpa -p 30379 -a Admin@123 ping >> "$OUTPUT_DIR/redis-test.txt" 2>&1 || echo "Redis connection failed" >> "$OUTPUT_DIR/redis-test.txt
else
    echo "redis-cli not available" >> "$OUTPUT_DIR/redis-test.txt"
fi

# Database query performance
echo "=== Database Query Performance ===" > "$OUTPUT_DIR/db-performance.txt"

if command -v psql &> /dev/null; then
    echo "Simple query (SELECT by ID):" >> "$OUTPUT_DIR/db-performance.txt"
    PGPASSWORD=Admin@123 psql -h spsql.home.arpa -p 5432 -U app -d benchmark_api -c "\timing on" >> "$OUTPUT_DIR/db-performance.txt"
    PGPASSWORD=Admin@123 psql -h spsql.home.arpa -p 5432 -U app -d benchmark_api -c "SELECT * FROM users WHERE id = 1;" >> "$OUTPUT_DIR/db-performance.txt" 2>&1 || echo "Query failed" >> "$OUTPUT_DIR/db-performance.txt"

    echo "" >> "$OUTPUT_DIR/db-performance.txt"
    echo "Complex query (JOIN + aggregation):" >> "$OUTPUT_DIR/db-performance.txt"
    PGPASSWORD=Admin@123 psql -h spsql.home.arpa -p 5432 -U app -d benchmark_api -c "
        SELECT
            u.id,
            CONCAT(u.first_name, ' ', u.last_name) as user_name,
            COUNT(DISTINCT o.id) as total_orders,
            COALESCE(SUM(oi.quantity * oi.price), 0) as total_value
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
        LEFT JOIN order_items oi ON o.id = oi.order_id
        WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY u.id, u.first_name, u.last_name
        LIMIT 10;" >> "$OUTPUT_DIR/db-performance.txt" 2>&1 || echo "Query failed" >> "$OUTPUT_DIR/db-performance.txt"
else
    echo "psql not available, skipping database performance tests" >> "$OUTPUT_DIR/db-performance.txt"
fi

# Network performance
echo "=== Network Performance ===" > "$OUTPUT_DIR/network-performance.txt"
echo "Testing connectivity to PostgreSQL..." >> "$OUTPUT_DIR/network-performance.txt"
timeout 5 bash -c "cat < /dev/null > /dev/tcp/spsql.home.arpa/5432" 2>&1 && echo "PostgreSQL port 5432 is open" >> "$OUTPUT_DIR/network-performance.txt" || echo "PostgreSQL port 5432 is closed or filtered" >> "$OUTPUT_DIR/network-performance.txt"

echo "Testing connectivity to Redis..." >> "$OUTPUT_DIR/network-performance.txt"
timeout 5 bash -c "cat < /dev/null > /dev/tcp/redis.home.arpa/30379" 2>&1 && echo "Redis port 30379 is open" >> "$OUTPUT_DIR/network-performance.txt" || echo "Redis port 30379 is closed or filtered" >> "$OUTPUT_DIR/network-performance.txt"

# Load average
echo "=== Load Average ===" > "$OUTPUT_DIR/load-average.txt"
uptime >> "$OUTPUT_DIR/load-average.txt"
cat /proc/loadavg >> "$OUTPUT_DIR/load-average.txt"

# Save timestamp
echo "=== Collection Timestamp ===" > "$OUTPUT_DIR/timestamp.txt"
date >> "$OUTPUT_DIR/timestamp.txt"
date -u >> "$OUTPUT_DIR/timestamp.txt"

# Generate summary
echo "=== Metrics Collection Summary ===" > "$OUTPUT_DIR/summary.txt"
echo "Timestamp: $(date)" >> "$OUTPUT_DIR/summary.txt"
echo "Output Directory: $OUTPUT_DIR" >> "$OUTPUT_DIR/summary.txt"
echo "" >> "$OUTPUT_DIR/summary.txt"
echo "Files generated:" >> "$OUTPUT_DIR/summary.txt"
ls -lh "$OUTPUT_DIR" | tail -n +2 >> "$OUTPUT_DIR/summary.txt"

echo ""
echo "=================================="
echo "Metrics collection completed!"
echo "Results directory: $OUTPUT_DIR"
echo "=================================="
echo ""
cat "$OUTPUT_DIR/summary.txt"
