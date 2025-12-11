package handlers

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"echo/services"
)

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
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		})
	}
}
