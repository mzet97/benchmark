#!/bin/bash
set -e

export FLASK_APP=app
export FLASK_ENV=production

# Run with gunicorn
exec gunicorn -b 0.0.0.0:8000 --workers 4 "app:create_app()"
