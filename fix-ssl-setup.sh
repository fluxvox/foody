#!/bin/bash

echo "🔧 Fixing SSL setup..."

# Navigate to the application directory
cd "$(dirname "$0")"

DOMAIN="lab10.ifalabs.org"

# 1. Create SSL directory and fix permissions
echo "📁 Creating SSL directory..."
sudo mkdir -p /etc/ssl/foody
sudo chown -R student:student /etc/ssl/foody

# 2. Generate mkcert certificates properly
echo "🔐 Generating mkcert certificates..."
cd /etc/ssl/foody
sudo -u student mkcert localhost lab10.ifalabs.org 127.0.0.1 ::1
sudo chown -R student:student /etc/ssl/foody

# 3. Check if certificates exist (check for any localhost+*.pem file)
if ls /etc/ssl/foody/localhost+*.pem 1> /dev/null 2>&1; then
    CERT_FILE=$(ls /etc/ssl/foody/localhost+*.pem | grep -v key | head -1)
    KEY_FILE=$(ls /etc/ssl/foody/localhost+*-key.pem | head -1)
    echo "✅ Certificates generated successfully:"
    echo "   Certificate: $CERT_FILE"
    echo "   Key: $KEY_FILE"
else
    echo "❌ Certificate generation failed. Let's use Let's Encrypt instead."
    echo "🔄 Proceeding with Let's Encrypt setup..."
    ./setup-letsencrypt.sh
    exit 0
fi

# 4. Update Nginx configuration with correct certificate paths
echo "🌐 Updating Nginx configuration..."
sudo tee /etc/nginx/sites-available/lab10.ifalabs.org > /dev/null << EOF
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
    ssl_certificate /etc/ssl/foody/localhost+3.pem;
    ssl_certificate_key /etc/ssl/foody/localhost+3-key.pem;
    
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

# 5. Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    
    # 6. Reload Nginx
    echo "🔄 Reloading Nginx..."
    sudo systemctl reload nginx
    
    # 7. Test SSL
    echo "🧪 Testing SSL..."
    curl -k -s -o /dev/null -w "HTTPS Status: %{http_code}\n" https://localhost/ || echo "❌ HTTPS test failed"
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/ || echo "❌ HTTP redirect test failed"
    
    echo ""
    echo "🎉 SSL setup fixed!"
    echo "✅ Local development: https://localhost (with mkcert)"
    echo "✅ Production: https://${DOMAIN} (with mkcert for now)"
    echo ""
    echo "🔧 For production Let's Encrypt, run:"
    echo "  ./setup-letsencrypt.sh"
    
else
    echo "❌ Nginx configuration error. Let's try Let's Encrypt instead."
    echo "🔄 Running Let's Encrypt setup..."
    ./setup-letsencrypt.sh
fi
