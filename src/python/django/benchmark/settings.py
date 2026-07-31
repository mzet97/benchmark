import os

DEBUG = os.getenv('DEBUG', 'False') == 'True'

SECRET_KEY = os.getenv('SECRET_KEY', 'django-insecure-benchmark-key')

ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'rest_framework',
    'benchmark',
]

# Parse DATABASE_URL or use individual env vars
DATABASE_URL = os.getenv('DATABASE_URL', '')

if DATABASE_URL:
    # Parse postgresql://user:pass@host:port/dbname
    import re
    match = re.match(r'postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)', DATABASE_URL)
    if match:
        db_user, db_pass, db_host, db_port, db_name = match.groups()
    else:
        db_user = os.getenv('DB_USER', 'app')
        db_pass = os.environ["DB_PASSWORD"]
        db_host = os.getenv('DB_HOST', 'spsql.home.arpa')
        db_port = os.getenv('DB_PORT', '5432')
        db_name = os.getenv('DB_NAME', 'benchmark_api')
else:
    db_user = os.getenv('DB_USER', 'app')
    db_pass = os.environ["DB_PASSWORD"]
    db_host = os.getenv('DB_HOST', 'spsql.home.arpa')
    db_port = os.getenv('DB_PORT', '5432')
    db_name = os.getenv('DB_NAME', 'benchmark_api')

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': db_name,
        'USER': db_user,
        'PASSWORD': db_pass,
        'HOST': db_host,
        'PORT': db_port,
        'CONN_MAX_AGE': 600,
        'OPTIONS': {
            'connect_timeout': 10,
        },
    }
}

ROOT_URLCONF = 'benchmark.urls'

MIDDLEWARE = []

USE_TZ = False

REST_FRAMEWORK = {
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
}

REDIS_URL = os.environ["REDIS_URL"]
