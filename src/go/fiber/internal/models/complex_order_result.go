package models

import "fmt"

// ComplexOrderResult mirrors UserOrderStats in contracts/grpc/benchmark.proto
// and type UserOrderStats in contracts/graphql/schema.graphql, so /db/complex
// returns the same shape over all three protocols.
//
// Field names are camelCase, matching the proto3 JSON mapping of the
// snake_case proto fields. See contracts/rest/canonical-payloads.md.
type ComplexOrderResult struct {
	UserID            int     `json:"userId"`
	UserName          string  `json:"userName"`
	TotalOrders       int64   `json:"totalOrders"`
	TotalValue        float64 `json:"totalValue"`
	AverageOrderValue float64 `json:"averageOrderValue"`
}

// NewComplexOrderResult creates a new ComplexOrderResult instance
func NewComplexOrderResult(
	userID int,
	userName string,
	totalOrders int64,
	totalValue float64,
	averageOrderValue float64,
) *ComplexOrderResult {
	return &ComplexOrderResult{
		UserID:            userID,
		UserName:          userName,
		TotalOrders:       totalOrders,
		TotalValue:        totalValue,
		AverageOrderValue: averageOrderValue,
	}
}

// String returns a string representation of the ComplexOrderResult
func (cor *ComplexOrderResult) String() string {
	return fmt.Sprintf("ComplexOrderResult{UserID: %d, Orders: %d}",
		cor.UserID, cor.TotalOrders)
}
