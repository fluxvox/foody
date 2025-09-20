#!/bin/bash

# Foody Local Deployment Script
# This script automates the deployment of Foody on a local Debian/Ubuntu server

set -e  # Exit on any error

echo "🍳 Foody Local Deployment Script"
echo "================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from template..."
    cp production.env.example .env
    echo "⚠️  Please edit .env file with your configuration before continuing."
    echo "   nano .env"
    read -p "Press Enter when you have configured .env file..."
fi

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "🔧 Installing required packages..."
sudo apt install -y python3 python3-pip python3-venv nginx mariadb-server

# Create virtual environment
echo "🐍 Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "📚 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Secure MariaDB installation
echo "🗄️  Configuring MariaDB..."
echo "You will be prompted to secure your MariaDB installation."
echo "Please set a root password and follow the security recommendations."
sudo mysql_secure_installation

# Create database and user
echo "📊 Setting up database..."
echo "Please enter your MariaDB root password to create the database and user:"
read -s -p "MariaDB root password: " MYSQL_ROOT_PASSWORD
echo

# Create database and user
mysql -u root -p$MYSQL_ROOT_PASSWORD << EOF
CREATE DATABASE IF NOT EXISTS foody CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'foody'@'localhost' IDENTIFIED BY 'foody123';
GRANT ALL PRIVILEGES ON foody.* TO 'foody'@'localhost';
FLUSH PRIVILEGES;
EOF

# Update .env with database URL
echo "🔧 Updating database configuration..."
sed -i 's|DATABASE_URL=.*|DATABASE_URL=mysql://foody:foody123@localhost:3306/foody|' .env

# Initialize database
echo "🗃️  Initializing database..."
flask db upgrade

# Create admin user
echo "👤 Creating admin user..."
flask shell << EOF
from app.models import User
from app import db
user = User(username='admin', email='admin@lab10.ifalabs.org')
user.set_password('admin123')
db.session.add(user)
db.session.commit()
print('Admin user created: username=admin, password=admin123')
EOF

# Create application user and directory
echo "👤 Setting up application user..."
sudo useradd -r -s /bin/false foody 2>/dev/null || true
sudo mkdir -p /opt/foody
sudo cp -r . /opt/foody/
sudo chown -R foody:foody /opt/foody

# Install systemd service
echo "⚙️  Installing systemd service..."
sudo cp foody.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable foody

# Configure Nginx
echo "🌐 Configuring Nginx..."
sudo cp nginx.conf /etc/nginx/sites-available/foody
sudo ln -sf /etc/nginx/sites-available/foody /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

# Start services
echo "🚀 Starting services..."
sudo systemctl start foody
sudo systemctl start nginx
sudo systemctl enable nginx mariadb

# Check service status
echo "📊 Checking service status..."
echo "Foody service:"
sudo systemctl status foody --no-pager
echo
echo "Nginx service:"
sudo systemctl status nginx --no-pager
echo
echo "MariaDB service:"
sudo systemctl status mariadb --no-pager

# Test application
echo "🧪 Testing application..."
sleep 5  # Wait for services to start
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ Application is running successfully!"
    echo "🌐 Access your application at: http://localhost"
    echo "👤 Admin login: username=admin, password=admin123"
else
    echo "❌ Application health check failed. Check logs with:"
    echo "   sudo journalctl -u foody -f"
fi

echo
echo "🎉 Deployment completed!"
echo "📖 For detailed information, see DEPLOYMENT.md"
echo "🔧 To manage services:"
echo "   sudo systemctl status foody"
echo "   sudo systemctl restart foody"
echo "   sudo journalctl -u foody -f"
