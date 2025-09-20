#!/bin/bash

# Check deployment status script
echo "🔍 Checking Foody deployment status..."

# Check if services are running
echo "📊 Service Status:"
echo "=================="
echo "Foody service:"
sudo systemctl status foody --no-pager -l

echo -e "\nNginx service:"
sudo systemctl status nginx --no-pager -l

echo -e "\nMariaDB service:"
sudo systemctl status mariadb --no-pager -l

# Check ports
echo -e "\n🌐 Port Status:"
echo "=============="
echo "Port 80 (HTTP):"
sudo netstat -tlnp | grep :80 || echo "Port 80 not listening"

echo -e "\nPort 443 (HTTPS):"
sudo netstat -tlnp | grep :443 || echo "Port 443 not listening"

echo -e "\nPort 5000 (Foody app):"
sudo netstat -tlnp | grep :5000 || echo "Port 5000 not listening"

# Check Nginx configuration
echo -e "\n🔧 Nginx Configuration:"
echo "========================"
echo "Active sites:"
ls -la /etc/nginx/sites-enabled/

echo -e "\nNginx config test:"
sudo nginx -t

# Test application endpoints
echo -e "\n🧪 Application Tests:"
echo "===================="
echo "Testing localhost:5000 (direct app):"
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ || echo "Failed"

echo -e "\nTesting localhost:80 (Nginx proxy):"
curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "Failed"

echo -e "\nTesting health endpoint:"
curl -s http://localhost:5000/health || echo "Health endpoint failed"

# Check logs
echo -e "\n📋 Recent Logs:"
echo "==============="
echo "Foody logs (last 10 lines):"
sudo journalctl -u foody --no-pager -n 10

echo -e "\nNginx logs (last 5 lines):"
sudo tail -n 5 /var/log/nginx/access.log 2>/dev/null || echo "No access logs"
sudo tail -n 5 /var/log/nginx/error.log 2>/dev/null || echo "No error logs"

echo -e "\n🎯 Summary:"
echo "============"
if systemctl is-active --quiet foody; then
    echo "✅ Foody service: RUNNING"
else
    echo "❌ Foody service: NOT RUNNING"
fi

if systemctl is-active --quiet nginx; then
    echo "✅ Nginx service: RUNNING"
else
    echo "❌ Nginx service: NOT RUNNING"
fi

if systemctl is-active --quiet mariadb; then
    echo "✅ MariaDB service: RUNNING"
else
    echo "❌ MariaDB service: NOT RUNNING"
fi

# Check if application is accessible
if curl -s http://localhost:5000/ > /dev/null 2>&1; then
    echo "✅ Application: ACCESSIBLE on port 5000"
else
    echo "❌ Application: NOT ACCESSIBLE on port 5000"
fi

if curl -s http://localhost/ > /dev/null 2>&1; then
    echo "✅ Nginx proxy: WORKING on port 80"
else
    echo "❌ Nginx proxy: NOT WORKING on port 80"
fi

echo -e "\n🔧 Deployment check complete!"
