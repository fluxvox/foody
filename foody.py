import sqlalchemy as sa
import sqlalchemy.orm as so
from app import create_app, db
from app.models import User, Post, Message, Notification, Task, Rating

app = create_app()


@app.shell_context_processor
def make_shell_context():
    return {'sa': sa, 'so': so, 'db': db, 'User': User, 'Post': Post,
            'Message': Message, 'Notification': Notification, 'Task': Task, 'Rating': Rating}


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5002)
