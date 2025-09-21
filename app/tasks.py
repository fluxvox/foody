# Task system disabled for local deployment (removed Redis/RQ from original tutorial)
# This file is kept for compatibility but tasks are handled synchronously

import json
import sys
import time
import sqlalchemy as sa
from flask import render_template
from app import create_app, db
from app.models import User, Post, Task
from app.email import send_email

app = create_app()
app.app_context().push()


def _set_task_progress(progress):
    # Task system disabled for local deployment (removed Redis/RQ from original tutorial)
    # Tasks are handled synchronously using Python threading
    pass


