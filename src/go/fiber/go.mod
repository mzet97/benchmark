module github.com/benchmark/go-fiber

go 1.23

require (
	github.com/gofiber/fiber/v2 v2.52.4
	github.com/gofiber/utils/v2 v2.0.0-beta.4

	// Database
	github.com/jackc/pgx/v5 v5.6.0
	github.com/redis/go-redis/v9 v9.4.0

	// Config & Logging
	github.com/joho/godotenv v1.5.1
	github.com/rs/zerolog v1.33.0

	// JSON
	github.com/goccy/go-json v0.10.2
)
