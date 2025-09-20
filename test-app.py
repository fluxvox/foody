#!/usr/bin/env python3

# Test script to verify the application can start without errors

import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Fix MySQL driver issue
try:
    import pymysql
    pymysql.install_as_MySQLdb()
    print("✅ MySQLdb monkey-patch applied!")
except ImportError:
    print("❌ PyMySQL not found. Please install it with: pip install PyMySQL")
    sys.exit(1)

try:
    print("🧪 Testing Foody application...")
    
    # Test imports
    print("📦 Testing imports...")
    from app import create_app, db
    from app.models import User, Recipe, Rating
    print("✅ All imports successful!")
    
    # Test app creation
    print("🏗️  Testing app creation...")
    app = create_app()
    print("✅ App created successfully!")
    
    # Test database connection
    print("🗄️  Testing database connection...")
    with app.app_context():
        # Try to query the database
        user_count = db.session.scalar(db.text("SELECT COUNT(*) FROM user"))
        print(f"✅ Database connection successful! Found {user_count} users.")
    
    print("🎉 All tests passed! The application is ready to run.")
    print("🚀 You can now start the application with: python foody.py")
    
except Exception as e:
    print(f"❌ Error: {e}")
    print("🔍 Check the error above and fix any issues.")
    sys.exit(1)
