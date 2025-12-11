package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"

	"chi/models"
	"chi/services"
)

func DatabaseSimpleHandler(dbService *services.DatabaseService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		id := 1
		if param := r.URL.Query().Get("id"); param != "" {
			if parsed, err := strconv.Atoi(param); err == nil {
				id = parsed
			} else {
				http.Error(w, "Invalid ID", http.StatusBadRequest)
				return
			}
		}

		user, err := dbService.GetUserByID(id)
		if err != nil {
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}

		json.NewEncoder(w).Encode(user)
	}
}

func DatabaseComplexHandler(dbService *services.DatabaseService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		days := 30
		if param := r.URL.Query().Get("days"); param != "" {
			if parsed, err := strconv.Atoi(param); err == nil && parsed > 0 && parsed <= 365 {
				days = parsed
			} else {
				http.Error(w, "Days must be between 1 and 365", http.StatusBadRequest)
				return
			}
		}

		stats, err := dbService.GetComplexQuery(days)
		if err != nil {
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}

		result := models.ComplexQueryResult{
			PeriodDays: days,
			TotalUsers: len(stats),
			Data:       stats,
		}

		json.NewEncoder(w).Encode(result)
	}
}
