package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/benchmark/go-fiber/internal/services"
	"github.com/gofiber/fiber/v2"
)

// DatabaseHandler handles database requests
type DatabaseHandler struct {
	dbService *services.DatabaseService
}

// NewDatabaseHandler creates a new DatabaseHandler instance
func NewDatabaseHandler(dbService *services.DatabaseService) *DatabaseHandler {
	return &DatabaseHandler{
		dbService: dbService,
	}
}

// HandleSimple godoc
// @Summary Simple database query
// @Description Get user by ID
// @Tags database
// @Accept json
// @Produce json
// @Param id query int false "User ID"
// @Success 200 {object} map[string]interface{} "User data"
// @Success 404 {object} map[string]interface{} "User not found"
// @Router /db/simple [get]
func (dh *DatabaseHandler) HandleSimple(c *fiber.Ctx) error {
	idParam := c.Query("id")
	if idParam == "" {
		idParam = "1"
	}

	id, err := strconv.Atoi(idParam)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid ID parameter",
		})
	}

	user, err := dh.dbService.FindUserByID(id)
	if err != nil {
		return c.Status(http.StatusNotFound).JSON(fiber.Map{
			"error": "User not found",
			"id":    id,
		})
	}

	response := fiber.Map{
		"user":      user,
		"timestamp": time.Now().Format(time.RFC3339),
	}

	return c.JSON(response)
}

// HandleComplex godoc
// @Summary Complex database query
// @Description Get aggregated order statistics
// @Tags database
// @Accept json
// @Produce json
// @Param days query int false "Number of days"
// @Success 200 {object} map[string]interface{} "Order statistics"
// @Router /db/complex [get]
func (dh *DatabaseHandler) HandleComplex(c *fiber.Ctx) error {
	daysParam := c.Query("days")
	if daysParam == "" {
		daysParam = "30"
	}

	days, err := strconv.Atoi(daysParam)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid days parameter",
		})
	}

	results, err := dh.dbService.FindComplexOrders(days)
	if err != nil {
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{
			"error": "Database error: " + err.Error(),
		})
	}

	response := fiber.Map{
		"orders":    results,
		"count":     len(results),
		"days":      days,
		"timestamp": time.Now().Format(time.RFC3339),
	}

	return c.JSON(response)
}
