package model

import "time"

type Direction struct {
	ID        string  `json:"id"`
	Slug      string  `json:"slug"`
	ShortName string  `json:"shortName"`
	Name      string  `json:"name"`
	Position  int     `json:"position"`
	Status    string  `json:"status"`
	Tracks    []Track `json:"tracks"`
}

type Track struct {
	ID          string    `json:"id"`
	Slug        string    `json:"slug"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Position    int       `json:"position"`
	Status      string    `json:"status"`
	Sections    []Section `json:"sections"`
}

type Section struct {
	ID          string  `json:"id"`
	TrackID     string  `json:"trackId,omitempty"`
	Slug        string  `json:"slug"`
	Title       string  `json:"title"`
	Description string  `json:"description"`
	Icon        string  `json:"icon"`
	Position    int     `json:"position"`
	Status      string  `json:"status"`
	ItemCount   int     `json:"itemCount"`
	Topics      []Topic `json:"topics"`
}

type Topic struct {
	ID          string `json:"id"`
	SectionID   string `json:"sectionId,omitempty"`
	Slug        string `json:"slug"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Position    int    `json:"position"`
	Status      string `json:"status"`
}

type Lesson struct {
	ID              string    `json:"id"`
	TopicID         string    `json:"topicId"`
	TrackSlug       string    `json:"trackSlug,omitempty"`
	SectionID       string    `json:"sectionId,omitempty"`
	DirectionSlug   string    `json:"directionSlug,omitempty"`
	SectionTitle    string    `json:"sectionTitle,omitempty"`
	Slug            string    `json:"slug"`
	Title           string    `json:"title"`
	BodyMarkdown    string    `json:"bodyMarkdown"`
	DurationMinutes int       `json:"durationMinutes"`
	Position        int       `json:"position"`
	Status          string    `json:"status"`
	CreatedAt       time.Time `json:"createdAt"`
	UpdatedAt       time.Time `json:"updatedAt"`
}

type Question struct {
	ID              string    `json:"id"`
	TopicID         string    `json:"topicId"`
	TrackSlug       string    `json:"trackSlug,omitempty"`
	SectionID       string    `json:"sectionId,omitempty"`
	DirectionSlug   string    `json:"directionSlug,omitempty"`
	SectionTitle    string    `json:"sectionTitle,omitempty"`
	Prompt          string    `json:"prompt"`
	Explanation     string    `json:"explanation,omitempty"`
	ReferenceAnswer string    `json:"referenceAnswer,omitempty"`
	Difficulty      int       `json:"difficulty"`
	Position        int       `json:"position"`
	Status          string    `json:"status"`
	CreatedAt       time.Time `json:"createdAt"`
	UpdatedAt       time.Time `json:"updatedAt"`
}

type CodingTask struct {
	ID                string    `json:"id"`
	TopicID           string    `json:"topicId"`
	TrackSlug         string    `json:"trackSlug,omitempty"`
	SectionID         string    `json:"sectionId,omitempty"`
	DirectionSlug     string    `json:"directionSlug,omitempty"`
	SectionTitle      string    `json:"sectionTitle,omitempty"`
	Slug              string    `json:"slug"`
	Title             string    `json:"title"`
	StatementMarkdown string    `json:"statementMarkdown"`
	Hint              string    `json:"hint,omitempty"`
	Language          string    `json:"language"`
	StarterCode       string    `json:"starterCode"`
	ReferenceSolution string    `json:"referenceSolution,omitempty"`
	TimeLimitMS       int       `json:"timeLimitMs"`
	MemoryLimitKB     int       `json:"memoryLimitKb"`
	Difficulty        int       `json:"difficulty"`
	Position          int       `json:"position"`
	Status            string    `json:"status"`
	CreatedAt         time.Time `json:"createdAt"`
	UpdatedAt         time.Time `json:"updatedAt"`
}

type Identity struct {
	ExternalID string
	Email      string
}

type Progress struct {
	ContentType  string     `json:"contentType"`
	ContentID    string     `json:"contentId"`
	Status       string     `json:"status"`
	LastPosition int        `json:"lastPosition"`
	StartedAt    *time.Time `json:"startedAt,omitempty"`
	CompletedAt  *time.Time `json:"completedAt,omitempty"`
	UpdatedAt    time.Time  `json:"updatedAt"`
}

type InterviewItem struct {
	ID           string         `json:"id"`
	Position     int            `json:"position"`
	QuestionID   *string        `json:"questionId,omitempty"`
	CodingTaskID *string        `json:"codingTaskId,omitempty"`
	Snapshot     map[string]any `json:"snapshot"`
	Answer       string         `json:"answer"`
	Code         string         `json:"code"`
	Passed       *bool          `json:"passed,omitempty"`
}

type InterviewSession struct {
	ID             string          `json:"id"`
	DirectionSlug  string          `json:"directionSlug"`
	Mode           string          `json:"mode"`
	RequestedCount int             `json:"requestedCount"`
	Status         string          `json:"status"`
	StartedAt      time.Time       `json:"startedAt"`
	CompletedAt    *time.Time      `json:"completedAt,omitempty"`
	Items          []InterviewItem `json:"items"`
}

type Submission struct {
	ID           string     `json:"id"`
	CodingTaskID *string    `json:"codingTaskId,omitempty"`
	Language     string     `json:"language"`
	Status       string     `json:"status"`
	Stdout       string     `json:"stdout"`
	Stderr       string     `json:"stderr"`
	PassedTests  int        `json:"passedTests"`
	TotalTests   int        `json:"totalTests"`
	DurationMS   *int       `json:"durationMs,omitempty"`
	CreatedAt    time.Time  `json:"createdAt"`
	FinishedAt   *time.Time `json:"finishedAt,omitempty"`
}
