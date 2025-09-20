from flask import current_app
import sqlalchemy as sa


def add_to_index(index, model):
    # Elasticsearch disabled - no-op for local deployment
    pass


def remove_from_index(index, model):
    # Elasticsearch disabled - no-op for local deployment
    pass


def query_index(index, query, page, per_page):
    # Fallback to database search when Elasticsearch is not available
    if index == 'recipe':
        # Import here to avoid circular import
        from app import db
        from app.models import Recipe
        
        # Use database LIKE search as fallback
        search_query = f"%{query}%"
        recipes = db.session.scalars(
            sa.select(Recipe).where(
                sa.or_(
                    Recipe.title.like(search_query),
                    Recipe.description.like(search_query),
                    Recipe.ingredients.like(search_query),
                    Recipe.instructions.like(search_query)
                )
            ).order_by(Recipe.timestamp.desc())
        ).all()
        
        # Simple pagination
        start = (page - 1) * per_page
        end = start + per_page
        paginated_recipes = recipes[start:end]
        
        ids = [recipe.id for recipe in paginated_recipes]
        total = len(recipes)
        
        return ids, total
    
    return [], 0
