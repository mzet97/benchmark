package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// Canonical /json payload. See contracts/rest/canonical-payloads.md.
//
// The previous version returned {id,name,email,timestamp} and called
// time.Now() inside the loop -- 1000 clock reads per request -- which is work
// no other implementation did and which is not what /json measures.
const (
	defaultJSONItems   = 1000
	maxJSONItems       = 10000
	canonicalCreatedAt = "2026-01-01T00:00:00Z"
)

type jsonItem struct {
	ID        int    `json:"id"`
	UUID      string `json:"uuid"`
	Name      string `json:"name"`
	Email     string `json:"email"`
	CreatedAt string `json:"createdAt"`
	IsActive  bool   `json:"isActive"`
}

// newJSONItem builds item i. Content is a pure function of the index: no
// randomness and no wall-clock, so the payload is identical across languages.
func newJSONItem(i int) jsonItem {
	return jsonItem{
		ID:        i,
		UUID:      fmt.Sprintf("00000000-0000-0000-0000-%012d", i),
		Name:      fmt.Sprintf("Item %d", i),
		Email:     fmt.Sprintf("item%d@benchmark.local", i),
		CreatedAt: canonicalCreatedAt,
		IsActive:  i%2 == 0,
	}
}

// itemCount parses ?n=. On a 1 GbE link n=1000 is network-bound at ~734 rps,
// so the serialization ranking is taken at n=100.
func itemCount(raw string) int {
	if raw == "" {
		return defaultJSONItems
	}
	n, err := strconv.Atoi(raw)
	if err != nil || n < 0 {
		return defaultJSONItems
	}
	if n > maxJSONItems {
		return maxJSONItems
	}
	return n
}

func buildItems(n int) []jsonItem {
	items := make([]jsonItem, n)
	for i := 0; i < n; i++ {
		items[i] = newJSONItem(i)
	}
	return items
}

func JsonHandler(c *gin.Context) {
	n := itemCount(c.Query("n"))

	// The envelope timestamp is the only clock-dependent field and is excluded
	// from the parity hash.
	c.JSON(http.StatusOK, gin.H{
		"items":     buildItems(n),
		"count":     n,
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}
