package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"
)

func JsonHandler(c echo.Context) error {
	items := make([]map[string]interface{}, 1000)
	for i := 0; i < 1000; i++ {
		items[i] = map[string]interface{}{
			"id":         i,
			"name":       "User " + strconv.Itoa(i),
			"email":      "user" + strconv.Itoa(i) + "@example.com",
			"timestamp":  time.Now().UTC().Format(time.RFC3339),
		}
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"items":     items,
		"count":     len(items),
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}
