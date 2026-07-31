package main

import (
	"database/sql"
	"os"

	"github.com/labstack/echo/v4"
	"echo/handlers"
	"echo/services"
	"github.com/go-redis/redis/v8"
	_ "github.com/lib/pq"
)

// mustEnv returns the value of key, aborting if it is unset. Credentials are
// never defaulted: a missing variable must fail loudly, not connect silently.
func mustEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		panic(key + " is required")
	}
	return v
}

func main() {
	db, err := sql.Open("postgres", mustEnv("DATABASE_URL"))
	if err != nil {
		panic(err)
	}
	defer db.Close()

	redisOpt, err := redis.ParseURL(mustEnv("REDIS_URL"))
	if err != nil {
		panic(err)
	}
	rdb := redis.NewClient(redisOpt)
	defer rdb.Close()

	dbService := services.NewDatabaseService(db)
	cacheService := services.NewCacheService(rdb)

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
