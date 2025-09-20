"""
Welcome email functionality for new users
"""

from flask import render_template, current_app
from flask_babel import _
from app.email import send_email


def send_welcome_email(user):
    """Send welcome email to new user"""
    send_email(
        subject=_('[Foody] Welcome to Foody!'),
        sender=current_app.config['ADMINS'][0],
        recipients=[user.email],
        text_body=render_template('email/welcome.txt', user=user),
        html_body=render_template('email/welcome.html', user=user)
    )


def send_recipe_share_email(recipe, sender_name, recipient_email):
    """Send recipe sharing email"""
    send_email(
        subject=_('[Foody] {} shared a recipe with you!').format(sender_name),
        sender=current_app.config['ADMINS'][0],
        recipients=[recipient_email],
        text_body=render_template('email/share_recipe.txt', 
                                 recipe=recipe, sender_name=sender_name),
        html_body=render_template('email/share_recipe.html', 
                                 recipe=recipe, sender_name=sender_name)
    )


def send_rating_notification_email(recipe, rating_user, rating):
    """Send notification email when someone rates your recipe"""
    if recipe.author.email != rating_user.email:  # Don't notify yourself
        send_email(
            subject=_('[Foody] Someone rated your recipe!'),
            sender=current_app.config['ADMINS'][0],
            recipients=[recipe.author.email],
            text_body=render_template('email/rating_notification.txt', 
                                     recipe=recipe, rating_user=rating_user, rating=rating),
            html_body=render_template('email/rating_notification.html', 
                                     recipe=recipe, rating_user=rating_user, rating=rating)
        )
