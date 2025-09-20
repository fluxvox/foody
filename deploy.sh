#!/bin/bash

# Production deployment script for Foody
set -e

echo "🚀 Starting Foody production deployment..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "Please copy production.env.example to .env and configure your environment variables."
    exit 1
fi

# Load environment variables
source .env

# Check required environment variables
required_vars=("POSTGRES_PASSWORD" "REDIS_PASSWORD" "SECRET_KEY")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: Required environment variable $var is not set!"
        exit 1
    fi
done

echo "✅ Environment variables validated"

# Create SSL certificate directory if it doesn't exist
mkdir -p deployment/nginx/ssl

# Generate self-signed SSL certificate if it doesn't exist
if [ ! -f deployment/nginx/ssl/cert.pem ] || [ ! -f deployment/nginx/ssl/key.pem ]; then
    echo "🔐 Generating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout deployment/nginx/ssl/key.pem \
        -out deployment/nginx/ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    echo "✅ SSL certificate generated"
else
    echo "✅ SSL certificate already exists"
fi

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down --remove-orphans

# Build and start services
echo "🔨 Building and starting services..."
docker-compose up --build -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
timeout=300
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose ps | grep -q "healthy"; then
        echo "✅ Services are healthy"
        break
    fi
    echo "Waiting for services... ($elapsed/$timeout seconds)"
    sleep 10
    elapsed=$((elapsed + 10))
done

if [ $elapsed -ge $timeout ]; then
    echo "❌ Timeout waiting for services to be healthy"
    docker-compose logs
    exit 1
fi

# Check application health
echo "🏥 Checking application health..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ Application is healthy and responding"
else
    echo "❌ Application health check failed"
    docker-compose logs web
    exit 1
fi

echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Service Information:"
echo "  - Web Application: http://localhost (HTTP redirects to HTTPS)"
echo "  - Web Application: https://localhost (HTTPS)"
echo "  - Health Check: https://localhost/health"
echo "  - API Base URL: https://localhost/api"
echo ""
echo "📊 Container Status:"
docker-compose ps
echo ""
echo "📝 Useful Commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop services: docker-compose down"
echo "  - Restart services: docker-compose restart"
echo "  - Update application: docker-compose up --build -d"

