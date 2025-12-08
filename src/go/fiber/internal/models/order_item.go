package models

import "time"

// OrderItem represents an item in an order
type OrderItem struct {
	ID          int       `json:"id"`
	OrderID     int       `json:"order_id"`
	ProductName string    `json:"product_name"`
	Quantity    int       `json:"quantity"`
	Price       float64   `json:"price"`
	CreatedAt   time.Time `json:"created_at"`
}

// NewOrderItem creates a new OrderItem instance
func NewOrderItem(id, orderID int, productName string, quantity int, price float64, createdAt time.Time) *OrderItem {
	return &OrderItem{
		ID:          id,
		OrderID:     orderID,
		ProductName: productName,
		Quantity:    quantity,
		Price:       price,
		CreatedAt:   createdAt,
	}
}

// String returns a string representation of the OrderItem
func (oi *OrderItem) String() string {
	return "OrderItem{ID: " + string(rune(oi.ID)) + ", Product: " + oi.ProductName + "}"
}
