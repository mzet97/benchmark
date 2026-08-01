package models

import "time"

// Mirrors UserResponse in contracts/grpc/benchmark.proto. Wire names are
// camelCase. See contracts/rest/canonical-payloads.md.
type User struct {
	ID        int       `json:"id"`
	Email     string    `json:"email"`
	FirstName string    `json:"firstName"`
	LastName  string    `json:"lastName"`
	Age       *int      `json:"age"`
	CreatedAt time.Time `json:"createdAt"`
}
