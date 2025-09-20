#!/usr/bin/env python3

# Startup script for Foody application
# This ensures the MySQL driver is properly configured

import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Fix MySQL driver issue
try:
    import pymysql
    pymysql.install_as_MySQLdb()
    print("✅ MySQL driver configured successfully!")
except ImportError:
    print("❌ PyMySQL not found. Please install it with: pip install PyMySQL")
    sys.exit(1)

# Set environment variables
os.environ.setdefault('FLASK_APP', 'foody.py')
os.environ.setdefault('FLASK_ENV', 'development')

# Import and run the application
from foody import app

if __name__ == '__main__':
    print("🚀 Starting Foody application...")
    print("🌐 Application will be available at: http://localhost:5002")
    print("📝 Press Ctrl+C to stop the application")
    app.run(debug=True, host='0.0.0.0', port=5002)
