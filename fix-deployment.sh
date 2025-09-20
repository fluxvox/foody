#!/bin/bash

# Fix deployment issues script
echo "🔧 Fixing Foody deployment issues..."

# Check if admin user already exists
echo "👤 Checking if admin user exists..."
export FLASK_APP=foody.py
export FLASK_ENV=development

# Check if admin user exists
flask shell << EOF
from app.models import User
from app import db
admin_user = User.query.filter_by(username='admin').first()
if admin_user:
    print('✅ Admin user already exists')
else:
    print('❌ Admin user does not exist')
EOF

# Fix systemd service
echo "⚙️  Fixing systemd service..."

# Check if service file exists
if [ -f "/etc/systemd/system/foody.service" ]; then
    echo "✅ Service file exists"
else
    echo "📝 Installing service file..."
    sudo cp foody.service /etc/systemd/system/
    sudo systemctl daemon-reload
fi

# Check service configuration
echo "🔍 Checking service configuration..."
sudo systemctl status foody --no-pager

# Check service logs
echo "📋 Checking service logs..."
sudo journalctl -u foody --no-pager -n 20

# Fix permissions
echo "🔐 Fixing permissions..."
sudo chown -R foody:foody /opt/foody 2>/dev/null || echo "⚠️  User foody not found, skipping permission fix"

# Test application manually
echo "🧪 Testing application manually..."
python test-app.py

if [ $? -eq 0 ]; then
    echo "✅ Application test successful!"
    
    # Try to start service
    echo "🚀 Starting service..."
    sudo systemctl start foody
    sudo systemctl status foody --no-pager
    
    if [ $? -eq 0 ]; then
        echo "✅ Service started successfully!"
    else
        echo "❌ Service failed to start. Check logs:"
        sudo journalctl -u foody --no-pager -n 10
    fi
else
    echo "❌ Application test failed. Fix the issues first."
fi

echo "🔧 Deployment fix complete!"
