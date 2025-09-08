#!/bin/bash
# Production boot script for Docker container

set -e

echo "Starting Foody application..."

# Wait for database to be ready
echo "Waiting for database connection..."
while ! flask db current >/dev/null 2>&1; do
    echo "Database not ready, waiting 5 seconds..."
    sleep 5
done

# Run database migrations
echo "Running database migrations..."
while true; do
    flask db upgrade
    if [[ "$?" == "0" ]]; then
        echo "Database migrations completed successfully"
        break
    fi
    echo "Migration failed, retrying in 5 seconds..."
    sleep 5
done

# Start the application with Gunicorn
echo "Starting Gunicorn server..."
exec gunicorn \
    --bind 0.0.0.0:5000 \
    --workers ${GUNICORN_WORKERS:-4} \
    --worker-class gevent \
    --worker-connections ${GUNICORN_WORKER_CONNECTIONS:-1000} \
    --max-requests ${GUNICORN_MAX_REQUESTS:-1000} \
    --max-requests-jitter ${GUNICORN_MAX_REQUESTS_JITTER:-100} \
    --timeout ${GUNICORN_TIMEOUT:-30} \
    --keep-alive ${GUNICORN_KEEPALIVE:-2} \
    --access-logfile - \
    --error-logfile - \
    --log-level ${LOG_LEVEL:-info} \
    --preload \
    foody:app
