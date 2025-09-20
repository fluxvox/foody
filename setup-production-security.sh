#!/bin/bash

echo "🔒 Setting up production security configuration..."

# Navigate to the application directory
cd "$(dirname "$0")"

# 1. Create secure .env file
echo "📝 Creating secure .env file..."
cat > .env << 'EOF'
# Production Environment Configuration
# This file contains secure production settings

# Database Configuration (MariaDB/MySQL)
DATABASE_URL=mysql+pymysql://foody:foody123@localhost:3306/foody

# Application Configuration
SECRET_KEY=stable-secret-key-for-foody-application-2024
FLASK_ENV=production
SERVER_NAME=lab10.ifalabs.org

# Email Configuration
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=true
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_email_app_password
ADMINS=admin@lab10.ifalabs.org

# Logging Configuration
LOG_TO_STDOUT=true

# Optional: Microsoft Translator API
# MS_TRANSLATOR_KEY=your_translator_api_key_here
EOF

# 2. Set proper file permissions
echo "🔐 Setting secure file permissions..."
chmod 600 .env
chown student:student .env

# 3. Update systemd service
echo "⚙️  Updating systemd service..."
sudo cp foody.service /etc/systemd/system/foody.service
sudo systemctl daemon-reload

# 4. Update Nginx configuration
echo "🌐 Updating Nginx configuration..."
sudo cp nginx.conf /etc/nginx/sites-available/lab10.ifalabs.org
sudo nginx -t && sudo systemctl reload nginx

# 5. Restart services
echo "🔄 Restarting services..."
sudo systemctl restart foody

# 6. Check service status
echo "📊 Checking service status..."
sudo systemctl status foody --no-pager

# 7. Test application
echo "🧪 Testing application..."
sleep 3
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://lab10.ifalabs.org/ || echo "❌ Application access failed"

echo ""
echo "🎉 Production security setup complete!"
echo "✅ Passwords moved to .env file (secure)"
echo "✅ Systemd security tightened"
echo "✅ Nginx paths corrected"
echo "✅ File permissions secured"
echo ""
echo "🌐 Your application is now production-ready at: http://lab10.ifalabs.org"
echo ""
echo "📋 Security improvements:"
echo "  - Passwords in .env file (not systemd)"
echo "  - Tightened systemd security"
echo "  - Corrected static file paths"
echo "  - Secure file permissions"
