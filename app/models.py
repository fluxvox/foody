from datetime import datetime, timezone, timedelta
from hashlib import md5
import json
import secrets
from time import time
from typing import Optional
import sqlalchemy as sa
import sqlalchemy.orm as so
from flask import current_app, url_for
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash
import jwt
import redis
import rq
from app import db, login
from app.search import add_to_index, remove_from_index, query_index


class SearchableMixin:
    @classmethod
    def search(cls, expression, page, per_page):
        ids, total = query_index(cls.__tablename__, expression, page, per_page)
        if total == 0:
            return [], 0
        when = []
        for i in range(len(ids)):
            when.append((ids[i], i))
        query = sa.select(cls).where(cls.id.in_(ids)).order_by(
            db.case(*when, value=cls.id))
        return db.session.scalars(query), total

    @classmethod
    def before_commit(cls, session):
        session._changes = {
            'add': list(session.new),
            'update': list(session.dirty),
            'delete': list(session.deleted)
        }

    @classmethod
    def after_commit(cls, session):
        for obj in session._changes['add']:
            if isinstance(obj, SearchableMixin):
                add_to_index(obj.__tablename__, obj)
        for obj in session._changes['update']:
            if isinstance(obj, SearchableMixin):
                add_to_index(obj.__tablename__, obj)
        for obj in session._changes['delete']:
            if isinstance(obj, SearchableMixin):
                remove_from_index(obj.__tablename__, obj)
        session._changes = None

    @classmethod
    def reindex(cls):
        for obj in db.session.scalars(sa.select(cls)):
            add_to_index(cls.__tablename__, obj)


db.event.listen(db.session, 'before_commit', SearchableMixin.before_commit)
db.event.listen(db.session, 'after_commit', SearchableMixin.after_commit)


class PaginatedAPIMixin(object):
    @staticmethod
    def to_collection_dict(query, page, per_page, endpoint, **kwargs):
        resources = db.paginate(query, page=page, per_page=per_page,
                                error_out=False)
        data = {
            'items': [item.to_dict() for item in resources.items],
            '_meta': {
                'page': page,
                'per_page': per_page,
                'total_pages': resources.pages,
                'total_items': resources.total
            },
            '_links': {
                'self': url_for(endpoint, page=page, per_page=per_page,
                                **kwargs),
                'next': url_for(endpoint, page=page + 1, per_page=per_page,
                                **kwargs) if resources.has_next else None,
                'prev': url_for(endpoint, page=page - 1, per_page=per_page,
                                **kwargs) if resources.has_prev else None
            }
        }
        return data


followers = sa.Table(
    'followers',
    db.metadata,
    sa.Column('follower_id', sa.Integer, sa.ForeignKey('user.id'),
              primary_key=True),
    sa.Column('followed_id', sa.Integer, sa.ForeignKey('user.id'),
              primary_key=True)
)


class User(PaginatedAPIMixin, UserMixin, db.Model):
    id: so.Mapped[int] = so.mapped_column(primary_key=True)
    username: so.Mapped[str] = so.mapped_column(sa.String(64), index=True,
                                                unique=True)
    email: so.Mapped[str] = so.mapped_column(sa.String(120), index=True,
                                             unique=True)
    password_hash: so.Mapped[Optional[str]] = so.mapped_column(sa.String(256))
    about_me: so.Mapped[Optional[str]] = so.mapped_column(sa.String(140))
    last_seen: so.Mapped[Optional[datetime]] = so.mapped_column(
        default=lambda: datetime.now(timezone.utc))
    token: so.Mapped[Optional[str]] = so.mapped_column(
        sa.String(32), index=True, unique=True)
    token_expiration: so.Mapped[Optional[datetime]]

    recipes: so.WriteOnlyMapped['Recipe'] = so.relationship(
        back_populates='author')
    # Keep posts for backward compatibility
    posts: so.WriteOnlyMapped['Recipe'] = so.relationship(
        back_populates='author', overlaps="recipes")
    following: so.WriteOnlyMapped['User'] = so.relationship(
        secondary=followers, primaryjoin=(followers.c.follower_id == id),
        secondaryjoin=(followers.c.followed_id == id),
        back_populates='followers')
    followers: so.WriteOnlyMapped['User'] = so.relationship(
        secondary=followers, primaryjoin=(followers.c.followed_id == id),
        secondaryjoin=(followers.c.follower_id == id),
        back_populates='following')
    messages_sent: so.WriteOnlyMapped['Message'] = so.relationship(
        foreign_keys='Message.sender_id', back_populates='author')
    messages_received: so.WriteOnlyMapped['Message'] = so.relationship(
        foreign_keys='Message.recipient_id', back_populates='recipient')
    ratings: so.WriteOnlyMapped['Rating'] = so.relationship(
        back_populates='user')
    comments: so.WriteOnlyMapped['Comment'] = so.relationship(
        back_populates='author')
    notifications: so.WriteOnlyMapped['Notification'] = so.relationship(
        back_populates='user')
    tasks: so.WriteOnlyMapped['Task'] = so.relationship(back_populates='user')

    def __repr__(self):
        return '<User {}>'.format(self.username)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def avatar(self, size):
        digest = md5(self.email.lower().encode('utf-8')).hexdigest()
        return f'https://www.gravatar.com/avatar/{digest}?d=identicon&s={size}'

    def follow(self, user):
        if not self.is_following(user):
            self.following.add(user)

    def unfollow(self, user):
        if self.is_following(user):
            self.following.remove(user)

    def is_following(self, user):
        query = self.following.select().where(User.id == user.id)
        return db.session.scalar(query) is not None

    def followers_count(self):
        query = sa.select(sa.func.count()).select_from(
            self.followers.select().subquery())
        return db.session.scalar(query)

    def following_count(self):
        query = sa.select(sa.func.count()).select_from(
            self.following.select().subquery())
        return db.session.scalar(query)

    def following_recipes(self):
        Author = so.aliased(User)
        Follower = so.aliased(User)
        return (
            sa.select(Recipe)
            .join(Recipe.author.of_type(Author))
            .join(Author.followers.of_type(Follower), isouter=True)
            .where(sa.or_(
                Follower.id == self.id,
                Author.id == self.id,
            ))
            .group_by(Recipe)
            .order_by(Recipe.timestamp.desc())
        )

    def following_posts(self):
        """Backward compatibility - returns recipes"""
        return self.following_recipes()

    def get_reset_password_token(self, expires_in=600):
        return jwt.encode(
            {'reset_password': self.id, 'exp': time() + expires_in},
            current_app.config['SECRET_KEY'], algorithm='HS256')

    @staticmethod
    def verify_reset_password_token(token):
        try:
            id = jwt.decode(token, current_app.config['SECRET_KEY'],
                            algorithms=['HS256'])['reset_password']
        except Exception:
            return
        return db.session.get(User, id)


    def add_notification(self, name, data):
        db.session.execute(self.notifications.delete().where(
            Notification.name == name))
        n = Notification(name=name, payload_json=json.dumps(data), user=self)
        db.session.add(n)
        return n

    def launch_task(self, name, description, *args, **kwargs):
        rq_job = current_app.task_queue.enqueue(f'app.tasks.{name}', self.id,
                                                *args, **kwargs)
        task = Task(id=rq_job.get_id(), name=name, description=description,
                    user=self)
        db.session.add(task)
        return task

    def get_tasks_in_progress(self):
        query = self.tasks.select().where(Task.complete == False)
        return db.session.scalars(query)

    def get_task_in_progress(self, name):
        query = self.tasks.select().where(Task.name == name,
                                          Task.complete == False)
        return db.session.scalar(query)

    def recipes_count(self):
        query = sa.select(sa.func.count()).select_from(
            self.recipes.select().subquery())
        return db.session.scalar(query)

    def posts_count(self):
        """Backward compatibility - returns recipe count"""
        return self.recipes_count()

    def to_dict(self, include_email=False):
        data = {
            'id': self.id,
            'username': self.username,
            'last_seen': self.last_seen.replace(
                tzinfo=timezone.utc).isoformat(),
            'about_me': self.about_me,
            'recipe_count': self.recipes_count(),
            'post_count': self.posts_count(),  # Backward compatibility
            'follower_count': self.followers_count(),
            'following_count': self.following_count(),
            '_links': {
                'self': url_for('api.get_user', id=self.id),
                'followers': url_for('api.get_followers', id=self.id),
                'following': url_for('api.get_following', id=self.id),
                'avatar': self.avatar(128)
            }
        }
        if include_email:
            data['email'] = self.email
        return data

    def from_dict(self, data, new_user=False):
        for field in ['username', 'email', 'about_me']:
            if field in data:
                setattr(self, field, data[field])
        if new_user and 'password' in data:
            self.set_password(data['password'])

    def get_token(self, expires_in=3600):
        now = datetime.now(timezone.utc)
        if self.token and self.token_expiration.replace(
                tzinfo=timezone.utc) > now + timedelta(seconds=60):
            return self.token
        self.token = secrets.token_hex(16)
        self.token_expiration = now + timedelta(seconds=expires_in)
        db.session.add(self)
        return self.token

    def revoke_token(self):
        self.token_expiration = datetime.now(timezone.utc) - timedelta(
            seconds=1)

    @staticmethod
    def check_token(token):
        user = db.session.scalar(sa.select(User).where(User.token == token))
        if user is None or user.token_expiration.replace(
                tzinfo=timezone.utc) < datetime.now(timezone.utc):
            return None
        return user


@login.user_loader
def load_user(id):
    return db.session.get(User, int(id))


class Recipe(SearchableMixin, db.Model):
    __searchable__ = ['title', 'description', 'ingredients', 'instructions']
    id: so.Mapped[int] = so.mapped_column(primary_key=True)
    title: so.Mapped[str] = so.mapped_column(sa.String(100), index=True)
    description: so.Mapped[Optional[str]] = so.mapped_column(sa.Text)
    ingredients: so.Mapped[str] = so.mapped_column(sa.Text)  # JSON string for structured ingredients
    instructions: so.Mapped[str] = so.mapped_column(sa.Text)
    prep_time: so.Mapped[Optional[int]] = so.mapped_column(sa.Integer)  # in minutes
    cook_time: so.Mapped[Optional[int]] = so.mapped_column(sa.Integer)  # in minutes
    servings: so.Mapped[Optional[int]] = so.mapped_column(sa.Integer)
    difficulty: so.Mapped[Optional[str]] = so.mapped_column(sa.String(20))  # Easy, Medium, Hard
    category: so.Mapped[Optional[str]] = so.mapped_column(sa.String(50))  # Breakfast, Lunch, Dinner, Dessert, etc.
    image_url: so.Mapped[Optional[str]] = so.mapped_column(sa.String(200))
    timestamp: so.Mapped[datetime] = so.mapped_column(
        index=True, default=lambda: datetime.now(timezone.utc))
    user_id: so.Mapped[int] = so.mapped_column(sa.ForeignKey(User.id),
                                               index=True)
    language: so.Mapped[Optional[str]] = so.mapped_column(sa.String(5))

    author: so.Mapped[User] = so.relationship(back_populates='recipes')
    ratings: so.WriteOnlyMapped['Rating'] = so.relationship(
        back_populates='recipe', cascade='all, delete-orphan')
    comments: so.WriteOnlyMapped['Comment'] = so.relationship(
        back_populates='recipe', cascade='all, delete-orphan')

    def __repr__(self):
        return '<Recipe {}>'.format(self.title)

    def total_time(self):
        """Calculate total time (prep + cook) in minutes"""
        prep = self.prep_time or 0
        cook = self.cook_time or 0
        return prep + cook

    def formatted_time(self, minutes):
        """Format time in minutes to human readable format"""
        if not minutes:
            return "Not specified"
        hours = minutes // 60
        mins = minutes % 60
        if hours > 0:
            return f"{hours}h {mins}m" if mins > 0 else f"{hours}h"
        return f"{mins}m"

    def get_ingredients_list(self):
        """Parse ingredients JSON and return list of ingredient dictionaries"""
        try:
            return json.loads(self.ingredients) if self.ingredients else []
        except (json.JSONDecodeError, TypeError):
            # Fallback for old format (plain text)
            return [{"amount": "", "unit": "", "ingredient": self.ingredients}] if self.ingredients else []

    def set_ingredients_list(self, ingredients_list):
        """Set ingredients from list of ingredient dictionaries"""
        self.ingredients = json.dumps(ingredients_list)

    def get_ingredients_text(self):
        """Get ingredients as formatted text for search"""
        ingredients_list = self.get_ingredients_list()
        return " ".join([f"{ing.get('amount', '')} {ing.get('unit', '')} {ing.get('ingredient', '')}".strip()
                        for ing in ingredients_list])

    def get_average_rating(self):
        """Calculate average rating for this recipe"""
        ratings = db.session.scalars(sa.select(Rating.rating).where(Rating.recipe_id == self.id)).all()
        if not ratings:
            return 0
        return round(sum(ratings) / len(ratings), 1)

    def get_rating_count(self):
        """Get total number of ratings for this recipe"""
        return db.session.scalar(sa.select(sa.func.count(Rating.id)).where(Rating.recipe_id == self.id))

    def get_user_rating(self, user):
        """Get rating given by a specific user for this recipe"""
        if user.is_anonymous:
            return None
        rating = db.session.scalar(sa.select(Rating.rating).where(
            sa.and_(Rating.recipe_id == self.id, Rating.user_id == user.id)))
        return rating

    def to_dict(self, include_author=False):
        """Convert recipe to dictionary for API responses"""
        data = {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'ingredients': self.get_ingredients_list(),
            'instructions': self.instructions,
            'prep_time': self.prep_time,
            'cook_time': self.cook_time,
            'total_time': self.total_time(),
            'servings': self.servings,
            'difficulty': self.difficulty,
            'category': self.category,
            'image_url': self.image_url,
            'timestamp': self.timestamp.replace(tzinfo=timezone.utc).isoformat(),
            'language': self.language,
            'average_rating': self.get_average_rating(),
            'rating_count': self.get_rating_count(),
            '_links': {
                'self': f'/api/recipes/{self.id}',
                'author': f'/api/users/{self.user_id}',
                'ratings': f'/api/recipes/{self.id}/ratings'
            }
        }
        if include_author:
            data['author'] = self.author.to_dict()
        return data

    def from_dict(self, data, new_recipe=False):
        """Create or update recipe from dictionary"""
        for field in ['title', 'description', 'instructions', 'prep_time', 
                     'cook_time', 'servings', 'difficulty', 'category', 
                     'image_url', 'language']:
            if field in data:
                setattr(self, field, data[field])
        
        if 'ingredients' in data:
            if isinstance(data['ingredients'], list):
                self.set_ingredients_list(data['ingredients'])
            else:
                self.ingredients = data['ingredients']
        
        if new_recipe and 'user_id' in data:
            self.user_id = data['user_id']


class Message(db.Model):
    id: so.Mapped[int] = so.mapped_column(primary_key=True)
    sender_id: so.Mapped[int] = so.mapped_column(sa.ForeignKey(User.id),
                                                 index=True)
    recipient_id: so.Mapped[int] = so.mapped_column(sa.ForeignKey(User.id),
                                                    index=True)
    body: so.Mapped[str] = so.mapped_column(sa.String(500))
    timestamp: so.Mapped[datetime] = so.mapped_column(
        index=True, default=lambda: datetime.now(timezone.utc))

    author: so.Mapped[User] = so.relationship(
        foreign_keys='Message.sender_id', back_populates='messages_sent')
    recipient: so.Mapped[User] = so.relationship(
        foreign_keys='Message.recipient_id', back_populates='messages_received')

    def __repr__(self):
        return '<Message {}>'.format(self.body)


# Keep Post model for backward compatibility, but alias it to Recipe
Post = Recipe


class Comment(db.Model):
    id: so.Mapped[int] = so.mapped_column(primary_key=True)
    body: so.Mapped[str] = so.mapped_column(sa.String(500))
    timestamp: so.Mapped[datetime] = so.mapped_column(
        index=True, default=lambda: datetime.now(timezone.utc))
    author_id: so.Mapped[int] = so.mapped_column(sa.ForeignKey(User.id),
                                                 index=True)
    recipe_id: so.Mapped[int] = so.mapped_column(sa.ForeignKey(Recipe.id),
                                                 index=True)

    author: so.Mapped[User] = so.relationship(back_populates='comments')
    recipe: so.Mapped[Recipe] = so.relationship(back_populates='comments')

    def __repr__(self):
        return '<Comment {}>'.format(self.body)


class Rating(PaginatedAPIMixin, db.Model):
    id: so.Mapped[int] = so.mapped_column(primary_key=True)
    rating: so.Mapped[int] = so.mapped_column(sa.Integer)  # 1-5 stars
    timestamp: so.Mapped[datetime] = so.mapped_column(
        index=True, default=lambda: datetime.now(timezone.utc))
    user_id: so.Mapped[int] = so.mapped_column(sa.ForeignKey(User.id),
                                               index=True)
    recipe_id: so.Mapped[int] = so.mapped_column(sa.ForeignKey(Recipe.id),
                                                 index=True)
    
    # Ensure one rating per user per recipe
    __table_args__ = (sa.UniqueConstraint('user_id', 'recipe_id', name='unique_user_recipe_rating'),)

    user: so.Mapped[User] = so.relationship(back_populates='ratings')
    recipe: so.Mapped[Recipe] = so.relationship(back_populates='ratings')

    def __repr__(self):
        return '<Rating {} stars by {}>'.format(self.rating, self.user.username)

    def to_dict(self, include_user=False):
        """Convert rating to dictionary for API responses"""
        data = {
            'id': self.id,
            'rating': self.rating,
            'timestamp': self.timestamp.replace(tzinfo=timezone.utc).isoformat(),
            'recipe_id': self.recipe_id,
            'user_id': self.user_id,
            '_links': {
                'self': f'/api/recipes/{self.recipe_id}/ratings/{self.id}',
                'user': f'/api/users/{self.user_id}',
                'recipe': f'/api/recipes/{self.recipe_id}'
            }
        }
        if include_user:
            data['user'] = self.user.to_dict()
        return data


class Notification(db.Model):
    id: so.Mapped[int] = so.mapped_column(primary_key=True)
    name: so.Mapped[str] = so.mapped_column(sa.String(128), index=True)
    user_id: so.Mapped[int] = so.mapped_column(sa.ForeignKey(User.id),
                                               index=True)
    timestamp: so.Mapped[float] = so.mapped_column(index=True, default=time)
    payload_json: so.Mapped[str] = so.mapped_column(sa.Text)

    user: so.Mapped[User] = so.relationship(back_populates='notifications')

    def get_data(self):
        return json.loads(str(self.payload_json))


class Task(db.Model):
    id: so.Mapped[str] = so.mapped_column(sa.String(36), primary_key=True)
    name: so.Mapped[str] = so.mapped_column(sa.String(128), index=True)
    description: so.Mapped[Optional[str]] = so.mapped_column(sa.String(128))
    user_id: so.Mapped[int] = so.mapped_column(sa.ForeignKey(User.id))
    complete: so.Mapped[bool] = so.mapped_column(default=False)

    user: so.Mapped[User] = so.relationship(back_populates='tasks')

    def get_rq_job(self):
        try:
            rq_job = rq.job.Job.fetch(self.id, connection=current_app.redis)
        except (redis.exceptions.RedisError, rq.exceptions.NoSuchJobError):
            return None
        return rq_job

    def get_progress(self):
        job = self.get_rq_job()
        return job.meta.get('progress', 0) if job is not None else 100
