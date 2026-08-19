package httpapi

import (
	"log/slog"
	"net/http"
	"runtime/debug"
	"strconv"
	"sync/atomic"
	"time"
)

var requestCounter atomic.Uint64

func requestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.Header.Get("X-Request-Id")
		if id == "" {
			id = strconv.FormatInt(time.Now().UnixMilli(), 36) + "-" + strconv.FormatUint(requestCounter.Add(1), 36)
		}
		w.Header().Set("X-Request-Id", id)
		next.ServeHTTP(w, r)
	})
}

func recoverer(logger *slog.Logger, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if recovered := recover(); recovered != nil {
				logger.Error("panic recovered", "error", recovered, "stack", string(debug.Stack()))
				writeProblem(w, http.StatusInternalServerError, "internal_error", "Внутренняя ошибка сервера", nil)
			}
		}()
		next.ServeHTTP(w, r)
	})
}

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Cache-Control", "no-store")
		next.ServeHTTP(w, r)
	})
}
