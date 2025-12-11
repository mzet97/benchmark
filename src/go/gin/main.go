package main

import (
	"database/sql"

	"github.com/gin-gonic/gin"
	"gin/handlers"
	"gin/services"
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
