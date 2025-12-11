#!/usr/bin/env python3
"""
Benchmark API - Python Flask
High-performance REST API benchmark implementation
"""

import asyncio
import os
from app import create_app

app = create_app()

if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == 'run':
        # Development mode
        port = int(os.getenv('PORT', 8000))
        app.run(host='0.0.0.0', port=port, debug=False)
    else:
        # Production mode with Gunicorn
        # This file is used by Gunicorn via: gunicorn app:app
        pass
