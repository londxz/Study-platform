package httpapi

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"regexp"
	"strings"
	"time"

	"learny/backend/internal/auth"
	"learny/backend/internal/config"
	"learny/backend/internal/model"
	"learny/backend/internal/runner"
	"learny/backend/internal/store"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgconn"
)

type API struct {
	config          config.Config
	store           *store.Store
	runner          *runner.Client
	logger          *slog.Logger
	verifier        *auth.Verifier
	submissionSlots chan struct{}
}

func New(cfg config.Config, data *store.Store, codeRunner *runner.Client, logger *slog.Logger) http.Handler {
	api := &API{config: cfg, store: data, runner: codeRunner, logger: logger,
		verifier: auth.NewVerifier(cfg.BFFSecret), submissionSlots: make(chan struct{}, cfg.SubmissionConcurrency)}
	router := chi.NewRouter()
	router.Use(requestID, securityHeaders)
	router.Use(func(next http.Handler) http.Handler { return recoverer(logger, next) })
	router.Use(middleware.Timeout(cfg.RequestTimeout))

	router.Get("/healthz", api.health)
	router.Get("/readyz", api.ready)
	router.Route("/v1", func(r chi.Router) {
		r.Get("/catalog", api.catalog(false))
		r.Get("/directions", api.directions)
		r.Get("/directions/{direction}", api.direction)
		r.Get("/directions/{direction}/tracks/{track}", api.track)
		r.Get("/sections/{id}", api.section)
		r.Get("/topics/{id}", api.topic)
		r.Get("/lessons/{id}", api.lesson)
		r.Get("/questions/{id}", api.question)
		r.Get("/coding-tasks/{id}", api.codingTask)

		r.Group(func(r chi.Router) {
			r.Use(api.verifier.Required)
			r.Get("/me/progress", api.progress)
			r.Get("/me/activity", api.activity)
			r.Put("/me/progress/{contentType}/{contentId}", api.setProgress)
			r.Post("/interview-sessions", api.createInterviewSession)
			r.Get("/interview-sessions/{id}", api.interviewSession)
			r.Put("/interview-sessions/{id}/items/{itemId}", api.updateInterviewItem)
			r.Post("/interview-sessions/{id}/complete", api.completeInterviewSession)
			r.Post("/submissions", api.createSubmission)
			r.Get("/submissions/{id}", api.submission)
		})

		r.Route("/admin", func(r chi.Router) {
			r.Use(api.verifier.Required)
			r.Use(api.requireAdmin)
			r.Get("/catalog", api.catalog(true))
			r.Get("/sections", api.adminSections)
			r.Post("/sections", api.createSection)
			r.Get("/sections/{id}", api.adminSection)
			r.Put("/sections/{id}", api.updateSection)
			r.Delete("/sections/{id}", api.archiveSection)
			r.Get("/topics", api.adminTopics)
			r.Post("/topics", api.createTopic)
			r.Get("/topics/{id}", api.adminTopic)
			r.Put("/topics/{id}", api.updateTopic)
			r.Delete("/topics/{id}", api.archiveTopic)
			r.Get("/lessons", api.adminLessons)
			r.Post("/lessons", api.createLesson)
			r.Get("/lessons/{id}", api.adminLesson)
			r.Put("/lessons/{id}", api.updateLesson)
			r.Delete("/lessons/{id}", api.archiveLesson)
			r.Get("/questions", api.adminQuestions)
			r.Post("/questions", api.createQuestion)
			r.Get("/questions/{id}", api.adminQuestion)
			r.Put("/questions/{id}", api.updateQuestion)
			r.Delete("/questions/{id}", api.archiveQuestion)
			r.Get("/coding-tasks", api.adminCodingTasks)
			r.Post("/coding-tasks", api.createCodingTask)
			r.Get("/coding-tasks/{id}", api.adminCodingTask)
			r.Put("/coding-tasks/{id}", api.updateCodingTask)
			r.Delete("/coding-tasks/{id}", api.archiveCodingTask)
			r.Get("/coding-tasks/{id}/tests", api.adminCodingTaskTests)
			r.Put("/coding-tasks/{id}/tests", api.replaceAdminCodingTaskTests)
		})
	})
	return router
}

func (api *API) health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (api *API) ready(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()
	if err := api.store.Ping(ctx); err != nil {
		writeProblem(w, http.StatusServiceUnavailable, "database_unavailable", "База временно недоступна", nil)
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

func (api *API) requireAdmin(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		identity, ok := auth.FromContext(r.Context())
		if !ok || !api.config.IsAdmin(identity.Email) {
			writeProblem(w, http.StatusForbidden, "forbidden", "Недостаточно прав", nil)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (api *API) catalog(includeDraft bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		directions, err := api.store.Catalog(r.Context(), includeDraft)
		if api.fail(w, err) {
			return
		}
		questions, err := api.store.Questions(r.Context(), includeDraft)
		if api.fail(w, err) {
			return
		}
		tasks, err := api.store.CodingTasks(r.Context(), includeDraft)
		if api.fail(w, err) {
			return
		}
		lessons, err := api.store.Lessons(r.Context(), includeDraft)
		if api.fail(w, err) {
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"directions": directions, "lessons": lessons, "questions": questions, "codingTasks": tasks})
	}
}

func (api *API) directions(w http.ResponseWriter, r *http.Request) {
	items, err := api.store.Catalog(r.Context(), false)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (api *API) direction(w http.ResponseWriter, r *http.Request) {
	item, err := api.store.Direction(r.Context(), chi.URLParam(r, "direction"), false)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (api *API) track(w http.ResponseWriter, r *http.Request) {
	item, err := api.store.Track(r.Context(), chi.URLParam(r, "direction"), chi.URLParam(r, "track"), false)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (api *API) section(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	items, err := api.store.Catalog(r.Context(), false)
	if api.fail(w, err) {
		return
	}
	for _, direction := range items {
		for _, track := range direction.Tracks {
			for _, section := range track.Sections {
				if section.ID == id {
					writeJSON(w, http.StatusOK, section)
					return
				}
			}
		}
	}
	writeProblem(w, http.StatusNotFound, "not_found", "Раздел не найден", nil)
}

func (api *API) topic(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	items, err := api.store.Catalog(r.Context(), false)
	if api.fail(w, err) {
		return
	}
	for _, direction := range items {
		for _, track := range direction.Tracks {
			for _, section := range track.Sections {
				for _, topic := range section.Topics {
					if topic.ID == id {
						writeJSON(w, http.StatusOK, topic)
						return
					}
				}
			}
		}
	}
	writeProblem(w, http.StatusNotFound, "not_found", "Тема не найдена", nil)
}

func (api *API) lesson(w http.ResponseWriter, r *http.Request) {
	item, err := api.store.Lesson(r.Context(), chi.URLParam(r, "id"), false)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (api *API) question(w http.ResponseWriter, r *http.Request) {
	item, err := api.store.Question(r.Context(), chi.URLParam(r, "id"), false)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (api *API) codingTask(w http.ResponseWriter, r *http.Request) {
	item, err := api.store.CodingTask(r.Context(), chi.URLParam(r, "id"), false)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (api *API) adminQuestions(w http.ResponseWriter, r *http.Request) {
	items, err := api.store.Questions(r.Context(), true)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (api *API) adminQuestion(w http.ResponseWriter, r *http.Request) {
	item, err := api.store.Question(r.Context(), chi.URLParam(r, "id"), true)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

type questionRequest struct {
	TopicID         string `json:"topicId"`
	Prompt          string `json:"prompt"`
	Explanation     string `json:"explanation"`
	ReferenceAnswer string `json:"referenceAnswer"`
	Difficulty      int    `json:"difficulty"`
	Position        int    `json:"position"`
	Status          string `json:"status"`
}

func (api *API) createQuestion(w http.ResponseWriter, r *http.Request) {
	var request questionRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	input, fields := validateQuestion(request)
	if len(fields) > 0 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Проверьте поля", fields)
		return
	}
	item, err := api.store.CreateQuestion(r.Context(), input)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (api *API) updateQuestion(w http.ResponseWriter, r *http.Request) {
	var request questionRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	input, fields := validateQuestion(request)
	if len(fields) > 0 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Проверьте поля", fields)
		return
	}
	item, err := api.store.UpdateQuestion(r.Context(), chi.URLParam(r, "id"), input)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func validateQuestion(request questionRequest) (store.QuestionInput, map[string]string) {
	fields := map[string]string{}
	if !validUUID(request.TopicID) {
		fields["topicId"] = "Выберите тему"
	}
	request.Prompt = strings.TrimSpace(request.Prompt)
	if len(request.Prompt) < 10 || len(request.Prompt) > 4000 {
		fields["prompt"] = "От 10 до 4000 символов"
	}
	if request.Difficulty < 1 || request.Difficulty > 5 {
		fields["difficulty"] = "От 1 до 5"
	}
	return store.QuestionInput{TopicID: request.TopicID, Prompt: request.Prompt, Explanation: strings.TrimSpace(request.Explanation),
		ReferenceAnswer: strings.TrimSpace(request.ReferenceAnswer), Difficulty: request.Difficulty, Position: max(0, request.Position),
		Status: store.NormalizeStatus(request.Status)}, fields
}

func (api *API) archiveQuestion(w http.ResponseWriter, r *http.Request) {
	if api.fail(w, api.store.ArchiveQuestion(r.Context(), chi.URLParam(r, "id"))) {
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (api *API) adminCodingTasks(w http.ResponseWriter, r *http.Request) {
	items, err := api.store.CodingTasks(r.Context(), true)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (api *API) adminCodingTask(w http.ResponseWriter, r *http.Request) {
	item, err := api.store.CodingTask(r.Context(), chi.URLParam(r, "id"), true)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

type codingTaskRequest struct {
	TopicID           string `json:"topicId"`
	Slug              string `json:"slug"`
	Title             string `json:"title"`
	StatementMarkdown string `json:"statementMarkdown"`
	Hint              string `json:"hint"`
	Language          string `json:"language"`
	StarterCode       string `json:"starterCode"`
	ReferenceSolution string `json:"referenceSolution"`
	TimeLimitMS       int    `json:"timeLimitMs"`
	MemoryLimitKB     int    `json:"memoryLimitKb"`
	Difficulty        int    `json:"difficulty"`
	Position          int    `json:"position"`
	Status            string `json:"status"`
}

func (api *API) createCodingTask(w http.ResponseWriter, r *http.Request) {
	var request codingTaskRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	input, fields := validateCodingTask(request)
	if len(fields) > 0 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Проверьте поля", fields)
		return
	}
	item, err := api.store.CreateCodingTask(r.Context(), input)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (api *API) updateCodingTask(w http.ResponseWriter, r *http.Request) {
	var request codingTaskRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	input, fields := validateCodingTask(request)
	if len(fields) > 0 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Проверьте поля", fields)
		return
	}
	item, err := api.store.UpdateCodingTask(r.Context(), chi.URLParam(r, "id"), input)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func validateCodingTask(request codingTaskRequest) (store.CodingTaskInput, map[string]string) {
	fields := map[string]string{}
	if !validUUID(request.TopicID) {
		fields["topicId"] = "Выберите тему"
	}
	request.Title = strings.TrimSpace(request.Title)
	if len(request.Title) < 3 || len(request.Title) > 160 {
		fields["title"] = "От 3 до 160 символов"
	}
	request.Slug = strings.ToLower(strings.TrimSpace(request.Slug))
	if !slugPattern.MatchString(request.Slug) {
		fields["slug"] = "Только латинские буквы, цифры и дефис"
	}
	if len(strings.TrimSpace(request.StatementMarkdown)) < 10 {
		fields["statementMarkdown"] = "Добавьте условие задачи"
	}
	if request.Language != "swift" && request.Language != "go" {
		fields["language"] = "Выберите Swift или Go"
	}
	if request.Difficulty < 1 || request.Difficulty > 5 {
		fields["difficulty"] = "От 1 до 5"
	}
	if request.TimeLimitMS == 0 {
		request.TimeLimitMS = 3000
	}
	if request.MemoryLimitKB == 0 {
		request.MemoryLimitKB = 128000
	}
	if request.TimeLimitMS < 100 || request.TimeLimitMS > 10000 {
		fields["timeLimitMs"] = "От 100 до 10000 мс"
	}
	if request.MemoryLimitKB < 16000 || request.MemoryLimitKB > 512000 {
		fields["memoryLimitKb"] = "От 16000 до 512000 КБ"
	}
	return store.CodingTaskInput{TopicID: request.TopicID, Slug: request.Slug, Title: request.Title,
		StatementMarkdown: strings.TrimSpace(request.StatementMarkdown), Hint: strings.TrimSpace(request.Hint),
		Language: request.Language, StarterCode: request.StarterCode, ReferenceSolution: request.ReferenceSolution,
		TimeLimitMS: request.TimeLimitMS, MemoryLimitKB: request.MemoryLimitKB, Difficulty: request.Difficulty,
		Position: max(0, request.Position), Status: store.NormalizeStatus(request.Status)}, fields
}

func (api *API) archiveCodingTask(w http.ResponseWriter, r *http.Request) {
	if api.fail(w, api.store.ArchiveCodingTask(r.Context(), chi.URLParam(r, "id"))) {
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (api *API) adminCodingTaskTests(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if !validUUID(id) {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Некорректная задача", nil)
		return
	}
	if _, err := api.store.CodingTask(r.Context(), id, true); api.fail(w, err) {
		return
	}
	items, err := api.store.TaskTests(r.Context(), id)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

type taskTestsRequest struct {
	Items []store.TaskTest `json:"items"`
}

func (api *API) replaceAdminCodingTaskTests(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if !validUUID(id) {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Некорректная задача", nil)
		return
	}
	var request taskTestsRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	if len(request.Items) > 50 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Не больше 50 тестов на задачу", nil)
		return
	}
	for index := range request.Items {
		request.Items[index].ID = ""
		request.Items[index].Position = index + 1
		if len(request.Items[index].Stdin) > 10000 || len(request.Items[index].ExpectedStdout) > 10000 {
			writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Тест слишком большой", nil)
			return
		}
	}
	items, err := api.store.ReplaceTaskTests(r.Context(), id, request.Items)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (api *API) progress(w http.ResponseWriter, r *http.Request) {
	identity, _ := api.identity(r)
	items, err := api.store.Progress(r.Context(), identity, api.config.IsAdmin(identity.Email))
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (api *API) activity(w http.ResponseWriter, r *http.Request) {
	identity, _ := api.identity(r)
	items, err := api.store.Progress(r.Context(), identity, api.config.IsAdmin(identity.Email))
	if api.fail(w, err) {
		return
	}
	if len(items) > 50 {
		items = items[:50]
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

type progressRequest struct {
	Status       string `json:"status"`
	LastPosition int    `json:"lastPosition"`
}

func (api *API) setProgress(w http.ResponseWriter, r *http.Request) {
	contentType, contentID := chi.URLParam(r, "contentType"), chi.URLParam(r, "contentId")
	allowed := map[string]bool{"lesson": true, "question": true, "coding_task": true, "topic": true, "section": true}
	if !allowed[contentType] || !validUUID(contentID) {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Некорректный материал", nil)
		return
	}
	var request progressRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	if request.Status != "not_started" && request.Status != "in_progress" && request.Status != "completed" {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Некорректный статус", nil)
		return
	}
	identity, _ := api.identity(r)
	item, err := api.store.SetProgress(r.Context(), identity, api.config.IsAdmin(identity.Email), model.Progress{
		ContentType: contentType, ContentID: contentID, Status: request.Status, LastPosition: max(0, request.LastPosition)})
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

type createInterviewRequest struct {
	Direction string `json:"direction"`
	Mode      string `json:"mode"`
	Count     int    `json:"count"`
}

func (api *API) createInterviewSession(w http.ResponseWriter, r *http.Request) {
	var request createInterviewRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	maximum, validMode := interviewMaximum(request.Mode)
	if !validMode {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Выберите теорию или лайвкодинг", nil)
		return
	}
	if request.Count < 1 || request.Count > maximum || (request.Direction != "ios" && request.Direction != "go") {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Проверьте направление и количество", nil)
		return
	}
	identity, _ := api.identity(r)
	item, err := api.store.CreateInterviewSession(r.Context(), identity, api.config.IsAdmin(identity.Email), request.Direction, request.Mode, request.Count)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func interviewMaximum(mode string) (int, bool) {
	switch mode {
	case "theory":
		return 20, true
	case "livecoding":
		return 10, true
	default:
		return 0, false
	}
}

func (api *API) interviewSession(w http.ResponseWriter, r *http.Request) {
	identity, _ := api.identity(r)
	item, err := api.store.InterviewSession(r.Context(), identity, api.config.IsAdmin(identity.Email), chi.URLParam(r, "id"))
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

type updateInterviewItemRequest struct {
	Answer          string `json:"answer"`
	Code            string `json:"code"`
	DurationSeconds *int   `json:"durationSeconds"`
}

func (api *API) updateInterviewItem(w http.ResponseWriter, r *http.Request) {
	var request updateInterviewItemRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	if len(request.Answer) > 20000 || len(request.Code) > 10000 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Ответ слишком большой", nil)
		return
	}
	identity, _ := api.identity(r)
	item, err := api.store.UpdateInterviewItem(r.Context(), identity, api.config.IsAdmin(identity.Email),
		chi.URLParam(r, "id"), chi.URLParam(r, "itemId"), request.Answer, request.Code, request.DurationSeconds)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (api *API) completeInterviewSession(w http.ResponseWriter, r *http.Request) {
	identity, _ := api.identity(r)
	item, err := api.store.CompleteInterviewSession(r.Context(), identity, api.config.IsAdmin(identity.Email), chi.URLParam(r, "id"))
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

type submissionRequest struct {
	CodingTaskID    *string `json:"codingTaskId"`
	InterviewItemID *string `json:"interviewItemId"`
	Language        string  `json:"language"`
	Code            string  `json:"code"`
}

func (api *API) createSubmission(w http.ResponseWriter, r *http.Request) {
	select {
	case api.submissionSlots <- struct{}{}:
		defer func() { <-api.submissionSlots }()
	default:
		writeProblem(w, http.StatusTooManyRequests, "runner_busy", "Компилятор занят, повторите попытку", nil)
		return
	}
	var request submissionRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	request.Code = strings.TrimSpace(request.Code)
	if len(request.Code) == 0 || len(request.Code) > 10000 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Код должен содержать от 1 до 10000 символов", nil)
		return
	}
	if request.Language != "swift" && request.Language != "go" {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Поддерживаются только Swift и Go", nil)
		return
	}
	if request.InterviewItemID != nil && !validUUID(*request.InterviewItemID) {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Некорректный элемент интервью", nil)
		return
	}
	if request.InterviewItemID != nil && request.CodingTaskID == nil {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Элемент интервью должен быть связан с задачей", nil)
		return
	}
	identity, _ := api.identity(r)
	userID, err := api.store.EnsureUser(r.Context(), identity, api.config.IsAdmin(identity.Email))
	if api.fail(w, err) {
		return
	}
	var task *model.CodingTask
	if request.CodingTaskID != nil {
		if !validUUID(*request.CodingTaskID) {
			writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Некорректная задача", nil)
			return
		}
		loaded, err := api.store.CodingTask(r.Context(), *request.CodingTaskID, false)
		if api.fail(w, err) {
			return
		}
		if loaded.Language != request.Language {
			writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Язык не совпадает с задачей", nil)
			return
		}
		task = &loaded
	}
	record, err := api.store.CreateSubmission(r.Context(), store.SubmissionRecordInput{UserID: &userID,
		CodingTaskID: request.CodingTaskID, Language: request.Language, SourceCode: request.Code})
	if api.fail(w, err) {
		return
	}
	tests := []store.TaskTest{{}}
	limitMS, memoryKB := 3000, 128000
	if task != nil {
		limitMS, memoryKB = task.TimeLimitMS, task.MemoryLimitKB
		loaded, err := api.store.TaskTests(r.Context(), task.ID)
		if api.fail(w, err) {
			return
		}
		if len(loaded) > 0 {
			tests = loaded
		}
	}
	started := time.Now()
	passed, stdout, stderr := 0, "", ""
	for _, test := range tests {
		result, err := api.runner.Run(r.Context(), request.Language, request.Code, test.Stdin, limitMS, memoryKB)
		if err != nil {
			stderr = "Сервис компиляции временно недоступен"
			record, _ = api.store.FinishSubmission(r.Context(), record.ID, "error", stdout, stderr, passed, len(tests), int(time.Since(started).Milliseconds()))
			if request.InterviewItemID != nil {
				_ = api.store.MarkInterviewItemResult(r.Context(), userID, *request.InterviewItemID, *request.CodingTaskID, false, request.Code)
			}
			writeJSON(w, http.StatusBadGateway, map[string]any{"ok": false, "stdout": stdout, "stderr": stderr, "compiler": compilerLabel(request.Language), "submission": record})
			return
		}
		stdout, stderr = result.Stdout, result.Stderr
		ok := result.OK
		if test.ExpectedStdout != "" {
			ok = ok && strings.TrimSpace(result.Stdout) == strings.TrimSpace(test.ExpectedStdout)
		}
		if ok {
			passed++
		} else {
			break
		}
	}
	status := "failed"
	if passed == len(tests) {
		status = "passed"
	}
	record, err = api.store.FinishSubmission(r.Context(), record.ID, status, stdout, stderr, passed, len(tests), int(time.Since(started).Milliseconds()))
	if api.fail(w, err) {
		return
	}
	if status == "passed" && task != nil {
		_ = api.store.MarkCodingTaskCompleted(r.Context(), identity, api.config.IsAdmin(identity.Email), task.ID)
	}
	if request.InterviewItemID != nil {
		_ = api.store.MarkInterviewItemResult(r.Context(), userID, *request.InterviewItemID, *request.CodingTaskID, status == "passed", request.Code)
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": status == "passed", "stdout": stdout, "stderr": stderr,
		"compiler": compilerLabel(request.Language), "submission": record})
}

func (api *API) submission(w http.ResponseWriter, r *http.Request) {
	identity, _ := api.identity(r)
	item, err := api.store.Submission(r.Context(), identity, api.config.IsAdmin(identity.Email), chi.URLParam(r, "id"))
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (api *API) identity(r *http.Request) (model.Identity, bool) {
	item, ok := auth.FromContext(r.Context())
	return model.Identity{ExternalID: item.UserID, Email: item.Email}, ok
}

func (api *API) fail(w http.ResponseWriter, err error) bool {
	if err == nil {
		return false
	}
	if errors.Is(err, store.ErrNotFound) {
		writeProblem(w, http.StatusNotFound, "not_found", "Запись не найдена", nil)
		return true
	}
	var databaseError *pgconn.PgError
	if errors.As(err, &databaseError) {
		switch databaseError.Code {
		case "23505":
			writeProblem(w, http.StatusConflict, "already_exists", "Запись с таким slug уже существует", nil)
			return true
		case "23503":
			writeProblem(w, http.StatusUnprocessableEntity, "invalid_relation", "Связанная запись не найдена", nil)
			return true
		}
	}
	api.logger.Error("request failed", "error", err)
	writeProblem(w, http.StatusInternalServerError, "internal_error", "Не удалось выполнить запрос", nil)
	return true
}

func compilerLabel(language string) string {
	if language == "swift" {
		return "Swift"
	}
	return "Go"
}

var uuidPattern = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$`)
var slugPattern = regexp.MustCompile(`^[a-z0-9]+(?:-[a-z0-9]+)*$`)

func validUUID(value string) bool { return uuidPattern.MatchString(value) }
