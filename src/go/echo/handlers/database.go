package handlers

import (
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
	"echo/services"
)

func DatabaseSimpleHandler(dbService *services.DatabaseService) echo.HandlerFunc {
	return func(c echo.Context) error {
		id := 1
		if param := c.QueryParam("id"); param != "" {
			if parsed, err := strconv.Atoi(param); err == nil {
				id = parsed
			} else {
				return c.JSON(http.StatusBadRequest, map[string]interface{}{"error": "Invalid ID"})
			}
		}

		user, err := dbService.GetUserByID(id)
		if err != nil {
			return c.JSON(http.StatusNotFound, map[string]interface{}{"error": "User not found"})
		}

		return c.JSON(http.StatusOK, user)
	}
}

func DatabaseComplexHandler(dbService *services.DatabaseService) echo.HandlerFunc {
	return func(c echo.Context) error {
		days := 30
		if param := c.QueryParam("days"); param != "" {
			if parsed, err := strconv.Atoi(param); err == nil && parsed > 0 && parsed <= 365 {
				days = parsed
			} else {
				return c.JSON(http.StatusBadRequest, map[string]interface{}{"error": "Days must be between 1 and 365"})
			}
		}

		stats, err := dbService.GetComplexQuery(days)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{"error": "Database error"})
		}

		result := map[string]interface{}{
			"periodDays": days,
			"totalUsers": len(stats),
			"data":        stats,
		}

		return c.JSON(http.StatusOK, result)
	}
}
