#!/bin/bash

echo "🍳 Setting up Foody application on lab10.ifalabs.org..."

# Navigate to the application directory
cd "$(dirname "$0")"

# 1. Check if the application is ready
echo "🔍 Checking application status..."
if [ ! -f "foody.py" ]; then
    echo "❌ foody.py not found. Are you in the right directory?"
    exit 1
fi

# 2. Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Please run setup first."
    exit 1
fi

# 3. Activate virtual environment and check dependencies
echo "📦 Checking Python dependencies..."
source venv/bin/activate
python -c "import flask, pymysql, gunicorn" 2>/dev/null || {
    echo "❌ Missing dependencies. Installing..."
    pip install -r requirements.txt
}

# 4. Check database connection
echo "🗄️  Testing database connection..."
export FLASK_APP=foody.py
export FLASK_ENV=production
python -c "
import pymysql
pymysql.install_as_MySQLdb()
from app import create_app, db
app = create_app()
with app.app_context():
    try:
        db.session.execute('SELECT 1')
        print('✅ Database connection successful')
    except Exception as e:
        print(f'❌ Database connection failed: {e}')
        exit(1)
" || {
    echo "❌ Database connection failed. Please check your database setup."
    exit 1
}

# 5. Test if the application can start
echo "🧪 Testing application startup..."
timeout 10s python -c "
import pymysql
pymysql.install_as_MySQLdb()
from app import create_app
app = create_app()
print('✅ Application can start successfully')
" || {
    echo "❌ Application startup failed"
    exit 1
}

# 6. Create systemd service for the application
echo "⚙️  Creating systemd service..."
sudo tee /etc/systemd/system/foody.service > /dev/null << EOF
[Unit]
Description=Foody Recipe Sharing Platform
After=network.target mariadb.service
Wants=mariadb.service

[Service]
Type=exec
User=student
Group=student
WorkingDirectory=$(pwd)
Environment=PATH=$(pwd)/venv/bin
Environment=FLASK_APP=foody.py
Environment=FLASK_ENV=production
ExecStart=$(pwd)/venv/bin/gunicorn --bind 127.0.0.1:5000 --workers 2 --timeout 30 --keep-alive 2 --max-requests 1000 --max-requests-jitter 100 foody:app
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=foody

# Security settings (relaxed for local deployment)
NoNewPrivileges=false
PrivateTmp=false
ProtectSystem=false
ProtectHome=false
ReadWritePaths=$(pwd)/logs
ReadWritePaths=$(pwd)/instance

[Install]
WantedBy=multi-user.target
EOF

# 7. Update Nginx configuration to proxy to the application
echo "🌐 Updating Nginx configuration..."
sudo tee /etc/nginx/sites-available/lab10.ifalabs.org > /dev/null << EOF
server {
    listen 80;
    server_name lab10.ifalabs.org localhost;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Proxy to Flask application
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Optional: Serve static files directly from Nginx for better performance
    location /static/ {
        alias $(pwd)/app/static/;
        expires 30d;
        access_log off;
    }
}
EOF

# 8. Enable and start the service
echo "🚀 Starting Foody service..."
sudo systemctl daemon-reload
sudo systemctl enable foody
sudo systemctl start foody

# 9. Check service status
echo "📊 Checking service status..."
sudo systemctl status foody --no-pager

# 10. Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t && sudo systemctl reload nginx

# 11. Test the application
echo "🧪 Testing application access..."
sleep 3
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:5000/ || echo "❌ Direct app access failed"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://lab10.ifalabs.org/ || echo "❌ Nginx proxy access failed"

echo ""
echo "🎉 Foody application setup complete!"
echo "🌐 Your application should now be available at: http://lab10.ifalabs.org"
echo ""
echo "📋 Service management:"
echo "  sudo systemctl status foody"
echo "  sudo systemctl restart foody"
echo "  sudo journalctl -u foody -f"
echo ""
echo "🔧 If there are issues, check the logs above and run:"
echo "  ./check-deployment.sh"
