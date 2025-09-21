# Fix MySQL driver issue - PyMySQL compatibility for MariaDB
# This is required for MariaDB/MySQL support in SQLAlchemy
try:
    import pymysql
    pymysql.install_as_MySQLdb()
except ImportError:
    pass

import sqlalchemy as sa
import sqlalchemy.orm as so
from app import create_app, db
from app.models import User, Recipe, Message, Notification, Task, Rating  # Extended models beyond original tutorial

app = create_app()


@app.shell_context_processor
def make_shell_context():
    return {'sa': sa, 'so': so, 'db': db, 'User': User, 'Recipe': Recipe,
            'Message': Message, 'Notification': Notification, 'Task': Task, 'Rating': Rating}


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5002)
