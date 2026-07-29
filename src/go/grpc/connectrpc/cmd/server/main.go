package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"benchmark-connectrpc/internal/cache"
	"benchmark-connectrpc/internal/db"
	"benchmark-connectrpc/internal/service"

	"connectrpc.com/connect"
	"connectrpc.com/grpchealth"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"

	benchmarkpb "benchmark-connectrpc/gen/benchmark"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Connect to PostgreSQL
	database, err := db.Connect(ctx)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.Close()

	// Connect to Redis
	redisCache, err := cache.Connect(ctx)
	if err != nil {
		log.Fatalf("Failed to connect to redis: %v", err)
	}
	defer redisCache.Close()

	// Create service handler
	svc := service.New(database, redisCache)

	// Create ConnectRPC handler with interceptors
	mux := http.NewServeMux()

	// Register the BenchmarkService ConnectRPC handler
	path, handler := benchmarkpb.NewBenchmarkServiceHandler(svc,
		connect.WithInterceptors(),
	)
	mux.Handle(path, handler)

	// Register gRPC health check service for k8s probes.
	// grpchealth.NewHandler returns an HTTP handler compatible with
	// the standard http.ServeMux pattern used by ConnectRPC.
	checker := grpchealth.NewStaticChecker(
		"benchmark.BenchmarkService",
	)
	healthPath, healthHandler := grpchealth.NewHandler(checker)
	mux.Handle(healthPath, healthHandler)

	// Create HTTP server with h2c for cleartext HTTP/2
	server := &http.Server{
		Addr:    ":50051",
		Handler: h2c.NewHandler(mux, &http2.Server{}),
	}

	// Graceful shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		sig := <-sigCh
		fmt.Printf("Received signal %v, shutting down gracefully...\n", sig)
		if err := server.Shutdown(ctx); err != nil {
			log.Printf("Server shutdown error: %v", err)
		}
		cancel()
	}()

	fmt.Println("ConnectRPC server listening on :50051")
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Failed to serve: %v", err)
	}
}
