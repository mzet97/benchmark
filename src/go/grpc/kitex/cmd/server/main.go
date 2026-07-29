package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"

	"benchmark-kitex/internal/cache"
	"benchmark-kitex/internal/db"
	"benchmark-kitex/internal/service"

	"github.com/cloudwego/kitex/server"
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

	// Create service implementation
	svc := service.New(database, redisCache)

	// Resolve listen address
	addr, _ := net.ResolveTCPAddr("tcp", ":50051")

	// Build Kitex server options
	opts := []server.Option{
		server.WithServiceAddr(addr),
		server.WithExitSignal(func() <-chan error {
			errCh := make(chan error, 1)
			sigCh := make(chan os.Signal, 1)
			signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
			go func() {
				sig := <-sigCh
				fmt.Printf("Received signal %v, shutting down gracefully...\n", sig)
				cancel()
				errCh <- nil
			}()
			return errCh
		}),
	}

	// Register the BenchmarkService with Kitex.
	// Once kitex_gen is generated, the actual call is:
	//   svr := benchmarksrv.NewServer(svc, opts...)
	// The placeholder below shows the wiring pattern.
	svr := registerService(svc, opts...)

	fmt.Println("Kitex server listening on :50051")
	if err := svr.Run(); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}

// registerService wires the BenchmarkServiceImpl into a Kitex server.
// Replace this with the generated benchmarksrv.NewServer once kitex_gen exists.
func registerService(svc *service.BenchmarkServiceImpl, opts ...server.Option) server.Server {
	// TODO: After running `kitex --service benchmark -gen-path kitex_gen benchmark.proto`
	// replace this with:
	//   return benchmarksrv.NewServer(svc, opts...)
	return server.NewServer(opts...)
}
