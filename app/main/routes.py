from datetime import datetime, timezone
from flask import render_template, flash, redirect, url_for, request, g, \
    current_app
from flask_login import current_user, login_required
from flask_babel import _, get_locale
import sqlalchemy as sa
import json
from langdetect import detect, LangDetectException
from app import db
from app.main.forms import EditProfileForm, EmptyForm, PostForm, RecipeForm, SearchForm, \
    MessageForm, CommentForm
from app.models import User, Post, Recipe, Message, Notification, Rating, Comment
from app.translate import translate
from app.main import bp


@bp.before_app_request
def before_request():
    if current_user.is_authenticated:
        current_user.last_seen = datetime.now(timezone.utc)
        db.session.commit()
        g.search_form = SearchForm()
    g.locale = str(get_locale())


@bp.route('/')
@bp.route('/index')
@login_required
def index():
    page = request.args.get('page', 1, type=int)
    query = sa.select(Recipe).order_by(Recipe.timestamp.desc())
    recipes = db.paginate(query, page=page,
                         per_page=current_app.config['POSTS_PER_PAGE'],
                         error_out=False)
    next_url = url_for('main.index', page=recipes.next_num) \
        if recipes.has_next else None
    prev_url = url_for('main.index', page=recipes.prev_num) \
        if recipes.has_prev else None
    return render_template('index.html', title=_('All Recipes'),
                           recipes=recipes.items, next_url=next_url,
                           prev_url=prev_url)


@bp.route('/following')
@login_required
def following():
    page = request.args.get('page', 1, type=int)
    recipes = db.paginate(current_user.following_recipes(), page=page,
                         per_page=current_app.config['POSTS_PER_PAGE'],
                         error_out=False)
    next_url = url_for('main.following', page=recipes.next_num) \
        if recipes.has_next else None
    prev_url = url_for('main.following', page=recipes.prev_num) \
        if recipes.has_prev else None
    return render_template('index.html', title=_('Following'),
                           recipes=recipes.items, next_url=next_url,
                           prev_url=prev_url)




@bp.route('/share', methods=['GET', 'POST'])
@login_required
def share_recipe():
    form = RecipeForm()
    if form.validate_on_submit():
        try:
            language = detect(form.title.data + ' ' + form.description.data)
        except LangDetectException:
            language = ''
        # Parse ingredients text into structured format
        ingredients_list = []
        for line in form.ingredients.data.strip().split('\n'):
            line = line.strip()
            if line:
                # Try to parse "amount unit ingredient" format
                parts = line.split(' ', 2)
                if len(parts) >= 3:
                    ingredients_list.append({
                        'amount': parts[0],
                        'unit': parts[1],
                        'ingredient': parts[2]
                    })
                elif len(parts) == 2:
                    ingredients_list.append({
                        'amount': parts[0],
                        'unit': '',
                        'ingredient': parts[1]
                    })
                else:
                    ingredients_list.append({
                        'amount': '',
                        'unit': '',
                        'ingredient': line
                    })
        
        recipe = Recipe(
            title=form.title.data,
            description=form.description.data,
            ingredients=json.dumps(ingredients_list),
            instructions=form.instructions.data,
            prep_time=form.prep_time.data,
            cook_time=form.cook_time.data,
            servings=form.servings.data,
            difficulty=form.difficulty.data,
            category=form.category.data,
            image_url=form.image_url.data,
            author=current_user,
            language=language
        )
        db.session.add(recipe)
        db.session.commit()
        flash(_('Your recipe has been shared!'))
        return redirect(url_for('main.index'))
    return render_template('share_recipe.html', title=_('Share Recipe'), form=form)


@bp.route('/recipe/<int:id>', methods=['GET', 'POST'])
@login_required
def recipe_detail(id):
    recipe = db.first_or_404(sa.select(Recipe).where(Recipe.id == id))
    form = CommentForm()
    if form.validate_on_submit():
        comment = Comment(body=form.body.data, author=current_user, recipe=recipe)
        db.session.add(comment)
        db.session.commit()
        flash(_('Your comment has been posted!'))
        return redirect(url_for('main.recipe_detail', id=id))
    
    # Get comments for this recipe
    page = request.args.get('page', 1, type=int)
    comments = db.paginate(recipe.comments.select().order_by(Comment.timestamp.desc()),
                          page=page, per_page=10, error_out=False)
    
    return render_template('recipe_detail.html', title=recipe.title, recipe=recipe,
                          form=form, comments=comments.items)


@bp.route('/recipe/<int:id>/rate', methods=['POST'])
@login_required
def rate_recipe(id):
    recipe = db.first_or_404(sa.select(Recipe).where(Recipe.id == id))
    rating_value = request.form.get('rating')
    
    if not rating_value or not rating_value.isdigit():
        flash(_('Invalid rating value.'))
        return redirect(url_for('main.recipe_detail', id=id))
    
    rating_value = int(rating_value)
    if rating_value < 1 or rating_value > 5:
        flash(_('Rating must be between 1 and 5 stars.'))
        return redirect(url_for('main.recipe_detail', id=id))
    
    # Check if user already rated this recipe
    existing_rating = db.session.scalar(sa.select(Rating).where(
        sa.and_(Rating.recipe_id == id, Rating.user_id == current_user.id)))
    
    if existing_rating:
        # Update existing rating
        existing_rating.rating = rating_value
        existing_rating.timestamp = datetime.now(timezone.utc)
        flash(_('Your rating has been updated!'))
    else:
        # Create new rating
        rating = Rating(rating=rating_value, user=current_user, recipe=recipe)
        db.session.add(rating)
        flash(_('Thank you for rating this recipe!'))
    
    db.session.commit()
    return redirect(url_for('main.recipe_detail', id=id))


@bp.route('/recipe/<int:id>/edit', methods=['GET', 'POST'])
@login_required
def edit_recipe(id):
    recipe = db.first_or_404(sa.select(Recipe).where(Recipe.id == id))
    # Check if user is the author of the recipe
    if recipe.author != current_user:
        flash(_('You can only edit your own recipes.'))
        return redirect(url_for('main.recipe_detail', id=id))
    
    form = RecipeForm()
    if form.validate_on_submit():
        try:
            language = detect(form.title.data + ' ' + form.description.data)
        except LangDetectException:
            language = ''
        
        # Parse ingredients text into structured format
        ingredients_list = []
        for line in form.ingredients.data.strip().split('\n'):
            line = line.strip()
            if line:
                # Try to parse "amount unit ingredient" format
                parts = line.split(' ', 2)
                if len(parts) >= 3:
                    ingredients_list.append({
                        'amount': parts[0],
                        'unit': parts[1],
                        'ingredient': parts[2]
                    })
                elif len(parts) == 2:
                    ingredients_list.append({
                        'amount': parts[0],
                        'unit': '',
                        'ingredient': parts[1]
                    })
                else:
                    ingredients_list.append({
                        'amount': '',
                        'unit': '',
                        'ingredient': line
                    })
        
        # Update recipe fields
        recipe.title = form.title.data
        recipe.description = form.description.data
        recipe.ingredients = json.dumps(ingredients_list)
        recipe.instructions = form.instructions.data
        recipe.prep_time = form.prep_time.data
        recipe.cook_time = form.cook_time.data
        recipe.servings = form.servings.data
        recipe.difficulty = form.difficulty.data
        recipe.category = form.category.data
        recipe.image_url = form.image_url.data
        recipe.language = language
        
        db.session.commit()
        flash(_('Your recipe has been updated!'))
        return redirect(url_for('main.recipe_detail', id=id))
    elif request.method == 'GET':
        # Pre-populate form with existing recipe data
        form.title.data = recipe.title
        form.description.data = recipe.description
        # Convert ingredients back to text format for editing
        ingredients_text = []
        for ingredient in recipe.get_ingredients_list():
            if ingredient.get('amount') and ingredient.get('unit'):
                ingredients_text.append(f"{ingredient['amount']} {ingredient['unit']} {ingredient.get('ingredient', '')}")
            elif ingredient.get('amount'):
                ingredients_text.append(f"{ingredient['amount']} {ingredient.get('ingredient', '')}")
            else:
                ingredients_text.append(ingredient.get('ingredient', ''))
        form.ingredients.data = '\n'.join(ingredients_text)
        form.instructions.data = recipe.instructions
        form.prep_time.data = recipe.prep_time
        form.cook_time.data = recipe.cook_time
        form.servings.data = recipe.servings
        form.difficulty.data = recipe.difficulty
        form.category.data = recipe.category
        form.image_url.data = recipe.image_url
    
    return render_template('edit_recipe.html', title=_('Edit Recipe'), form=form, recipe=recipe)


@bp.route('/recipe/<int:id>/delete', methods=['POST'])
@login_required
def delete_recipe(id):
    recipe = db.first_or_404(sa.select(Recipe).where(Recipe.id == id))
    # Check if user is the author of the recipe
    if recipe.author != current_user:
        flash(_('You can only delete your own recipes.'))
        return redirect(url_for('main.recipe_detail', id=id))
    
    # Delete the recipe
    db.session.delete(recipe)
    db.session.commit()
    flash(_('Your recipe has been deleted.'))
    return redirect(url_for('main.index'))


@bp.route('/user/<username>')
@login_required
def user(username):
    user = db.first_or_404(sa.select(User).where(User.username == username))
    page = request.args.get('page', 1, type=int)
    query = user.recipes.select().order_by(Recipe.timestamp.desc())
    recipes = db.paginate(query, page=page,
                         per_page=current_app.config['POSTS_PER_PAGE'],
                         error_out=False)
    next_url = url_for('main.user', username=user.username,
                       page=recipes.next_num) if recipes.has_next else None
    prev_url = url_for('main.user', username=user.username,
                       page=recipes.prev_num) if recipes.has_prev else None
    form = EmptyForm()
    return render_template('user.html', user=user, recipes=recipes.items,
                           next_url=next_url, prev_url=prev_url, form=form)


@bp.route('/user/<username>/popup')
@login_required
def user_popup(username):
    user = db.first_or_404(sa.select(User).where(User.username == username))
    form = EmptyForm()
    return render_template('user_popup.html', user=user, form=form)


@bp.route('/edit_profile', methods=['GET', 'POST'])
@login_required
def edit_profile():
    form = EditProfileForm(current_user.username)
    if form.validate_on_submit():
        current_user.username = form.username.data
        current_user.about_me = form.about_me.data
        db.session.commit()
        flash(_('Your changes have been saved.'))
        return redirect(url_for('main.edit_profile'))
    elif request.method == 'GET':
        form.username.data = current_user.username
        form.about_me.data = current_user.about_me
    return render_template('edit_profile.html', title=_('Edit Profile'),
                           form=form)


@bp.route('/follow/<username>', methods=['POST'])
@login_required
def follow(username):
    form = EmptyForm()
    if form.validate_on_submit():
        user = db.session.scalar(
            sa.select(User).where(User.username == username))
        if user is None:
            flash(_('User %(username)s not found.', username=username))
            return redirect(url_for('main.index'))
        if user == current_user:
            flash(_('You cannot follow yourself!'))
            return redirect(url_for('main.user', username=username))
        current_user.follow(user)
        db.session.commit()
        flash(_('You are following %(username)s!', username=username))
        return redirect(url_for('main.user', username=username))
    else:
        return redirect(url_for('main.index'))


@bp.route('/unfollow/<username>', methods=['POST'])
@login_required
def unfollow(username):
    form = EmptyForm()
    if form.validate_on_submit():
        user = db.session.scalar(
            sa.select(User).where(User.username == username))
        if user is None:
            flash(_('User %(username)s not found.', username=username))
            return redirect(url_for('main.index'))
        if user == current_user:
            flash(_('You cannot unfollow yourself!'))
            return redirect(url_for('main.user', username=username))
        current_user.unfollow(user)
        db.session.commit()
        flash(_('You are not following %(username)s.', username=username))
        return redirect(url_for('main.user', username=username))
    else:
        return redirect(url_for('main.index'))


@bp.route('/translate', methods=['POST'])
@login_required
def translate_text():
    data = request.get_json()
    return {'text': translate(data['text'],
                              data['source_language'],
                              data['dest_language'])}


@bp.route('/search')
@login_required
def search():
    if not g.search_form.validate():
        return redirect(url_for('main.index'))
    page = request.args.get('page', 1, type=int)
    search_query = g.search_form.q.data
    
    # Try Elasticsearch search first
    recipes, total = Recipe.search(search_query, page, current_app.config['POSTS_PER_PAGE'])
    
    # If no results from Elasticsearch (likely not configured), fall back to database search
    if total == 0:
        # Simple database search across recipe fields (case-insensitive)
        search_filter = sa.or_(
            Recipe.title.ilike(f'%{search_query}%'),
            Recipe.description.ilike(f'%{search_query}%'),
            Recipe.instructions.ilike(f'%{search_query}%'),
            Recipe.ingredients.ilike(f'%{search_query}%'),
            Recipe.category.ilike(f'%{search_query}%')
        )
        query = sa.select(Recipe).where(search_filter).order_by(Recipe.timestamp.desc())
        recipes_paginated = db.paginate(query, page=page,
                                       per_page=current_app.config['POSTS_PER_PAGE'],
                                       error_out=False)
        recipes = recipes_paginated.items
        total = recipes_paginated.total
    
    next_url = url_for('main.search', q=search_query, page=page + 1) \
        if total > page * current_app.config['POSTS_PER_PAGE'] else None
    prev_url = url_for('main.search', q=search_query, page=page - 1) \
        if page > 1 else None
    return render_template('search.html', title=_('Search Results'), recipes=recipes,
                           next_url=next_url, prev_url=prev_url)




@bp.route('/export_posts')
@login_required
def export_posts():
    if current_user.get_task_in_progress('export_posts'):
        flash(_('An export task is currently in progress'))
    else:
        current_user.launch_task('export_posts', _('Exporting posts...'))
        db.session.commit()
    return redirect(url_for('main.user', username=current_user.username))


@bp.route('/notifications')
@login_required
def notifications():
    since = request.args.get('since', 0.0, type=float)
    query = current_user.notifications.select().where(
        Notification.timestamp > since).order_by(Notification.timestamp.asc())
    notifications = db.session.scalars(query)
    return [{
        'name': n.name,
        'data': n.get_data(),
        'timestamp': n.timestamp
    } for n in notifications]
