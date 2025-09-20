#!/bin/bash

# Test production deployment
echo "🌐 Testing production deployment..."

# 1. Test HTTP (should work)
echo "🧪 Testing HTTP access..."
echo "Testing localhost:"
curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "Failed"

echo -e "\nTesting lab10.ifalabs.org (HTTP):"
curl -s -o /dev/null -w "%{http_code}" http://lab10.ifalabs.org/ || echo "Failed"

# 2. Test specific endpoints
echo -e "\n🔍 Testing specific endpoints..."
echo "Login page:"
curl -s http://lab10.ifalabs.org/auth/login | head -5

echo -e "\nIndex page:"
curl -s http://lab10.ifalabs.org/index | head -5

# 3. Check if we can access the application
echo -e "\n🌐 Testing application access..."
if curl -s http://lab10.ifalabs.org/auth/login | grep -q "login\|Login"; then
    echo "✅ Application is accessible via lab10.ifalabs.org"
    echo "🌐 Production URL: http://lab10.ifalabs.org"
    echo "👤 Login: admin / admin123"
else
    echo "❌ Application not accessible via lab10.ifalabs.org"
    echo "🔍 Checking DNS resolution..."
    nslookup lab10.ifalabs.org
fi

# 4. Check HTTPS setup
echo -e "\n🔒 Checking HTTPS setup..."
if curl -s -o /dev/null -w "%{http_code}" https://lab10.ifalabs.org/ 2>/dev/null | grep -q "200\|301\|302"; then
    echo "✅ HTTPS is working"
else
    echo "❌ HTTPS not configured"
    echo "💡 To set up HTTPS, run:"
    echo "   sudo apt install certbot python3-certbot-nginx"
    echo "   sudo certbot --nginx -d lab10.ifalabs.org"
fi

# 5. Show current status
echo -e "\n📊 Production Status:"
echo "===================="
echo "✅ HTTP: http://lab10.ifalabs.org"
echo "❌ HTTPS: https://lab10.ifalabs.org (not configured)"
echo "👤 Admin: admin / admin123"
echo ""
echo "🔧 To access your application:"
echo "   Open browser: http://lab10.ifalabs.org"
echo "   Login with: admin / admin123"
echo ""
echo "🔒 To enable HTTPS:"
echo "   sudo certbot --nginx -d lab10.ifalabs.org"
