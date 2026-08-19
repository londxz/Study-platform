package store

import (
	"context"

	"learny/backend/internal/model"
)

type LessonInput struct {
	TopicID         string
	Slug            string
	Title           string
	BodyMarkdown    string
	DurationMinutes int
	Position        int
	Status          string
}

func (s *Store) Lessons(ctx context.Context, includeDraft bool) ([]model.Lesson, error) {
	predicate := "WHERE l.status='published' AND tp.status='published' AND s.status='published' AND tr.status='published' AND d.status='published'"
	if includeDraft {
		predicate = ""
	}
	rows, err := s.pool.Query(ctx, `SELECT l.id::text,l.topic_id::text,tr.slug,s.id::text,d.slug,s.title,
		l.slug,l.title,l.body_markdown,l.duration_minutes,l.position,l.status::text,l.created_at,l.updated_at
		FROM lessons l JOIN topics tp ON tp.id=l.topic_id JOIN sections s ON s.id=tp.section_id
		JOIN tracks tr ON tr.id=s.track_id JOIN directions d ON d.id=tr.direction_id `+predicate+`
		ORDER BY d.position,tr.position,s.position,l.position,l.created_at`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := make([]model.Lesson, 0)
	for rows.Next() {
		var item model.Lesson
		if err := rows.Scan(&item.ID, &item.TopicID, &item.TrackSlug, &item.SectionID, &item.DirectionSlug,
			&item.SectionTitle, &item.Slug, &item.Title, &item.BodyMarkdown, &item.DurationMinutes,
			&item.Position, &item.Status, &item.CreatedAt, &item.UpdatedAt); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) Lesson(ctx context.Context, id string, includeDraft bool) (model.Lesson, error) {
	predicate := "AND l.status='published' AND tp.status='published' AND s.status='published' AND tr.status='published' AND d.status='published'"
	if includeDraft {
		predicate = ""
	}
	var item model.Lesson
	err := s.pool.QueryRow(ctx, `SELECT l.id::text,l.topic_id::text,tr.slug,s.id::text,d.slug,s.title,
		l.slug,l.title,l.body_markdown,l.duration_minutes,l.position,l.status::text,l.created_at,l.updated_at
		FROM lessons l JOIN topics tp ON tp.id=l.topic_id JOIN sections s ON s.id=tp.section_id
		JOIN tracks tr ON tr.id=s.track_id JOIN directions d ON d.id=tr.direction_id
		WHERE l.id=$1 `+predicate, id).Scan(&item.ID, &item.TopicID, &item.TrackSlug, &item.SectionID,
		&item.DirectionSlug, &item.SectionTitle, &item.Slug, &item.Title, &item.BodyMarkdown,
		&item.DurationMinutes, &item.Position, &item.Status, &item.CreatedAt, &item.UpdatedAt)
	return item, notFound(err)
}

func (s *Store) CreateLesson(ctx context.Context, input LessonInput) (model.Lesson, error) {
	var id string
	err := s.pool.QueryRow(ctx, `INSERT INTO lessons (topic_id,slug,title,body_markdown,duration_minutes,position,status)
		VALUES ($1,$2,$3,$4,$5,$6,$7::content_status) RETURNING id::text`, input.TopicID, input.Slug,
		input.Title, input.BodyMarkdown, input.DurationMinutes, input.Position, input.Status).Scan(&id)
	if err != nil {
		return model.Lesson{}, err
	}
	return s.Lesson(ctx, id, true)
}

func (s *Store) UpdateLesson(ctx context.Context, id string, input LessonInput) (model.Lesson, error) {
	tag, err := s.pool.Exec(ctx, `UPDATE lessons SET topic_id=$2,slug=$3,title=$4,body_markdown=$5,
		duration_minutes=$6,position=$7,status=$8::content_status,updated_at=now() WHERE id=$1`, id,
		input.TopicID, input.Slug, input.Title, input.BodyMarkdown, input.DurationMinutes, input.Position, input.Status)
	if err != nil {
		return model.Lesson{}, err
	}
	if tag.RowsAffected() == 0 {
		return model.Lesson{}, ErrNotFound
	}
	return s.Lesson(ctx, id, true)
}

func (s *Store) ArchiveLesson(ctx context.Context, id string) error {
	tag, err := s.pool.Exec(ctx, `UPDATE lessons SET status='archived',updated_at=now() WHERE id=$1`, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}
