package main

import (
	"database/sql"
	"os"

	"github.com/gin-gonic/gin"
	"gin/handlers"
	"gin/services"
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

	r := gin.Default()

	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "running"})
	})

	r.GET("/health", handlers.HealthHandler(db, cacheService))
	r.GET("/healthz", handlers.HealthzHandler)
	r.GET("/json", handlers.JsonHandler)
	r.GET("/db/simple", handlers.DatabaseSimpleHandler(dbService))
	r.GET("/db/complex", handlers.DatabaseComplexHandler(dbService))
	r.GET("/cache", handlers.CacheHandler(cacheService))

	r.Run(":3000")
}
