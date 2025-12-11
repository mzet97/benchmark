package models

type ComplexQueryResult struct {
	PeriodDays int           `json:"period_days"`
	TotalUsers int           `json:"total_users"`
	Data       []UserStats   `json:"data"`
}

type UserStats struct {
	UserID     int     `json:"user_id"`
	UserName   string  `json:"user_name"`
	TotalOrders int    `json:"total_orders"`
	TotalValue  float64 `json:"total_value"`
	AverageValue float64 `json:"average_value"`
}
