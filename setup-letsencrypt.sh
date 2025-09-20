#!/bin/bash

echo "🔒 Setting up Let's Encrypt SSL certificates for production..."

# Navigate to the application directory
cd "$(dirname "$0")"

DOMAIN="lab10.ifalabs.org"

# 1. Check if domain is accessible
echo "🔍 Checking domain accessibility..."
if curl -s --connect-timeout 10 "http://${DOMAIN}" > /dev/null; then
    echo "✅ Domain ${DOMAIN} is accessible"
else
    echo "❌ Domain ${DOMAIN} is not accessible. Please check DNS and firewall."
    exit 1
fi

# 2. Stop Nginx temporarily for certificate generation
echo "⏸️  Stopping Nginx temporarily..."
sudo systemctl stop nginx

# 3. Generate Let's Encrypt certificate
echo "🔐 Generating Let's Encrypt certificate..."
sudo certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email admin@${DOMAIN} \
    --domains ${DOMAIN}

if [ $? -eq 0 ]; then
    echo "✅ Let's Encrypt certificate generated successfully"
else
    echo "❌ Failed to generate Let's Encrypt certificate"
    echo "🔄 Starting Nginx with local certificates..."
    sudo systemctl start nginx
    exit 1
fi

# 4. Update Nginx configuration for Let's Encrypt
echo "🌐 Updating Nginx configuration for Let's Encrypt..."
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
    
    # SSL Configuration (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    
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
    
    # 6. Start Nginx
    echo "🔄 Starting Nginx..."
    sudo systemctl start nginx
    
    # 7. Test SSL
    echo "🧪 Testing SSL..."
    sleep 3
    curl -s -o /dev/null -w "HTTPS Status: %{http_code}\n" https://${DOMAIN}/ || echo "❌ HTTPS test failed"
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://${DOMAIN}/ || echo "❌ HTTP redirect test failed"
    
    # 8. Set up auto-renewal
    echo "🔄 Setting up auto-renewal..."
    sudo crontab -l 2>/dev/null | grep -v "certbot renew" | sudo crontab -
    echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
    
    echo ""
    echo "🎉 Let's Encrypt SSL setup complete!"
    echo "✅ Production SSL: https://${DOMAIN}"
    echo "✅ Auto-renewal: Configured"
    echo "✅ Security headers: Enabled"
    echo ""
    echo "🔧 Test your site: https://${DOMAIN}"
    
else
    echo "❌ Nginx configuration error. Please check the configuration."
    sudo systemctl start nginx
    exit 1
fi