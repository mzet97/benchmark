package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gin/services"
)

func DatabaseSimpleHandler(dbService *services.DatabaseService) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := 1
		if param, exists := c.GetQuery("id"); exists {
			if parsed, err := strconv.Atoi(param); err == nil {
				id = parsed
			} else {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
				return
			}
		}

		user, err := dbService.GetUserByID(id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			return
		}

		c.JSON(http.StatusOK, user)
	}
}

func DatabaseComplexHandler(dbService *services.DatabaseService) gin.HandlerFunc {
	return func(c *gin.Context) {
		days := 30
		if param, exists := c.GetQuery("days"); exists {
			if parsed, err := strconv.Atoi(param); err == nil && parsed > 0 && parsed <= 365 {
				days = parsed
			} else {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Days must be between 1 and 365"})
				return
			}
		}

		stats, err := dbService.GetComplexQuery(days)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
			return
		}

		result := gin.H{
			"periodDays": days,
			"totalUsers": len(stats),
			"data":        stats,
		}

		c.JSON(http.StatusOK, result)
	}
}
