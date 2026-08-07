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
    # Use the standard URL parser instead of a hand-rolled regex. urlparse does
    # not percent-decode the userinfo, so a password of Admin%40123 came back as
    # the literal "Admin%40123" and Django sent it verbatim -- Postgres rejected
    # it. The previous regex ([^@]+) also broke on any password containing an
    # unencoded '@'. unquote() yields the real "Admin@123".
    from urllib.parse import urlparse, unquote
    parsed = urlparse(DATABASE_URL)
    db_user = unquote(parsed.username) if parsed.username else os.getenv('DB_USER', 'app')
    db_pass = unquote(parsed.password) if parsed.password else os.environ["DB_PASSWORD"]
    db_host = parsed.hostname or os.getenv('DB_HOST', 'spsql.home.arpa')
    db_port = str(parsed.port) if parsed.port else os.getenv('DB_PORT', '5432')
    db_name = parsed.path.lstrip('/') or os.getenv('DB_NAME', 'benchmark_api')
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
