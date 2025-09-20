#!/bin/bash

# Fix systemd service script
echo "🔧 Fixing systemd service..."

# Create instance directory
echo "📁 Creating instance directory..."
mkdir -p /home/student/foody/instance
mkdir -p /home/student/foody/logs

# Update service file
echo "⚙️  Updating service file..."
sudo cp foody.service /etc/systemd/system/
sudo systemctl daemon-reload

# Stop existing service
echo "🛑 Stopping existing service..."
sudo systemctl stop foody

# Start service
echo "🚀 Starting service..."
sudo systemctl start foody

# Check status
echo "📊 Checking service status..."
sudo systemctl status foody --no-pager

# Check logs
echo "📋 Checking service logs..."
sudo journalctl -u foody --no-pager -n 10

if systemctl is-active --quiet foody; then
    echo "✅ Service is running successfully!"
    echo "🌐 Application should be available at: http://localhost:5000"
else
    echo "❌ Service failed to start. Check logs:"
    sudo journalctl -u foody --no-pager -n 20
fi

echo "🔧 Service fix complete!"
