#!/bin/bash

# Database initialization script for Foody
echo "🍳 Initializing Foody database..."

# Set environment variables
export FLASK_APP=foody.py
export FLASK_ENV=development

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cp production.env.example .env
    echo "⚠️  Please edit .env file with your database configuration:"
    echo "   nano .env"
    echo "   Update DATABASE_URL with your MariaDB credentials"
    read -p "Press Enter when you have configured .env file..."
fi

# Load environment variables
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo "🗃️  Running database migrations..."
flask db upgrade

if [ $? -eq 0 ]; then
    echo "✅ Database migration successful!"
    
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
    
    if [ $? -eq 0 ]; then
        echo "✅ Admin user created successfully!"
        echo "🎉 Database initialization complete!"
        echo "🧪 Testing application..."
        python test-app.py
    else
        echo "❌ Failed to create admin user"
    fi
else
    echo "❌ Database migration failed"
    echo "💡 Check your database connection and try again"
fi
