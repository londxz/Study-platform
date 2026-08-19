package httpapi

import "testing"

func TestInterviewMaximum(t *testing.T) {
	tests := []struct {
		mode string
		want int
		ok   bool
	}{
		{mode: "theory", want: 20, ok: true},
		{mode: "livecoding", want: 10, ok: true},
		{mode: "unknown", want: 0, ok: false},
	}
	for _, test := range tests {
		t.Run(test.mode, func(t *testing.T) {
			got, ok := interviewMaximum(test.mode)
			if got != test.want || ok != test.ok {
				t.Fatalf("interviewMaximum(%q) = (%d,%v), want (%d,%v)", test.mode, got, ok, test.want, test.ok)
			}
		})
	}
}

func TestValidateQuestion(t *testing.T) {
	_, fields := validateQuestion(questionRequest{TopicID: "bad", Prompt: "short", Difficulty: 8})
	for _, field := range []string{"topicId", "prompt", "difficulty"} {
		if fields[field] == "" {
			t.Fatalf("expected validation error for %s", field)
		}
	}
}

func TestValidateCodingTaskDefaultsAndLanguage(t *testing.T) {
	input, fields := validateCodingTask(codingTaskRequest{
		TopicID:           "40000000-0000-4000-8000-000000000001",
		Slug:              "valid-task",
		Title:             "Valid task",
		StatementMarkdown: "Long enough task statement",
		Language:          "swift",
		Difficulty:        2,
		Status:            "published",
	})
	if len(fields) != 0 {
		t.Fatalf("unexpected fields: %#v", fields)
	}
	if input.TimeLimitMS != 3000 || input.MemoryLimitKB != 128000 {
		t.Fatalf("unexpected defaults: %d/%d", input.TimeLimitMS, input.MemoryLimitKB)
	}
}

func TestValidateContentStructure(t *testing.T) {
	validID := "40000000-0000-4000-8000-000000000001"
	tests := []struct {
		name   string
		fields map[string]string
	}{
		{name: "section", fields: func() map[string]string {
			_, fields := validateSection(sectionRequest{TrackID: validID, Slug: "bad slug", Title: "A"})
			return fields
		}()},
		{name: "topic", fields: func() map[string]string {
			_, fields := validateTopic(topicRequest{SectionID: "bad", Slug: "topic", Title: "T"})
			return fields
		}()},
		{name: "lesson", fields: func() map[string]string {
			_, fields := validateLesson(lessonRequest{TopicID: validID, Slug: "lesson", Title: "OK", BodyMarkdown: "short", DurationMinutes: 601})
			return fields
		}()},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if len(test.fields) == 0 {
				t.Fatal("expected validation errors")
			}
		})
	}
}
