package models

import (
	"crypto/rand"
	"encoding/hex"
	"time"
)

// JSONItem represents a JSON response item
type JSONItem struct {
	ID          int       `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Timestamp   string    `json:"timestamp"`
	Random      string    `json:"random"`
}

// NewJSONItem creates a new JSONItem instance
func NewJSONItem(id int) *JSONItem {
	// Generate random data
	bytes := make([]byte, 16)
	rand.Read(bytes)
	randomStr := hex.EncodeToString(bytes)

	return &JSONItem{
		ID:          id,
		Name:        "Item " + string(rune(id)),
		Description: "This is item number " + string(rune(id)),
		Timestamp:   time.Now().Format(time.RFC3339),
		Random:      "data-" + randomStr,
	}
}
