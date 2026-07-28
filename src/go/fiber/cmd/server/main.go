package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/benchmark/go-fiber/internal/handlers"
	"github.com/benchmark/go-fiber/internal/services"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/compress"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/fiber/v2/middleware/requestid"
	"github.com/jackc/pgx/v5"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"
)

var log zerolog.Logger

func main() {
	// Initialize logger
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
	log = zerolog.New(os.Stdout).With().Timestamp().Logger()

	// Load environment variables
	if err := loadEnv(); err != nil {
		log.Fatal().Err(err).Msg("Failed to load environment variables")
	}

	// Initialize database connection
	dbConn, err := initDatabase()
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to connect to database")
	}
	defer dbConn.Close(context.Background())

	// Initialize cache connection
	redisClient, err := initRedis()
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to connect to Redis")
	}
	defer redisClient.Close()

	// Initialize services
	dbService := services.NewDatabaseService(dbConn)
	cacheService := services.NewCacheService(redisClient)

	// Initialize handlers
	healthHandler := handlers.NewHealthHandler(dbService, cacheService)
	jsonHandler := handlers.NewJSONHandler()
	dbHandler := handlers.NewDatabaseHandler(dbService)
	cacheHandler := handlers.NewCacheHandler(cacheService)

	// Create Fiber app
	app := fiber.New(fiber.Config{
		Prefork:       false,
		CaseSensitive: true,
		StrictRouting: false,
		BodyLimit:     1 * 1024 * 1024, // 1MB
		WriteTimeout:  5 * time.Second,
		ReadTimeout:   5 * time.Second,
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}
			return c.Status(code).JSON(fiber.Map{
				"error":   err.Error(),
				"code":    code,
				"message": "Internal Server Error",
			})
		},
	})

	// Middleware
	app.Use(recover.New())
	app.Use(cors.New())
	app.Use(compress.New())
	app.Use(logger.New())
	app.Use(requestid.New())

	// Routes
	setupRoutes(app, healthHandler, jsonHandler, dbHandler, cacheHandler)

	// Start server in a goroutine
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	go func() {
		addr := fmt.Sprintf("0.0.0.0:%s", port)
		log.Info().Msg("Starting server on " + addr)
		if err := app.Listen(addr); err != nil {
			log.Fatal().Err(err).Msg("Failed to start server")
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info().Msg("Shutting down server...")

	// Close connections
	dbService.Close()
	cacheService.Close()

	// Shutdown server
	if err := app.Shutdown(); err != nil {
		log.Fatal().Err(err).Msg("Server forced to shutdown")
	}

	log.Info().Msg("Server exited")
}

func setupRoutes(
	app *fiber.App,
	healthHandler *handlers.HealthHandler,
	jsonHandler *handlers.JSONHandler,
	dbHandler *handlers.DatabaseHandler,
	cacheHandler *handlers.CacheHandler,
) {
	api := app.Group("/api/v1")

	// Health
	api.Get("/health", healthHandler.HandleHealth)

	// JSON
	api.Get("/json", jsonHandler.HandleJSON)

	// Database
	db := api.Group("/db")
	db.Get("/simple", dbHandler.HandleSimple)
	db.Get("/complex", dbHandler.HandleComplex)

	// Cache
	api.Get("/cache", cacheHandler.HandleCache)

	// Legacy routes (without /api/v1 prefix)
	app.Get("/health", healthHandler.HandleHealth)
	app.Get("/json", jsonHandler.HandleJSON)
	app.Get("/db/simple", dbHandler.HandleSimple)
	app.Get("/db/complex", dbHandler.HandleComplex)
	app.Get("/cache", cacheHandler.HandleCache)
}

func initDatabase() (*pgx.Conn, error) {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"
	}

	conn, err := pgx.Connect(context.Background(), dbURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	log.Info().Msg("Connected to PostgreSQL database")
	return conn, nil
}

func initRedis() (*redis.Client, error) {
	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		redisURL = "redis://:Admin@123@redis.home.arpa:30379"
	}

	opt, err := redis.ParseURL(redisURL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse Redis URL: %w", err)
	}

	client := redis.NewClient(opt)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to ping Redis: %w", err)
	}

	log.Info().Msg("Connected to Redis")
	return client, nil
}

func loadEnv() error {
	return nil // Using os.Getenv directly
}
