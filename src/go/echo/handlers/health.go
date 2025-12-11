package handlers

import (
	"database/sql"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"echo/services"
)

func HealthHandler(db *sql.DB, cacheService *services.CacheService) echo.HandlerFunc {
	return func(c echo.Context) error {
		dbStatus := "disconnected"
		if db != nil {
			if err := db.Ping(); err == nil {
				dbStatus = "connected"
			}
		}

		cacheStatus := "disconnected"
		if cacheService != nil {
			if err := cacheService.Ping(); err == nil {
				cacheStatus = "connected"
			}
		}

		status := "healthy"
		if dbStatus == "disconnected" || cacheStatus == "disconnected" {
			status = "unhealthy"
		}

		return c.JSON(http.StatusOK, map[string]interface{}{
			"status":    status,
			"version":   "1.0.0",
			"timestamp": time.Now().UTC().Format(time.RFC3339),
			"database":  dbStatus,
			"cache":     cacheStatus,
		})
	}
}

func HealthzHandler(c echo.Context) error {
	return c.String(http.StatusOK, "OK")
}
