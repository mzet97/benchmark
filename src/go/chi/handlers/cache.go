package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"chi/services"
)

func CacheHandler(cacheService *services.CacheService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		key := "test"
		if param := r.URL.Query().Get("key"); param != "" {
			key = param
		}

		value, wasCached, err := cacheService.GetOrSet(key)
		if err != nil {
			http.Error(w, "Cache error", http.StatusInternalServerError)
			return
		}

		json.NewEncoder(w).Encode(map[string]interface{}{
			"key":       key,
			"value":     value,
			"cached":    wasCached,
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		})
	}
}
