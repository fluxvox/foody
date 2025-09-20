#!/bin/bash

# Production setup script for lab10.ifalabs.org
echo "🌐 Setting up Foody for production domain: lab10.ifalabs.org"

# 1. Configure environment for production
echo "⚙️  Configuring production environment..."
cat > .env << EOF
# Production Environment Configuration
DATABASE_URL=mysql+pymysql://foody:foody123@localhost:3306/foody
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
FLASK_ENV=production
SERVER_NAME=lab10.ifalabs.org
LOG_TO_STDOUT=true

# Email Configuration (update with your settings)
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=true
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_app_password
ADMINS=admin@lab10.ifalabs.org
EOF

echo "✅ Environment configured for lab10.ifalabs.org"

# 2. Update Nginx configuration
echo "🌐 Updating Nginx configuration..."
sudo cp nginx.conf /etc/nginx/sites-available/foody
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    sudo systemctl reload nginx
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

# 3. Test database connection
echo "🗄️  Testing database connection..."
mysql -u foody -pfoody123 -e "SELECT 1;" foody > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Database connection successful"
else
    echo "❌ Database connection failed. Fixing..."
    
    # Recreate database user
    echo "Please enter MariaDB root password:"
    read -s -p "MariaDB root password: " MYSQL_ROOT_PASSWORD
    echo
    
    mysql -u root -p$MYSQL_ROOT_PASSWORD << EOF
DROP USER IF EXISTS 'foody'@'localhost';
CREATE USER 'foody'@'localhost' IDENTIFIED BY 'foody123';
GRANT ALL PRIVILEGES ON foody.* TO 'foody'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Test again
    mysql -u foody -pfoody123 -e "SELECT 1;" foody > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Database connection fixed"
    else
        echo "❌ Database connection still failing"
        exit 1
    fi
fi

# 4. Restart Foody service
echo "🔄 Restarting Foody service..."
sudo systemctl restart foody
sleep 5

# 5. Test endpoints
echo "🧪 Testing endpoints..."
echo "Testing localhost (for local testing):"
curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "Failed"

echo -e "\nTesting lab10.ifalabs.org (production domain):"
curl -s -o /dev/null -w "%{http_code}" http://lab10.ifalabs.org/ || echo "Failed"

# 6. Check if application is accessible
echo -e "\n🌐 Testing application access..."
if curl -s http://localhost/ | grep -q "Foody\|Recipe"; then
    echo "✅ Application is accessible via localhost"
else
    echo "❌ Application not accessible via localhost"
fi

if curl -s http://lab10.ifalabs.org/ | grep -q "Foody\|Recipe"; then
    echo "✅ Application is accessible via lab10.ifalabs.org"
else
    echo "❌ Application not accessible via lab10.ifalabs.org"
fi

# 7. Show final status
echo -e "\n🎯 Production Setup Complete!"
echo "================================"
echo "🌐 Public URL: http://lab10.ifalabs.org"
echo "🔧 Local URL: http://localhost"
echo "📊 Admin login: username=admin, password=admin123"
echo ""
echo "🔧 Service management:"
echo "  sudo systemctl status foody"
echo "  sudo systemctl restart foody"
echo "  sudo journalctl -u foody -f"
echo ""
echo "📋 Check logs:"
echo "  sudo journalctl -u foody -f"
echo "  sudo tail -f /var/log/nginx/access.log"
echo "  sudo tail -f /var/log/nginx/error.log"
