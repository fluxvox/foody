#!/usr/bin/env python3

"""
Email Testing Script for Foody Application
Tests email functionality and sends sample emails
"""

import os
import sys
import time
from datetime import datetime

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

from app import create_app, db, mail
from app.models import User
from app.email import send_email
from flask_mail import Message


def test_email_configuration():
    """Test email configuration"""
    print("🔧 Testing email configuration...")
    
    app = create_app()
    with app.app_context():
        # Check email configuration
        print(f"📧 Mail Server: {app.config.get('MAIL_SERVER', 'Not configured')}")
        print(f"📧 Mail Port: {app.config.get('MAIL_PORT', 'Not configured')}")
        print(f"📧 Mail TLS: {app.config.get('MAIL_USE_TLS', 'Not configured')}")
        print(f"📧 Mail Username: {app.config.get('MAIL_USERNAME', 'Not configured')}")
        print(f"📧 Admins: {app.config.get('ADMINS', 'Not configured')}")
        
        # Test mail object
        if mail:
            print("✅ Flask-Mail initialized successfully")
        else:
            print("❌ Flask-Mail not initialized")
            return False
            
    return True


def test_simple_email():
    """Test sending a simple email"""
    print("\n📧 Testing simple email sending...")
    
    app = create_app()
    with app.app_context():
        try:
            # Create a simple test message
            msg = Message(
                subject='🧪 Foody Email Test',
                sender=app.config.get('ADMINS', ['test@foody.com'])[0],
                recipients=['test@example.com'],
                body='This is a test email from Foody application.',
                html='<h1>🧪 Foody Email Test</h1><p>This is a test email from Foody application.</p>'
            )
            
            # Send email (synchronously for testing)
            mail.send(msg)
            print("✅ Simple email sent successfully")
            return True
            
        except Exception as e:
            print(f"❌ Failed to send simple email: {e}")
            return False


def test_async_email():
    """Test async email sending"""
    print("\n📧 Testing async email sending...")
    
    app = create_app()
    with app.app_context():
        try:
            # Test async email function
            send_email(
                subject='🧪 Foody Async Email Test',
                sender=app.config.get('ADMINS', ['test@foody.com'])[0],
                recipients=['test@example.com'],
                text_body='This is an async test email from Foody application.',
                html_body='<h1>🧪 Foody Async Email Test</h1><p>This is an async test email from Foody application.</p>',
                sync=True  # Use sync for testing
            )
            print("✅ Async email sent successfully")
            return True
            
        except Exception as e:
            print(f"❌ Failed to send async email: {e}")
            return False


def test_password_reset_email():
    """Test password reset email"""
    print("\n📧 Testing password reset email...")
    
    app = create_app()
    with app.app_context():
        try:
            # Create a test user
            test_user = User(
                username='testuser',
                email='test@example.com'
            )
            test_user.set_password('testpassword')
            
            # Generate reset token
            token = test_user.get_reset_password_token()
            print(f"🔑 Generated reset token: {token[:20]}...")
            
            # Send password reset email
            from app.auth.email import send_password_reset_email
            send_password_reset_email(test_user)
            print("✅ Password reset email sent successfully")
            return True
            
        except Exception as e:
            print(f"❌ Failed to send password reset email: {e}")
            return False


def test_welcome_email():
    """Test welcome email for new users"""
    print("\n📧 Testing welcome email...")
    
    app = create_app()
    with app.app_context():
        try:
            # Create welcome email content
            subject = '🍳 Welcome to Foody!'
            text_body = f"""
Dear New User,

Welcome to Foody - your recipe sharing platform!

Get started by:
1. Creating your first recipe
2. Browsing recipes from other users
3. Rating recipes you try

Happy cooking!

The Foody Team
            """.strip()
            
            html_body = f"""
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; }}
        .header {{ background-color: #f8f9fa; padding: 20px; text-align: center; }}
        .content {{ padding: 20px; }}
        .footer {{ background-color: #e9ecef; padding: 10px; text-align: center; font-size: 12px; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🍳 Welcome to Foody!</h1>
    </div>
    <div class="content">
        <p>Dear New User,</p>
        <p>Welcome to Foody - your recipe sharing platform!</p>
        <p>Get started by:</p>
        <ul>
            <li>Creating your first recipe</li>
            <li>Browsing recipes from other users</li>
            <li>Rating recipes you try</li>
        </ul>
        <p>Happy cooking!</p>
    </div>
    <div class="footer">
        <p>The Foody Team</p>
    </div>
</body>
</html>
            """.strip()
            
            # Send welcome email
            send_email(
                subject=subject,
                sender=app.config.get('ADMINS', ['admin@foody.com'])[0],
                recipients=['newuser@example.com'],
                text_body=text_body,
                html_body=html_body,
                sync=True
            )
            print("✅ Welcome email sent successfully")
            return True
            
        except Exception as e:
            print(f"❌ Failed to send welcome email: {e}")
            return False


def test_recipe_share_email():
    """Test recipe sharing email"""
    print("\n📧 Testing recipe sharing email...")
    
    app = create_app()
    with app.app_context():
        try:
            # Create recipe sharing email content
            recipe_title = "Delicious Pasta Recipe"
            recipe_url = "https://lab10.ifalabs.org/recipe/1"
            sender_name = "Chef John"
            
            subject = f'🍝 {sender_name} shared a recipe with you!'
            text_body = f"""
Hi there!

{sender_name} shared a recipe with you: "{recipe_title}"

Check it out: {recipe_url}

Happy cooking!

The Foody Team
            """.strip()
            
            html_body = f"""
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; }}
        .header {{ background-color: #f8f9fa; padding: 20px; text-align: center; }}
        .content {{ padding: 20px; }}
        .recipe-card {{ border: 1px solid #dee2e6; border-radius: 8px; padding: 15px; margin: 15px 0; }}
        .btn {{ background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; }}
        .footer {{ background-color: #e9ecef; padding: 10px; text-align: center; font-size: 12px; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🍝 Recipe Shared with You!</h1>
    </div>
    <div class="content">
        <p>Hi there!</p>
        <p><strong>{sender_name}</strong> shared a recipe with you:</p>
        <div class="recipe-card">
            <h3>🍝 {recipe_title}</h3>
            <a href="{recipe_url}" class="btn">View Recipe</a>
        </div>
        <p>Happy cooking!</p>
    </div>
    <div class="footer">
        <p>The Foody Team</p>
    </div>
</body>
</html>
            """.strip()
            
            # Send recipe sharing email
            send_email(
                subject=subject,
                sender=app.config.get('ADMINS', ['admin@foody.com'])[0],
                recipients=['friend@example.com'],
                text_body=text_body,
                html_body=html_body,
                sync=True
            )
            print("✅ Recipe sharing email sent successfully")
            return True
            
        except Exception as e:
            print(f"❌ Failed to send recipe sharing email: {e}")
            return False


def main():
    """Run all email tests"""
    print("🧪 Foody Email Testing Suite")
    print("=" * 50)
    
    # Test results
    results = []
    
    # Run tests
    results.append(("Email Configuration", test_email_configuration()))
    results.append(("Simple Email", test_simple_email()))
    results.append(("Async Email", test_async_email()))
    results.append(("Password Reset Email", test_password_reset_email()))
    results.append(("Welcome Email", test_welcome_email()))
    results.append(("Recipe Share Email", test_recipe_share_email()))
    
    # Print results
    print("\n📊 Test Results:")
    print("=" * 50)
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} {test_name}")
        if result:
            passed += 1
    
    print(f"\n🎯 Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All email tests passed! Email functionality is working correctly.")
    else:
        print("⚠️  Some email tests failed. Check your email configuration.")
    
    return passed == total


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
