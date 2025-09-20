#!/bin/bash

# Fix SERVER_NAME configuration
echo "🔧 Fixing SERVER_NAME configuration..."

# 1. Update .env file with correct SERVER_NAME
echo "📝 Updating .env file..."
cat > .env << 'EOF'
# STABLE CONFIGURATION - DO NOT CHANGE
DATABASE_URL=mysql+pymysql://foody:foody123@localhost:3306/foody
SECRET_KEY=stable-secret-key-for-foody-application-2024
FLASK_ENV=production
SERVER_NAME=localhost
LOG_TO_STDOUT=true

# Email Configuration
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=true
MAIL_USERNAME=admin@lab10.ifalabs.org
MAIL_PASSWORD=your_email_password
ADMINS=admin@lab10.ifalabs.org
EOF

echo "✅ .env file updated with SERVER_NAME=localhost"

# 2. Restart the service
echo "🔄 Restarting Foody service..."
sudo systemctl restart foody
sleep 5

# 3. Test the application
echo "🧪 Testing application..."
echo "Testing localhost:5000 (direct app):"
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ || echo "Failed"

echo -e "\nTesting localhost (nginx proxy):"
curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "Failed"

# 4. Test with actual content
echo -e "\n🔍 Testing with actual content..."
echo "Direct app response:"
curl -s http://localhost:5000/ | head -3

echo -e "\nNginx proxy response:"
curl -s http://localhost/ | head -3

# 5. Test login page
echo -e "\n🔐 Testing login page..."
curl -s http://localhost:5000/auth/login | grep -i "login\|title" | head -2

echo -e "\n🎯 SERVER_NAME fix complete!"
echo "🌐 Test your application:"
echo "  http://localhost:5000 (direct app)"
echo "  http://localhost (nginx proxy)"
echo "  http://lab10.ifalabs.org (production - after DNS fix)"
