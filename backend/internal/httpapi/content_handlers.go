package httpapi

import (
	"net/http"
	"strings"

	"learny/backend/internal/model"
	"learny/backend/internal/store"

	"github.com/go-chi/chi/v5"
)

func (api *API) adminSections(w http.ResponseWriter, r *http.Request) {
	catalog, err := api.store.Catalog(r.Context(), true)
	if api.fail(w, err) {
		return
	}
	items := make([]model.Section, 0)
	for _, direction := range catalog {
		for _, track := range direction.Tracks {
			items = append(items, track.Sections...)
		}
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (api *API) adminSection(w http.ResponseWriter, r *http.Request) {
	item, err := api.store.Section(r.Context(), chi.URLParam(r, "id"), true)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

type sectionRequest struct {
	TrackID     string `json:"trackId"`
	Slug        string `json:"slug"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Icon        string `json:"icon"`
	Position    int    `json:"position"`
	Status      string `json:"status"`
}

func validateSection(request sectionRequest) (store.SectionInput, map[string]string) {
	fields := map[string]string{}
	if !validUUID(request.TrackID) {
		fields["trackId"] = "Выберите трек"
	}
	request.Slug = strings.ToLower(strings.TrimSpace(request.Slug))
	if !slugPattern.MatchString(request.Slug) {
		fields["slug"] = "Только латинские буквы, цифры и дефис"
	}
	request.Title = strings.TrimSpace(request.Title)
	if len(request.Title) < 2 || len(request.Title) > 160 {
		fields["title"] = "От 2 до 160 символов"
	}
	if len(request.Description) > 1000 {
		fields["description"] = "Не больше 1000 символов"
	}
	if len(request.Icon) > 20 {
		fields["icon"] = "Не больше 20 символов"
	}
	return store.SectionInput{TrackID: request.TrackID, Slug: request.Slug, Title: request.Title,
		Description: strings.TrimSpace(request.Description), Icon: strings.TrimSpace(request.Icon),
		Position: max(0, request.Position), Status: store.NormalizeStatus(request.Status)}, fields
}

func (api *API) createSection(w http.ResponseWriter, r *http.Request) {
	var request sectionRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	input, fields := validateSection(request)
	if len(fields) > 0 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Проверьте поля", fields)
		return
	}
	item, err := api.store.CreateSection(r.Context(), input)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (api *API) updateSection(w http.ResponseWriter, r *http.Request) {
	var request sectionRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	input, fields := validateSection(request)
	if len(fields) > 0 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Проверьте поля", fields)
		return
	}
	item, err := api.store.UpdateSection(r.Context(), chi.URLParam(r, "id"), input)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (api *API) archiveSection(w http.ResponseWriter, r *http.Request) {
	if api.fail(w, api.store.ArchiveSection(r.Context(), chi.URLParam(r, "id"))) {
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (api *API) adminTopics(w http.ResponseWriter, r *http.Request) {
	catalog, err := api.store.Catalog(r.Context(), true)
	if api.fail(w, err) {
		return
	}
	items := make([]model.Topic, 0)
	for _, direction := range catalog {
		for _, track := range direction.Tracks {
			for _, section := range track.Sections {
				items = append(items, section.Topics...)
			}
		}
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (api *API) adminTopic(w http.ResponseWriter, r *http.Request) {
	item, err := api.store.Topic(r.Context(), chi.URLParam(r, "id"), true)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

type topicRequest struct {
	SectionID   string `json:"sectionId"`
	Slug        string `json:"slug"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Position    int    `json:"position"`
	Status      string `json:"status"`
}

func validateTopic(request topicRequest) (store.TopicInput, map[string]string) {
	fields := map[string]string{}
	if !validUUID(request.SectionID) {
		fields["sectionId"] = "Выберите раздел"
	}
	request.Slug = strings.ToLower(strings.TrimSpace(request.Slug))
	if !slugPattern.MatchString(request.Slug) {
		fields["slug"] = "Только латинские буквы, цифры и дефис"
	}
	request.Title = strings.TrimSpace(request.Title)
	if len(request.Title) < 2 || len(request.Title) > 160 {
		fields["title"] = "От 2 до 160 символов"
	}
	if len(request.Description) > 1000 {
		fields["description"] = "Не больше 1000 символов"
	}
	return store.TopicInput{SectionID: request.SectionID, Slug: request.Slug, Title: request.Title,
		Description: strings.TrimSpace(request.Description), Position: max(0, request.Position),
		Status: store.NormalizeStatus(request.Status)}, fields
}

func (api *API) createTopic(w http.ResponseWriter, r *http.Request) {
	var request topicRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	input, fields := validateTopic(request)
	if len(fields) > 0 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Проверьте поля", fields)
		return
	}
	item, err := api.store.CreateTopic(r.Context(), input)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (api *API) updateTopic(w http.ResponseWriter, r *http.Request) {
	var request topicRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	input, fields := validateTopic(request)
	if len(fields) > 0 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Проверьте поля", fields)
		return
	}
	item, err := api.store.UpdateTopic(r.Context(), chi.URLParam(r, "id"), input)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (api *API) archiveTopic(w http.ResponseWriter, r *http.Request) {
	if api.fail(w, api.store.ArchiveTopic(r.Context(), chi.URLParam(r, "id"))) {
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (api *API) adminLessons(w http.ResponseWriter, r *http.Request) {
	items, err := api.store.Lessons(r.Context(), true)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (api *API) adminLesson(w http.ResponseWriter, r *http.Request) {
	item, err := api.store.Lesson(r.Context(), chi.URLParam(r, "id"), true)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

type lessonRequest struct {
	TopicID         string `json:"topicId"`
	Slug            string `json:"slug"`
	Title           string `json:"title"`
	BodyMarkdown    string `json:"bodyMarkdown"`
	DurationMinutes int    `json:"durationMinutes"`
	Position        int    `json:"position"`
	Status          string `json:"status"`
}

func validateLesson(request lessonRequest) (store.LessonInput, map[string]string) {
	fields := map[string]string{}
	if !validUUID(request.TopicID) {
		fields["topicId"] = "Выберите тему"
	}
	request.Slug = strings.ToLower(strings.TrimSpace(request.Slug))
	if !slugPattern.MatchString(request.Slug) {
		fields["slug"] = "Только латинские буквы, цифры и дефис"
	}
	request.Title = strings.TrimSpace(request.Title)
	if len(request.Title) < 3 || len(request.Title) > 160 {
		fields["title"] = "От 3 до 160 символов"
	}
	if len(request.BodyMarkdown) < 10 || len(request.BodyMarkdown) > 200000 {
		fields["bodyMarkdown"] = "От 10 до 200000 символов"
	}
	if request.DurationMinutes < 0 || request.DurationMinutes > 600 {
		fields["durationMinutes"] = "От 0 до 600 минут"
	}
	return store.LessonInput{TopicID: request.TopicID, Slug: request.Slug, Title: request.Title,
		BodyMarkdown: request.BodyMarkdown, DurationMinutes: request.DurationMinutes,
		Position: max(0, request.Position), Status: store.NormalizeStatus(request.Status)}, fields
}

func (api *API) createLesson(w http.ResponseWriter, r *http.Request) {
	var request lessonRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	input, fields := validateLesson(request)
	if len(fields) > 0 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Проверьте поля", fields)
		return
	}
	item, err := api.store.CreateLesson(r.Context(), input)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (api *API) updateLesson(w http.ResponseWriter, r *http.Request) {
	var request lessonRequest
	if !decodeJSON(w, r, &request) {
		return
	}
	input, fields := validateLesson(request)
	if len(fields) > 0 {
		writeProblem(w, http.StatusUnprocessableEntity, "validation_failed", "Проверьте поля", fields)
		return
	}
	item, err := api.store.UpdateLesson(r.Context(), chi.URLParam(r, "id"), input)
	if api.fail(w, err) {
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (api *API) archiveLesson(w http.ResponseWriter, r *http.Request) {
	if api.fail(w, api.store.ArchiveLesson(r.Context(), chi.URLParam(r, "id"))) {
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
