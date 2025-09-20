#!/bin/bash

# Debug the real issue
echo "🔍 Debugging the real issue..."

# 1. Test what's actually happening
echo "🧪 Testing actual responses..."
echo "Testing localhost:5000 (direct app):"
curl -v http://localhost:5000/ 2>&1 | head -10

echo -e "\nTesting localhost (nginx):"
curl -v http://localhost/ 2>&1 | head -10

# 2. Check if the app is actually responding with content
echo -e "\n🔍 Checking if app returns HTML content..."
curl -s http://localhost:5000/ | head -5
echo "---"
curl -s http://localhost/ | head -5

# 3. Check Nginx logs for errors
echo -e "\n📋 Checking Nginx error logs..."
sudo tail -5 /var/log/nginx/error.log 2>/dev/null || echo "No error logs"

# 4. Check if there are any 404s in access logs
echo -e "\n📋 Checking Nginx access logs..."
sudo tail -5 /var/log/nginx/access.log 2>/dev/null || echo "No access logs"

# 5. Test the application directly with Python
echo -e "\n🐍 Testing application directly..."
python3 -c "
import sys
sys.path.insert(0, '.')
try:
    from foody import app
    with app.test_client() as client:
        # Test root route
        response = client.get('/')
        print(f'Root route status: {response.status_code}')
        print(f'Root route data: {response.data[:100]}')
        
        # Test index route
        response = client.get('/index')
        print(f'Index route status: {response.status_code}')
        print(f'Index route data: {response.data[:100]}')
        
        # Test login route
        response = client.get('/auth/login')
        print(f'Login route status: {response.status_code}')
        print(f'Login route data: {response.data[:100]}')
        
except Exception as e:
    print(f'Error: {e}')
"

# 6. Check if the issue is with the Flask app configuration
echo -e "\n🔧 Checking Flask configuration..."
python3 -c "
import os
print('SERVER_NAME:', os.environ.get('SERVER_NAME', 'Not set'))
print('FLASK_ENV:', os.environ.get('FLASK_ENV', 'Not set'))
"

echo -e "\n🎯 Real issue debugging complete!"
