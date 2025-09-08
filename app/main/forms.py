from flask import request
from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField, TextAreaField, IntegerField, SelectField, FieldList, FormField
from wtforms.validators import ValidationError, DataRequired, Length, Optional, NumberRange
from wtforms.widgets import html_params
import sqlalchemy as sa
from flask_babel import _, lazy_gettext as _l
from app import db
from app.models import User


class EditProfileForm(FlaskForm):
    username = StringField(_l('Username'), validators=[DataRequired()])
    about_me = TextAreaField(_l('About me'),
                             validators=[Length(min=0, max=140)])
    submit = SubmitField(_l('Submit'))

    def __init__(self, original_username, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.original_username = original_username

    def validate_username(self, username):
        if username.data != self.original_username:
            user = db.session.scalar(sa.select(User).where(
                User.username == username.data))
            if user is not None:
                raise ValidationError(_('Please use a different username.'))


class EmptyForm(FlaskForm):
    submit = SubmitField('Submit')


class IngredientForm(FlaskForm):
    amount = StringField(_l('Amount'), validators=[Optional(), Length(max=20)])
    unit = SelectField(_l('Unit'), choices=[
        ('', _l('Select unit')),
        ('cup', _l('cup')),
        ('cups', _l('cups')),
        ('tbsp', _l('tablespoon')),
        ('tbsp', _l('tablespoons')),
        ('tsp', _l('teaspoon')),
        ('tsp', _l('teaspoons')),
        ('ml', _l('ml')),
        ('l', _l('liter')),
        ('g', _l('grams')),
        ('kg', _l('kg')),
        ('oz', _l('ounces')),
        ('lb', _l('pounds')),
        ('piece', _l('piece')),
        ('pieces', _l('pieces')),
        ('clove', _l('clove')),
        ('cloves', _l('cloves')),
        ('pinch', _l('pinch')),
        ('dash', _l('dash')),
        ('to taste', _l('to taste')),
        ('as needed', _l('as needed'))
    ], validators=[Optional()])
    ingredient = StringField(_l('Ingredient'), validators=[DataRequired(), Length(max=100)])


class RecipeForm(FlaskForm):
    title = StringField(_l('Recipe Title'), validators=[
        DataRequired(), Length(min=1, max=100)])
    description = TextAreaField(_l('Description'), validators=[
        Optional(), Length(min=0, max=500)])
    ingredients = TextAreaField(_l('Ingredients (one per line, format: amount unit ingredient)'), validators=[
        DataRequired(), Length(min=1, max=2000)])
    instructions = TextAreaField(_l('Instructions'), validators=[
        DataRequired(), Length(min=1, max=5000)])
    prep_time = IntegerField(_l('Prep Time (minutes)'), validators=[
        Optional(), NumberRange(min=0, max=1440)])
    cook_time = IntegerField(_l('Cook Time (minutes)'), validators=[
        Optional(), NumberRange(min=0, max=1440)])
    servings = IntegerField(_l('Servings'), validators=[
        Optional(), NumberRange(min=1, max=100)])
    difficulty = SelectField(_l('Difficulty'), choices=[
        ('', _l('Select difficulty')),
        ('Easy', _l('Easy')),
        ('Medium', _l('Medium')),
        ('Hard', _l('Hard'))
    ], validators=[Optional()])
    category = SelectField(_l('Category'), choices=[
        ('', _l('Select category')),
        ('Breakfast', _l('Breakfast')),
        ('Lunch', _l('Lunch')),
        ('Dinner', _l('Dinner')),
        ('Dessert', _l('Dessert')),
        ('Snack', _l('Snack')),
        ('Appetizer', _l('Appetizer')),
        ('Beverage', _l('Beverage')),
        ('Other', _l('Other'))
    ], validators=[Optional()])
    image_url = StringField(_l('Image URL (optional)'), validators=[
        Optional(), Length(min=0, max=200)])
    submit = SubmitField(_l('Share Recipe'))

# Keep PostForm for backward compatibility
class PostForm(FlaskForm):
    post = TextAreaField(_l('Say something'), validators=[
        DataRequired(), Length(min=1, max=140)])
    submit = SubmitField(_l('Submit'))


class SearchForm(FlaskForm):
    q = StringField(_l('Search'), validators=[DataRequired()])

    def __init__(self, *args, **kwargs):
        if 'formdata' not in kwargs:
            kwargs['formdata'] = request.args
        if 'meta' not in kwargs:
            kwargs['meta'] = {'csrf': False}
        super(SearchForm, self).__init__(*args, **kwargs)


class MessageForm(FlaskForm):
    message = TextAreaField(_l('Message'), validators=[
        DataRequired(), Length(min=1, max=140)])
    submit = SubmitField(_l('Submit'))
