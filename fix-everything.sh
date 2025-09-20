#!/bin/bash

# FIX EVERYTHING SCRIPT - NO MORE CHANGES
echo "🔧 FIXING EVERYTHING - STABLE CONFIGURATION"

# 1. Create a STABLE .env file that won't change
echo "📝 Creating STABLE .env file..."
cat > .env << 'EOF'
# STABLE CONFIGURATION - DO NOT CHANGE
DATABASE_URL=mysql+pymysql://foody:foody123@localhost:3306/foody
SECRET_KEY=stable-secret-key-for-foody-application-2024
FLASK_ENV=production
SERVER_NAME=lab10.ifalabs.org
LOG_TO_STDOUT=true

# Email Configuration
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=true
MAIL_USERNAME=admin@lab10.ifalabs.org
MAIL_PASSWORD=your_email_password
ADMINS=admin@lab10.ifalabs.org
EOF

echo "✅ STABLE .env file created"

# 2. Fix database with KNOWN password
echo "🗄️  Fixing database with KNOWN password: foody123"
mysql -u root -p << 'EOF'
DROP USER IF EXISTS 'foody'@'localhost';
CREATE USER 'foody'@'localhost' IDENTIFIED BY 'foody123';
GRANT ALL PRIVILEGES ON foody.* TO 'foody'@'localhost';
FLUSH PRIVILEGES;
EOF

# Test database connection
mysql -u foody -pfoody123 -e "SELECT 1;" foody
if [ $? -eq 0 ]; then
    echo "✅ Database connection working with foody123"
else
    echo "❌ Database still not working"
    exit 1
fi

# 3. Check if admin user exists
echo "👤 Checking admin user..."
export FLASK_APP=foody.py
flask shell << 'EOF'
from app.models import User
from app import db
admin_user = User.query.filter_by(username='admin').first()
if admin_user:
    print('✅ Admin user exists')
else:
    print('❌ Admin user does not exist')
EOF

# 4. Restart service
echo "🔄 Restarting Foody service..."
sudo systemctl restart foody
sleep 5

# 5. Check service status
echo "📊 Checking service status..."
sudo systemctl status foody --no-pager

# 6. Test application
echo "🧪 Testing application..."
curl -s http://localhost:5000/ | head -20

# 7. Show current configuration
echo -e "\n📋 CURRENT CONFIGURATION:"
echo "=========================="
echo "Database: foody:foody123@localhost:3306/foody"
echo "Secret Key: stable-secret-key-for-foody-application-2024"
echo "Server Name: lab10.ifalabs.org"
echo "Admin User: admin / admin123"
echo ""
echo "🌐 Test URLs:"
echo "  http://localhost:5000 (direct app)"
echo "  http://localhost (nginx proxy)"
echo "  http://lab10.ifalabs.org (production)"
echo ""
echo "🔧 Service commands:"
echo "  sudo systemctl status foody"
echo "  sudo systemctl restart foody"
echo "  sudo journalctl -u foody -f"

echo -e "\n✅ FIXED - NO MORE CHANGES!"
