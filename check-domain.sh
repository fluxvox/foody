#!/bin/bash

# Check domain and network configuration
echo "🔍 Checking domain and network configuration..."

# 1. Check if domain resolves
echo "🌐 Checking DNS resolution..."
echo "Testing lab10.ifalabs.org:"
ping -c 3 lab10.ifalabs.org 2>/dev/null || echo "❌ Domain does not resolve"

# 2. Check server IP
echo -e "\n🖥️  Checking server IP..."
echo "Server IP addresses:"
ip addr show | grep "inet " | grep -v "127.0.0.1"

# 3. Check if domain points to this server
echo -e "\n🔍 Checking if domain points to this server..."
SERVER_IP=$(ip route get 8.8.8.8 | awk '{print $7}' | head -1)
echo "This server's public IP: $SERVER_IP"

# 4. Test local access
echo -e "\n🧪 Testing local access..."
echo "Testing localhost:5000 (direct app):"
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ || echo "Failed"

echo -e "\nTesting localhost (nginx proxy):"
curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "Failed"

# 5. Check Nginx configuration
echo -e "\n🔧 Checking Nginx configuration..."
echo "Active sites:"
ls -la /etc/nginx/sites-enabled/

echo -e "\nNginx config test:"
sudo nginx -t

# 6. Check if Nginx is listening on port 80
echo -e "\n🌐 Checking port 80..."
sudo netstat -tlnp | grep :80

# 7. Test with different approaches
echo -e "\n🧪 Testing different approaches..."
echo "Testing with IP address:"
curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP/ || echo "Failed"

echo -e "\nTesting with Host header:"
curl -s -o /dev/null -w "%{http_code}" -H "Host: lab10.ifalabs.org" http://localhost/ || echo "Failed"

# 8. Show troubleshooting steps
echo -e "\n🔧 Troubleshooting Steps:"
echo "========================"
echo "1. Check if domain lab10.ifalabs.org points to this server's IP: $SERVER_IP"
echo "2. Check DNS settings with your domain provider"
echo "3. Test locally: http://localhost"
echo "4. Test direct app: http://localhost:5000"
echo ""
echo "💡 If domain doesn't point to this server:"
echo "   - Update DNS A record for lab10.ifalabs.org to point to $SERVER_IP"
echo "   - Wait for DNS propagation (can take up to 24 hours)"
echo ""
echo "💡 If domain points to this server but still not working:"
echo "   - Check firewall: sudo ufw status"
echo "   - Check if port 80 is open: sudo netstat -tlnp | grep :80"
echo "   - Check Nginx logs: sudo tail -f /var/log/nginx/error.log"
