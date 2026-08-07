package handlers

import (
	"net/http"
	"time"

	"github.com/benchmark/go-fiber/internal/services"
	"github.com/gofiber/fiber/v2"
)

// HealthHandler handles health check requests
type HealthHandler struct {
	dbService  *services.DatabaseService
	cacheService *services.CacheService
}

// NewHealthHandler creates a new HealthHandler instance
func NewHealthHandler(dbService *services.DatabaseService, cacheService *services.CacheService) *HealthHandler {
	return &HealthHandler{
		dbService:     dbService,
		cacheService: cacheService,
	}
}

// HandleHealth godoc
// @Summary Health check
// @Description Check database and cache connectivity
// @Tags health
// @Accept json
// @Produce json
// @Success 200 {object} map[string]interface{} "Health status"
// @Router /health [get]
func (hh *HealthHandler) HandleHealth(c *fiber.Ctx) error {
	dbHealthy := hh.dbService.HealthCheck()
	cacheHealthy := hh.cacheService.HealthCheck()

	response := fiber.Map{
		"status":    "healthy",
		"version":   "1.0.0",
		"database":  "disconnected",
		"cache":     "disconnected",
		"timestamp": time.Now().Format(time.RFC3339),
	}

	if dbHealthy {
		response["database"] = "connected"
	}
	if cacheHealthy {
		response["cache"] = "connected"
	}

	if !dbHealthy || !cacheHealthy {
		response["status"] = "unhealthy"
		return c.Status(http.StatusServiceUnavailable).JSON(response)
	}

	return c.JSON(response)
}
