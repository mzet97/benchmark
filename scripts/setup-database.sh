#!/bin/bash

# Setup PostgreSQL database for benchmark
# Usage: ./setup-database.sh [host] [port] [database] [username] [password]

set -e

HOST=${1:-"spsql.home.arpa"}
PORT=${2:-"5432"}
DATABASE=${3:-"benchmark_api"}
USERNAME=${4:-"app"}
PASSWORD=${5:-"Admin@123"}

PGPASSWORD="$PASSWORD"

echo "=================================="
echo "Database Setup"
echo "=================================="
echo "Host: $HOST"
echo "Port: $PORT"
echo "Database: $DATABASE"
echo "Username: $USERNAME"
echo "=================================="
echo ""

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo "Error: psql is not installed"
    echo "Install with: sudo apt-get install postgresql-client"
    exit 1
fi

# Test connection
echo "Testing database connection..."
if ! PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USERNAME" -d "$DATABASE" -c "SELECT 1;" &> /dev/null; then
    echo "Error: Cannot connect to database"
    echo "Please check:"
    echo "  - Database is running"
    echo "  - Host: $HOST is accessible"
    echo "  - Port: $PORT is open"
    echo "  - Username: $USERNAME"
    echo "  - Database: $DATABASE exists"
    exit 1
fi

echo "✓ Database connection successful"
echo ""

# Create schema
echo "Creating schema..."
if PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USERNAME" -d "$DATABASE" -f sql/01_schema.sql; then
    echo "✓ Schema created successfully"
else
    echo "✗ Failed to create schema"
    exit 1
fi
echo ""

# Seed data
echo "Seeding data (this may take a few minutes)..."
if PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USERNAME" -d "$DATABASE" -f sql/02_seed.sql > /dev/null 2>&1; then
    echo "✓ Data seeded successfully"
else
    echo "✗ Failed to seed data"
    exit 1
fi
echo ""

# Create indexes
echo "Creating indexes..."
if PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USERNAME" -d "$DATABASE" -f sql/03_indexes.sql > /dev/null 2>&1; then
    echo "✓ Indexes created successfully"
else
    echo "✗ Failed to create indexes"
    exit 1
fi
echo ""

# Verify data
echo "Verifying data..."
echo "Row counts:"
PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USERNAME" -d "$DATABASE" -t -c "
SELECT 'users: ' || COUNT(*) FROM users
UNION ALL
SELECT 'orders: ' || COUNT(*) FROM orders
UNION ALL
SELECT 'order_items: ' || COUNT(*) FROM order_items;
"

# Show sample data
echo ""
echo "Sample user:"
PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USERNAME" -d "$DATABASE" -c "SELECT * FROM users LIMIT 1;"

echo ""
echo "Sample order:"
PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USERNAME" -d "$DATABASE" -c "SELECT * FROM orders LIMIT 1;"

echo ""
echo "Sample order item:"
PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USERNAME" -d "$DATABASE" -c "SELECT * FROM order_items LIMIT 1;"

# Show index information
echo ""
echo "Indexes created:"
PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USERNAME" -d "$DATABASE" -c "
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('users', 'orders', 'order_items')
ORDER BY tablename, indexname;
"

echo ""
echo "=================================="
echo "Database setup completed successfully!"
echo "=================================="
echo ""
echo "Next steps:"
echo "  1. Build the C# application: dotnet build src/csharp/MinimalApi"
echo "  2. Deploy to Kubernetes: kubectl apply -f src/csharp/MinimalApi/k8s/"
echo "  3. Run benchmarks: ./scripts/benchmark-wrk.sh csharp-minimalapi"
echo "=================================="
