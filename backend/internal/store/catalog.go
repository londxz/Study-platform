package store

import (
	"context"
	"fmt"

	"learny/backend/internal/model"
)

func (s *Store) Catalog(ctx context.Context, includeDraft bool) ([]model.Direction, error) {
	predicate := "WHERE status = 'published'"
	if includeDraft {
		predicate = ""
	}
	rows, err := s.pool.Query(ctx, `SELECT id::text, slug, short_name, name, position, status::text FROM directions `+predicate+` ORDER BY position, name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	directions := make([]model.Direction, 0)
	for rows.Next() {
		var item model.Direction
		if err := rows.Scan(&item.ID, &item.Slug, &item.ShortName, &item.Name, &item.Position, &item.Status); err != nil {
			return nil, err
		}
		item.Tracks = []model.Track{}
		directions = append(directions, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for index := range directions {
		tracks, err := s.tracks(ctx, directions[index].ID, includeDraft)
		if err != nil {
			return nil, err
		}
		directions[index].Tracks = tracks
	}
	return directions, nil
}

func (s *Store) Direction(ctx context.Context, slug string, includeDraft bool) (model.Direction, error) {
	catalog, err := s.Catalog(ctx, includeDraft)
	if err != nil {
		return model.Direction{}, err
	}
	for _, direction := range catalog {
		if direction.Slug == slug {
			return direction, nil
		}
	}
	return model.Direction{}, ErrNotFound
}

func (s *Store) Track(ctx context.Context, directionSlug, trackSlug string, includeDraft bool) (model.Track, error) {
	direction, err := s.Direction(ctx, directionSlug, includeDraft)
	if err != nil {
		return model.Track{}, err
	}
	for _, track := range direction.Tracks {
		if track.Slug == trackSlug {
			return track, nil
		}
	}
	return model.Track{}, ErrNotFound
}

func (s *Store) tracks(ctx context.Context, directionID string, includeDraft bool) ([]model.Track, error) {
	predicate := "AND status = 'published'"
	if includeDraft {
		predicate = ""
	}
	rows, err := s.pool.Query(ctx, fmt.Sprintf(`SELECT id::text, slug, title, description, position, status::text
		FROM tracks WHERE direction_id = $1 %s ORDER BY position, title`, predicate), directionID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := make([]model.Track, 0)
	for rows.Next() {
		var item model.Track
		if err := rows.Scan(&item.ID, &item.Slug, &item.Title, &item.Description, &item.Position, &item.Status); err != nil {
			return nil, err
		}
		item.Sections = []model.Section{}
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for index := range items {
		sections, err := s.sections(ctx, items[index].ID, includeDraft)
		if err != nil {
			return nil, err
		}
		items[index].Sections = sections
	}
	return items, nil
}

func (s *Store) sections(ctx context.Context, trackID string, includeDraft bool) ([]model.Section, error) {
	predicate := "AND status = 'published'"
	itemPredicate := "= 'published'"
	if includeDraft {
		predicate = ""
		itemPredicate = "<> 'archived'"
	}
	rows, err := s.pool.Query(ctx, fmt.Sprintf(`SELECT s.id::text, s.slug, s.title, s.description, s.icon, s.position, s.status::text,
		(SELECT count(*) FROM questions q JOIN topics qt ON qt.id=q.topic_id WHERE qt.section_id=s.id AND qt.status %s AND q.status %s) +
		(SELECT count(*) FROM coding_tasks ct JOIN topics ctt ON ctt.id=ct.topic_id WHERE ctt.section_id=s.id AND ctt.status %s AND ct.status %s) +
		(SELECT count(*) FROM lessons l JOIN topics lt ON lt.id=l.topic_id WHERE lt.section_id=s.id AND lt.status %s AND l.status %s) AS item_count
		FROM sections s WHERE track_id = $1 %s ORDER BY position, title`, itemPredicate, itemPredicate,
		itemPredicate, itemPredicate, itemPredicate, itemPredicate, predicate), trackID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := make([]model.Section, 0)
	for rows.Next() {
		var item model.Section
		if err := rows.Scan(&item.ID, &item.Slug, &item.Title, &item.Description, &item.Icon, &item.Position, &item.Status, &item.ItemCount); err != nil {
			return nil, err
		}
		item.Topics = []model.Topic{}
		item.TrackID = trackID
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for index := range items {
		topics, err := s.topics(ctx, items[index].ID, includeDraft)
		if err != nil {
			return nil, err
		}
		items[index].Topics = topics
	}
	return items, nil
}

func (s *Store) topics(ctx context.Context, sectionID string, includeDraft bool) ([]model.Topic, error) {
	predicate := "AND status = 'published'"
	if includeDraft {
		predicate = ""
	}
	rows, err := s.pool.Query(ctx, fmt.Sprintf(`SELECT id::text, slug, title, description, position, status::text
		FROM topics WHERE section_id = $1 %s ORDER BY position, title`, predicate), sectionID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := make([]model.Topic, 0)
	for rows.Next() {
		var item model.Topic
		if err := rows.Scan(&item.ID, &item.Slug, &item.Title, &item.Description, &item.Position, &item.Status); err != nil {
			return nil, err
		}
		items = append(items, item)
		items[len(items)-1].SectionID = sectionID
	}
	return items, rows.Err()
}
