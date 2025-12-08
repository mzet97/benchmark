package models

// ComplexOrderResult represents aggregated order statistics for a user
type ComplexOrderResult struct {
	UserID              int     `json:"user_id"`
	Email               string  `json:"email"`
	OrderCount          int64   `json:"order_count"`
	TotalAmount         float64 `json:"total_amount"`
	AverageAmount       float64 `json:"avg_amount"`
	DaysSinceFirstOrder int64   `json:"days_since_first_order"`
}

// NewComplexOrderResult creates a new ComplexOrderResult instance
func NewComplexOrderResult(
	userID int,
	email string,
	orderCount int64,
	totalAmount float64,
	averageAmount float64,
	daysSinceFirstOrder int64,
) *ComplexOrderResult {
	return &ComplexOrderResult{
		UserID:              userID,
		Email:               email,
		OrderCount:          orderCount,
		TotalAmount:         totalAmount,
		AverageAmount:       averageAmount,
		DaysSinceFirstOrder: daysSinceFirstOrder,
	}
}

// String returns a string representation of the ComplexOrderResult
func (cor *ComplexOrderResult) String() string {
	return "ComplexOrderResult{UserID: " + string(rune(cor.UserID)) + ", Orders: " + string(rune(cor.OrderCount)) + "}"
}
