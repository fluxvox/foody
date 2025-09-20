#!/bin/bash

# Setup Nginx to show welcome page at lab10.ifalabs.org
echo "🌐 Setting up Nginx welcome page for lab10.ifalabs.org..."

# 1. Remove the Foody site configuration
echo "🗑️  Removing Foody site configuration..."
sudo rm -f /etc/nginx/sites-enabled/foody
sudo rm -f /etc/nginx/sites-available/foody

# 2. Create a new Nginx configuration for lab10.ifalabs.org
echo "📝 Creating Nginx configuration for lab10.ifalabs.org..."
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

# 3. Enable the new site
echo "🔗 Enabling lab10.ifalabs.org site..."
sudo ln -sf /etc/nginx/sites-available/lab10.ifalabs.org /etc/nginx/sites-enabled/

# 4. Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    
    # 5. Reload Nginx
    echo "🔄 Reloading Nginx..."
    sudo systemctl reload nginx
    
    # 6. Test the welcome page
    echo "🧪 Testing welcome page..."
    curl -s http://lab10.ifalabs.org/ | head -5
    
    echo -e "\n🎯 Nginx welcome page setup complete!"
    echo "🌐 Your site is now available at: http://lab10.ifalabs.org"
    echo "📋 Configuration file: /etc/nginx/sites-available/lab10.ifalabs.org"
    echo "🔧 To manage:"
    echo "  sudo systemctl status nginx"
    echo "  sudo systemctl reload nginx"
    echo "  sudo tail -f /var/log/nginx/access.log"
    
else
    echo "❌ Nginx configuration has errors"
    echo "🔍 Check the configuration:"
    echo "  sudo nginx -t"
fi
