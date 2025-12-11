package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"
)

func JsonHandler(w http.ResponseWriter, r *http.Request) {
	items := make([]map[string]interface{}, 1000)
	for i := 0; i < 1000; i++ {
		items[i] = map[string]interface{}{
			"id":         i,
			"name":       "User " + strconv.Itoa(i),
			"email":      "user" + strconv.Itoa(i) + "@example.com",
			"timestamp":  time.Now().UTC().Format(time.RFC3339),
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"items":     items,
		"count":     len(items),
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}
