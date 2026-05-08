#!/bin/sh
set -e

echo "=== Learno Backend Starting ==="

# Ensure data directory exists (for SQLite volume)
mkdir -p /data /app/static/generated_images

echo "Database tables will be created on first request via app lifespan."

WORKERS=${WORKERS:-2}

echo "Starting uvicorn with $WORKERS worker(s)..."
exec uvicorn app.main:app \
    --host 0.0.0.0 \
    --port "${PORT:-8000}" \
    --workers "$WORKERS" \
    --proxy-headers \
    --forwarded-allow-ips "*"
