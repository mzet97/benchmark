package db

import (
	"context"
	"fmt"
	"os"
	"strconv"

	"github.com/jackc/pgx/v5/pgxpool"
)

type DB struct {
	Pool *pgxpool.Pool
}

func Connect(ctx context.Context) (*DB, error) {
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		databaseURL = "postgres://postgres:postgres@localhost:5432/benchmark"
	}

	cfg, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("parse database url: %w", err)
	}
	// pgxpool.New with no config leaves MaxConns at pgx's default of
	// max(4, runtime.NumCPU()) -- around 48 on this node, and derived from the
	// *host* core count rather than from the contract. DB_POOL_MAX exists so the
	// pool size is not a per-implementation accident.
	cfg.MaxConns = int32(envInt("DB_POOL_MAX", 32))

	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("unable to create connection pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("unable to ping database: %w", err)
	}

	return &DB{Pool: pool}, nil
}

func (d *DB) Close() {
	if d.Pool != nil {
		d.Pool.Close()
	}
}

// envInt reads an integer from the environment, falling back to def when unset or
// unparseable. DB_POOL_MAX is a contract-level knob from the shared ConfigMap
// (deploy/k3s/base/configmap.yaml): every implementation reads the same value so
// the data access layer stops being a hidden variable in the ranking.
func envInt(key string, def int) int {
	if raw := os.Getenv(key); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil && n > 0 {
			return n
		}
	}
	return def
}
