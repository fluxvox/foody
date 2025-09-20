#!/usr/bin/env python3

# Quick fix for MySQL driver issue

import os
import sys

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def fix_mysql_import():
    """Fix MySQL import by monkey-patching MySQLdb"""
    try:
        import pymysql
        pymysql.install_as_MySQLdb()
        print("✅ MySQLdb monkey-patch applied successfully!")
        return True
    except ImportError:
        print("❌ PyMySQL not installed. Installing...")
        os.system("pip install PyMySQL")
        try:
            import pymysql
            pymysql.install_as_MySQLdb()
            print("✅ PyMySQL installed and monkey-patch applied!")
            return True
        except Exception as e:
            print(f"❌ Failed to install PyMySQL: {e}")
            return False

if __name__ == "__main__":
    print("🔧 Fixing MySQL driver issue...")
    if fix_mysql_import():
        print("🎉 MySQL driver fixed! You can now run the application.")
    else:
        print("❌ Failed to fix MySQL driver. Please install PyMySQL manually:")
        print("   pip install PyMySQL")
