#!/bin/bash

# Setup Nginx welcome page on current server (34.65.201.63)
echo "🌐 Setting up Nginx welcome page on current server..."

# 1. Check current server IP
echo "🖥️  Checking current server IP..."
CURRENT_IP=$(curl -s ifconfig.me)
echo "Current server IP: $CURRENT_IP"

# 2. Check if domain resolves to this server
echo "🔍 Checking domain resolution..."
DOMAIN_IP=$(ping -c 1 lab10.ifalabs.org | grep "PING" | awk '{print $3}' | tr -d '()')
echo "Domain resolves to: $DOMAIN_IP"

if [ "$CURRENT_IP" = "$DOMAIN_IP" ]; then
    echo "✅ Domain points to this server"
else
    echo "❌ Domain does not point to this server"
    echo "💡 You may need to update DNS or check if you're on the right server"
fi

# 3. Install Nginx if not installed
echo "📦 Checking Nginx installation..."
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt update
    sudo apt install -y nginx
else
    echo "✅ Nginx is already installed"
fi

# 4. Create Nginx configuration for lab10.ifalabs.org
echo "📝 Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/lab10.ifalabs.org << 'EOF'
server {
    listen 80;
    server_name lab10.ifalabs.org;
    
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
EOF

# 5. Enable the site
echo "🔗 Enabling lab10.ifalabs.org site..."
sudo ln -sf /etc/nginx/sites-available/lab10.ifalabs.org /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 6. Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    
    # 7. Start/restart Nginx
    echo "🔄 Starting Nginx..."
    sudo systemctl enable nginx
    sudo systemctl start nginx
    sudo systemctl reload nginx
    
    # 8. Check Nginx status
    echo "📊 Checking Nginx status..."
    sudo systemctl status nginx --no-pager
    
    # 9. Test the welcome page
    echo "🧪 Testing welcome page..."
    curl -s http://lab10.ifalabs.org/ | head -5
    
    echo -e "\n🎯 Nginx welcome page setup complete!"
    echo "🌐 Your site should now be available at: http://lab10.ifalabs.org"
    echo "📋 Server IP: $CURRENT_IP"
    echo "📋 Domain IP: $DOMAIN_IP"
    
else
    echo "❌ Nginx configuration has errors"
    echo "🔍 Check the configuration:"
    echo "  sudo nginx -t"
fi
