package handlers

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"echo/services"
)

// The TTL is part of the response contract; it must match the value the
// cache service writes. See contracts/rest/canonical-payloads.md.
const cacheTTLSeconds = 300

func CacheHandler(cacheService *services.CacheService) echo.HandlerFunc {
	return func(c echo.Context) error {
		key := "test"
		if param := c.QueryParam("key"); param != "" {
			key = param
		}

		value, wasCached, err := cacheService.GetOrSet(key)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": "Cache error"})
		}

		return c.JSON(http.StatusOK, map[string]interface{}{
			"key":       key,
			"value":     value,
			"cached":    wasCached,
			"ttl":       cacheTTLSeconds,
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		})
	}
}
