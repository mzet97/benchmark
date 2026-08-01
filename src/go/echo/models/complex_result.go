package models

// ComplexQueryResult and UserStats mirror ComplexOrdersResponse and
// UserOrderStats in contracts/grpc/benchmark.proto, so /db/complex returns
// the same shape over REST, gRPC and GraphQL.
//
// Field names are camelCase, matching the proto3 JSON mapping of the
// snake_case proto fields. See contracts/rest/canonical-payloads.md.
type ComplexQueryResult struct {
	PeriodDays int         `json:"periodDays"`
	TotalUsers int         `json:"totalUsers"`
	Data       []UserStats `json:"data"`
}

type UserStats struct {
	UserID            int     `json:"userId"`
	UserName          string  `json:"userName"`
	TotalOrders       int     `json:"totalOrders"`
	TotalValue        float64 `json:"totalValue"`
	AverageOrderValue float64 `json:"averageOrderValue"`
}
