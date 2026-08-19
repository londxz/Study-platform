package store

import (
	"context"
	"fmt"

	"learny/backend/internal/model"
)

type SectionInput struct {
	TrackID     string
	Slug        string
	Title       string
	Description string
	Icon        string
	Position    int
	Status      string
}

func (s *Store) Section(ctx context.Context, id string, includeDraft bool) (model.Section, error) {
	predicate := "AND s.status='published'"
	itemPredicate := "= 'published'"
	if includeDraft {
		predicate = ""
		itemPredicate = "<> 'archived'"
	}
	var item model.Section
	query := fmt.Sprintf(`SELECT s.id::text,s.track_id::text,s.slug,s.title,s.description,s.icon,s.position,s.status::text,
		(SELECT count(*) FROM questions q JOIN topics tp ON tp.id=q.topic_id WHERE tp.section_id=s.id AND q.status %s)+
		(SELECT count(*) FROM coding_tasks ct JOIN topics tp ON tp.id=ct.topic_id WHERE tp.section_id=s.id AND ct.status %s)+
		(SELECT count(*) FROM lessons l JOIN topics tp ON tp.id=l.topic_id WHERE tp.section_id=s.id AND l.status %s)
		FROM sections s WHERE s.id=$1 %s`, itemPredicate, itemPredicate, itemPredicate, predicate)
	err := s.pool.QueryRow(ctx, query, id).Scan(&item.ID, &item.TrackID, &item.Slug, &item.Title,
		&item.Description, &item.Icon, &item.Position, &item.Status, &item.ItemCount)
	if err != nil {
		return model.Section{}, notFound(err)
	}
	item.Topics, err = s.topics(ctx, item.ID, includeDraft)
	return item, err
}

func (s *Store) CreateSection(ctx context.Context, input SectionInput) (model.Section, error) {
	var id string
	err := s.pool.QueryRow(ctx, `INSERT INTO sections (track_id,slug,title,description,icon,position,status)
		VALUES ($1,$2,$3,$4,$5,$6,$7::content_status) RETURNING id::text`, input.TrackID, input.Slug,
		input.Title, input.Description, input.Icon, input.Position, input.Status).Scan(&id)
	if err != nil {
		return model.Section{}, err
	}
	return s.Section(ctx, id, true)
}

func (s *Store) UpdateSection(ctx context.Context, id string, input SectionInput) (model.Section, error) {
	tag, err := s.pool.Exec(ctx, `UPDATE sections SET track_id=$2,slug=$3,title=$4,description=$5,icon=$6,
		position=$7,status=$8::content_status,updated_at=now() WHERE id=$1`, id, input.TrackID, input.Slug,
		input.Title, input.Description, input.Icon, input.Position, input.Status)
	if err != nil {
		return model.Section{}, err
	}
	if tag.RowsAffected() == 0 {
		return model.Section{}, ErrNotFound
	}
	return s.Section(ctx, id, true)
}

func (s *Store) ArchiveSection(ctx context.Context, id string) error {
	tag, err := s.pool.Exec(ctx, `UPDATE sections SET status='archived',updated_at=now() WHERE id=$1`, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

type TopicInput struct {
	SectionID   string
	Slug        string
	Title       string
	Description string
	Position    int
	Status      string
}

func (s *Store) Topic(ctx context.Context, id string, includeDraft bool) (model.Topic, error) {
	predicate := "AND status='published'"
	if includeDraft {
		predicate = ""
	}
	var item model.Topic
	err := s.pool.QueryRow(ctx, `SELECT id::text,section_id::text,slug,title,description,position,status::text
		FROM topics WHERE id=$1 `+predicate, id).Scan(&item.ID, &item.SectionID, &item.Slug, &item.Title,
		&item.Description, &item.Position, &item.Status)
	return item, notFound(err)
}

func (s *Store) CreateTopic(ctx context.Context, input TopicInput) (model.Topic, error) {
	var id string
	err := s.pool.QueryRow(ctx, `INSERT INTO topics (section_id,slug,title,description,position,status)
		VALUES ($1,$2,$3,$4,$5,$6::content_status) RETURNING id::text`, input.SectionID, input.Slug,
		input.Title, input.Description, input.Position, input.Status).Scan(&id)
	if err != nil {
		return model.Topic{}, err
	}
	return s.Topic(ctx, id, true)
}

func (s *Store) UpdateTopic(ctx context.Context, id string, input TopicInput) (model.Topic, error) {
	tag, err := s.pool.Exec(ctx, `UPDATE topics SET section_id=$2,slug=$3,title=$4,description=$5,
		position=$6,status=$7::content_status,updated_at=now() WHERE id=$1`, id, input.SectionID,
		input.Slug, input.Title, input.Description, input.Position, input.Status)
	if err != nil {
		return model.Topic{}, err
	}
	if tag.RowsAffected() == 0 {
		return model.Topic{}, ErrNotFound
	}
	return s.Topic(ctx, id, true)
}

func (s *Store) ArchiveTopic(ctx context.Context, id string) error {
	tag, err := s.pool.Exec(ctx, `UPDATE topics SET status='archived',updated_at=now() WHERE id=$1`, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}
