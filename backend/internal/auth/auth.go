package auth

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"
)

const (
	headerUserID    = "X-Learny-User-Id"
	headerUserEmail = "X-Learny-User-Email"
	headerTimestamp = "X-Learny-Timestamp"
	headerSignature = "X-Learny-Signature"
	maxSignedBody   = 64 << 10
)

type Identity struct {
	UserID string
	Email  string
}

type contextKey struct{}

func FromContext(ctx context.Context) (Identity, bool) {
	identity, ok := ctx.Value(contextKey{}).(Identity)
	return identity, ok
}

type Verifier struct {
	secret []byte
	now    func() time.Time
}

func NewVerifier(secret string) *Verifier {
	return &Verifier{secret: []byte(secret), now: time.Now}
}

func (v *Verifier) Optional(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get(headerSignature) == "" {
			next.ServeHTTP(w, r)
			return
		}
		identity, err := v.verify(r)
		if err != nil {
			writeUnauthorized(w)
			return
		}
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), contextKey{}, identity)))
	})
}

func (v *Verifier) Required(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		identity, err := v.verify(r)
		if err != nil || identity.UserID == "" || identity.Email == "" {
			writeUnauthorized(w)
			return
		}
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), contextKey{}, identity)))
	})
}

func (v *Verifier) verify(r *http.Request) (Identity, error) {
	if len(v.secret) == 0 {
		return Identity{}, errors.New("signing secret is not configured")
	}
	userID := strings.TrimSpace(r.Header.Get(headerUserID))
	email := strings.ToLower(strings.TrimSpace(r.Header.Get(headerUserEmail)))
	timestampRaw := strings.TrimSpace(r.Header.Get(headerTimestamp))
	signatureRaw := strings.TrimSpace(r.Header.Get(headerSignature))
	if userID == "" || timestampRaw == "" || signatureRaw == "" {
		return Identity{}, errors.New("missing signed identity headers")
	}
	timestamp, err := strconv.ParseInt(timestampRaw, 10, 64)
	if err != nil || v.now().Sub(time.Unix(timestamp, 0)).Abs() > 5*time.Minute {
		return Identity{}, errors.New("expired signature")
	}
	body, err := io.ReadAll(io.LimitReader(r.Body, maxSignedBody+1))
	if err != nil || len(body) > maxSignedBody {
		return Identity{}, errors.New("request body is too large")
	}
	r.Body.Close()
	r.Body = io.NopCloser(strings.NewReader(string(body)))
	bodyHash := sha256.Sum256(body)
	payload := fmt.Sprintf("%s\n%s\n%s\n%s\n%s\n%s", timestampRaw, r.Method, r.URL.RequestURI(), userID, email, hex.EncodeToString(bodyHash[:]))
	mac := hmac.New(sha256.New, v.secret)
	_, _ = mac.Write([]byte(payload))
	expected := mac.Sum(nil)
	provided, err := hex.DecodeString(signatureRaw)
	if err != nil || !hmac.Equal(expected, provided) {
		return Identity{}, errors.New("invalid signature")
	}
	return Identity{UserID: userID, Email: email}, nil
}

func writeUnauthorized(w http.ResponseWriter) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusUnauthorized)
	_, _ = w.Write([]byte(`{"error":{"code":"unauthorized","message":"Требуется авторизация"}}`))
}
