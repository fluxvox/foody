#!/bin/bash

echo "🧹 Cleaning up Docker leftovers and fixing Nginx..."

# 1. Stop and remove all Docker containers
echo "🐳 Stopping all Docker containers..."
sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
sudo docker rm $(sudo docker ps -aq) 2>/dev/null || true

# 2. Stop Docker services
echo "🛑 Stopping Docker services..."
sudo systemctl stop docker
sudo systemctl stop containerd
sudo systemctl disable docker
sudo systemctl disable containerd

# 3. Check what's using port 80
echo "🔍 Checking what's using port 80..."
sudo netstat -tlnp | grep :80 || echo "Nothing listening on port 80"

# 4. Check Nginx status
echo "📊 Checking Nginx status..."
sudo systemctl status nginx --no-pager

# 5. Restart Nginx to ensure it's running
echo "🔄 Restarting Nginx..."
sudo systemctl restart nginx

# 6. Check if Nginx is listening on port 80
echo "🔍 Checking if Nginx is listening on port 80..."
sudo netstat -tlnp | grep :80

# 7. Test local connection
echo "🧪 Testing local connection..."
curl -s http://localhost/ | head -5 || echo "❌ Local connection failed"

# 8. Test domain connection
echo "🧪 Testing domain connection..."
curl -s http://lab10.ifalabs.org/ | head -5 || echo "❌ Domain connection failed"

# 9. Check Nginx configuration
echo "📝 Checking Nginx configuration..."
sudo nginx -t

# 10. Check if the site is enabled
echo "🔗 Checking enabled sites..."
ls -la /etc/nginx/sites-enabled/

# 11. Check Nginx error logs
echo "📋 Recent Nginx error logs:"
sudo tail -10 /var/log/nginx/error.log

# 12. Check Nginx access logs
echo "📋 Recent Nginx access logs:"
sudo tail -10 /var/log/nginx/access.log

echo ""
echo "🎯 Cleanup complete! Check the output above for any issues."
echo "🌐 Try accessing: http://lab10.ifalabs.org"
