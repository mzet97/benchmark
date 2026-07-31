package handlers

import (
	"time"

	"github.com/benchmark/go-fiber/internal/models"
	"github.com/gofiber/fiber/v2"
)

// JSONHandler handles JSON response requests
type JSONHandler struct{}

// NewJSONHandler creates a new JSONHandler instance
func NewJSONHandler() *JSONHandler {
	return &JSONHandler{}
}

const (
	defaultJSONItems = 1000
	maxJSONItems     = 10000
)

// HandleJSON godoc
// @Summary JSON response
// @Description Returns n canonical JSON objects (default 1000)
// @Tags json
// @Accept json
// @Produce json
// @Param n query int false "Item count (default 1000, max 10000)"
// @Success 200 {object} map[string]interface{} "JSON response"
// @Router /json [get]
//
// n is part of the contract: on a 1 GbE link n=1000 is network-bound at
// ~734 req/s, so the serialization ranking is taken at n=100.
// See contracts/rest/canonical-payloads.md.
func (jh *JSONHandler) HandleJSON(c *fiber.Ctx) error {
	n := c.QueryInt("n", defaultJSONItems)
	if n < 0 {
		n = 0
	}
	if n > maxJSONItems {
		n = maxJSONItems
	}

	items := make([]*models.JSONItem, n)
	for i := 0; i < n; i++ {
		items[i] = models.NewJSONItem(i)
	}

	// The envelope timestamp is the only clock-dependent field, and it is
	// excluded from the parity hash.
	response := fiber.Map{
		"items":     items,
		"count":     n,
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	}

	return c.JSON(response)
}
