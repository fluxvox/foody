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
                
                # Send welcome email with logo attachment (testing if attachments work)
                from app.email import send_email
                import os
                logo_path = os.path.join(app.root_path, 'static', 'foody-logo.png')
                attachments = []
                
                # Add logo as attachment if it exists
                if os.path.exists(logo_path):
                    with open(logo_path, 'rb') as f:
                        logo_data = f.read()
                    attachments = [('foody-logo.png', 'image/png', logo_data)]
                    click.echo(f"📎 Adding logo attachment from {logo_path}")
                else:
                    click.echo(f"⚠️  Logo not found at {logo_path}")
                
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
                    html_body=None,  # No HTML content to avoid spam filtering
                    attachments=attachments,
                    sync=True
                )
                click.echo("✅ Welcome email sent successfully!")
                
            elif type == 'password-reset':
                # Create a test user
                test_user = User(username='testuser', email=recipient)
                test_user.set_password('testpassword')
                
                # Generate reset token
                token = test_user.get_reset_password_token()
                
                # Send password reset email with simple content (no HTML to avoid spam)
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
                    html_body=None,  # No HTML content to avoid spam filtering
                    sync=True
                )
                click.echo("✅ Password reset email sent successfully!")
                
            elif type == 'recipe-share':
                # Get a recipe from database or create test data
                recipe = db.session.scalar(db.select(Recipe).limit(1))
                if recipe:
                    # Send recipe share email with simple content (no HTML to avoid spam)
                    from app.email import send_email
                    send_email(
                        subject='[Foody] Test Chef shared a recipe with you!',
                        sender=app.config['ADMINS'][0],
                        recipients=[recipient],
                        text_body=f"""Hi there!

Test Chef shared a recipe with you: "{recipe.title}"

Recipe Details:
- Prep Time: {recipe.prep_time} minutes
- Servings: {recipe.servings}
- Rating: No ratings yet

View the full recipe: https://lab10.ifalabs.org/recipe/{recipe.id}

Happy cooking!

The Foody Team""",
                        html_body=None,  # No HTML content to avoid spam filtering
                        sync=True
                    )
                    click.echo("✅ Recipe share email sent successfully!")
                else:
                    click.echo("❌ No recipes found in database. Create a recipe first.")
                    
            elif type == 'rating':
                # Get a recipe and user from database
                recipe = db.session.scalar(db.select(Recipe).limit(1))
                rating_user = db.session.scalar(db.select(User).limit(1))
                if recipe and rating_user:
                    # Send rating notification email with simple content (no HTML to avoid spam)
                    from app.email import send_email
                    send_email(
                        subject='[Foody] Someone rated your recipe!',
                        sender=app.config['ADMINS'][0],
                        recipients=[recipe.author.email],
                        text_body=f"""Dear {recipe.author.username},

Great news! {rating_user.username} just rated your recipe "{recipe.title}" with 5 stars!

Recipe: {recipe.title}
Rating: 5/5 stars
Rated by: {rating_user.username}

Keep up the great cooking!

The Foody Team""",
                        html_body=None,  # No HTML content to avoid spam filtering
                        sync=True
                    )
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
                html_body=None,
                sync=True
            )
            click.echo("✅ Welcome email sent")
            
            # Password reset email
            click.echo("Sending password reset email...")
            token = test_user.get_reset_password_token()
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
                html_body=None,
                sync=True
            )
            click.echo("✅ Password reset email sent")
            
            # Recipe share email (if recipe exists)
            recipe = db.session.scalar(db.select(Recipe).limit(1))
            if recipe:
                click.echo("Sending recipe share email...")
                send_email(
                    subject='[Foody] Test Chef shared a recipe with you!',
                    sender=app.config['ADMINS'][0],
                    recipients=[recipient],
                    text_body=f"""Hi there!

Test Chef shared a recipe with you: "{recipe.title}"

Recipe Details:
- Prep Time: {recipe.prep_time} minutes
- Servings: {recipe.servings}
- Rating: No ratings yet

View the full recipe: https://lab10.ifalabs.org/recipe/{recipe.id}

Happy cooking!

The Foody Team""",
                    html_body=None,
                    sync=True
                )
                click.echo("✅ Recipe share email sent")
            else:
                click.echo("⚠️  No recipes found, skipping recipe share email")
            
            # Rating notification (if recipe and user exist)
            rating_user = db.session.scalar(db.select(User).limit(1))
            if recipe and rating_user:
                click.echo("Sending rating notification email...")
                send_email(
                    subject='[Foody] Someone rated your recipe!',
                    sender=app.config['ADMINS'][0],
                    recipients=[recipe.author.email],
                    text_body=f"""Dear {recipe.author.username},

Great news! {rating_user.username} just rated your recipe "{recipe.title}" with 5 stars!

Recipe: {recipe.title}
Rating: 5/5 stars
Rated by: {rating_user.username}

Keep up the great cooking!

The Foody Team""",
                    html_body=None,
                    sync=True
                )
                click.echo("✅ Rating notification email sent")
            else:
                click.echo("⚠️  No recipes or users found, skipping rating notification email")
                
            click.echo("\n🎉 All available emails sent successfully!")
            
        except Exception as e:
            click.echo(f"❌ Error sending emails: {e}")
