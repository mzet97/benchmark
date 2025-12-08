package models

import "time"

// Order represents an order in the system
type Order struct {
	ID           int       `json:"id"`
	UserID       int       `json:"user_id"`
	TotalAmount  float64   `json:"total_amount"`
	Status       string    `json:"status"`
	CreatedAt    time.Time `json:"created_at"`
}

// NewOrder creates a new Order instance
func NewOrder(id, userID int, totalAmount float64, status string, createdAt time.Time) *Order {
	return &Order{
		ID:           id,
		UserID:       userID,
		TotalAmount:  totalAmount,
		Status:       status,
		CreatedAt:    createdAt,
	}
}

// String returns a string representation of the Order
func (o *Order) String() string {
	return "Order{ID: " + string(rune(o.ID)) + ", UserID: " + string(rune(o.UserID)) + "}"
}
