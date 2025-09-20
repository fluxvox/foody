#!/bin/bash

echo "🔧 Fixing iptables rules for external access..."

# 1. Check current iptables rules
echo "📋 Current iptables rules:"
sudo iptables -L -n --line-numbers

# 2. Clear all iptables rules (be careful in production!)
echo "🧹 Clearing all iptables rules..."
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X

# 3. Set default policies
echo "⚙️  Setting default policies..."
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

# 4. Allow HTTP and HTTPS traffic
echo "🌐 Allowing HTTP and HTTPS traffic..."
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 5. Allow SSH (important!)
echo "🔐 Allowing SSH..."
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 6. Allow established connections
echo "🔗 Allowing established connections..."
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 7. Allow loopback
echo "🔄 Allowing loopback..."
sudo iptables -A INPUT -i lo -j ACCEPT

# 8. Show new rules
echo "📋 New iptables rules:"
sudo iptables -L -n --line-numbers

# 9. Test external access
echo "🧪 Testing external access..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://lab10.ifalabs.org/ || echo "Still failing"

# 10. Check if Nginx is still running
echo "📊 Checking Nginx status..."
sudo systemctl status nginx --no-pager | head -5

echo ""
echo "🎯 iptables rules fixed!"
echo "🌐 Try accessing http://lab10.ifalabs.org now"
echo ""
echo "⚠️  Note: These rules will be lost on reboot."
echo "💡 To make them persistent, install iptables-persistent:"
echo "   sudo apt install iptables-persistent"
