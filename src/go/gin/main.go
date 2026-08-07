package main

import (
	"database/sql"
	"os"
	"runtime"
	"strconv"

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

	db, err := sql.Open("postgres", mustEnv("DATABASE_URL"))
	if err != nil {
		panic(err)
	}
	defer db.Close()

	// database/sql defaults to unlimited open connections and only 2 idle
	// ones, so the effective pool differed from every other implementation.
	// DB_POOL_MAX is the contract-level value. See Fase 3.2.
	poolMax := envInt("DB_POOL_MAX", 32)
	db.SetMaxOpenConns(poolMax)
	db.SetMaxIdleConns(poolMax)

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

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	r.Run(":" + port)
}
