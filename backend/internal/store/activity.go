package store

import (
	"context"
	"encoding/json"
	"errors"

	"learny/backend/internal/model"

	"github.com/jackc/pgx/v5"
)

func (s *Store) EnsureUser(ctx context.Context, identity model.Identity, admin bool) (string, error) {
	var id string
	err := s.pool.QueryRow(ctx, `INSERT INTO users (external_user_id,email,role)
		VALUES ($1,$2,CASE WHEN $3 THEN 'admin'::user_role ELSE 'student'::user_role END)
		ON CONFLICT (external_user_id) DO UPDATE SET email=EXCLUDED.email,
		role=CASE WHEN $3 THEN 'admin'::user_role ELSE users.role END,updated_at=now()
		RETURNING id::text`, identity.ExternalID, identity.Email, admin).Scan(&id)
	return id, err
}

func (s *Store) Progress(ctx context.Context, identity model.Identity, admin bool) ([]model.Progress, error) {
	userID, err := s.EnsureUser(ctx, identity, admin)
	if err != nil {
		return nil, err
	}
	rows, err := s.pool.Query(ctx, `SELECT content_type,content_id::text,status::text,last_position,started_at,
		completed_at,updated_at FROM user_progress WHERE user_id=$1 ORDER BY updated_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := make([]model.Progress, 0)
	for rows.Next() {
		var item model.Progress
		if err := rows.Scan(&item.ContentType, &item.ContentID, &item.Status, &item.LastPosition,
			&item.StartedAt, &item.CompletedAt, &item.UpdatedAt); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) SetProgress(ctx context.Context, identity model.Identity, admin bool, item model.Progress) (model.Progress, error) {
	userID, err := s.EnsureUser(ctx, identity, admin)
	if err != nil {
		return model.Progress{}, err
	}
	err = s.pool.QueryRow(ctx, `INSERT INTO user_progress
		(user_id,content_type,content_id,status,last_position,started_at,completed_at)
		VALUES ($1,$2,$3,$4::progress_status,$5,
			CASE WHEN $4 <> 'not_started' THEN now() ELSE NULL END,
			CASE WHEN $4 = 'completed' THEN now() ELSE NULL END)
		ON CONFLICT (user_id,content_type,content_id) DO UPDATE SET status=EXCLUDED.status,
		last_position=EXCLUDED.last_position,
		started_at=COALESCE(user_progress.started_at,EXCLUDED.started_at),
		completed_at=CASE WHEN EXCLUDED.status='completed' THEN COALESCE(user_progress.completed_at,now()) ELSE NULL END,
		updated_at=now()
		RETURNING content_type,content_id::text,status::text,last_position,started_at,completed_at,updated_at`,
		userID, item.ContentType, item.ContentID, item.Status, item.LastPosition).Scan(&item.ContentType,
		&item.ContentID, &item.Status, &item.LastPosition, &item.StartedAt, &item.CompletedAt, &item.UpdatedAt)
	return item, err
}

func (s *Store) CreateInterviewSession(ctx context.Context, identity model.Identity, admin bool, directionSlug, mode string, count int) (model.InterviewSession, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return model.InterviewSession{}, err
	}
	defer func() { _ = tx.Rollback(ctx) }()
	var userID, directionID string
	err = tx.QueryRow(ctx, `INSERT INTO users (external_user_id,email,role) VALUES
		($1,$2,CASE WHEN $3 THEN 'admin'::user_role ELSE 'student'::user_role END)
		ON CONFLICT (external_user_id) DO UPDATE SET email=EXCLUDED.email,
		role=CASE WHEN $3 THEN 'admin'::user_role ELSE users.role END,updated_at=now()
		RETURNING id::text`, identity.ExternalID, identity.Email, admin).Scan(&userID)
	if err != nil {
		return model.InterviewSession{}, err
	}
	if err := tx.QueryRow(ctx, `SELECT id::text FROM directions WHERE slug=$1 AND status='published'`, directionSlug).Scan(&directionID); err != nil {
		return model.InterviewSession{}, notFound(err)
	}
	var session model.InterviewSession
	err = tx.QueryRow(ctx, `INSERT INTO interview_sessions (user_id,direction_id,mode,requested_count)
		VALUES ($1,$2,$3::interview_mode,$4)
		RETURNING id::text,$3,status::text,started_at,completed_at`, userID, directionID, mode, count).Scan(
		&session.ID, &session.Mode, &session.Status, &session.StartedAt, &session.CompletedAt)
	if err != nil {
		return model.InterviewSession{}, err
	}
	session.DirectionSlug = directionSlug
	session.RequestedCount = count
	session.Items = []model.InterviewItem{}
	if mode == "theory" {
		rows, err := tx.Query(ctx, `SELECT q.id::text,q.prompt,q.difficulty,s.title
			FROM questions q JOIN topics tp ON tp.id=q.topic_id JOIN sections s ON s.id=tp.section_id
			JOIN tracks tr ON tr.id=s.track_id JOIN directions d ON d.id=tr.direction_id
			WHERE d.id=$1 AND tr.slug='interview' AND tr.status='published' AND s.status='published'
			AND tp.status='published' AND q.status='published'
			ORDER BY random() LIMIT $2`, directionID, count)
		if err != nil {
			return model.InterviewSession{}, err
		}
		type questionCandidate struct {
			id, prompt, section string
			difficulty          int
		}
		candidates := make([]questionCandidate, 0, count)
		for rows.Next() {
			var candidate questionCandidate
			if err := rows.Scan(&candidate.id, &candidate.prompt, &candidate.difficulty, &candidate.section); err != nil {
				rows.Close()
				return model.InterviewSession{}, err
			}
			candidates = append(candidates, candidate)
		}
		if err := rows.Err(); err != nil {
			rows.Close()
			return model.InterviewSession{}, err
		}
		rows.Close()
		for index, candidate := range candidates {
			snapshot := map[string]any{"prompt": candidate.prompt, "difficulty": candidate.difficulty, "section": candidate.section}
			item, err := insertSessionItem(ctx, tx, session.ID, index+1, &candidate.id, nil, snapshot)
			if err != nil {
				return model.InterviewSession{}, err
			}
			session.Items = append(session.Items, item)
		}
	} else {
		rows, err := tx.Query(ctx, `SELECT ct.id::text,ct.title,ct.statement_markdown,ct.hint,ct.language,ct.starter_code,ct.difficulty,s.title
			FROM coding_tasks ct JOIN topics tp ON tp.id=ct.topic_id JOIN sections s ON s.id=tp.section_id
			JOIN tracks tr ON tr.id=s.track_id JOIN directions d ON d.id=tr.direction_id
			WHERE d.id=$1 AND tr.slug='interview' AND tr.status='published' AND s.status='published'
			AND tp.status='published' AND ct.status='published'
			ORDER BY random() LIMIT $2`, directionID, count)
		if err != nil {
			return model.InterviewSession{}, err
		}
		type taskCandidate struct {
			id, title, statement, hint, language, starterCode, section string
			difficulty                                                 int
		}
		candidates := make([]taskCandidate, 0, count)
		for rows.Next() {
			var candidate taskCandidate
			if err := rows.Scan(&candidate.id, &candidate.title, &candidate.statement, &candidate.hint,
				&candidate.language, &candidate.starterCode, &candidate.difficulty, &candidate.section); err != nil {
				rows.Close()
				return model.InterviewSession{}, err
			}
			candidates = append(candidates, candidate)
		}
		if err := rows.Err(); err != nil {
			rows.Close()
			return model.InterviewSession{}, err
		}
		rows.Close()
		for index, candidate := range candidates {
			snapshot := map[string]any{"title": candidate.title, "statementMarkdown": candidate.statement, "hint": candidate.hint,
				"language": candidate.language, "starterCode": candidate.starterCode, "difficulty": candidate.difficulty, "section": candidate.section}
			item, err := insertSessionItem(ctx, tx, session.ID, index+1, nil, &candidate.id, snapshot)
			if err != nil {
				return model.InterviewSession{}, err
			}
			session.Items = append(session.Items, item)
		}
	}
	if len(session.Items) != count {
		return model.InterviewSession{}, errors.New("not enough published interview items")
	}
	if err := tx.Commit(ctx); err != nil {
		return model.InterviewSession{}, err
	}
	return session, nil
}

func insertSessionItem(ctx context.Context, tx pgx.Tx, sessionID string, position int, questionID, taskID *string, snapshot map[string]any) (model.InterviewItem, error) {
	raw, err := json.Marshal(snapshot)
	if err != nil {
		return model.InterviewItem{}, err
	}
	item := model.InterviewItem{Position: position, QuestionID: questionID, CodingTaskID: taskID, Snapshot: snapshot}
	err = tx.QueryRow(ctx, `INSERT INTO interview_session_items
		(session_id,question_id,coding_task_id,position,snapshot) VALUES ($1,$2,$3,$4,$5)
		RETURNING id::text,answer,code,passed`, sessionID, questionID, taskID, position, raw).Scan(&item.ID, &item.Answer, &item.Code, &item.Passed)
	return item, err
}

func (s *Store) InterviewSession(ctx context.Context, identity model.Identity, admin bool, id string) (model.InterviewSession, error) {
	userID, err := s.EnsureUser(ctx, identity, admin)
	if err != nil {
		return model.InterviewSession{}, err
	}
	var session model.InterviewSession
	err = s.pool.QueryRow(ctx, `SELECT se.id::text,d.slug,se.mode::text,se.requested_count,se.status::text,se.started_at,se.completed_at
		FROM interview_sessions se JOIN directions d ON d.id=se.direction_id
		WHERE se.id=$1 AND se.user_id=$2`, id, userID).Scan(&session.ID, &session.DirectionSlug, &session.Mode,
		&session.RequestedCount, &session.Status, &session.StartedAt, &session.CompletedAt)
	if err != nil {
		return model.InterviewSession{}, notFound(err)
	}
	rows, err := s.pool.Query(ctx, `SELECT id::text,question_id::text,coding_task_id::text,position,snapshot,answer,code,passed
		FROM interview_session_items WHERE session_id=$1 ORDER BY position`, id)
	if err != nil {
		return model.InterviewSession{}, err
	}
	defer rows.Close()
	session.Items = []model.InterviewItem{}
	for rows.Next() {
		var item model.InterviewItem
		var raw []byte
		if err := rows.Scan(&item.ID, &item.QuestionID, &item.CodingTaskID, &item.Position, &raw, &item.Answer, &item.Code, &item.Passed); err != nil {
			return model.InterviewSession{}, err
		}
		if err := json.Unmarshal(raw, &item.Snapshot); err != nil {
			return model.InterviewSession{}, err
		}
		session.Items = append(session.Items, item)
	}
	return session, rows.Err()
}

func (s *Store) UpdateInterviewItem(ctx context.Context, identity model.Identity, admin bool, sessionID, itemID, answer, code string, duration *int) (model.InterviewSession, error) {
	userID, err := s.EnsureUser(ctx, identity, admin)
	if err != nil {
		return model.InterviewSession{}, err
	}
	tag, err := s.pool.Exec(ctx, `UPDATE interview_session_items item SET answer=$4,code=$5,duration_seconds=$6,updated_at=now()
		FROM interview_sessions se WHERE item.id=$1 AND item.session_id=$2 AND se.id=item.session_id AND se.user_id=$3 AND se.status='active'`,
		itemID, sessionID, userID, answer, code, duration)
	if err != nil {
		return model.InterviewSession{}, err
	}
	if tag.RowsAffected() == 0 {
		return model.InterviewSession{}, ErrNotFound
	}
	return s.InterviewSession(ctx, identity, admin, sessionID)
}

func (s *Store) CompleteInterviewSession(ctx context.Context, identity model.Identity, admin bool, id string) (model.InterviewSession, error) {
	userID, err := s.EnsureUser(ctx, identity, admin)
	if err != nil {
		return model.InterviewSession{}, err
	}
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return model.InterviewSession{}, err
	}
	defer func() { _ = tx.Rollback(ctx) }()
	tag, err := tx.Exec(ctx, `UPDATE interview_sessions SET status='completed',completed_at=COALESCE(completed_at,now())
		WHERE id=$1 AND user_id=$2`, id, userID)
	if err != nil {
		return model.InterviewSession{}, err
	}
	if tag.RowsAffected() == 0 {
		return model.InterviewSession{}, ErrNotFound
	}
	_, err = tx.Exec(ctx, `INSERT INTO user_progress (user_id,content_type,content_id,status,started_at,completed_at)
		SELECT se.user_id,'question',item.question_id,'completed',se.started_at,now()
		FROM interview_session_items item JOIN interview_sessions se ON se.id=item.session_id
		WHERE se.id=$1 AND se.user_id=$2 AND item.question_id IS NOT NULL AND btrim(item.answer) <> ''
		ON CONFLICT (user_id,content_type,content_id) DO UPDATE SET status='completed',
		started_at=COALESCE(user_progress.started_at,EXCLUDED.started_at),
		completed_at=COALESCE(user_progress.completed_at,EXCLUDED.completed_at),updated_at=now()`, id, userID)
	if err != nil {
		return model.InterviewSession{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return model.InterviewSession{}, err
	}
	return s.InterviewSession(ctx, identity, admin, id)
}

type SubmissionRecordInput struct {
	UserID       *string
	CodingTaskID *string
	Language     string
	SourceCode   string
}

func (s *Store) CreateSubmission(ctx context.Context, input SubmissionRecordInput) (model.Submission, error) {
	var item model.Submission
	err := s.pool.QueryRow(ctx, `INSERT INTO code_submissions (user_id,coding_task_id,language,source_code,status)
		VALUES ($1,$2,$3,$4,'running') RETURNING id::text,coding_task_id::text,language,status::text,stdout,stderr,
		passed_tests,total_tests,duration_ms,created_at,finished_at`, input.UserID, input.CodingTaskID, input.Language,
		input.SourceCode).Scan(&item.ID, &item.CodingTaskID, &item.Language, &item.Status, &item.Stdout, &item.Stderr,
		&item.PassedTests, &item.TotalTests, &item.DurationMS, &item.CreatedAt, &item.FinishedAt)
	return item, err
}

func (s *Store) FinishSubmission(ctx context.Context, id, status, stdout, stderr string, passed, total, durationMS int) (model.Submission, error) {
	var item model.Submission
	err := s.pool.QueryRow(ctx, `UPDATE code_submissions SET status=$2::submission_status,stdout=$3,stderr=$4,
		passed_tests=$5,total_tests=$6,duration_ms=$7,finished_at=now() WHERE id=$1
		RETURNING id::text,coding_task_id::text,language,status::text,stdout,stderr,passed_tests,total_tests,duration_ms,created_at,finished_at`,
		id, status, stdout, stderr, passed, total, durationMS).Scan(&item.ID, &item.CodingTaskID, &item.Language,
		&item.Status, &item.Stdout, &item.Stderr, &item.PassedTests, &item.TotalTests, &item.DurationMS,
		&item.CreatedAt, &item.FinishedAt)
	return item, notFound(err)
}

func (s *Store) Submission(ctx context.Context, identity model.Identity, admin bool, id string) (model.Submission, error) {
	userID, err := s.EnsureUser(ctx, identity, admin)
	if err != nil {
		return model.Submission{}, err
	}
	var item model.Submission
	err = s.pool.QueryRow(ctx, `SELECT id::text,coding_task_id::text,language,status::text,stdout,stderr,
		passed_tests,total_tests,duration_ms,created_at,finished_at FROM code_submissions
		WHERE id=$1 AND user_id=$2`, id, userID).Scan(&item.ID, &item.CodingTaskID, &item.Language,
		&item.Status, &item.Stdout, &item.Stderr, &item.PassedTests, &item.TotalTests,
		&item.DurationMS, &item.CreatedAt, &item.FinishedAt)
	return item, notFound(err)
}

type TaskTest struct {
	ID             string `json:"id"`
	Stdin          string `json:"stdin"`
	ExpectedStdout string `json:"expectedStdout"`
	Hidden         bool   `json:"hidden"`
	Position       int    `json:"position"`
}

func (s *Store) TaskTests(ctx context.Context, taskID string) ([]TaskTest, error) {
	rows, err := s.pool.Query(ctx, `SELECT id::text,stdin,expected_stdout,hidden,position FROM coding_task_tests WHERE coding_task_id=$1 ORDER BY position,id`, taskID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := []TaskTest{}
	for rows.Next() {
		var item TaskTest
		if err := rows.Scan(&item.ID, &item.Stdin, &item.ExpectedStdout, &item.Hidden, &item.Position); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) ReplaceTaskTests(ctx context.Context, taskID string, items []TaskTest) ([]TaskTest, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback(ctx) }()
	var exists bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM coding_tasks WHERE id=$1)`, taskID).Scan(&exists); err != nil {
		return nil, err
	}
	if !exists {
		return nil, ErrNotFound
	}
	if _, err := tx.Exec(ctx, `DELETE FROM coding_task_tests WHERE coding_task_id=$1`, taskID); err != nil {
		return nil, err
	}
	for index, item := range items {
		position := item.Position
		if position < 1 {
			position = index + 1
		}
		if _, err := tx.Exec(ctx, `INSERT INTO coding_task_tests
			(coding_task_id,stdin,expected_stdout,hidden,position) VALUES ($1,$2,$3,$4,$5)`,
			taskID, item.Stdin, item.ExpectedStdout, item.Hidden, position); err != nil {
			return nil, err
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return s.TaskTests(ctx, taskID)
}

func (s *Store) MarkCodingTaskCompleted(ctx context.Context, identity model.Identity, admin bool, taskID string) error {
	_, err := s.SetProgress(ctx, identity, admin, model.Progress{ContentType: "coding_task", ContentID: taskID, Status: "completed"})
	return err
}

func (s *Store) MarkInterviewItemResult(ctx context.Context, userID, itemID, taskID string, passed bool, code string) error {
	tag, err := s.pool.Exec(ctx, `UPDATE interview_session_items item SET passed=$4,code=$5,updated_at=now()
		FROM interview_sessions se WHERE item.id=$1 AND item.session_id=se.id AND se.user_id=$2
		AND se.status='active' AND item.coding_task_id=$3`,
		itemID, userID, taskID, passed, code)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}
