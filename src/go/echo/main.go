package main

import (
	"database/sql"

	"github.com/labstack/echo/v4"
	"echo/handlers"
	"echo/services"
	"github.com/go-redis/redis/v8"
	_ "github.com/lib/pq"
)

func main() {
	db, err := sql.Open("postgres", "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	redis := redis.NewClient(&redis.Options{
		Addr:     "redis.home.arpa:30379",
		Password: "Admin@123",
	})
	defer redis.Close()

	dbService := services.NewDatabaseService(db)
	cacheService := services.NewCacheService(redis)

	e := echo.New()

	e.GET("/", func(c echo.Context) error {
		return c.JSON(200, map[string]interface{}{"status": "running"})
	})

	e.GET("/health", handlers.HealthHandler(db, cacheService))
	e.GET("/healthz", handlers.HealthzHandler)
	e.GET("/json", handlers.JsonHandler)
	e.GET("/db/simple", handlers.DatabaseSimpleHandler(dbService))
	e.GET("/db/complex", handlers.DatabaseComplexHandler(dbService))
	e.GET("/cache", handlers.CacheHandler(cacheService))

	e.Logger.Fatal(e.Start(":3000"))
}
