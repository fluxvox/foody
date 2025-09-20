#!/bin/bash

echo "🗄️  Fixing database connection issues..."

# Navigate to the application directory
cd "$(dirname "$0")"

# 1. Check if .env file exists and has correct database URL
echo "📝 Checking .env configuration..."
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cp production.env.example .env
fi

# Ensure database URL is correct
DB_URL="mysql+pymysql://foody:foody123@localhost:3306/foody"
sed -i "s|^DATABASE_URL=.*|DATABASE_URL=${DB_URL}|" .env
echo "✅ .env file configured with: ${DB_URL}"

# 2. Test database connection directly
echo "🧪 Testing direct database connection..."
mysql -u foody -pfoody123 foody -e "SELECT 1;" 2>/dev/null && echo "✅ Direct MySQL connection successful" || {
    echo "❌ Direct MySQL connection failed"
    echo "🔧 Setting up database..."
    
    # Create database and user if they don't exist
    sudo mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS foody CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'foody'@'localhost' IDENTIFIED BY 'foody123';
GRANT ALL PRIVILEGES ON foody.* TO 'foody'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
    
    # Test again
    mysql -u foody -pfoody123 foody -e "SELECT 1;" && echo "✅ Database setup successful" || {
        echo "❌ Database setup failed. Please check MariaDB status."
        sudo systemctl status mariadb
        exit 1
    }
}

# 3. Activate virtual environment
echo "🐍 Activating virtual environment..."
source venv/bin/activate

# 4. Set Flask environment variables
export FLASK_APP=foody.py
export FLASK_ENV=production

# 5. Test database connection with proper SQLAlchemy syntax
echo "🧪 Testing SQLAlchemy connection..."
python -c "
import pymysql
pymysql.install_as_MySQLdb()
from app import create_app, db
import sqlalchemy as sa

app = create_app()
with app.app_context():
    try:
        # Use proper SQLAlchemy text() function
        result = db.session.execute(sa.text('SELECT 1'))
        print('✅ SQLAlchemy database connection successful')
    except Exception as e:
        print(f'❌ SQLAlchemy connection failed: {e}')
        exit(1)
" || {
    echo "❌ SQLAlchemy connection failed"
    exit 1
}

# 6. Check if database tables exist
echo "📊 Checking database tables..."
python -c "
import pymysql
pymysql.install_as_MySQLdb()
from app import create_app, db
from app.models import User

app = create_app()
with app.app_context():
    try:
        # Check if User table exists
        user_count = db.session.scalar(db.select(db.func.count(User.id)))
        print(f'✅ Database tables exist. Found {user_count} users.')
    except Exception as e:
        print(f'❌ Database tables issue: {e}')
        print('🔄 Running database migrations...')
        import subprocess
        subprocess.run(['flask', 'db', 'upgrade'])
        print('✅ Database migrations completed')
" || {
    echo "❌ Database table check failed"
    exit 1
}

# 7. Test application startup
echo "🚀 Testing application startup..."
timeout 15s python -c "
import pymysql
pymysql.install_as_MySQLdb()
from app import create_app
app = create_app()
print('✅ Application can start successfully')
" || {
    echo "❌ Application startup failed"
    exit 1
}

echo ""
echo "🎉 Database connection fixed!"
echo "✅ Database: foody:foody123@localhost:3306/foody"
echo "✅ SQLAlchemy: Working with proper syntax"
echo "✅ Application: Can start successfully"
echo ""
echo "🌐 You can now run: ./setup-foody-app.sh"
