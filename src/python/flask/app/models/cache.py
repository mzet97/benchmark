from dataclasses import dataclass
from typing import Optional

@dataclass
class CacheResponse:
    key: str
    value: str
    cached: bool
    ttl: int

    def to_dict(self):
        return {
            'key': self.key,
            'value': self.value,
            'cached': self.cached,
            'ttl': self.ttl
        }
