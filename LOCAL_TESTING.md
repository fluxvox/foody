# Local Docker Testing Guide

This guide will help you test the Foody application locally using Docker without needing a full production setup.

## Quick Start

### 1. Prerequisites

- Docker Desktop or Docker Engine installed
- Basic command line knowledge
- 4GB+ RAM available for containers

### 2. One-Command Testing

```bash
./test-local.sh
```

This script will:
- Check Docker is running
- Stop any existing containers
- Build and start all services
- Wait for health checks
- Validate the application

### 3. Access the Application

- **Web Application**: http://localhost:5000
- **Health Check**: http://localhost:5000/health
- **API Base**: http://localhost:5000/api

## Manual Testing Steps

### 1. Start Services

```bash
# Start all services
docker-compose -f docker-compose.local.yml up --build -d

# Check status
docker-compose -f docker-compose.local.yml ps
```

### 2. Wait for Health Checks

```bash
# Monitor logs
docker-compose -f docker-compose.local.yml logs -f

# Check health
curl http://localhost:5000/health
```

### 3. Test the Application

```bash
# Test API endpoints
./test-api.sh

# Or test manually
curl http://localhost:5000/api/users
curl http://localhost:5000/api/recipes
curl "http://localhost:5000/api/recipes/search?q=pasta"
```

## Service Details

### Local Services

| Service | Port | Description |
|---------|------|-------------|
| Web App | 5000 | Main Flask application |
| PostgreSQL | 5432 | Database (user: foody, password: foody123) |
| Redis | 6379 | Cache and task queue |
| Elasticsearch | 9200 | Search engine |

### Environment Configuration

The local setup uses simplified configuration:

```yaml
Environment:
- FLASK_ENV: development
- SECRET_KEY: dev-secret-key-not-for-production
- Database: PostgreSQL with simple credentials
- Redis: No password required
- Email: Console output (no real email sending)
```

## Testing Scenarios

### 1. Basic Functionality

```bash
# 1. Register a new user
curl -X POST http://localhost:5000/register \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&email=test@example.com&password=testpass123&password2=testpass123"

# 2. Login
curl -X POST http://localhost:5000/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=testpass123"

# 3. Create a recipe (requires authentication)
curl -X POST http://localhost:5000/api/recipes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "title": "Test Recipe",
    "description": "A test recipe",
    "ingredients": "1 cup flour, 2 eggs",
    "instructions": "Mix ingredients and cook",
    "prep_time": 15,
    "cook_time": 30,
    "servings": 4,
    "difficulty": "Easy",
    "category": "Main Course"
  }'
```

### 2. API Testing

```bash
# Test all API endpoints
./test-api.sh

# Test specific endpoints
curl http://localhost:5000/api/recipes/categories
curl http://localhost:5000/api/recipes/difficulties
curl "http://localhost:5000/api/recipes/search?q=chicken"
```

### 3. Database Testing

```bash
# Access PostgreSQL
docker-compose -f docker-compose.local.yml exec db psql -U foody -d foody

# Run SQL queries
\dt  # List tables
SELECT * FROM users LIMIT 5;
SELECT * FROM recipes LIMIT 5;
\q   # Quit
```

### 4. Redis Testing

```bash
# Access Redis
docker-compose -f docker-compose.local.yml exec redis redis-cli

# Test Redis
ping
keys *
info
quit
```

### 5. Elasticsearch Testing

```bash
# Test Elasticsearch
curl http://localhost:9200/_cluster/health
curl http://localhost:9200/_cat/indices
curl "http://localhost:9200/recipes/_search?q=*"
```

## Troubleshooting

### Common Issues

#### 1. Services Not Starting

```bash
# Check Docker status
docker info

# Check container logs
docker-compose -f docker-compose.local.yml logs

# Restart services
docker-compose -f docker-compose.local.yml restart
```

#### 2. Database Connection Issues

```bash
# Check database logs
docker-compose -f docker-compose.local.yml logs db

# Test database connection
docker-compose -f docker-compose.local.yml exec db pg_isready -U foody -d foody
```

#### 3. Application Not Responding

```bash
# Check application logs
docker-compose -f docker-compose.local.yml logs web

# Check health endpoint
curl -v http://localhost:5000/health

# Restart application
docker-compose -f docker-compose.local.yml restart web
```

#### 4. Port Conflicts

If you have port conflicts, modify the ports in `docker-compose.local.yml`:

```yaml
ports:
  - "5001:5000"  # Change 5000 to 5001
  - "5433:5432"  # Change 5432 to 5433
```

### Performance Issues

#### 1. Slow Startup

```bash
# Reduce Elasticsearch memory
# In docker-compose.local.yml, change:
ES_JAVA_OPTS=-Xms128m -Xmx128m

# Reduce Gunicorn workers
GUNICORN_WORKERS=1
```

#### 2. High Memory Usage

```bash
# Check resource usage
docker stats

# Stop unused services
docker-compose -f docker-compose.local.yml stop elasticsearch
```

## Development Workflow

### 1. Making Changes

```bash
# 1. Make code changes
# 2. Rebuild and restart
docker-compose -f docker-compose.local.yml up --build -d

# 3. Test changes
curl http://localhost:5000/health
```

### 2. Database Migrations

```bash
# Run migrations
docker-compose -f docker-compose.local.yml exec web flask db upgrade

# Create new migration
docker-compose -f docker-compose.local.yml exec web flask db migrate -m "Description"
```

### 3. Adding Dependencies

```bash
# 1. Update requirements.txt
# 2. Rebuild containers
docker-compose -f docker-compose.local.yml up --build -d
```

## Cleanup

### Stop Services

```bash
# Stop all services
docker-compose -f docker-compose.local.yml down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose -f docker-compose.local.yml down -v
```

### Clean Up Docker

```bash
# Remove unused containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Full cleanup (WARNING: removes everything)
docker system prune -a
```

## Useful Commands

### Container Management

```bash
# View running containers
docker-compose -f docker-compose.local.yml ps

# View logs
docker-compose -f docker-compose.local.yml logs -f web
docker-compose -f docker-compose.local.yml logs -f db

# Execute commands in containers
docker-compose -f docker-compose.local.yml exec web bash
docker-compose -f docker-compose.local.yml exec db psql -U foody -d foody
```

### Monitoring

```bash
# Monitor resource usage
docker stats

# Monitor logs in real-time
docker-compose -f docker-compose.local.yml logs -f

# Check service health
docker-compose -f docker-compose.local.yml ps
```

## Next Steps

Once local testing is successful:

1. **Production Deployment**: Use `./deploy.sh` for production
2. **Custom Configuration**: Modify `production.env.example` for your needs
3. **SSL Certificates**: Set up proper SSL certificates for production
4. **Domain Configuration**: Configure your domain name
5. **Monitoring**: Set up proper monitoring and logging

## Support

For issues:

1. Check the logs: `docker-compose -f docker-compose.local.yml logs`
2. Verify configuration: `docker-compose -f docker-compose.local.yml config`
3. Check service health: `docker-compose -f docker-compose.local.yml ps`
4. Review this documentation
