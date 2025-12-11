package handlers

import (
	"database/sql"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"gin/services"
)

func HealthHandler(db *sql.DB, cacheService *services.CacheService) gin.HandlerFunc {
	return func(c *gin.Context) {
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

		c.JSON(http.StatusOK, gin.H{
			"status":    status,
			"version":   "1.0.0",
			"timestamp": time.Now().UTC().Format(time.RFC3339),
			"database":  dbStatus,
			"cache":     cacheStatus,
		})
	}
}

func HealthzHandler(c *gin.Context) {
	c.String(http.StatusOK, "OK")
}
