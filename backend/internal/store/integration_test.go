package store

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"learny/backend/internal/model"

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

func TestCreateInterviewSessionIntegration(t *testing.T) {
	dsn := os.Getenv("LEARNY_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("LEARNY_TEST_DATABASE_URL is not set")
	}
	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()

	identity := model.Identity{
		ExternalID: fmt.Sprintf("interview-integration-%d", time.Now().UnixNano()),
		Email:      "interview-integration@learny.local",
	}
	session, err := New(pool).CreateInterviewSession(context.Background(), identity, false, "ios", "livecoding", 3)
	if err != nil {
		t.Fatal(err)
	}
	if len(session.Items) != 3 {
		t.Fatalf("expected 3 interview items, got %d", len(session.Items))
	}
	for _, item := range session.Items {
		if item.Snapshot["title"] == nil || item.Snapshot["starterCode"] == nil {
			t.Fatalf("interview item snapshot is incomplete: %#v", item.Snapshot)
		}
	}
}
