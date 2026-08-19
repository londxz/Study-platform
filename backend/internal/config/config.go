package config

import (
	"errors"
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Environment           string
	Address               string
	DatabaseURL           string
	BFFSecret             string
	AdminEmails           map[string]struct{}
	MigrateOnStart        bool
	SeedOnStart           bool
	Judge0URL             string
	RequestTimeout        time.Duration
	SubmissionConcurrency int
}

func Load() (Config, error) {
	port := value("PORT", "8080")
	cfg := Config{
		Environment:           value("LEARNY_ENV", "development"),
		Address:               ":" + port,
		DatabaseURL:           strings.TrimSpace(os.Getenv("DATABASE_URL")),
		BFFSecret:             strings.TrimSpace(os.Getenv("LEARNY_BFF_SECRET")),
		AdminEmails:           parseEmails(os.Getenv("LEARNY_ADMIN_EMAILS")),
		MigrateOnStart:        boolean("LEARNY_MIGRATE_ON_START", false),
		SeedOnStart:           boolean("LEARNY_SEED_ON_START", false),
		Judge0URL:             strings.TrimRight(value("JUDGE0_URL", "https://ce.judge0.com"), "/"),
		RequestTimeout:        duration("LEARNY_REQUEST_TIMEOUT", 12*time.Second),
		SubmissionConcurrency: integer("LEARNY_SUBMISSION_CONCURRENCY", 2),
	}
	if cfg.DatabaseURL == "" {
		return Config{}, errors.New("DATABASE_URL is required")
	}
	if cfg.Environment == "production" && len(cfg.BFFSecret) < 32 {
		return Config{}, errors.New("LEARNY_BFF_SECRET must contain at least 32 characters in production")
	}
	if cfg.Environment == "production" && len(cfg.AdminEmails) == 0 {
		return Config{}, errors.New("LEARNY_ADMIN_EMAILS is required in production")
	}
	if cfg.SubmissionConcurrency < 1 || cfg.SubmissionConcurrency > 20 {
		return Config{}, errors.New("LEARNY_SUBMISSION_CONCURRENCY must be between 1 and 20")
	}
	return cfg, nil
}

func (c Config) IsAdmin(email string) bool {
	_, ok := c.AdminEmails[strings.ToLower(strings.TrimSpace(email))]
	return ok || (c.Environment != "production" && len(c.AdminEmails) == 0)
}

func value(key, fallback string) string {
	if result := strings.TrimSpace(os.Getenv(key)); result != "" {
		return result
	}
	return fallback
}

func boolean(key string, fallback bool) bool {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return fallback
	}
	result, err := strconv.ParseBool(raw)
	return err == nil && result
}

func duration(key string, fallback time.Duration) time.Duration {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return fallback
	}
	result, err := time.ParseDuration(raw)
	if err != nil {
		return fallback
	}
	return result
}

func integer(key string, fallback int) int {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return fallback
	}
	result, err := strconv.Atoi(raw)
	if err != nil {
		return fallback
	}
	return result
}

func parseEmails(raw string) map[string]struct{} {
	result := make(map[string]struct{})
	for _, item := range strings.Split(raw, ",") {
		if email := strings.ToLower(strings.TrimSpace(item)); email != "" {
			result[email] = struct{}{}
		}
	}
	return result
}
