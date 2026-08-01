from dataclasses import dataclass
from datetime import datetime
from typing import Optional


# Wire names are camelCase, matching the proto3 JSON mapping of the snake_case
# proto fields. See contracts/rest/canonical-payloads.md. The route serializes
# the database row directly -- the normative SQL already aliases its columns to
# these names -- so this class exists to keep one definition of the shape
# rather than a second, divergent one.
@dataclass
class User:
    id: int
    email: str
    firstName: str
    lastName: str
    age: Optional[int] = None
    createdAt: Optional[datetime] = None

    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'firstName': self.firstName,
            'lastName': self.lastName,
            'age': self.age,
            'createdAt': self.createdAt.isoformat() if self.createdAt else None
        }
