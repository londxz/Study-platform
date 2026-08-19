package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"learny/backend/internal/config"
	"learny/backend/internal/httpapi"
	"learny/backend/internal/runner"
	"learny/backend/internal/store"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))
	cfg, err := config.Load()
	if err != nil {
		logger.Error("configuration error", "error", err)
		os.Exit(1)
	}
	if cfg.MigrateOnStart {
		if err := migrate(cfg.DatabaseURL); err != nil {
			logger.Error("migration failed", "error", err)
			os.Exit(1)
		}
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	poolConfig, err := pgxpool.ParseConfig(cfg.DatabaseURL)
	if err != nil {
		cancel()
		logger.Error("database configuration failed", "error", err)
		os.Exit(1)
	}
	// Neon uses PgBouncer transaction pooling for pooled connection strings.
	// Unnamed execution avoids prepared-statement name collisions between
	// backend connections while retaining the extended PostgreSQL protocol.
	poolConfig.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeExec
	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	cancel()
	if err != nil {
		logger.Error("database connection failed", "error", err)
		os.Exit(1)
	}
	defer pool.Close()
	if err := pool.Ping(context.Background()); err != nil {
		logger.Error("database is unavailable", "error", err)
		os.Exit(1)
	}

	data := store.New(pool)
	codeRunner := runner.New(cfg.Judge0URL, 10*time.Second)
	server := &http.Server{
		Addr:              cfg.Address,
		Handler:           httpapi.New(cfg, data, codeRunner, logger),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      20 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	shutdownCtx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	go func() {
		logger.Info("learny api started", "address", cfg.Address, "environment", cfg.Environment)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("server failed", "error", err)
			stop()
		}
	}()

	<-shutdownCtx.Done()
	ctx, cancel = context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := server.Shutdown(ctx); err != nil {
		logger.Error("graceful shutdown failed", "error", err)
	}
}

func migrate(databaseURL string) error {
	connConfig, err := pgx.ParseConfig(databaseURL)
	if err != nil {
		return err
	}
	connConfig.DefaultQueryExecMode = pgx.QueryExecModeExec
	db := stdlib.OpenDB(*connConfig)
	defer db.Close()
	if err := goose.SetDialect("postgres"); err != nil {
		return err
	}
	return goose.Up(db, "migrations")
}
