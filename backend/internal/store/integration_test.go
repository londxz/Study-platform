package store

import (
	"context"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
)

func TestCatalogIntegration(t *testing.T) {
	dsn := os.Getenv("LEARNY_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("LEARNY_TEST_DATABASE_URL is not set")
	}
	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	data := New(pool)
	items, err := data.Catalog(context.Background(), false)
	if err != nil {
		t.Fatal(err)
	}
	if len(items) != 2 || len(items[0].Tracks) != 2 || len(items[1].Tracks) != 2 {
		t.Fatalf("unexpected catalog shape: %#v", items)
	}
	lessons, err := data.Lessons(context.Background(), false)
	if err != nil {
		t.Fatal(err)
	}
	if len(lessons) < 2 {
		t.Fatalf("expected seeded lessons, got %d", len(lessons))
	}
}
