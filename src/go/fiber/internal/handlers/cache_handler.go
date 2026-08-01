package handlers

import (
	"net/http"
	"time"

	"github.com/benchmark/go-fiber/internal/services"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// The TTL is part of the response contract; it must match the value written
// to Redis below. See contracts/rest/canonical-payloads.md.
const cacheTTLSeconds = 300

// CacheHandler handles cache requests
type CacheHandler struct {
	cacheService *services.CacheService
}

// NewCacheHandler creates a new CacheHandler instance
func NewCacheHandler(cacheService *services.CacheService) *CacheHandler {
	return &CacheHandler{
		cacheService: cacheService,
	}
}

// HandleCache godoc
// @Summary Cache operations
// @Description Get or set cache value
// @Tags cache
// @Accept json
// @Produce json
// @Param key query string false "Cache key"
// @Success 200 {object} map[string]interface{} "Cache response"
// @Router /cache [get]
func (ch *CacheHandler) HandleCache(c *fiber.Ctx) error {
	key := c.Query("key")
	if key == "" {
		key = "test"
	}

	// Generate new value
	newValue := "cached-value-" + uuid.New().String()

	// Get or set value
	val, err := ch.cacheService.GetOrSet(key, newValue, cacheTTLSeconds*time.Second)
	if err != nil {
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{
			"error": "Cache error: " + err.Error(),
		})
	}

	// The contract carries a boolean plus the TTL, not a free-form "source"
	// string. See contracts/rest/canonical-payloads.md.
	response := fiber.Map{
		"key":       key,
		"value":     val,
		"cached":    val != newValue,
		"ttl":       cacheTTLSeconds,
		"timestamp": time.Now().Format(time.RFC3339),
	}

	return c.JSON(response)
}
