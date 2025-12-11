from dataclasses import dataclass
from typing import Optional

@dataclass
class HealthStatus:
    status: str
    version: str
    timestamp: str
    database: str
    cache: str

    @classmethod
    def create(cls, db_healthy: bool, cache_healthy: bool):
        return cls(
            status='healthy' if (db_healthy and cache_healthy) else 'unhealthy',
            version='1.0.0',
            timestamp=datetime.utcnow().isoformat(),
            database='healthy' if db_healthy else 'unhealthy',
            cache='healthy' if cache_healthy else 'unhealthy'
        )

    def to_dict(self):
        return {
            'status': self.status,
            'version': self.version,
            'timestamp': self.timestamp,
            'database': self.database,
            'cache': self.cache
        }
