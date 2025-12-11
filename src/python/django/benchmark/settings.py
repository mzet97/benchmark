import os

DEBUG = os.getenv('DEBUG', 'False') == 'True'

SECRET_KEY = os.getenv('SECRET_KEY', 'django-insecure-benchmark-key')

ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'rest_framework',
    'benchmark',
]

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'benchmark_api',
        'USER': 'app',
        'PASSWORD': 'Admin@123',
        'HOST': 'spsql.home.arpa',
        'PORT': '5432',
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

REDIS_URL = os.getenv('REDIS_URL', 'redis://:Admin@123@redis.home.arpa:30379')
