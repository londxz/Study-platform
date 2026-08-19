package runner

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"
)

type Client struct {
	baseURL string
	http    *http.Client
}

type Result struct {
	OK         bool
	Stdout     string
	Stderr     string
	Status     string
	DurationMS int
}

type judgeResponse struct {
	Stdout        *string `json:"stdout"`
	Stderr        *string `json:"stderr"`
	CompileOutput *string `json:"compile_output"`
	Message       *string `json:"message"`
	Time          *string `json:"time"`
	Status        struct {
		ID          int    `json:"id"`
		Description string `json:"description"`
	} `json:"status"`
}

func New(baseURL string, timeout time.Duration) *Client {
	return &Client{baseURL: strings.TrimRight(baseURL, "/"), http: &http.Client{Timeout: timeout}}
}

func (c *Client) Run(ctx context.Context, language, source, stdin string, timeLimitMS, memoryLimitKB int) (Result, error) {
	languageID, ok := map[string]int{"swift": 83, "go": 107}[language]
	if !ok {
		return Result{}, errors.New("unsupported language")
	}
	payload := map[string]any{
		"language_id":     languageID,
		"source_code":     source,
		"stdin":           stdin,
		"cpu_time_limit":  max(1, timeLimitMS/1000),
		"wall_time_limit": max(2, timeLimitMS/1000+2),
		"memory_limit":    memoryLimitKB,
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return Result{}, err
	}
	endpoint, err := url.Parse(c.baseURL + "/submissions")
	if err != nil {
		return Result{}, err
	}
	query := endpoint.Query()
	query.Set("base64_encoded", "false")
	query.Set("wait", "true")
	query.Set("fields", "stdout,stderr,compile_output,message,time,status")
	endpoint.RawQuery = query.Encode()
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint.String(), bytes.NewReader(body))
	if err != nil {
		return Result{}, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	response, err := c.http.Do(req)
	if err != nil {
		return Result{}, err
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		return Result{}, fmt.Errorf("runner returned status %d", response.StatusCode)
	}
	var result judgeResponse
	decoder := json.NewDecoder(response.Body)
	if err := decoder.Decode(&result); err != nil {
		return Result{}, err
	}
	stderr := join(result.CompileOutput, result.Stderr, result.Message)
	duration := 0
	if result.Time != nil {
		var seconds float64
		if _, err := fmt.Sscanf(*result.Time, "%f", &seconds); err == nil {
			duration = int(seconds * 1000)
		}
	}
	return Result{OK: result.Status.ID == 3, Stdout: value(result.Stdout), Stderr: stderr,
		Status: result.Status.Description, DurationMS: duration}, nil
}

func value(item *string) string {
	if item == nil {
		return ""
	}
	return *item
}

func join(items ...*string) string {
	parts := make([]string, 0, len(items))
	for _, item := range items {
		if item != nil && strings.TrimSpace(*item) != "" {
			parts = append(parts, strings.TrimSpace(*item))
		}
	}
	return strings.Join(parts, "\n")
}
