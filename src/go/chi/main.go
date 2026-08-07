package main

import (
	"database/sql"
	"log"
	"net/http"
	"os"
	"runtime"
	"strconv"

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

// envInt reads an integer tuning knob from the environment, falling back to
// def when unset or unparseable. These knobs (BENCH_CPUS, DB_POOL_MAX) come
// from the shared ConfigMap so every implementation is configured alike.
func envInt(key string, def int) int {
	raw := os.Getenv(key)
	if raw == "" {
		return def
	}
	v, err := strconv.Atoi(raw)
	if err != nil || v <= 0 {
		return def
	}
	return v
}

func main() {
	// Go reads the host's CPU count, not the cgroup quota, so inside a pod
	// limited to N cores it would still size its scheduler for every core on
	// the node. See docs/ACTION_PLAN.md, Fase 3.1.
	runtime.GOMAXPROCS(envInt("BENCH_CPUS", runtime.NumCPU()))

	var err error

	db, err = sql.Open("postgres", mustEnv("DATABASE_URL"))
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	// database/sql defaults to unlimited open connections and only 2 idle
	// ones, so the effective pool differed from every other implementation.
	// DB_POOL_MAX is the contract-level value. See Fase 3.2.
	poolMax := envInt("DB_POOL_MAX", 32)
	db.SetMaxOpenConns(poolMax)
	db.SetMaxIdleConns(poolMax)

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

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Println("Starting server on :" + port)
	http.ListenAndServe(":"+port, r)
}
