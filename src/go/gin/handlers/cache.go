package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"gin/services"
)

// The TTL is part of the response contract; it must match the value the
// cache service writes. See contracts/rest/canonical-payloads.md.
const cacheTTLSeconds = 300

func CacheHandler(cacheService *services.CacheService) gin.HandlerFunc {
	return func(c *gin.Context) {
		key := "test"
		if param, exists := c.GetQuery("key"); exists {
			key = param
		}

		value, wasCached, err := cacheService.GetOrSet(key)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Cache error"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"key":       key,
			"value":     value,
			"cached":    wasCached,
			"ttl":       cacheTTLSeconds,
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		})
	}
}
