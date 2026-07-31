package models

import (
	"fmt"
	"time"
)

// User represents a user in the system
type User struct {
	ID        int       `json:"id"`
	Email     string    `json:"email"`
	FirstName string    `json:"firstName"`
	LastName  string    `json:"lastName"`
	Age       int       `json:"age"`
	CreatedAt time.Time `json:"createdAt"`
}

// NewUser creates a new User instance
func NewUser(id int, email, firstName, lastName string, age int, createdAt time.Time) *User {
	return &User{
		ID:        id,
		Email:     email,
		FirstName: firstName,
		LastName:  lastName,
		Age:       age,
		CreatedAt: createdAt,
	}
}

// String returns a string representation of the User
func (u *User) String() string {
	return fmt.Sprintf("User{ID: %d, Email: %s}", u.ID, u.Email)
}
