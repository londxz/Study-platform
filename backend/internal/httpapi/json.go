package httpapi

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
)

type apiError struct {
	Error problem `json:"error"`
}

type problem struct {
	Code    string            `json:"code"`
	Message string            `json:"message"`
	Fields  map[string]string `json:"fields,omitempty"`
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

func writeProblem(w http.ResponseWriter, status int, code, message string, fields map[string]string) {
	writeJSON(w, status, apiError{Error: problem{Code: code, Message: message, Fields: fields}})
}

func decodeJSON(w http.ResponseWriter, r *http.Request, target any) bool {
	r.Body = http.MaxBytesReader(w, r.Body, 64<<10)
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		message := "Некорректный JSON"
		var maxBytes *http.MaxBytesError
		if errors.As(err, &maxBytes) {
			message = "Запрос слишком большой"
		}
		writeProblem(w, http.StatusBadRequest, "invalid_request", message, nil)
		return false
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		writeProblem(w, http.StatusBadRequest, "invalid_request", "В запросе должен быть один JSON-объект", nil)
		return false
	}
	return true
}
