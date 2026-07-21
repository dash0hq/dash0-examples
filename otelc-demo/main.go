package main

import (
	"database/sql"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"time"

	_ "modernc.org/sqlite"
)

func main() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)))

	db, err := openDatabase()
	if err != nil {
		slog.Error("failed to initialize database", "error", err)
		os.Exit(1)
	}
	defer db.Close()

	mux := http.NewServeMux()
	mux.HandleFunc("GET /", handleIndex(db))
	mux.HandleFunc("GET /fetch", handleFetch)

	server := &http.Server{
		Addr:              ":8080",
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}

	slog.Info("server starting", "addr", server.Addr)
	if err := server.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
		slog.Error("server stopped", "error", err)
		os.Exit(1)
	}
}

func openDatabase() (*sql.DB, error) {
	db, err := sql.Open("sqlite", "file:visits?mode=memory&cache=shared")
	if err != nil {
		return nil, err
	}

	// Keep the in-memory database on one connection so every request sees the
	// same schema and data.
	db.SetMaxOpenConns(1)

	_, err = db.Exec(`
		CREATE TABLE visits (
			id   INTEGER PRIMARY KEY AUTOINCREMENT,
			path TEXT NOT NULL,
			ts   DATETIME DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		db.Close()
		return nil, err
	}

	return db, nil
}

func handleIndex(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		slog.InfoContext(ctx, "recording visit", "path", r.URL.Path)

		if _, err := db.ExecContext(
			ctx,
			"INSERT INTO visits (path) VALUES (?)",
			r.URL.Path,
		); err != nil {
			slog.ErrorContext(ctx, "insert failed", "error", err)
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}

		var count int
		if err := db.QueryRowContext(
			ctx,
			"SELECT COUNT(*) FROM visits",
		).Scan(&count); err != nil {
			slog.ErrorContext(ctx, "query failed", "error", err)
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}

		slog.InfoContext(ctx, "visit recorded", "total", count)
		writeJSON(w, http.StatusOK, map[string]any{
			"message": "hello from otelc-demo",
			"visits":  count,
		})
	}
}

func handleFetch(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	slog.InfoContext(ctx, "starting outbound call")

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodGet,
		"http://localhost:8080/",
		nil,
	)
	if err != nil {
		slog.ErrorContext(ctx, "failed to build request", "error", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		slog.ErrorContext(ctx, "outbound call failed", "error", err)
		http.Error(w, "fetch failed", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	var upstream map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&upstream); err != nil {
		slog.ErrorContext(ctx, "failed to decode response", "error", err)
		http.Error(w, "invalid upstream response", http.StatusBadGateway)
		return
	}

	slog.InfoContext(
		ctx,
		"outbound call complete",
		"status",
		resp.StatusCode,
	)

	writeJSON(w, http.StatusOK, map[string]any{
		"proxied":  true,
		"upstream": upstream,
	})
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(value); err != nil {
		slog.Error("failed to encode response", "error", err)
	}
}
