# 🚀 Foody Local Deployment Guide

This guide covers deploying the Foody recipe sharing platform on a local Debian/Ubuntu server without Docker.

## 📋 System Requirements

- **OS**: Debian 11+ or Ubuntu 20.04+
- **RAM**: Minimum 1GB (2GB recommended)
- **CPU**: 2 cores minimum
- **Disk**: 5GB free space
- **Network**: Internet connection for package installation

## 🔧 Prerequisites

### 1. Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Required Packages
```bash
sudo apt install -y python3 python3-pip python3-venv nginx mariadb-server
```

### 3. Install Python Dependencies
```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install requirements
pip install -r requirements.txt
```

## 🗄️ Database Setup

### 1. Secure MariaDB Installation
```bash
sudo mysql_secure_installation
```

### 2. Create Database and User
```bash
sudo mysql -u root -p
```

```sql
CREATE DATABASE foody CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'foody'@'localhost' IDENTIFIED BY 'your_secure_password_here';
GRANT ALL PRIVILEGES ON foody.* TO 'foody'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Test Database Connection
```bash
mysql -u foody -p foody
# Enter password when prompted
# Type 'exit' to quit
```

## ⚙️ Application Configuration

### 1. Create Environment File
```bash
cp production.env.example .env
nano .env
```

Update the following values in `.env`:
```env
# Database Configuration
DATABASE_URL=mysql://foody:your_secure_password_here@localhost:3306/foody

# Application Configuration
SECRET_KEY=your_very_long_and_secure_secret_key_here
FLASK_ENV=production
SERVER_NAME=lab10.ifalabs.org

# Email Configuration
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=true
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_app_password
ADMINS=admin@lab10.ifalabs.org

# Logging
LOG_TO_STDOUT=true
```

### 2. Initialize Database
```bash
# Activate virtual environment
source venv/bin/activate

# Initialize database
flask db upgrade

# Create admin user (optional)
flask shell
```

```python
from app.models import User
from app import db
user = User(username='admin', email='admin@lab10.ifalabs.org')
user.set_password('admin123')
db.session.add(user)
db.session.commit()
exit()
```

## 🔧 System Service Setup

### 1. Create Application User
```bash
sudo useradd -r -s /bin/false foody
sudo mkdir -p /opt/foody
sudo chown -R foody:foody /opt/foody
```

### 2. Copy Application Files
```bash
# Copy your application to /opt/foody
sudo cp -r /path/to/your/foody/* /opt/foody/
sudo chown -R foody:foody /opt/foody
```

### 3. Install Systemd Service
```bash
sudo cp foody.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable foody
```

### 4. Start Application
```bash
sudo systemctl start foody
sudo systemctl status foody
```

## 🌐 Nginx Configuration

### 1. Install Nginx Configuration
```bash
sudo cp nginx.conf /etc/nginx/sites-available/foody
sudo ln -s /etc/nginx/sites-available/foody /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
```

### 2. Test and Reload Nginx
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 3. Enable Nginx
```bash
sudo systemctl enable nginx
sudo systemctl start nginx
```

## 🔍 Verification

### 1. Check Services
```bash
# Check application status
sudo systemctl status foody

# Check Nginx status
sudo systemctl status nginx

# Check MariaDB status
sudo systemctl status mariadb
```

### 2. Test Application
```bash
# Test health endpoint
curl http://localhost/health

# Test main page
curl http://localhost/
```

### 3. Check Logs
```bash
# Application logs
sudo journalctl -u foody -f

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## 🛠️ Maintenance Commands

### Application Management
```bash
# Restart application
sudo systemctl restart foody

# Check application status
sudo systemctl status foody

# View application logs
sudo journalctl -u foody -f
```

### Database Management
```bash
# Backup database
mysqldump -u foody -p foody > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database
mysql -u foody -p foody < backup_file.sql
```

### Updates
```bash
# Update application code
sudo systemctl stop foody
sudo cp -r /path/to/updated/foody/* /opt/foody/
sudo chown -R foody:foody /opt/foody
sudo systemctl start foody
```

## 🔒 Security Considerations

### 1. Firewall Configuration
```bash
# Install UFW
sudo apt install ufw

# Configure firewall
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### 2. SSL Certificate (Optional)
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d lab10.ifalabs.org
```

### 3. Database Security
```bash
# Remove test database
sudo mysql -u root -p
DROP DATABASE test;
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
FLUSH PRIVILEGES;
EXIT;
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Application Won't Start
```bash
# Check logs
sudo journalctl -u foody -f

# Check permissions
sudo chown -R foody:foody /opt/foody

# Check virtual environment
ls -la /opt/foody/venv/bin/activate
```

#### 2. Database Connection Issues
```bash
# Test database connection
mysql -u foody -p foody

# Check MariaDB status
sudo systemctl status mariadb

# Check database configuration
cat /opt/foody/.env | grep DATABASE_URL
```

#### 3. Nginx Issues
```bash
# Test Nginx configuration
sudo nginx -t

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log

# Restart Nginx
sudo systemctl restart nginx
```

### Performance Optimization

#### 1. Database Optimization
```sql
-- Add indexes for better performance
USE foody;
CREATE INDEX idx_recipe_timestamp ON recipe(timestamp);
CREATE INDEX idx_recipe_user_id ON recipe(user_id);
CREATE INDEX idx_rating_recipe_id ON rating(recipe_id);
```

#### 2. Application Optimization
```bash
# Increase Gunicorn workers (edit /etc/systemd/system/foody.service)
# Change --workers 2 to --workers 4 for more CPU cores
sudo systemctl daemon-reload
sudo systemctl restart foody
```

## 📊 Monitoring

### 1. System Resources
```bash
# Check memory usage
free -h

# Check disk usage
df -h

# Check CPU usage
top
```

### 2. Application Monitoring
```bash
# Check application health
curl http://localhost/health

# Monitor logs
sudo journalctl -u foody -f
```

## 🔄 Backup Strategy

### 1. Database Backup
```bash
#!/bin/bash
# Create backup script
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -u foody -p foody > $BACKUP_DIR/foody_$DATE.sql
```

### 2. Application Backup
```bash
#!/bin/bash
# Backup application files
tar -czf /opt/backups/foody_app_$(date +%Y%m%d_%H%M%S).tar.gz /opt/foody
```

## 📞 Support

If you encounter issues:

1. Check the logs: `sudo journalctl -u foody -f`
2. Verify all services are running: `sudo systemctl status foody nginx mariadb`
3. Test database connection: `mysql -u foody -p foody`
4. Check application health: `curl http://localhost/health`

For additional help, check the main README.md file or create an issue in the repository.
