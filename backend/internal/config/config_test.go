package config

import "testing"

func TestLoadProductionRequirements(t *testing.T) {
	t.Setenv("DATABASE_URL", "postgres://example")
	t.Setenv("LEARNY_ENV", "production")
	t.Setenv("LEARNY_BFF_SECRET", "a-secret-with-at-least-thirty-two-characters")
	t.Setenv("LEARNY_ADMIN_EMAILS", "LONDXZ@example.com")
	t.Setenv("LEARNY_SUBMISSION_CONCURRENCY", "3")
	cfg, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if !cfg.IsAdmin("londxz@example.com") || cfg.SubmissionConcurrency != 3 {
		t.Fatalf("unexpected config: %#v", cfg)
	}
}

func TestLoadRejectsUnsafeConcurrency(t *testing.T) {
	t.Setenv("DATABASE_URL", "postgres://example")
	t.Setenv("LEARNY_ENV", "development")
	t.Setenv("LEARNY_SUBMISSION_CONCURRENCY", "0")
	if _, err := Load(); err == nil {
		t.Fatal("expected invalid concurrency error")
	}
}
