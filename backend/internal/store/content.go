package store

import (
	"context"
	"strings"

	"learny/backend/internal/model"
)

type QuestionInput struct {
	TopicID         string
	Prompt          string
	Explanation     string
	ReferenceAnswer string
	Difficulty      int
	Position        int
	Status          string
}

func (s *Store) Questions(ctx context.Context, includeDraft bool) ([]model.Question, error) {
	predicate := "WHERE q.status = 'published' AND tp.status='published' AND s.status='published' AND tr.status='published' AND d.status='published'"
	if includeDraft {
		predicate = ""
	}
	rows, err := s.pool.Query(ctx, `SELECT q.id::text, q.topic_id::text, tr.slug, s.id::text, d.slug, s.title, q.prompt, q.explanation,
		q.reference_answer, q.difficulty, q.position, q.status::text, q.created_at, q.updated_at
		FROM questions q
		JOIN topics tp ON tp.id = q.topic_id
		JOIN sections s ON s.id = tp.section_id
		JOIN tracks tr ON tr.id = s.track_id
		JOIN directions d ON d.id = tr.direction_id `+predicate+`
		ORDER BY d.position, s.position, q.position, q.created_at`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := make([]model.Question, 0)
	for rows.Next() {
		var item model.Question
		if err := rows.Scan(&item.ID, &item.TopicID, &item.TrackSlug, &item.SectionID, &item.DirectionSlug, &item.SectionTitle, &item.Prompt,
			&item.Explanation, &item.ReferenceAnswer, &item.Difficulty, &item.Position, &item.Status,
			&item.CreatedAt, &item.UpdatedAt); err != nil {
			return nil, err
		}
		if !includeDraft {
			item.ReferenceAnswer = ""
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) Question(ctx context.Context, id string, includeDraft bool) (model.Question, error) {
	predicate := "AND q.status = 'published' AND tp.status='published' AND s.status='published' AND tr.status='published' AND d.status='published'"
	if includeDraft {
		predicate = ""
	}
	var item model.Question
	err := s.pool.QueryRow(ctx, `SELECT q.id::text, q.topic_id::text, tr.slug, s.id::text, d.slug, s.title, q.prompt, q.explanation,
		q.reference_answer, q.difficulty, q.position, q.status::text, q.created_at, q.updated_at
		FROM questions q JOIN topics tp ON tp.id=q.topic_id JOIN sections s ON s.id=tp.section_id
		JOIN tracks tr ON tr.id=s.track_id JOIN directions d ON d.id=tr.direction_id
		WHERE q.id=$1 `+predicate, id).Scan(&item.ID, &item.TopicID, &item.TrackSlug, &item.SectionID, &item.DirectionSlug, &item.SectionTitle,
		&item.Prompt, &item.Explanation, &item.ReferenceAnswer, &item.Difficulty, &item.Position,
		&item.Status, &item.CreatedAt, &item.UpdatedAt)
	if err != nil {
		return model.Question{}, notFound(err)
	}
	if !includeDraft {
		item.ReferenceAnswer = ""
	}
	return item, nil
}

func (s *Store) CreateQuestion(ctx context.Context, input QuestionInput) (model.Question, error) {
	var id string
	err := s.pool.QueryRow(ctx, `INSERT INTO questions
		(topic_id,prompt,explanation,reference_answer,difficulty,position,status)
		VALUES ($1,$2,$3,$4,$5,$6,$7::content_status) RETURNING id::text`, input.TopicID, input.Prompt,
		input.Explanation, input.ReferenceAnswer, input.Difficulty, input.Position, input.Status).Scan(&id)
	if err != nil {
		return model.Question{}, err
	}
	return s.Question(ctx, id, true)
}

func (s *Store) UpdateQuestion(ctx context.Context, id string, input QuestionInput) (model.Question, error) {
	tag, err := s.pool.Exec(ctx, `UPDATE questions SET topic_id=$2,prompt=$3,explanation=$4,reference_answer=$5,
		difficulty=$6,position=$7,status=$8::content_status,updated_at=now() WHERE id=$1`, id, input.TopicID,
		input.Prompt, input.Explanation, input.ReferenceAnswer, input.Difficulty, input.Position, input.Status)
	if err != nil {
		return model.Question{}, err
	}
	if tag.RowsAffected() == 0 {
		return model.Question{}, ErrNotFound
	}
	return s.Question(ctx, id, true)
}

func (s *Store) ArchiveQuestion(ctx context.Context, id string) error {
	tag, err := s.pool.Exec(ctx, `UPDATE questions SET status='archived',updated_at=now() WHERE id=$1`, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

type CodingTaskInput struct {
	TopicID           string
	Slug              string
	Title             string
	StatementMarkdown string
	Hint              string
	Language          string
	StarterCode       string
	ReferenceSolution string
	TimeLimitMS       int
	MemoryLimitKB     int
	Difficulty        int
	Position          int
	Status            string
}

func (s *Store) CodingTasks(ctx context.Context, includeDraft bool) ([]model.CodingTask, error) {
	predicate := "WHERE ct.status = 'published' AND tp.status='published' AND s.status='published' AND tr.status='published' AND d.status='published'"
	if includeDraft {
		predicate = ""
	}
	rows, err := s.pool.Query(ctx, `SELECT ct.id::text,ct.topic_id::text,tr.slug,s.id::text,d.slug,s.title,ct.slug,ct.title,
		ct.statement_markdown,ct.hint,ct.language,ct.starter_code,ct.reference_solution,ct.time_limit_ms,
		ct.memory_limit_kb,ct.difficulty,ct.position,ct.status::text,ct.created_at,ct.updated_at
		FROM coding_tasks ct JOIN topics tp ON tp.id=ct.topic_id JOIN sections s ON s.id=tp.section_id
		JOIN tracks tr ON tr.id=s.track_id JOIN directions d ON d.id=tr.direction_id `+predicate+`
		ORDER BY d.position,s.position,ct.position,ct.created_at`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := make([]model.CodingTask, 0)
	for rows.Next() {
		var item model.CodingTask
		if err := scanCodingTask(rows.Scan, &item); err != nil {
			return nil, err
		}
		if !includeDraft {
			item.ReferenceSolution = ""
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) CodingTask(ctx context.Context, id string, includeDraft bool) (model.CodingTask, error) {
	predicate := "AND ct.status = 'published' AND tp.status='published' AND s.status='published' AND tr.status='published' AND d.status='published'"
	if includeDraft {
		predicate = ""
	}
	var item model.CodingTask
	row := s.pool.QueryRow(ctx, `SELECT ct.id::text,ct.topic_id::text,tr.slug,s.id::text,d.slug,s.title,ct.slug,ct.title,
		ct.statement_markdown,ct.hint,ct.language,ct.starter_code,ct.reference_solution,ct.time_limit_ms,
		ct.memory_limit_kb,ct.difficulty,ct.position,ct.status::text,ct.created_at,ct.updated_at
		FROM coding_tasks ct JOIN topics tp ON tp.id=ct.topic_id JOIN sections s ON s.id=tp.section_id
		JOIN tracks tr ON tr.id=s.track_id JOIN directions d ON d.id=tr.direction_id WHERE ct.id=$1 `+predicate, id)
	if err := scanCodingTask(row.Scan, &item); err != nil {
		return model.CodingTask{}, notFound(err)
	}
	if !includeDraft {
		item.ReferenceSolution = ""
	}
	return item, nil
}

type scanner func(dest ...any) error

func scanCodingTask(scan scanner, item *model.CodingTask) error {
	return scan(&item.ID, &item.TopicID, &item.TrackSlug, &item.SectionID, &item.DirectionSlug, &item.SectionTitle, &item.Slug, &item.Title,
		&item.StatementMarkdown, &item.Hint, &item.Language, &item.StarterCode, &item.ReferenceSolution,
		&item.TimeLimitMS, &item.MemoryLimitKB, &item.Difficulty, &item.Position, &item.Status,
		&item.CreatedAt, &item.UpdatedAt)
}

func (s *Store) CreateCodingTask(ctx context.Context, input CodingTaskInput) (model.CodingTask, error) {
	var id string
	err := s.pool.QueryRow(ctx, `INSERT INTO coding_tasks (topic_id,slug,title,statement_markdown,hint,language,
		starter_code,reference_solution,time_limit_ms,memory_limit_kb,difficulty,position,status)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13::content_status) RETURNING id::text`, input.TopicID,
		input.Slug, input.Title, input.StatementMarkdown, input.Hint, input.Language, input.StarterCode,
		input.ReferenceSolution, input.TimeLimitMS, input.MemoryLimitKB, input.Difficulty, input.Position, input.Status).Scan(&id)
	if err != nil {
		return model.CodingTask{}, err
	}
	return s.CodingTask(ctx, id, true)
}

func (s *Store) UpdateCodingTask(ctx context.Context, id string, input CodingTaskInput) (model.CodingTask, error) {
	tag, err := s.pool.Exec(ctx, `UPDATE coding_tasks SET topic_id=$2,slug=$3,title=$4,statement_markdown=$5,
		hint=$6,language=$7,starter_code=$8,reference_solution=$9,time_limit_ms=$10,memory_limit_kb=$11,
		difficulty=$12,position=$13,status=$14::content_status,updated_at=now() WHERE id=$1`, id, input.TopicID,
		input.Slug, input.Title, input.StatementMarkdown, input.Hint, input.Language, input.StarterCode,
		input.ReferenceSolution, input.TimeLimitMS, input.MemoryLimitKB, input.Difficulty, input.Position, input.Status)
	if err != nil {
		return model.CodingTask{}, err
	}
	if tag.RowsAffected() == 0 {
		return model.CodingTask{}, ErrNotFound
	}
	return s.CodingTask(ctx, id, true)
}

func (s *Store) ArchiveCodingTask(ctx context.Context, id string) error {
	tag, err := s.pool.Exec(ctx, `UPDATE coding_tasks SET status='archived',updated_at=now() WHERE id=$1`, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

func NormalizeStatus(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "published" || value == "archived" {
		return value
	}
	return "draft"
}
