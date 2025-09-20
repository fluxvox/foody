# 🍳 Foody - Recipe Sharing Platform

A comprehensive recipe sharing platform built with Flask, featuring a 1-5 star rating system, MariaDB database, and REST API. Transform your cooking experience by sharing recipes, discovering new dishes, and rating your favorites!

## 🎯 Overview

Foody is a modern recipe sharing platform that allows users to:
- **Share Recipes**: Create and share detailed recipes with ingredients, instructions, and metadata
- **Rate Recipes**: Use a 1-5 star rating system to help the community discover the best recipes
- **Search & Discover**: Find recipes by ingredients, title, category, or difficulty level
- **Follow Users**: Connect with other food enthusiasts and follow their recipe collections
- **API Access**: Use the REST API for programmatic access to recipes and ratings

## ✨ Key Features

### 🌟 Recipe Rating System
- **Interactive Star Rating**: 1-5 star rating system with visual feedback
- **Rating Aggregation**: Automatic calculation of average ratings and counts
- **User Rating Tracking**: Users can rate recipes and update their ratings
- **Visual Display**: Star ratings visible on recipe cards and detail pages

### 🍽️ Recipe Management
- **Complete Recipe Data**: Title, description, ingredients, instructions, prep/cook times
- **Recipe Metadata**: Servings, difficulty level, category, and image support
- **CRUD Operations**: Create, read, update, and delete recipes
- **Recipe Search**: Enhanced search functionality with database fallback

### 🔓 Public API Access
- **Public Endpoints**: Browse recipes, search, and view ratings without authentication
- **Protected Operations**: Create, edit, and rate recipes require authentication
- **RESTful Design**: Clean API with proper HTTP methods and status codes
- **Pagination Support**: Efficient handling of large recipe collections

### 🚀 Production Ready
- **Local Deployment**: Optimized for small servers (2GB RAM, 2 CPU cores)
- **MariaDB Database**: Lightweight and efficient database solution
- **Nginx + Gunicorn**: High-performance web server setup
- **Systemd Integration**: Automatic startup and service management

## 🚀 Quick Start

### Local Development

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd foody
   ```

2. **Set up virtual environment:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Initialize database:**
   ```bash
   flask db upgrade
   ```

4. **Run the application:**
   ```bash
   python foody.py
   ```

5. **Access the application:**
   - Web Interface: http://localhost:5002
   - API Base: http://localhost:5002/api

### Docker Local Testing

1. **One-command testing:**
   ```bash
   ./test-local.sh
   ```

2. **Access the application:**
   - Web Interface: http://localhost:5001
   - Health Check: http://localhost:5001/health
   - API Base: http://localhost:5001/api

## 🐳 Docker Deployment

### Local Testing with Docker

```bash
# Start all services
docker compose -f docker-compose.local.yml up --build -d

# Check status
docker compose -f docker-compose.local.yml ps

# View logs
docker compose -f docker-compose.local.yml logs -f

# Stop services
docker compose -f docker-compose.local.yml down
```

### Production Deployment

For production deployment on a small server (2GB RAM, 2 CPU cores), see the comprehensive [DEPLOYMENT.md](DEPLOYMENT.md) guide.

**Quick deployment steps:**

1. **Install dependencies:**
   ```bash
   sudo apt update && sudo apt install -y python3 python3-pip python3-venv nginx mariadb-server
   ```

2. **Configure database:**
   ```bash
   sudo mysql_secure_installation
   # Create database and user (see DEPLOYMENT.md for details)
   ```

3. **Setup application:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   cp production.env.example .env
   # Edit .env with your configuration
   flask db upgrade
   ```

4. **Configure services:**
   ```bash
   sudo cp foody.service /etc/systemd/system/
   sudo cp nginx.conf /etc/nginx/sites-available/foody
   sudo systemctl enable foody nginx mariadb
   sudo systemctl start foody nginx mariadb
   ```

5. **Access your application:**
   - Web Interface: http://your-domain.com
   - API Base: http://your-domain.com/api

## 📊 Database Schema

### Rating Table
```sql
CREATE TABLE rating (
    id INTEGER PRIMARY KEY,
    rating INTEGER NOT NULL,  -- 1-5 stars
    timestamp DATETIME,
    user_id INTEGER,
    recipe_id INTEGER,
    UNIQUE(user_id, recipe_id)  -- One rating per user per recipe
);
```

### Recipe Model
- Rating relationships and helper methods
- Average rating calculation
- Rating count tracking
- User rating retrieval

## 🔌 API Documentation

### Public Endpoints (No Authentication Required)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/recipes` | GET | Browse all recipes with pagination and filtering |
| `/api/recipes/{id}` | GET | View specific recipe details |
| `/api/recipes/search` | GET | Search recipes by title, description, ingredients, etc. |
| `/api/recipes/categories` | GET | Get available recipe categories |
| `/api/recipes/difficulties` | GET | Get available difficulty levels |
| `/api/recipes/{id}/ratings` | GET | View recipe ratings |

### Protected Endpoints (Authentication Required)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/recipes` | POST | Create new recipe |
| `/api/recipes/{id}` | PUT | Update recipe (only author) |
| `/api/recipes/{id}` | DELETE | Delete recipe (only author) |
| `/api/recipes/{id}/ratings` | POST | Rate recipe |
| `/api/recipes/{id}/ratings` | DELETE | Remove rating |

### API Usage Examples

```bash
# Browse recipes
curl http://localhost:5001/api/recipes

# Search recipes
curl "http://localhost:5001/api/recipes/search?q=pasta"

# Get recipe categories
curl http://localhost:5001/api/recipes/categories

# Get specific recipe
curl http://localhost:5001/api/recipes/1
```

## 🛠️ Development

### Project Structure

```
foody/
├── app/
│   ├── api/           # REST API endpoints
│   ├── auth/          # Authentication routes
│   ├── main/          # Main application routes
│   ├── models.py      # Database models
│   ├── static/        # Static assets (CSS, JS, images)
│   └── templates/     # Jinja2 templates
├── migrations/        # Database migrations
├── deployment/        # Production deployment configs
├── docker-compose.yml # Production Docker setup
├── docker-compose.local.yml # Local testing setup
├── Dockerfile         # Production Docker image
├── Dockerfile.local   # Local testing Docker image
├── foody.py          # Application entry point
└── requirements.txt  # Python dependencies
```

### Key Technologies

- **Backend**: Flask, SQLAlchemy, Flask-Migrate
- **Database**: PostgreSQL (production), SQLite (development)
- **Cache**: Redis
- **Search**: Elasticsearch
- **Frontend**: Bootstrap 5, JavaScript
- **Containerization**: Docker, Docker Compose
- **Web Server**: Gunicorn, Nginx
- **Authentication**: Flask-Login, JWT tokens

### Environment Configuration

Copy `production.env.example` to `.env` and configure:

```bash
# Database Configuration
POSTGRES_DB=foody
POSTGRES_USER=foody
POSTGRES_PASSWORD=your_secure_password

# Application Configuration
SECRET_KEY=your_very_long_secret_key
FLASK_ENV=production

# Email Configuration
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=true
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_email_password
```

## 🧪 Testing

### Local Testing

```bash
# Test API endpoints
./test-api.sh

# Test health endpoint
curl http://localhost:5001/health

# Test recipe browsing
curl http://localhost:5001/api/recipes
```

### Manual Testing Checklist

- [ ] User registration and login
- [ ] Recipe creation and editing
- [ ] Star rating system functionality
- [ ] Recipe search functionality
- [ ] API endpoint responses
- [ ] Responsive design on different screen sizes
- [ ] Database operations and migrations

## 🔧 Troubleshooting

### Common Issues

#### Docker Issues
```bash
# Check Docker status
docker info

# Check container logs
docker compose -f docker-compose.local.yml logs

# Restart services
docker compose -f docker-compose.local.yml restart
```

#### Port Conflicts
If port 5000 is busy (macOS Control Center), the local setup uses port 5001:
```bash
# Access local application
http://localhost:5001
```

#### Database Issues
```bash
# Check database connection
docker compose -f docker-compose.local.yml exec db psql -U foody -d foody

# Run migrations
docker compose -f docker-compose.local.yml exec web flask db upgrade
```

## 🚀 Production Deployment

### Server Requirements

- Ubuntu 20.04+ server
- 2GB+ RAM
- 10GB+ disk space
- Docker and Docker Compose

### Deployment Steps

1. **Server Setup:**
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

2. **Application Deployment:**
   ```bash
   git clone <your-repo-url>
   cd foody
   cp production.env.example .env
   # Edit .env with your production values
   ./deploy.sh
   ```

3. **SSL Configuration:**
   ```bash
   # Generate Let's Encrypt certificate
   sudo certbot certonly --standalone -d yourdomain.com
   
   # Copy certificates
   sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem deployment/nginx/ssl/cert.pem
   sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem deployment/nginx/ssl/key.pem
   ```

### Production Features

- **SSL/TLS Termination**: Automatic HTTPS with certificate management
- **Rate Limiting**: DDoS protection and abuse prevention
- **Security Headers**: Comprehensive web security
- **Health Monitoring**: Container health checks and monitoring
- **Logging**: Structured logging with configurable levels
- **Backup Support**: Database backup and restore capabilities

## 📈 Performance & Scaling

### Optimization Features

- **Database Connection Pooling**: Efficient database connections
- **Redis Caching**: Fast data retrieval and session management
- **Elasticsearch Search**: Fast full-text search capabilities
- **Gzip Compression**: Reduced bandwidth usage
- **Static File Optimization**: Efficient asset delivery
- **Horizontal Scaling**: Easy scaling of web services

### Monitoring

```bash
# Check service health
curl https://yourdomain.com/health

# Monitor resource usage
docker stats

# View application logs
docker compose logs -f web
```

## 🔒 Security

### Security Features

- **Authentication**: JWT-based API authentication
- **Authorization**: Role-based access control
- **Input Validation**: Comprehensive form and API validation
- **XSS Protection**: Proper template escaping
- **CSRF Protection**: CSRF tokens on all forms
- **Rate Limiting**: API and login endpoint protection
- **Security Headers**: HSTS, XSS protection, content type sniffing prevention

### Best Practices

- Use strong passwords and secret keys
- Keep dependencies updated
- Monitor logs for suspicious activity
- Regular database backups
- SSL/TLS encryption in production

## 📝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:

1. Check the logs: `docker compose logs`
2. Verify configuration: `docker compose config`
3. Check service health: `docker compose ps`
4. Review this documentation

## 🎉 Acknowledgments

- Built on the Flask Mega-Tutorial by Miguel Grinberg
- Uses Bootstrap 5 for responsive design
- Docker containerization for easy deployment
- Community-driven recipe rating system

---

**🍳 Happy Cooking with Foody! Share your favorite recipes and discover new culinary adventures!**