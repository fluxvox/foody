#!/bin/bash

# Database debugging script for Foody
echo "🔍 Debugging Foody database connection..."

# Check if MariaDB is running
echo "📊 Checking MariaDB status..."
if systemctl is-active --quiet mariadb; then
    echo "✅ MariaDB is running"
else
    echo "❌ MariaDB is not running. Starting it..."
    sudo systemctl start mariadb
    sudo systemctl enable mariadb
fi

# Check MariaDB version
echo "📋 MariaDB version:"
mysql --version

# Test root connection
echo "🔐 Testing root connection..."
echo "Please enter your MariaDB root password:"
read -s -p "MariaDB root password: " MYSQL_ROOT_PASSWORD
echo

mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SELECT 'Root connection successful' as status;" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Root connection successful"
else
    echo "❌ Root connection failed"
    echo "💡 Try: sudo mysql_secure_installation"
    exit 1
fi

# Check if database exists
echo "🗄️  Checking if database exists..."
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES LIKE 'foody';" 2>/dev/null | grep -q foody
if [ $? -eq 0 ]; then
    echo "✅ Database 'foody' exists"
else
    echo "❌ Database 'foody' does not exist"
fi

# Check if user exists
echo "👤 Checking if user 'foody' exists..."
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SELECT User, Host FROM mysql.user WHERE User='foody';" 2>/dev/null | grep -q foody
if [ $? -eq 0 ]; then
    echo "✅ User 'foody' exists"
else
    echo "❌ User 'foody' does not exist"
fi

# Test foody user connection
echo "🧪 Testing 'foody' user connection..."
mysql -u foody -pfoody123 -e "SELECT 'Foody user connection successful' as status;" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Foody user connection successful"
else
    echo "❌ Foody user connection failed"
    echo "💡 Let's recreate the user..."
    
    # Recreate user
    mysql -u root -p$MYSQL_ROOT_PASSWORD << EOF
DROP USER IF EXISTS 'foody'@'localhost';
CREATE USER 'foody'@'localhost' IDENTIFIED BY 'foody123';
GRANT ALL PRIVILEGES ON foody.* TO 'foody'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Test again
    mysql -u foody -pfoody123 -e "SELECT 'Foody user connection successful' as status;" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Foody user recreated and connection successful"
    else
        echo "❌ Still failing. Let's try a different approach..."
        
        # Try with different authentication plugin
        mysql -u root -p$MYSQL_ROOT_PASSWORD << EOF
DROP USER IF EXISTS 'foody'@'localhost';
CREATE USER 'foody'@'localhost' IDENTIFIED WITH mysql_native_password BY 'foody123';
GRANT ALL PRIVILEGES ON foody.* TO 'foody'@'localhost';
FLUSH PRIVILEGES;
EOF
        
        # Test again
        mysql -u foody -pfoody123 -e "SELECT 'Foody user connection successful' as status;" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ Foody user created with native password and connection successful"
        else
            echo "❌ Still failing. Check MariaDB configuration."
        fi
    fi
fi

# Show current .env configuration
echo "📝 Current .env configuration:"
if [ -f ".env" ]; then
    grep DATABASE_URL .env
else
    echo "❌ .env file not found"
fi

echo "🔍 Debugging complete!"
