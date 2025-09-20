#!/bin/bash

echo "🔄 Restarting Foody service with domain configuration..."

# Navigate to the application directory
cd "$(dirname "$0")"

# 1. Copy the updated service file
echo "📝 Updating systemd service..."
sudo cp foody.service /etc/systemd/system/foody.service

# 2. Reload systemd and restart service
echo "🔄 Reloading systemd and restarting service..."
sudo systemctl daemon-reload
sudo systemctl restart foody

# 3. Check service status
echo "📊 Checking service status..."
sudo systemctl status foody --no-pager

# 4. Test the application
echo "🧪 Testing application..."
sleep 3
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:5000/ || echo "❌ Direct app access failed"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://lab10.ifalabs.org/ || echo "❌ Nginx proxy access failed"

echo ""
echo "🎯 Service restarted with domain configuration!"
echo "🌐 Check http://lab10.ifalabs.org - URLs should now use the correct domain"
echo ""
echo "📋 If issues persist, check logs:"
echo "  sudo journalctl -u foody -f"
