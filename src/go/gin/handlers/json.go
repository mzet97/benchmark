package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

func JsonHandler(c *gin.Context) {
	items := make([]map[string]interface{}, 1000)
	for i := 0; i < 1000; i++ {
		items[i] = map[string]interface{}{
			"id":         i,
			"name":       "User " + strconv.Itoa(i),
			"email":      "user" + strconv.Itoa(i) + "@example.com",
			"timestamp":  time.Now().UTC().Format(time.RFC3339),
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"items":     items,
		"count":     len(items),
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}
