from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class User:
    id: int
    email: str
    first_name: str
    last_name: str
    age: Optional[int] = None
    created_at: Optional[datetime] = None

    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'age': self.age,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
