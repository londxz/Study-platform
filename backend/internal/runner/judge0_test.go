package runner

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"testing"
	"time"
)

type roundTripFunc func(*http.Request) (*http.Response, error)

func (fn roundTripFunc) RoundTrip(request *http.Request) (*http.Response, error) { return fn(request) }

func TestRunMapsLanguageAndResult(t *testing.T) {
	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		var payload map[string]any
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			t.Fatal(err)
		}
		if payload["language_id"] != float64(107) {
			t.Fatalf("language_id = %#v", payload["language_id"])
		}
		body := []byte(`{"stdout":"ok\n","stderr":null,"compile_output":null,"message":null,"time":"0.04","status":{"id":3,"description":"Accepted"}}`)
		return &http.Response{StatusCode: http.StatusOK, Header: make(http.Header), Body: io.NopCloser(bytes.NewReader(body))}, nil
	})

	client := New("http://runner.test", time.Second)
	client.http.Transport = transport
	result, err := client.Run(context.Background(), "go", "package main", "", 3000, 128000)
	if err != nil {
		t.Fatal(err)
	}
	if !result.OK || result.Stdout != "ok\n" || result.DurationMS != 40 {
		t.Fatalf("unexpected result: %#v", result)
	}
}

func TestRunRejectsUnsupportedLanguage(t *testing.T) {
	client := New("http://example.invalid", time.Second)
	if _, err := client.Run(context.Background(), "python", "", "", 1000, 16000); err == nil {
		t.Fatal("expected unsupported language error")
	}
}
