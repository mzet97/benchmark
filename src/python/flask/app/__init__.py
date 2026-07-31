"""
Benchmark API - Python Flask
High-performance REST API benchmark implementation
"""

import os
from flask import Flask
from structlog.stdlib import LoggerFactory
import structlog

structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

def create_app():
    """Application factory pattern"""
    app = Flask(__name__)

    # Configuration
    app.config['DEBUG'] = os.getenv('DEBUG', 'false').lower() == 'true'
    app.config['LOG_LEVEL'] = os.getenv('LOG_LEVEL', 'info')
    app.config['DATABASE_URL'] = os.environ["DATABASE_URL"]
    app.config['REDIS_URL'] = os.environ["REDIS_URL"]

    # Register blueprints
    from app.routes import health, json, database, cache

    app.register_blueprint(health.bp)
    app.register_blueprint(json.bp)
    app.register_blueprint(database.bp)
    app.register_blueprint(cache.bp)

    app.logger.info("Flask application initialized", extra={
        'version': '1.0.0',
        'debug': app.config['DEBUG'],
        'log_level': app.config['LOG_LEVEL']
    })

    return app
