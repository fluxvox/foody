import sqlalchemy as sa
from flask import request, url_for, abort
from app import db
from app.models import Recipe, User, Rating
from app.api import bp
from app.api.auth import token_auth
from app.api.errors import bad_request


@bp.route('/recipes', methods=['GET'])
@token_auth.login_required
def get_recipes():
    """Get paginated list of recipes"""
    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 10, type=int), 100)
    include_author = request.args.get('include_author', False, type=bool)
    
    # Get query with optional filtering
    query = sa.select(Recipe).order_by(Recipe.timestamp.desc())
    
    # Filter by category if provided
    category = request.args.get('category')
    if category:
        query = query.where(Recipe.category == category)
    
    # Filter by difficulty if provided
    difficulty = request.args.get('difficulty')
    if difficulty:
        query = query.where(Recipe.difficulty == difficulty)
    
    # Filter by author if provided
    author_id = request.args.get('author_id', type=int)
    if author_id:
        query = query.where(Recipe.user_id == author_id)
    
    return Recipe.to_collection_dict(query, page, per_page, 'api.get_recipes',
                                   include_author=include_author)


@bp.route('/recipes/<int:id>', methods=['GET'])
@token_auth.login_required
def get_recipe(id):
    """Get specific recipe by ID"""
    recipe = db.get_or_404(Recipe, id)
    include_author = request.args.get('include_author', True, type=bool)
    return recipe.to_dict(include_author=include_author)


@bp.route('/recipes', methods=['POST'])
@token_auth.login_required
def create_recipe():
    """Create a new recipe"""
    data = request.get_json()
    if not data:
        return bad_request('must include recipe data')
    
    # Required fields validation
    required_fields = ['title', 'ingredients', 'instructions']
    for field in required_fields:
        if field not in data or not data[field]:
            return bad_request(f'must include {field} field')
    
    # Create new recipe
    recipe = Recipe()
    recipe.from_dict(data, new_recipe=True)
    recipe.user_id = token_auth.current_user().id
    
    db.session.add(recipe)
    db.session.commit()
    
    return recipe.to_dict(include_author=True), 201, {
        'Location': url_for('api.get_recipe', id=recipe.id)
    }


@bp.route('/recipes/<int:id>', methods=['PUT'])
@token_auth.login_required
def update_recipe(id):
    """Update an existing recipe"""
    recipe = db.get_or_404(Recipe, id)
    current_user = token_auth.current_user()
    
    # Check if user is the author
    if recipe.user_id != current_user.id:
        abort(403)
    
    data = request.get_json()
    if not data:
        return bad_request('must include recipe data')
    
    recipe.from_dict(data, new_recipe=False)
    db.session.commit()
    
    return recipe.to_dict(include_author=True)


@bp.route('/recipes/<int:id>', methods=['DELETE'])
@token_auth.login_required
def delete_recipe(id):
    """Delete a recipe"""
    recipe = db.get_or_404(Recipe, id)
    current_user = token_auth.current_user()
    
    # Check if user is the author
    if recipe.user_id != current_user.id:
        abort(403)
    
    db.session.delete(recipe)
    db.session.commit()
    
    return '', 204


@bp.route('/recipes/search', methods=['GET'])
@token_auth.login_required
def search_recipes():
    """Search recipes by title, description, ingredients, or instructions"""
    query = request.args.get('q', '')
    if not query:
        return bad_request('must include search query parameter')
    
    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 10, type=int), 100)
    include_author = request.args.get('include_author', False, type=bool)
    
    # Use Elasticsearch if available, otherwise fallback to database search
    if Recipe.__searchable__:
        recipes, total = Recipe.search(query, page, per_page)
        if recipes:
            data = {
                'items': [recipe.to_dict(include_author=include_author) for recipe in recipes],
                '_meta': {
                    'page': page,
                    'per_page': per_page,
                    'total_items': total,
                    'total_pages': (total + per_page - 1) // per_page
                },
                '_links': {
                    'self': url_for('api.search_recipes', q=query, page=page, per_page=per_page),
                    'next': url_for('api.search_recipes', q=query, page=page + 1, per_page=per_page) if page * per_page < total else None,
                    'prev': url_for('api.search_recipes', q=query, page=page - 1, per_page=per_page) if page > 1 else None
                }
            }
            return data
    
    # Fallback to database search
    search_query = sa.select(Recipe).where(
        sa.or_(
            Recipe.title.ilike(f'%{query}%'),
            Recipe.description.ilike(f'%{query}%'),
            Recipe.ingredients.ilike(f'%{query}%'),
            Recipe.instructions.ilike(f'%{query}%'),
            Recipe.category.ilike(f'%{query}%')
        )
    ).order_by(Recipe.timestamp.desc())
    
    return Recipe.to_collection_dict(search_query, page, per_page, 'api.search_recipes',
                                   q=query, include_author=include_author)


@bp.route('/recipes/<int:id>/ratings', methods=['GET'])
@token_auth.login_required
def get_recipe_ratings(id):
    """Get all ratings for a specific recipe"""
    recipe = db.get_or_404(Recipe, id)
    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 10, type=int), 100)
    
    query = sa.select(Rating).where(Rating.recipe_id == id).order_by(Rating.timestamp.desc())
    return Rating.to_collection_dict(query, page, per_page, 'api.get_recipe_ratings', id=id)


@bp.route('/recipes/<int:id>/ratings', methods=['POST'])
@token_auth.login_required
def rate_recipe(id):
    """Rate a recipe (1-5 stars)"""
    recipe = db.get_or_404(Recipe, id)
    current_user = token_auth.current_user()
    
    data = request.get_json()
    if not data or 'rating' not in data:
        return bad_request('must include rating field')
    
    rating_value = data['rating']
    if not isinstance(rating_value, int) or rating_value < 1 or rating_value > 5:
        return bad_request('rating must be an integer between 1 and 5')
    
    # Check if user already rated this recipe
    existing_rating = db.session.scalar(sa.select(Rating).where(
        sa.and_(Rating.recipe_id == id, Rating.user_id == current_user.id)))
    
    if existing_rating:
        # Update existing rating
        existing_rating.rating = rating_value
    else:
        # Create new rating
        rating = Rating(recipe_id=id, user_id=current_user.id, rating=rating_value)
        db.session.add(rating)
    
    db.session.commit()
    
    return recipe.to_dict(include_author=True), 201


@bp.route('/recipes/<int:id>/ratings', methods=['DELETE'])
@token_auth.login_required
def delete_recipe_rating(id):
    """Remove user's rating for a recipe"""
    current_user = token_auth.current_user()
    
    rating = db.session.scalar(sa.select(Rating).where(
        sa.and_(Rating.recipe_id == id, Rating.user_id == current_user.id)))
    
    if not rating:
        abort(404)
    
    db.session.delete(rating)
    db.session.commit()
    
    return '', 204


@bp.route('/recipes/categories', methods=['GET'])
@token_auth.login_required
def get_recipe_categories():
    """Get list of available recipe categories"""
    categories = db.session.scalars(
        sa.select(Recipe.category).where(Recipe.category.isnot(None)).distinct()
    ).all()
    
    return {
        'categories': [cat for cat in categories if cat],
        'count': len([cat for cat in categories if cat])
    }


@bp.route('/recipes/difficulties', methods=['GET'])
@token_auth.login_required
def get_recipe_difficulties():
    """Get list of available recipe difficulties"""
    difficulties = db.session.scalars(
        sa.select(Recipe.difficulty).where(Recipe.difficulty.isnot(None)).distinct()
    ).all()
    
    return {
        'difficulties': [diff for diff in difficulties if diff],
        'count': len([diff for diff in difficulties if diff])
    }
