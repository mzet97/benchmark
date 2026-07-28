#!/bin/bash
set -e

PORT=${PORT:-8000}
HOST=${HOST:-"0.0.0.0"}

echo "=========================================="
echo "  Python Django - Benchmark API"
echo "=========================================="
echo "Starting on ${HOST}:${PORT}"
echo ""

# Run migrations
python manage.py migrate --run-syncdb 2>/dev/null || true

# Start server
if [ "$1" = "dev" ]; then
    python manage.py runserver ${HOST}:${PORT}
else
    gunicorn -b ${HOST}:${PORT} --workers 4 --threads 2 app.wsgi:application
fi
