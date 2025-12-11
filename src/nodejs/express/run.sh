#!/bin/bash
set -e

export NODE_ENV=production
export PORT=${PORT:-3000}

# Run the application
exec node index.js
