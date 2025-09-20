#!/bin/bash

# Fix production deployment issues
echo "🔧 Fixing production deployment issues..."

# 1. Fix server name configuration
echo "🌐 Fixing server name configuration..."
if [ -f ".env" ]; then
    # Update SERVER_NAME to localhost for testing
    sed -i 's|SERVER_NAME=.*|SERVER_NAME=localhost|' .env
    echo "✅ Updated SERVER_NAME to localhost"
else
    echo "DATABASE_URL=mysql+pymysql://foody:foody123@localhost:3306/foody" > .env
    echo "SECRET_KEY=your-secret-key-here" >> .env
    echo "FLASK_ENV=production" >> .env
    echo "SERVER_NAME=localhost" >> .env
    echo "✅ Created .env file with localhost configuration"
fi

# 2. Add health endpoint
echo "🏥 Adding health endpoint..."
cat > health_check.py << 'EOF'
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "foody"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
EOF

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
    fi
fi

# 4. Restart services
echo "🔄 Restarting services..."
sudo systemctl restart foody
sleep 3

# 5. Test endpoints
echo "🧪 Testing endpoints..."
echo "Testing localhost:5000 (direct app):"
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ || echo "Failed"

echo -e "\nTesting localhost:80 (Nginx proxy):"
curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "Failed"

echo -e "\nTesting health endpoint:"
curl -s http://localhost:5000/health || echo "Health endpoint failed"

# 6. Check if application is accessible
echo -e "\n🌐 Testing application access..."
if curl -s http://localhost:5000/ | grep -q "Foody\|Recipe"; then
    echo "✅ Application is accessible and showing content"
else
    echo "❌ Application is not showing expected content"
    echo "🔍 Checking application logs..."
    sudo journalctl -u foody --no-pager -n 10
fi

echo -e "\n🎯 Production fix complete!"
echo "🌐 Try accessing: http://localhost/"
echo "🔧 Check logs: sudo journalctl -u foody -f"
