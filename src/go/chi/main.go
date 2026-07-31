package main

import (
	"database/sql"
	"log"
	"net/http"
	"os"

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

// mustEnv returns the value of key, aborting if it is unset. Credentials are
// never defaulted: a missing variable must fail loudly, not connect silently.
func mustEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.Fatalf("%s is required", key)
	}
	return v
}

func main() {
	var err error

	db, err = sql.Open("postgres", mustEnv("DATABASE_URL"))
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	redisOpt, err := goredis.ParseURL(mustEnv("REDIS_URL"))
	if err != nil {
		log.Fatal("Failed to parse REDIS_URL:", err)
	}
	redisClient = goredis.NewClient(redisOpt)
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
