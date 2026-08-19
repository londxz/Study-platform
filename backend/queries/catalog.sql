-- name: ListPublishedDirections :many
SELECT id, slug, short_name, name, position, status, created_at, updated_at
FROM directions
WHERE status = 'published'
ORDER BY position, name;

-- name: ListPublishedTracks :many
SELECT id, direction_id, slug, title, description, position, status, created_at, updated_at
FROM tracks
WHERE direction_id = $1 AND status = 'published'
ORDER BY position, title;

-- name: ListPublishedSections :many
SELECT id, track_id, slug, title, description, icon, position, status, created_at, updated_at
FROM sections
WHERE track_id = $1 AND status = 'published'
ORDER BY position, title;

-- name: ListPublishedTopics :many
SELECT id, section_id, slug, title, description, position, status, created_at, updated_at
FROM topics
WHERE section_id = $1 AND status = 'published'
ORDER BY position, title;

