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

func TestIOSInterviewBankIntegration(t *testing.T) {
	dsn := os.Getenv("LEARNY_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("LEARNY_TEST_DATABASE_URL is not set")
	}
	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()

	var theoryCount, livecodingCount, hiddenTestCount, tasksWithoutTests int
	err = pool.QueryRow(context.Background(), `
		SELECT
		 (SELECT count(*) FROM questions q
		  JOIN topics tp ON tp.id=q.topic_id JOIN sections s ON s.id=tp.section_id
		  JOIN tracks tr ON tr.id=s.track_id JOIN directions d ON d.id=tr.direction_id
		  WHERE d.slug='ios' AND tr.slug='interview' AND q.position BETWEEN 10000 AND 12020),
		 (SELECT count(*) FROM coding_tasks ct
		  JOIN topics tp ON tp.id=ct.topic_id JOIN sections s ON s.id=tp.section_id
		  JOIN tracks tr ON tr.id=s.track_id JOIN directions d ON d.id=tr.direction_id
		  WHERE d.slug='ios' AND tr.slug='interview' AND ct.slug LIKE 'ios-drill-%'),
		 (SELECT count(*) FROM coding_task_tests test
		  JOIN coding_tasks ct ON ct.id=test.coding_task_id
		  WHERE ct.slug LIKE 'ios-drill-%' AND test.hidden),
		 (SELECT count(*) FROM (
		  SELECT ct.id FROM coding_tasks ct
		  LEFT JOIN coding_task_tests test ON test.coding_task_id=ct.id
		  WHERE ct.slug LIKE 'ios-drill-%'
		  GROUP BY ct.id HAVING count(test.id)=0 OR bool_or(ct.reference_solution='')
		 ) invalid_tasks)
	`).Scan(&theoryCount, &livecodingCount, &hiddenTestCount, &tasksWithoutTests)
	if err != nil {
		t.Fatal(err)
	}
	if theoryCount != 1400 || livecodingCount != 600 {
		t.Fatalf("unexpected iOS interview bank: theory=%d livecoding=%d", theoryCount, livecodingCount)
	}
	if hiddenTestCount != 1100 || tasksWithoutTests != 0 {
		t.Fatalf("invalid iOS livecoding verification: hiddenTests=%d tasksWithoutTests=%d", hiddenTestCount, tasksWithoutTests)
	}
}

func TestIOSAdvancedLivecodingBankIntegration(t *testing.T) {
	dsn := os.Getenv("LEARNY_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("LEARNY_TEST_DATABASE_URL is not set")
	}
	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()

	var archetypeCount, drillCount, archetypeTestCount, drillTestCount, invalidTaskCount int
	err = pool.QueryRow(context.Background(), `
		SELECT
		 (SELECT count(*) FROM coding_tasks ct
		  JOIN topics tp ON tp.id=ct.topic_id JOIN sections s ON s.id=tp.section_id
		  JOIN tracks tr ON tr.id=s.track_id JOIN directions d ON d.id=tr.direction_id
		  WHERE d.slug='ios' AND tr.slug='interview'
		    AND ct.slug LIKE 'ios-advanced-%' AND ct.slug NOT LIKE 'ios-advanced-drill-%'),
		 (SELECT count(*) FROM coding_tasks ct
		  JOIN topics tp ON tp.id=ct.topic_id JOIN sections s ON s.id=tp.section_id
		  JOIN tracks tr ON tr.id=s.track_id JOIN directions d ON d.id=tr.direction_id
		  WHERE d.slug='ios' AND tr.slug='interview' AND ct.slug LIKE 'ios-advanced-drill-%'),
		 (SELECT count(*) FROM coding_task_tests test
		  JOIN coding_tasks ct ON ct.id=test.coding_task_id
		  WHERE ct.slug LIKE 'ios-advanced-%' AND ct.slug NOT LIKE 'ios-advanced-drill-%' AND test.hidden),
		 (SELECT count(*) FROM coding_task_tests test
		  JOIN coding_tasks ct ON ct.id=test.coding_task_id
		  WHERE ct.slug LIKE 'ios-advanced-drill-%' AND test.hidden),
		 (SELECT count(*) FROM (
		  SELECT ct.id FROM coding_tasks ct
		  LEFT JOIN coding_task_tests test ON test.coding_task_id=ct.id
		  WHERE ct.slug LIKE 'ios-advanced-%'
		  GROUP BY ct.id HAVING count(test.id)=0 OR bool_or(ct.reference_solution='')
		 ) invalid_tasks)
	`).Scan(&archetypeCount, &drillCount, &archetypeTestCount, &drillTestCount, &invalidTaskCount)
	if err != nil {
		t.Fatal(err)
	}
	if archetypeCount != 30 || drillCount != 600 {
		t.Fatalf("unexpected advanced livecoding bank: archetypes=%d drills=%d", archetypeCount, drillCount)
	}
	if archetypeTestCount != 60 || drillTestCount != 1200 || invalidTaskCount != 0 {
		t.Fatalf("invalid advanced livecoding verification: archetypeTests=%d drillTests=%d invalidTasks=%d", archetypeTestCount, drillTestCount, invalidTaskCount)
	}
}
