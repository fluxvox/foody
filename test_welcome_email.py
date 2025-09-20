#!/usr/bin/env python3
"""
Simple test script to verify welcome email functionality.
This script can be run to test the email templates and functionality.
"""

import os
import sys
from flask import Flask

# Add the project root to the Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app, db
from app.models import User
from app.auth.email import send_welcome_email

def test_welcome_email():
    """Test the welcome email functionality"""
    app = create_app()
    
    with app.app_context():
        # Create a test user
        test_user = User(
            username='testuser',
            email='test@example.com'
        )
        
        print("Testing welcome email functionality...")
        print(f"User: {test_user.username}")
        print(f"Email: {test_user.email}")
        
        try:
            # Test sending welcome email
            send_welcome_email(test_user)
            print("✅ Welcome email sent successfully!")
            print("Check your email configuration and logs for any issues.")
        except Exception as e:
            print(f"❌ Failed to send welcome email: {str(e)}")
            print("Make sure your email configuration is set up correctly.")
            print("Check the .env file for MAIL_SERVER, MAIL_USERNAME, MAIL_PASSWORD, etc.")

if __name__ == '__main__':
    test_welcome_email()
