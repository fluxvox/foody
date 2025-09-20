#!/bin/bash

echo "🔒 Setting up SSL with Let's Encrypt and mkcert..."

# Navigate to the application directory
cd "$(dirname "$0")"

DOMAIN="lab10.ifalabs.org"
NGINX_CONF="/etc/nginx/sites-available/lab10.ifalabs.org"

# 1. Install Certbot for Let's Encrypt
echo "📦 Installing Certbot..."
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# 2. Install mkcert for local development
echo "📦 Installing mkcert for local development..."
if ! command -v mkcert &> /dev/null; then
    # Install mkcert
    curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
    chmod +x mkcert-v*-linux-amd64
    sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
    mkcert -install
    echo "✅ mkcert installed and root CA installed"
else
    echo "✅ mkcert already installed"
fi

# 3. Create SSL directory
echo "📁 Creating SSL directory..."
sudo mkdir -p /etc/ssl/foody
sudo chown -R student:student /etc/ssl/foody

# 4. Generate local development certificates
echo "🔐 Generating local development certificates..."
cd /etc/ssl/foody
sudo -u student mkcert localhost lab10.ifalabs.org 127.0.0.1 ::1
sudo chown -R student:student /etc/ssl/foody

# 5. Update Nginx configuration for SSL
echo "🌐 Updating Nginx configuration for SSL..."
sudo tee "$NGINX_CONF" > /dev/null << EOF
# HTTP server - redirect to HTTPS
server {
    listen 80;
    server_name ${DOMAIN} localhost;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirect all HTTP to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server - main application
server {
    listen 443 ssl http2;
    server_name ${DOMAIN} localhost;
    
    # SSL Configuration
    ssl_certificate /etc/ssl/foody/localhost+2.pem;
    ssl_certificate_key /etc/ssl/foody/localhost+2-key.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Client settings
    client_max_body_size 10M;
    client_body_timeout 60s;
    client_header_timeout 60s;
    
    # Static files
    location /static {
        alias /home/student/foody/app/static;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # API endpoints
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # All other requests
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
}
EOF

# 6. Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    
    # 7. Reload Nginx
    echo "🔄 Reloading Nginx..."
    sudo systemctl reload nginx
    
    # 8. Test SSL
    echo "🧪 Testing SSL..."
    curl -k -s -o /dev/null -w "HTTPS Status: %{http_code}\n" https://localhost/ || echo "❌ HTTPS test failed"
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/ || echo "❌ HTTP redirect test failed"
    
    echo ""
    echo "🎉 SSL setup complete!"
    echo "✅ Local development: https://localhost (with mkcert)"
    echo "✅ Production: https://${DOMAIN} (with Let's Encrypt)"
    echo ""
    echo "🔧 Next steps for production:"
    echo "  1. Run: sudo certbot --nginx -d ${DOMAIN}"
    echo "  2. Test: https://${DOMAIN}"
    echo "  3. Auto-renewal: sudo certbot renew --dry-run"
    
else
    echo "❌ Nginx configuration error. Please check the configuration."
    exit 1
fi
