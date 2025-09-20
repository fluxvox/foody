#!/bin/bash

echo "🌐 Fixing external access to lab10.ifalabs.org..."

# 1. Check current server IP
echo "🖥️  Current server IP:"
curl -s ifconfig.me
echo ""

# 2. Check if domain resolves to this server
echo "🔍 Domain resolution:"
ping -c 1 lab10.ifalabs.org | grep "PING" | awk '{print $3}' | tr -d '()'
echo ""

# 3. Check firewall status
echo "🔥 Checking firewall status..."
sudo ufw status || echo "UFW not installed/configured"

# 4. Check if port 80 is open externally
echo "🔍 Checking if port 80 is accessible externally..."
sudo netstat -tlnp | grep :80

# 5. Check iptables rules
echo "🔒 Checking iptables rules..."
sudo iptables -L -n | grep -E "(80|ACCEPT|DROP)" || echo "No specific iptables rules for port 80"

# 6. Test local access
echo "🧪 Testing local access..."
curl -s -o /dev/null -w "Local HTTP status: %{http_code}\n" http://localhost/

# 7. Test external access from server
echo "🧪 Testing external access from server..."
curl -s -o /dev/null -w "External HTTP status: %{http_code}\n" http://lab10.ifalabs.org/

# 8. Check if Nginx is binding to all interfaces
echo "🔍 Checking Nginx binding..."
sudo netstat -tlnp | grep nginx

# 9. Check Nginx configuration for server_name
echo "📝 Checking Nginx server_name configuration..."
sudo grep -r "server_name" /etc/nginx/sites-available/lab10.ifalabs.org

# 10. Open firewall for HTTP if needed
echo "🔥 Opening firewall for HTTP..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 11. Check if UFW is active
echo "🔥 UFW status:"
sudo ufw status verbose

# 12. Test external connectivity
echo "🧪 Testing external connectivity..."
echo "Testing from external perspective..."
curl -s -I http://lab10.ifalabs.org/ | head -3

# 13. Check if there are any other services blocking port 80
echo "🔍 Checking for other services on port 80..."
sudo lsof -i :80

# 14. Restart Nginx to ensure proper binding
echo "🔄 Restarting Nginx..."
sudo systemctl restart nginx

# 15. Final test
echo "🧪 Final connectivity test..."
echo "Testing HTTP access to lab10.ifalabs.org:"
curl -v http://lab10.ifalabs.org/ 2>&1 | head -10

echo ""
echo "🎯 If you still can't access the site:"
echo "1. Check if your cloud provider has security groups/firewalls"
echo "2. Verify the domain DNS is pointing to the correct IP"
echo "3. Try accessing from a different network"
echo "4. Check if there are any proxy/CDN settings"
