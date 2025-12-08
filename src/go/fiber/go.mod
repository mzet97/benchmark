module github.com/benchmark/go-fiber

go 1.23

require (
	github.com/gofiber/fiber/v2 v2.52.4
	github.com/gofiber/fiber/v2/middleware/compress v2.52.4
	github.com/gofiber/fiber/v2/middleware/cors v2.52.4
	github.com/gofiber/fiber/v2/middleware/logger v2.52.4
	github.com/gofiber/fiber/v2/middleware/recover v2.52.4
	github.com/gofiber/template/django v1.52.4
	github.com/gofiber/utils/v2 v2.52.4

	// Database
	github.com/jackc/pgx/v5 v5.6.0
	github.com/redis/go-redis/v9 v9.4.0

	// Config & Logging
	github.com/joho/godotenv v1.5.1
	github.com/rs/zerolog v1.33.0

	// JSON
	github.com/goccy/go-json v0.10.2

	// Health Checks
	github.com/gofiber/fiber/v2/middleware/healthcheck v2.52.4
)

// Development dependencies
require (
	github.com/onsi/ginkgo/v2 v2.16.0
	github.com/onsi/gomega v1.34.1
	github.com/stretchr/testify v1.9.0
)
