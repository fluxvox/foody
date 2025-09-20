import os
from flask import Blueprint, current_app
import click
from app import create_app, db
from app.models import User, Recipe
from app.auth.welcome_email import send_welcome_email, send_recipe_share_email, send_rating_notification_email
from app.auth.email import send_password_reset_email

bp = Blueprint('cli', __name__, cli_group=None)


@bp.cli.group()
def translate():
    """Translation and localization commands."""
    pass


@translate.command()
@click.argument('lang')
def init(lang):
    """Initialize a new language."""
    if os.system('pybabel extract -F babel.cfg -k _l -o messages.pot .'):
        raise RuntimeError('extract command failed')
    if os.system(
            'pybabel init -i messages.pot -d app/translations -l ' + lang):
        raise RuntimeError('init command failed')
    os.remove('messages.pot')


@translate.command()
def update():
    """Update all languages."""
    if os.system('pybabel extract -F babel.cfg -k _l -o messages.pot .'):
        raise RuntimeError('extract command failed')
    if os.system('pybabel update -i messages.pot -d app/translations'):
        raise RuntimeError('update command failed')
    os.remove('messages.pot')


@translate.command()
def compile():
    """Compile all languages."""
    if os.system('pybabel compile -d app/translations'):
        raise RuntimeError('compile command failed')


@bp.cli.group()
def email():
    """Email testing and management commands."""
    pass


@email.command()
@click.option('--recipient', '-r', default='test@example.com', help='Email recipient')
@click.option('--type', '-t', type=click.Choice(['welcome', 'password-reset', 'recipe-share', 'rating']), 
              default='welcome', help='Email type to test')
def test(recipient, type):
    """Test email functionality."""
    app = create_app()
    
    with app.app_context():
        click.echo(f"🧪 Testing {type} email to {recipient}...")
        
        try:
            if type == 'welcome':
                # Create a test user
                test_user = User(username='testuser', email=recipient)
                test_user.set_password('testpassword')
                
                # Send welcome email with simple content (no templates)
                from app.email import send_email
                send_email(
                    subject='[Foody] Welcome to Foody!',
                    sender=app.config['ADMINS'][0],
                    recipients=[recipient],
                    text_body=f"""Dear {test_user.username},

Welcome to Foody! We're excited to have you join our community of food enthusiasts.

🚀 Get Started:
- Share Recipes: Upload your favorite recipes with photos and detailed instructions
- Discover New Dishes: Browse recipes from our community
- Rate & Review: Help others find the best recipes with your ratings
- Follow Chefs: Connect with other food lovers

Start cooking: https://lab10.ifalabs.org

Happy cooking!

The Foody Team""",
                    html_body=f"""<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background-color: #f8f9fa; padding: 30px 20px; text-align: center; border-radius: 8px 8px 0 0; }}
        .header h1 {{ color: #e74c3c; margin: 0; font-size: 28px; }}
        .content {{ background-color: #ffffff; padding: 30px 20px; border: 1px solid #dee2e6; }}
        .cta-button {{ display: inline-block; background-color: #e74c3c; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; margin: 20px 0; }}
        .footer {{ background-color: #e9ecef; padding: 20px; text-align: center; border-radius: 0 0 8px 8px; font-size: 14px; color: #6c757d; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🍳 Welcome to Foody!</h1>
        <p>Your recipe sharing platform</p>
    </div>
    <div class="content">
        <p>Dear {test_user.username},</p>
        <p>Welcome to Foody! We're excited to have you join our community of food enthusiasts.</p>
        <div style="text-align: center;">
            <a href="https://lab10.ifalabs.org" class="cta-button">Start Cooking! 🍳</a>
        </div>
        <p>Happy cooking!</p>
        <p><strong>The Foody Team</strong></p>
    </div>
    <div class="footer">
        <p>You received this email because you signed up for Foody.</p>
        <p>&copy; 2024 Foody. All rights reserved.</p>
    </div>
</body>
</html>""",
                    sync=True
                )
                click.echo("✅ Welcome email sent successfully!")
                
            elif type == 'password-reset':
                # Create a test user
                test_user = User(username='testuser', email=recipient)
                test_user.set_password('testpassword')
                
                # Generate reset token
                token = test_user.get_reset_password_token()
                
                # Send password reset email with simple content
                from app.email import send_email
                send_email(
                    subject='[Foody] Reset Your Password',
                    sender=app.config['ADMINS'][0],
                    recipients=[recipient],
                    text_body=f"""Dear {test_user.username},

To reset your password click on the following link:

https://lab10.ifalabs.org/auth/reset_password/{token}

If you have not requested a password reset simply ignore this message.

Sincerely,

The Foody Team""",
                    html_body=f"""<!DOCTYPE html>
<html>
<body>
    <p>Dear {test_user.username},</p>
    <p>To reset your password <a href="https://lab10.ifalabs.org/auth/reset_password/{token}">click here</a>.</p>
    <p>Alternatively, you can paste the following link in your browser's address bar:</p>
    <p>https://lab10.ifalabs.org/auth/reset_password/{token}</p>
    <p>If you have not requested a password reset simply ignore this message.</p>
    <p>Sincerely,</p>
    <p>The Foody Team</p>
</body>
</html>""",
                    sync=True
                )
                click.echo("✅ Password reset email sent successfully!")
                
            elif type == 'recipe-share':
                # Get a recipe from database or create test data
                recipe = db.session.scalar(db.select(Recipe).limit(1))
                if recipe:
                    send_recipe_share_email(recipe, 'Test Chef', recipient)
                    click.echo("✅ Recipe share email sent successfully!")
                else:
                    click.echo("❌ No recipes found in database. Create a recipe first.")
                    
            elif type == 'rating':
                # Get a recipe and user from database
                recipe = db.session.scalar(db.select(Recipe).limit(1))
                rating_user = db.session.scalar(db.select(User).limit(1))
                if recipe and rating_user:
                    send_rating_notification_email(recipe, rating_user, 5)
                    click.echo("✅ Rating notification email sent successfully!")
                else:
                    click.echo("❌ No recipes or users found in database.")
                    
        except Exception as e:
            click.echo(f"❌ Failed to send email: {e}")


@email.command()
def config():
    """Show email configuration."""
    app = create_app()
    
    with app.app_context():
        click.echo("📧 Email Configuration:")
        click.echo("=" * 40)
        click.echo(f"Mail Server: {current_app.config.get('MAIL_SERVER', 'Not configured')}")
        click.echo(f"Mail Port: {current_app.config.get('MAIL_PORT', 'Not configured')}")
        click.echo(f"Mail TLS: {current_app.config.get('MAIL_USE_TLS', 'Not configured')}")
        click.echo(f"Mail Username: {current_app.config.get('MAIL_USERNAME', 'Not configured')}")
        click.echo(f"Admins: {current_app.config.get('ADMINS', 'Not configured')}")


@email.command()
@click.option('--recipient', '-r', default='test@example.com', help='Email recipient')
def send_all(recipient):
    """Send all email types for testing."""
    app = create_app()
    
    with app.app_context():
        click.echo(f"📧 Sending all email types to {recipient}...")
        
        # Test user
        test_user = User(username='testuser', email=recipient)
        test_user.set_password('testpassword')
        
        try:
            # Welcome email
            click.echo("Sending welcome email...")
            send_welcome_email(test_user)
            click.echo("✅ Welcome email sent")
            
            # Password reset email
            click.echo("Sending password reset email...")
            send_password_reset_email(test_user)
            click.echo("✅ Password reset email sent")
            
            # Recipe share email (if recipe exists)
            recipe = db.session.scalar(db.select(Recipe).limit(1))
            if recipe:
                click.echo("Sending recipe share email...")
                send_recipe_share_email(recipe, 'Test Chef', recipient)
                click.echo("✅ Recipe share email sent")
            else:
                click.echo("⚠️  No recipes found, skipping recipe share email")
            
            # Rating notification (if recipe and user exist)
            rating_user = db.session.scalar(db.select(User).limit(1))
            if recipe and rating_user:
                click.echo("Sending rating notification email...")
                send_rating_notification_email(recipe, rating_user, 5)
                click.echo("✅ Rating notification email sent")
            else:
                click.echo("⚠️  No recipes or users found, skipping rating notification email")
                
            click.echo("\n🎉 All available emails sent successfully!")
            
        except Exception as e:
            click.echo(f"❌ Error sending emails: {e}")
