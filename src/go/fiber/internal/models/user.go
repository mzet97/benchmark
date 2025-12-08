package models

import "time"

// User represents a user in the system
type User struct {
	ID        int       `json:"id"`
	Email     string    `json:"email"`
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	Age       int       `json:"age"`
	CreatedAt time.Time `json:"created_at"`
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
	return "User{ID: " + string(rune(u.ID)) + ", Email: " + u.Email + "}"
}
