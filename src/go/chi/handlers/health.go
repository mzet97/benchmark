package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"time"

	"chi/services"
)

func HealthHandler(db *sql.DB, cacheService *services.CacheService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

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

		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":    status,
			"version":   "1.0.0",
			"timestamp": time.Now().UTC().Format(time.RFC3339),
			"database":  dbStatus,
			"cache":     cacheStatus,
		})
	}
}

func HealthzHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}
