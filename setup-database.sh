#!/bin/bash

# Database setup script for Foody
echo "🍳 Setting up Foody database..."

# Check if MariaDB is running
if ! systemctl is-active --quiet mariadb; then
    echo "🚀 Starting MariaDB service..."
    sudo systemctl start mariadb
    sudo systemctl enable mariadb
fi

# Create database and user
echo "📊 Creating database and user..."
echo "Please enter your MariaDB root password:"
read -s -p "MariaDB root password: " MYSQL_ROOT_PASSWORD
echo

# Create database and user
mysql -u root -p$MYSQL_ROOT_PASSWORD << EOF
CREATE DATABASE IF NOT EXISTS foody CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'foody'@'localhost' IDENTIFIED BY 'foody123';
GRANT ALL PRIVILEGES ON foody.* TO 'foody'@'localhost';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo "✅ Database and user created successfully!"
    
    # Update .env file
    echo "🔧 Updating .env file..."
    if [ -f ".env" ]; then
        sed -i 's|DATABASE_URL=.*|DATABASE_URL=mysql+pymysql://foody:foody123@localhost:3306/foody|' .env
    else
        echo "DATABASE_URL=mysql+pymysql://foody:foody123@localhost:3306/foody" > .env
        echo "SECRET_KEY=your-secret-key-here" >> .env
        echo "FLASK_ENV=development" >> .env
    fi
    
    echo "✅ .env file updated!"
    echo "🧪 Testing database connection..."
    
    # Test database connection
    mysql -u foody -pfoody123 foody -e "SELECT 1;" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Database connection successful!"
        echo "🗃️  Running database migrations..."
        export FLASK_APP=foody.py
        flask db upgrade
        echo "✅ Database setup complete!"
    else
        echo "❌ Database connection failed. Please check your MariaDB configuration."
    fi
else
    echo "❌ Failed to create database. Please check your MariaDB root password."
fi
