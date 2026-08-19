-- +goose Up
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE content_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE user_role AS ENUM ('student', 'admin');
CREATE TYPE progress_status AS ENUM ('not_started', 'in_progress', 'completed');
CREATE TYPE interview_mode AS ENUM ('theory', 'livecoding');
CREATE TYPE session_status AS ENUM ('active', 'completed', 'abandoned');
CREATE TYPE submission_status AS ENUM ('queued', 'running', 'passed', 'failed', 'error');

CREATE TABLE users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    external_user_id text NOT NULL UNIQUE,
    email text NOT NULL,
    role user_role NOT NULL DEFAULT 'student',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE directions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug text NOT NULL UNIQUE,
    short_name text NOT NULL,
    name text NOT NULL,
    position integer NOT NULL DEFAULT 0,
    status content_status NOT NULL DEFAULT 'draft',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tracks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    direction_id uuid NOT NULL REFERENCES directions(id) ON DELETE CASCADE,
    slug text NOT NULL CHECK (slug IN ('interview', 'learning')),
    title text NOT NULL,
    description text NOT NULL DEFAULT '',
    position integer NOT NULL DEFAULT 0,
    status content_status NOT NULL DEFAULT 'draft',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(direction_id, slug)
);

CREATE TABLE sections (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    track_id uuid NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
    slug text NOT NULL,
    title text NOT NULL,
    description text NOT NULL DEFAULT '',
    icon text NOT NULL DEFAULT '',
    position integer NOT NULL DEFAULT 0,
    status content_status NOT NULL DEFAULT 'draft',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(track_id, slug)
);

CREATE TABLE topics (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    section_id uuid NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    slug text NOT NULL,
    title text NOT NULL,
    description text NOT NULL DEFAULT '',
    position integer NOT NULL DEFAULT 0,
    status content_status NOT NULL DEFAULT 'draft',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(section_id, slug)
);

CREATE TABLE lessons (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id uuid NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    slug text NOT NULL,
    title text NOT NULL,
    body_markdown text NOT NULL DEFAULT '',
    duration_minutes integer NOT NULL DEFAULT 0 CHECK (duration_minutes >= 0),
    position integer NOT NULL DEFAULT 0,
    status content_status NOT NULL DEFAULT 'draft',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(topic_id, slug)
);

CREATE TABLE questions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id uuid NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    prompt text NOT NULL,
    explanation text NOT NULL DEFAULT '',
    reference_answer text NOT NULL DEFAULT '',
    difficulty smallint NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    position integer NOT NULL DEFAULT 0,
    status content_status NOT NULL DEFAULT 'draft',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE coding_tasks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id uuid NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    slug text NOT NULL,
    title text NOT NULL,
    statement_markdown text NOT NULL,
    hint text NOT NULL DEFAULT '',
    language text NOT NULL CHECK (language IN ('swift', 'go')),
    starter_code text NOT NULL DEFAULT '',
    reference_solution text NOT NULL DEFAULT '',
    time_limit_ms integer NOT NULL DEFAULT 3000 CHECK (time_limit_ms BETWEEN 100 AND 10000),
    memory_limit_kb integer NOT NULL DEFAULT 128000 CHECK (memory_limit_kb BETWEEN 16000 AND 512000),
    difficulty smallint NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    position integer NOT NULL DEFAULT 0,
    status content_status NOT NULL DEFAULT 'draft',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(topic_id, slug)
);

CREATE TABLE coding_task_tests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    coding_task_id uuid NOT NULL REFERENCES coding_tasks(id) ON DELETE CASCADE,
    stdin text NOT NULL DEFAULT '',
    expected_stdout text NOT NULL DEFAULT '',
    hidden boolean NOT NULL DEFAULT true,
    position integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tags (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug text NOT NULL UNIQUE,
    name text NOT NULL
);

CREATE TABLE content_tags (
    tag_id uuid NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    content_type text NOT NULL CHECK (content_type IN ('lesson', 'question', 'coding_task')),
    content_id uuid NOT NULL,
    PRIMARY KEY(tag_id, content_type, content_id)
);

CREATE TABLE user_progress (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type text NOT NULL CHECK (content_type IN ('lesson', 'question', 'coding_task', 'topic', 'section')),
    content_id uuid NOT NULL,
    status progress_status NOT NULL DEFAULT 'not_started',
    last_position integer NOT NULL DEFAULT 0,
    started_at timestamptz,
    completed_at timestamptz,
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(user_id, content_type, content_id)
);

CREATE TABLE interview_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    direction_id uuid NOT NULL REFERENCES directions(id),
    mode interview_mode NOT NULL,
    requested_count integer NOT NULL CHECK (requested_count BETWEEN 1 AND 20),
    status session_status NOT NULL DEFAULT 'active',
    started_at timestamptz NOT NULL DEFAULT now(),
    completed_at timestamptz
);

CREATE TABLE interview_session_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id uuid NOT NULL REFERENCES interview_sessions(id) ON DELETE CASCADE,
    question_id uuid REFERENCES questions(id) ON DELETE SET NULL,
    coding_task_id uuid REFERENCES coding_tasks(id) ON DELETE SET NULL,
    position integer NOT NULL,
    snapshot jsonb NOT NULL,
    answer text NOT NULL DEFAULT '',
    code text NOT NULL DEFAULT '',
    passed boolean,
    duration_seconds integer,
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(session_id, position),
    CHECK ((question_id IS NOT NULL) <> (coding_task_id IS NOT NULL))
);

CREATE TABLE code_submissions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    coding_task_id uuid REFERENCES coding_tasks(id) ON DELETE SET NULL,
    language text NOT NULL CHECK (language IN ('swift', 'go')),
    source_code text NOT NULL,
    status submission_status NOT NULL DEFAULT 'queued',
    stdout text NOT NULL DEFAULT '',
    stderr text NOT NULL DEFAULT '',
    passed_tests integer NOT NULL DEFAULT 0,
    total_tests integer NOT NULL DEFAULT 0,
    duration_ms integer,
    created_at timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz
);

CREATE TABLE audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    action text NOT NULL,
    entity_type text NOT NULL,
    entity_id uuid,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX tracks_direction_position_idx ON tracks(direction_id, position);
CREATE INDEX sections_track_position_idx ON sections(track_id, position);
CREATE INDEX topics_section_position_idx ON topics(section_id, position);
CREATE INDEX questions_topic_status_position_idx ON questions(topic_id, status, position);
CREATE INDEX coding_tasks_topic_status_position_idx ON coding_tasks(topic_id, status, position);
CREATE INDEX progress_user_updated_idx ON user_progress(user_id, updated_at DESC);
CREATE INDEX sessions_user_started_idx ON interview_sessions(user_id, started_at DESC);
CREATE INDEX submissions_user_created_idx ON code_submissions(user_id, created_at DESC);

-- +goose Down
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS code_submissions;
DROP TABLE IF EXISTS interview_session_items;
DROP TABLE IF EXISTS interview_sessions;
DROP TABLE IF EXISTS user_progress;
DROP TABLE IF EXISTS content_tags;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS coding_task_tests;
DROP TABLE IF EXISTS coding_tasks;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS lessons;
DROP TABLE IF EXISTS topics;
DROP TABLE IF EXISTS sections;
DROP TABLE IF EXISTS tracks;
DROP TABLE IF EXISTS directions;
DROP TABLE IF EXISTS users;
DROP TYPE IF EXISTS submission_status;
DROP TYPE IF EXISTS session_status;
DROP TYPE IF EXISTS interview_mode;
DROP TYPE IF EXISTS progress_status;
DROP TYPE IF EXISTS user_role;
DROP TYPE IF EXISTS content_status;

