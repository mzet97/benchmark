package handlers

import (
	"github.com/benchmark/go-fiber/internal/models"
	"github.com/gofiber/fiber/v2"
)

// JSONHandler handles JSON response requests
type JSONHandler struct{}

// NewJSONHandler creates a new JSONHandler instance
func NewJSONHandler() *JSONHandler {
	return &JSONHandler{}
}

// HandleJSON godoc
// @Summary JSON response
// @Description Returns 1000 JSON objects
// @Tags json
// @Accept json
// @Produce json
// @Success 200 {object} map[string]interface{} "JSON response"
// @Router /json [get]
func (jh *JSONHandler) HandleJSON(c *fiber.Ctx) error {
	items := make([]*models.JSONItem, 1000)
	for i := 0; i < 1000; i++ {
		items[i] = models.NewJSONItem(i)
	}

	response := fiber.Map{
		"items":     items,
		"count":     len(items),
		"timestamp": items[0].Timestamp,
	}

	return c.JSON(response)
}
