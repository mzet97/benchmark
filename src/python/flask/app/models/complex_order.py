from dataclasses import dataclass
from typing import Optional

@dataclass
class ComplexOrderResult:
    user_id: int
    email: str
    order_count: int
    total_amount: float
    avg_amount: float
    days_since_first_order: Optional[int] = None

    def to_dict(self):
        return {
            'user_id': self.user_id,
            'email': self.email,
            'order_count': self.order_count,
            'total_amount': float(self.total_amount),
            'avg_amount': float(self.avg_amount),
            'days_since_first_order': self.days_since_first_order
        }
