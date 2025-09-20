#!/bin/bash

# Database reset script for Foody
echo "🔄 Resetting Foody database..."

# Set environment variables
export FLASK_APP=foody.py
export FLASK_ENV=development

# Drop and recreate database
echo "🗑️  Dropping existing database..."
mysql -u foody -pfoody123 -e "DROP DATABASE IF EXISTS foody;"

echo "📊 Creating fresh database..."
mysql -u foody -pfoody123 -e "CREATE DATABASE foody CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Reset migration history
echo "🔄 Resetting migration history..."
rm -rf migrations/versions/*.py
flask db init
flask db migrate -m "Initial migration for local deployment"

# Run the migration
echo "🗃️  Running fresh migration..."
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
        echo "🎉 Database reset complete!"
        echo "🧪 Testing application..."
        python test-app.py
    else
        echo "❌ Failed to create admin user"
    fi
else
    echo "❌ Database migration failed"
    echo "💡 Let's try a different approach..."
    
    # Try creating tables manually
    echo "🔧 Creating tables manually..."
    flask shell << EOF
from app import db
from app.models import User, Recipe, Rating, Message, Notification, Task
db.create_all()
print('Tables created successfully!')
EOF
    
    if [ $? -eq 0 ]; then
        echo "✅ Tables created manually!"
        
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
        
        echo "🎉 Database setup complete!"
        echo "🧪 Testing application..."
        python test-app.py
    else
        echo "❌ Manual table creation failed"
    fi
fi
