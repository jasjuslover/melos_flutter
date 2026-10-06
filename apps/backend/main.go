package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	_ "github.com/joho/godotenv/autoload"
)

type App struct {
	db        *pgxpool.Pool
	jwtSecret []byte
}

func main() {
	ctx := context.Background()

	dbURL := getenv("DATABASE_URL", "postgres://app:secret@localhost:5432/appdb?sslmode=disable")
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		log.Fatal("JWT_SECRET is required")
	}

	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		log.Fatal("failed to create database connection: %v", err)
		return
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("database not responded: %v", err)
	}

	app := &App{db: pool, jwtSecret: []byte(secret)}

	mux := http.NewServeMux()

	// public route
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})
	mux.HandleFunc("POST /auth/register", app.register)
	mux.HandleFunc("POST /auth/login", app.login)

	// Route needs login (wrapped middleware auth)
	mux.Handle("GET /products", app.auth(http.HandlerFunc(app.listProducts)))
	mux.Handle("POST /products", app.auth(http.HandlerFunc(app.createProduct)))
	mux.Handle("GET /products/{id}", app.auth(http.HandlerFunc(app.getProduct)))
	mux.Handle("PUT /products/{id}", app.auth(http.HandlerFunc(app.updateProduct)))
	mux.Handle("DELETE /products/{id}", app.auth(http.HandlerFunc(app.deleteProduct)))

	addr := getenv("ADDR", ":8080")
	srv := &http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}
	log.Printf("API run on %s", addr)
	log.Fatal(srv.ListenAndServe())
}

func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}

	return fallback
}
