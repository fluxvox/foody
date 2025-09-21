# 🍳 Foody - Recipe Sharing Platform

A comprehensive recipe sharing platform built with Flask, featuring a 1-5 star rating system, MariaDB database, and REST API. Optimized for local deployment on small servers with Nginx, Gunicorn, and Systemd. Transform your cooking experience by sharing recipes, discovering new dishes, and rating your favorites!

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
- **SSL/TLS Security**: Let's Encrypt certificates with auto-renewal
- **Systemd Integration**: Automatic startup and service management
- **Email System**: Postfix integration for notifications and password resets

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

### Local Testing

1. **Test API endpoints:**
   ```bash
   ./test-api.sh
   ```

2. **Access the application:**
   - Web Interface: http://localhost:5002
   - Health Check: http://localhost:5002/health
   - API Base: http://localhost:5002/api

## 🚀 Production Deployment

For production deployment on a small server (2GB RAM, 2 CPU cores), follow the comprehensive deployment guide below.

**Quick deployment steps:**

1. **Install dependencies:**
   ```bash
   sudo apt update && sudo apt install -y python3 python3-pip python3-venv nginx mariadb-server postfix
   ```

2. **Configure database:**
   ```bash
   sudo mysql_secure_installation
   # Create database and user
   sudo mysql -e "CREATE DATABASE foody;"
   sudo mysql -e "CREATE USER 'foody'@'localhost' IDENTIFIED BY 'your_password';"
   sudo mysql -e "GRANT ALL PRIVILEGES ON foody.* TO 'foody'@'localhost';"
   sudo mysql -e "FLUSH PRIVILEGES;"
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
   sudo systemctl enable foody nginx mariadb postfix
   sudo systemctl start foody nginx mariadb postfix
   ```

5. **Setup SSL (optional):**
   ```bash
   ./setup-letsencrypt.sh
   ```

6. **Access your application:**
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
├── foody.py          # Application entry point
├── foody.service      # Systemd service file
├── nginx.conf         # Nginx configuration
├── gunicorn.conf.py   # Gunicorn configuration
├── requirements.txt   # Python dependencies
└── test-api.sh        # API testing script
```

### Key Technologies

- **Backend**: Flask, SQLAlchemy, Flask-Migrate
- **Database**: MariaDB (production), SQLite (development)
- **Search**: Database-based LIKE queries
- **Frontend**: Bootstrap 5, JavaScript
- **Web Server**: Gunicorn, Nginx
- **Authentication**: Flask-Login, JWT tokens
- **Email**: Postfix MTA
- **Process Management**: Systemd

### Environment Configuration

Copy `production.env.example` to `.env` and configure:

```bash
# Database Configuration
DATABASE_URL=mysql+pymysql://foody:your_password@localhost/foody

# Application Configuration
SECRET_KEY=your_very_long_secret_key
FLASK_ENV=production
SERVER_NAME=your-domain.com

# Email Configuration
MAIL_SERVER=localhost
MAIL_PORT=25
MAIL_USE_TLS=false
ADMINS=admin@your-domain.com
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

#### Service Issues
```bash
# Check service status
sudo systemctl status foody nginx mariadb

# Check service logs
sudo journalctl -u foody -f
sudo journalctl -u nginx -f

# Restart services
sudo systemctl restart foody nginx
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
mysql -u foody -p foody

# Run migrations
flask db upgrade
```

## 🚀 Production Deployment

### Server Requirements

- Debian/Ubuntu 20.04+ server
- 2GB+ RAM
- 10GB+ disk space
- Python 3.8+, Nginx, MariaDB, Postfix

### Deployment Steps

1. **Server Setup:**
   ```bash
   # Install dependencies
   sudo apt update && sudo apt install -y python3 python3-pip python3-venv nginx mariadb-server postfix
   ```

2. **Application Deployment:**
   ```bash
   git clone <your-repo-url>
   cd foody
   cp production.env.example .env
   # Edit .env with your production values
   # Follow the manual setup steps above
   ```

3. **SSL Configuration:**
   ```bash
   # Generate Let's Encrypt certificate
   ./setup-letsencrypt.sh
   
   # Or manually:
   sudo certbot certonly --standalone -d yourdomain.com
   ```

### Production Features

- **SSL/TLS Termination**: Automatic HTTPS with certificate management
- **Rate Limiting**: DDoS protection and abuse prevention
- **Security Headers**: Comprehensive web security
- **Health Monitoring**: Systemd service monitoring and health checks
- **Logging**: Structured logging with systemd journal
- **Email System**: Postfix integration for notifications
- **Backup Support**: Database backup and restore capabilities

## 📈 Performance & Scaling

### Optimization Features

- **Database Connection Pooling**: Efficient database connections
- **Database Search**: Fast full-text search with LIKE queries
- **Gzip Compression**: Reduced bandwidth usage
- **Static File Optimization**: Efficient asset delivery
- **Systemd Service Management**: Reliable process management

### Monitoring

```bash
# Check service health
curl https://yourdomain.com/health

# Monitor resource usage
systemctl status foody nginx mariadb

# View application logs
sudo journalctl -u foody -f
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

1. Check the logs: `sudo journalctl -u foody -f`
2. Verify configuration: `sudo systemctl status foody`
3. Check service health: `systemctl status foody nginx mariadb`
4. Review this documentation

## 🎉 Acknowledgments

- **Forked from**: [Flask Mega-Tutorial by Miguel Grinberg](http://blog.miguelgrinberg.com/post/the-flask-mega-tutorial-part-i-hello-world)
- **Educational Purpose**: This project was developed for a diploma program and is intended for educational purposes only
- Uses Bootstrap 5 for responsive design
- Local deployment optimized for small servers
- Community-driven recipe rating system

---

**🍳 Happy Cooking with Foody! Share your favorite recipes and discover new culinary adventures!**