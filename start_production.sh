#!/bin/bash

# Production startup script for LaTeX Compiler Service

set -e

# Configuration
export API_KEY=${API_KEY:-"djsakjc213hjbkk3h123jkb123kbj"}
export FLASK_ENV=production
export PYTHONPATH=/app

# Create log directories
mkdir -p /var/log/gunicorn
mkdir -p /app/logs

# Set proper permissions for log directories
chmod 755 /var/log/gunicorn
chmod 755 /app/logs

echo "Starting LaTeX Compiler Service in production mode..."
echo "API Key configured: ${API_KEY:0:10}..."
echo "Workers: $(python3 -c 'import multiprocessing; print(multiprocessing.cpu_count() * 2 + 1)')"

# Start Gunicorn with production configuration
exec gunicorn \
    --config /app/gunicorn.conf.py \
    --chdir /app \
    app:app
