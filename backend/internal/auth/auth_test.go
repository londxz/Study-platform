package auth

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestVerifierAcceptsSignedRequest(t *testing.T) {
	const secret = "this-secret-is-long-enough-for-the-test"
	const timestamp = "1724083200"
	body := []byte(`{"value":1}`)
	hash := sha256.Sum256(body)
	payload := fmt.Sprintf("%s\nPOST\n/v1/me/progress\nuser-1\nme@example.com\n%s", timestamp, hex.EncodeToString(hash[:]))
	mac := hmac.New(sha256.New, []byte(secret))
	_, _ = mac.Write([]byte(payload))

	req := httptest.NewRequest(http.MethodPost, "/v1/me/progress", strings.NewReader(string(body)))
	req.Header.Set(headerUserID, "user-1")
	req.Header.Set(headerUserEmail, "me@example.com")
	req.Header.Set(headerTimestamp, timestamp)
	req.Header.Set(headerSignature, hex.EncodeToString(mac.Sum(nil)))

	verifier := NewVerifier(secret)
	verifier.now = func() time.Time { return time.Unix(1724083200, 0) }
	called := false
	handler := verifier.Required(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		identity, ok := FromContext(r.Context())
		called = ok && identity.UserID == "user-1" && identity.Email == "me@example.com"
	}))
	handler.ServeHTTP(httptest.NewRecorder(), req)
	if !called {
		t.Fatal("signed identity was not added to context")
	}
}
