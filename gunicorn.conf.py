# Gunicorn configuration file for production deployment
import multiprocessing
import os

# Server socket
bind = "0.0.0.0:8080"
backlog = 2048

# Worker processes
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
timeout = 60
keepalive = 5

# Maximum requests a worker will process before restarting
max_requests = 1000
max_requests_jitter = 100

# Logging
loglevel = "info"
accesslog = "/var/log/gunicorn/access.log"
errorlog = "/var/log/gunicorn/error.log"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "latex_compiler_service"

# Preload application for better performance
preload_app = True

# Security
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190

# Graceful timeout
graceful_timeout = 30

# User and group to run as (set these if running as root)
# user = "www-data"
# group = "www-data"

# Enable stats at /stats endpoint
# statsd_host = "localhost:8125"

# Enable worker recycling
worker_tmp_dir = "/dev/shm"

# Disable access log for health checks (optional)
def when_not_health_check(record):
    return record.getMessage().find('/health') == -1

if os.path.exists('/var/log/gunicorn/access.log'):
    access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'
