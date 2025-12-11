from dataclasses import dataclass
from typing import Optional

@dataclass
class JsonItem:
    id: int
    name: str
    value: str
    timestamp: Optional[str] = None

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'value': self.value,
            'timestamp': self.timestamp
        }
