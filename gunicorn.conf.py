# Gunicorn configuration file for Foody application

# Server socket
bind = "127.0.0.1:5000"
backlog = 2048

# Worker processes
workers = 2
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2

# Restart workers after this many requests, to help prevent memory leaks
max_requests = 1000
max_requests_jitter = 100

# Logging
accesslog = "-"
errorlog = "-"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'

# Process naming
proc_name = "foody"

# Server mechanics
daemon = False
pidfile = "/tmp/foody.pid"
user = "student"
group = "student"
tmp_upload_dir = None

# SSL (if needed in future)
# keyfile = "/path/to/keyfile"
# certfile = "/path/to/certfile"

# Preload app for better performance
preload_app = True

# Worker timeout
graceful_timeout = 30

# Security
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190
