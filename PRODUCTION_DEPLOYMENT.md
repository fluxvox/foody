# Foody Production Deployment Guide

This guide will help you deploy the Foody recipe sharing application to a production Ubuntu server using Docker.

## Prerequisites

- Ubuntu 20.04+ server
- Docker and Docker Compose installed
- Domain name (optional, for SSL certificates)
- Basic knowledge of Linux command line

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd foody
   ```

2. **Configure environment:**
   ```bash
   cp production.env.example .env
   nano .env  # Edit with your production values
   ```

3. **Deploy:**
   ```bash
   ./deploy.sh
   ```

## Detailed Setup

### 1. Server Preparation

Install Docker and Docker Compose on Ubuntu:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again to apply group changes
```

### 2. Environment Configuration

Copy the example environment file and configure it:

```bash
cp production.env.example .env
```

Edit `.env` with your production values:

```bash
# Database Configuration
POSTGRES_DB=foody
POSTGRES_USER=foody
POSTGRES_PASSWORD=your_very_secure_database_password

# Redis Configuration
REDIS_PASSWORD=your_very_secure_redis_password

# Application Configuration
SECRET_KEY=your_very_long_and_secure_secret_key_at_least_32_characters
FLASK_ENV=production

# Email Configuration
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=true
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_email_app_password
ADMINS=admin@yourdomain.com

# Gunicorn Configuration (adjust based on your server specs)
GUNICORN_WORKERS=4
GUNICORN_WORKER_CONNECTIONS=1000
GUNICORN_MAX_REQUESTS=1000
GUNICORN_TIMEOUT=30
LOG_LEVEL=info
```

### 3. SSL Certificates

#### Option A: Self-signed Certificate (Development/Testing)
The deployment script will automatically generate a self-signed certificate.

#### Option B: Let's Encrypt Certificate (Production)
For production with a domain name:

```bash
# Install Certbot
sudo apt install certbot

# Generate certificate
sudo certbot certonly --standalone -d yourdomain.com

# Copy certificates to the project
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem deployment/nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem deployment/nginx/ssl/key.pem
sudo chown $USER:$USER deployment/nginx/ssl/*.pem
```

### 4. Deployment

Run the deployment script:

```bash
./deploy.sh
```

This script will:
- Validate environment variables
- Generate SSL certificates (if needed)
- Build and start all services
- Wait for services to be healthy
- Perform health checks

### 5. Verification

Check that all services are running:

```bash
docker-compose ps
```

Test the application:

```bash
# Health check
curl https://localhost/health

# API test
curl https://localhost/api/users
```

## Architecture

The application consists of the following services:

- **web**: Main Flask application (Gunicorn)
- **worker**: Background task worker (RQ)
- **db**: PostgreSQL database
- **redis**: Redis for caching and task queue
- **elasticsearch**: Search engine
- **nginx**: Reverse proxy and SSL termination

## Configuration

### Nginx Configuration

The Nginx configuration includes:
- SSL/TLS termination
- Rate limiting
- Security headers
- Static file serving
- Gzip compression
- Health checks

### Gunicorn Configuration

Gunicorn is configured with:
- Multiple workers (configurable)
- Gevent worker class for async support
- Request limits and timeouts
- Graceful restarts

### Database Configuration

PostgreSQL is configured with:
- Persistent data volumes
- Health checks
- Connection pooling
- Backup support

## Monitoring and Maintenance

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f db
```

### Updating the Application

```bash
# Pull latest changes
git pull

# Rebuild and restart
docker-compose up --build -d
```

### Database Backups

```bash
# Create backup
docker-compose exec db pg_dump -U foody foody > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
docker-compose exec -T db psql -U foody foody < backup_file.sql
```

### Scaling

To scale the web application:

```bash
# Scale web service
docker-compose up --scale web=3 -d
```

## Security Considerations

1. **Change default passwords** in the `.env` file
2. **Use strong passwords** for database and Redis
3. **Keep the secret key secure** and rotate it regularly
4. **Use HTTPS** in production (configured by default)
5. **Regular updates** of Docker images and dependencies
6. **Monitor logs** for suspicious activity
7. **Backup data** regularly

## Troubleshooting

### Common Issues

1. **Services not starting:**
   ```bash
   docker-compose logs
   ```

2. **Database connection issues:**
   ```bash
   docker-compose exec db psql -U foody -d foody -c "SELECT 1;"
   ```

3. **SSL certificate issues:**
   ```bash
   # Check certificate
   openssl x509 -in deployment/nginx/ssl/cert.pem -text -noout
   ```

4. **Memory issues:**
   ```bash
   # Check resource usage
   docker stats
   ```

### Performance Tuning

1. **Adjust Gunicorn workers** based on CPU cores
2. **Configure Redis memory** limits
3. **Optimize PostgreSQL** settings
4. **Use CDN** for static files
5. **Enable caching** headers

## Support

For issues and questions:
1. Check the logs: `docker-compose logs`
2. Verify configuration: `docker-compose config`
3. Check service health: `docker-compose ps`
4. Review this documentation

## Production Checklist

- [ ] Environment variables configured
- [ ] SSL certificates installed
- [ ] Database passwords changed
- [ ] Email configuration tested
- [ ] Health checks passing
- [ ] Logs being monitored
- [ ] Backups configured
- [ ] Domain name configured (if applicable)
- [ ] Firewall configured
- [ ] Monitoring setup
