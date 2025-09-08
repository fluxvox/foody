#!/bin/bash

# Local Docker testing script for Foody
set -e

echo "🧪 Starting local Docker testing for Foody..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running!"
    echo "Please start Docker Desktop or Docker daemon and try again."
    exit 1
fi

echo "✅ Docker is running"

# Stop any existing containers
echo "🛑 Stopping existing local containers..."
docker compose -f docker-compose.local.yml down --remove-orphans

# Build and start services
echo "🔨 Building and starting local services..."
docker compose -f docker-compose.local.yml up --build -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
timeout=300
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker compose -f docker-compose.local.yml ps | grep -q "healthy"; then
        echo "✅ Services are healthy"
        break
    fi
    echo "Waiting for services... ($elapsed/$timeout seconds)"
    sleep 10
    elapsed=$((elapsed + 10))
done

if [ $elapsed -ge $timeout ]; then
    echo "❌ Timeout waiting for services to be healthy"
    docker compose -f docker-compose.local.yml logs
    exit 1
fi

# Check application health
echo "🏥 Checking application health..."
if curl -f http://localhost:5001/health > /dev/null 2>&1; then
    echo "✅ Application is healthy and responding"
else
    echo "❌ Application health check failed"
    docker compose -f docker-compose.local.yml logs web
    exit 1
fi

echo "🎉 Local Docker testing setup completed successfully!"
echo ""
echo "📋 Local Service Information:"
echo "  - Web Application: http://localhost:5001"
echo "  - Health Check: http://localhost:5001/health"
echo "  - API Base URL: http://localhost:5001/api"
echo "  - Database: localhost:5432 (user: foody, password: foody123, db: foody)"
echo "  - Redis: localhost:6379"
echo "  - Elasticsearch: http://localhost:9200"
echo ""
echo "📊 Container Status:"
docker compose -f docker-compose.local.yml ps
echo ""
echo "📝 Useful Commands:"
echo "  - View logs: docker compose -f docker-compose.local.yml logs -f"
echo "  - Stop services: docker compose -f docker-compose.local.yml down"
echo "  - Restart services: docker compose -f docker-compose.local.yml restart"
echo "  - Update application: docker compose -f docker-compose.local.yml up --build -d"
echo "  - Access database: docker compose -f docker-compose.local.yml exec db psql -U foody -d foody"
echo "  - Access Redis: docker compose -f docker-compose.local.yml exec redis redis-cli"
echo ""
echo "🔍 Testing Commands:"
echo "  - Test health: curl http://localhost:5001/health"
echo "  - Test API: curl http://localhost:5001/api/users"
echo "  - Test search: curl 'http://localhost:5001/api/recipes/search?q=pasta'"
echo ""
echo "🌐 Open your browser and go to: http://localhost:5001"
