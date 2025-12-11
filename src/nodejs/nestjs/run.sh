#!/bin/bash
set -e

echo "Starting Node.js NestJS API..."
export NODE_ENV=production

npm run start:prod
