# 📧 Email Testing Guide

This guide covers testing email functionality in the Foody application.

## 🧪 Email Testing Methods

### 1. Python Test Script
```bash
# Run comprehensive email tests
python test-email.py

# Test specific email types
python test-email.py --type welcome
python test-email.py --type password-reset
python test-email.py --type recipe-share
```

### 2. Flask CLI Commands
```bash
# Show email configuration
flask email config

# Test specific email type
flask email test --type welcome --recipient your@email.com

# Send all email types
flask email send-all --recipient your@email.com
```

### 3. Manual Testing
```bash
# Test in Flask shell
flask shell
>>> from app.auth.welcome_email import send_welcome_email
>>> from app.models import User
>>> user = User(username='test', email='test@example.com')
>>> send_welcome_email(user)
```

## 📧 Email Types Available

### 1. Welcome Email
- **Trigger**: New user registration
- **Template**: `email/welcome.html` and `email/welcome.txt`
- **Features**: Welcome message, getting started guide, CTA button

### 2. Password Reset Email
- **Trigger**: Password reset request
- **Template**: `email/reset_password.html` and `email/reset_password.txt`
- **Features**: Secure reset link, token-based authentication

### 3. Recipe Share Email
- **Trigger**: User shares recipe with someone
- **Template**: `email/share_recipe.html` and `email/share_recipe.txt`
- **Features**: Recipe details, author info, direct link to recipe

### 4. Rating Notification Email
- **Trigger**: Someone rates your recipe
- **Template**: `email/rating_notification.html` and `email/rating_notification.txt`
- **Features**: Rating details, recipe info, user who rated

## 🔧 Email Configuration

### Environment Variables
```bash
# Required email settings
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=true
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_app_password
ADMINS=admin@yourdomain.com
```

### Gmail Setup
1. **Enable 2-Factor Authentication**
2. **Generate App Password**: Google Account → Security → App passwords
3. **Use App Password**: Not your regular Gmail password

### Other SMTP Providers
```bash
# Outlook/Hotmail
MAIL_SERVER=smtp-mail.outlook.com
MAIL_PORT=587

# Yahoo
MAIL_SERVER=smtp.mail.yahoo.com
MAIL_PORT=587

# Custom SMTP
MAIL_SERVER=your-smtp-server.com
MAIL_PORT=587
```

## 🧪 Testing Checklist

### Basic Email Tests
- [ ] **Configuration**: Email settings loaded correctly
- [ ] **Connection**: Can connect to SMTP server
- [ ] **Authentication**: SMTP credentials work
- [ ] **Sending**: Emails sent successfully

### Email Type Tests
- [ ] **Welcome Email**: New user receives welcome
- [ ] **Password Reset**: Reset link works correctly
- [ ] **Recipe Share**: Recipe details displayed properly
- [ ] **Rating Notification**: Rating info included

### Template Tests
- [ ] **HTML Rendering**: Templates render correctly
- [ ] **Text Fallback**: Plain text versions work
- [ ] **Links**: All links work and are external
- [ ] **Styling**: CSS styles applied correctly

### Production Tests
- [ ] **Real Recipients**: Test with real email addresses
- [ ] **Spam Check**: Emails don't go to spam
- [ ] **Mobile Rendering**: Templates work on mobile
- [ ] **Email Clients**: Test in different email clients

## 🐛 Troubleshooting

### Common Issues

#### 1. Authentication Failed
```
Error: SMTPAuthenticationError
```
**Solution**: Check username/password, use app password for Gmail

#### 2. Connection Refused
```
Error: SMTPConnectError
```
**Solution**: Check MAIL_SERVER and MAIL_PORT settings

#### 3. TLS Error
```
Error: SMTPException
```
**Solution**: Set MAIL_USE_TLS=true and check port 587

#### 4. Template Not Found
```
Error: TemplateNotFound
```
**Solution**: Check template files exist in `app/templates/email/`

### Debug Mode
```bash
# Enable email debugging
export FLASK_DEBUG=1
python test-email.py
```

### Log Email Sending
```python
# In Flask shell
import logging
logging.basicConfig(level=logging.DEBUG)
```

## 📊 Email Analytics

### Track Email Metrics
- **Delivery Rate**: Percentage of emails delivered
- **Open Rate**: Percentage of emails opened
- **Click Rate**: Percentage of links clicked
- **Bounce Rate**: Percentage of failed deliveries

### Email Logging
```python
# Add to email functions
import logging
logger = logging.getLogger(__name__)

def send_email(...):
    logger.info(f"Email sent to {recipients}")
    # ... email sending code
```

## 🔒 Security Best Practices

### Email Security
- **Use TLS**: Always use encrypted connections
- **App Passwords**: Use app-specific passwords
- **Rate Limiting**: Limit email sending frequency
- **Validation**: Validate email addresses before sending

### Template Security
- **XSS Prevention**: Escape user content in templates
- **Link Validation**: Ensure all links are safe
- **Content Filtering**: Filter malicious content

## 📈 Performance Optimization

### Async Email Sending
```python
# Already implemented in app/email.py
send_email(..., sync=False)  # Async (default)
send_email(..., sync=True)   # Sync for testing
```

### Email Queuing
```python
# For high-volume email sending
from celery import Celery

@celery.task
def send_email_async(subject, recipients, ...):
    # Email sending code
```

## 🎯 Production Deployment

### Email Service Providers
- **SendGrid**: Professional email service
- **Mailgun**: Developer-friendly email API
- **Amazon SES**: AWS email service
- **Postmark**: Transactional email service

### Production Configuration
```bash
# Use professional email service
MAIL_SERVER=smtp.sendgrid.net
MAIL_PORT=587
MAIL_USERNAME=apikey
MAIL_PASSWORD=your_sendgrid_api_key
```

---

## 🚀 Quick Start

1. **Configure email settings** in `.env`
2. **Run email tests**: `python test-email.py`
3. **Test with CLI**: `flask email test --type welcome`
4. **Verify in inbox**: Check your email for test messages

**Your email system is now fully functional and ready for production!** 📧✨
