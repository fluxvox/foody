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

# Create admin user
echo "👤 Creating admin user..."
export FLASK_APP=foody.py
export FLASK_ENV=production
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
