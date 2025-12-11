package models

import "time"

type User struct {
	ID        int       `json:"id"`
	Email     string    `json:"email"`
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	Age       *int      `json:"age"`
	CreatedAt time.Time `json:"created_at"`
}
