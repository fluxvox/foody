#!/bin/bash

# Debug routes and application
echo "🔍 Debugging application routes..."

# 1. Check if the application is actually responding
echo "🧪 Testing basic connectivity..."
curl -v http://localhost:5000/ 2>&1 | head -20

echo -e "\n🧪 Testing with different paths..."
curl -s http://localhost:5000/index
curl -s http://localhost:5000/login
curl -s http://localhost:5000/register

# 2. Check Flask routes
echo -e "\n📋 Checking Flask routes..."
export FLASK_APP=foody.py
flask routes 2>/dev/null || echo "Flask routes command failed"

# 3. Test the application directly
echo -e "\n🔧 Testing application directly..."
python3 -c "
import sys
sys.path.insert(0, '.')
try:
    from foody import app
    with app.test_client() as client:
        response = client.get('/')
        print(f'Status: {response.status_code}')
        print(f'Data: {response.data[:200]}')
        if response.status_code == 200:
            print('✅ Application is working!')
        else:
            print('❌ Application has issues')
except Exception as e:
    print(f'❌ Error: {e}')
"

# 4. Check if there are any import errors
echo -e "\n🔍 Checking for import errors..."
python3 -c "
try:
    from app import create_app
    app = create_app()
    print('✅ App creation successful')
except Exception as e:
    print(f'❌ App creation failed: {e}')
"

# 5. Check database tables
echo -e "\n🗄️  Checking database tables..."
mysql -u foody -pfoody123 -e "SHOW TABLES;" foody

# 6. Check if admin user exists
echo -e "\n👤 Checking admin user in database..."
mysql -u foody -pfoody123 -e "SELECT username, email FROM user;" foody

echo -e "\n🎯 Route debugging complete!"
