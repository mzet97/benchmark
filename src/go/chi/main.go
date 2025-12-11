package main

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"chi/handlers"
	"chi/services"
	goredis "github.com/go-redis/redis/v8"
	_ "github.com/lib/pq"
)

var (
	db          *sql.DB
	redisClient *goredis.Client
)

func main() {
	var err error

	db, err = sql.Open("postgres", "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api")
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	redisClient = goredis.NewClient(&goredis.Options{
		Addr:     "redis.home.arpa:30379",
		Password: "Admin@123",
	})
	defer redisClient.Close()

	dbService := services.NewDatabaseService(db)
	cacheService := services.NewCacheService(redisClient)

	r := chi.NewRouter()

	r.Get("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status": "running"}`))
	})

	r.Get("/health", handlers.HealthHandler(db, cacheService))
	r.Get("/healthz", handlers.HealthzHandler)
	r.Get("/json", handlers.JsonHandler)
	r.Get("/db/simple", handlers.DatabaseSimpleHandler(dbService))
	r.Get("/db/complex", handlers.DatabaseComplexHandler(dbService))
	r.Get("/cache", handlers.CacheHandler(cacheService))

	log.Println("Starting server on :3000")
	http.ListenAndServe(":3000", r)
}
