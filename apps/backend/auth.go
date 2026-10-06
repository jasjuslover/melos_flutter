package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"golang.org/x/crypto/bcrypt"
)

type credentials struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// POST /auth/register
func (a *App) register(w http.ResponseWriter, r *http.Request) {
	var c credentials
	if err := decodeJSON(r, &c); err != nil {
		log.Printf("register decode: %v", err)
		writeError(w, http.StatusBadRequest, HTTP_CODE_INVALID_JSON, MSG_INVALID_BODY_REQUEST)
		return
	}
	c.Email = strings.ToLower(strings.TrimSpace(c.Email))
	if !strings.Contains(c.Email, "@") || len(c.Password) < 8 {
		writeError(w, http.StatusUnprocessableEntity, HTTP_CODE_VALIDATION_ERROR, "Invalid email and minimum password length is 8 chars")
		return
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(c.Password), bcrypt.DefaultCost)
	if err != nil {
		writeError(w, http.StatusInternalServerError, HTTP_CODE_INTERNAL, MSG_SOMETHING_WENT_WRONG)
		return
	}

	var id int64
	err = a.db.QueryRow(r.Context(),
		`INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id`,
		c.Email, string(hash),
	).Scan(&id)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, pgErr) && pgErr.Code == "23505" {
			writeError(w, http.StatusInternalServerError, HTTP_CODE_INTERNAL, MSG_SOMETHING_WENT_WRONG)
			return
		}

		log.Printf("register: %v", err)
		writeError(w, http.StatusInternalServerError, HTTP_CODE_INTERNAL, MSG_SOMETHING_WENT_WRONG)
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{"id": id, "email": c.Email})
}

// POST /auth/login
func (a *App) login(w http.ResponseWriter, r *http.Request) {
	var c credentials
	if err := decodeJSON(r, &c); err != nil {
		writeError(w, http.StatusBadRequest, HTTP_CODE_INVALID_JSON, MSG_INVALID_BODY_REQUEST)
		return
	}
	c.Email = strings.ToLower(strings.TrimSpace(c.Email))

	var id int64
	var hash string
	err := a.db.QueryRow(r.Context(),
		`SELECT id, password_hash FROM users WHERE email = $1`, c.Email,
	).Scan(&id, &hash)
	if err != nil {
		writeError(w, http.StatusInternalServerError, HTTP_CODE_INTERNAL, MSG_SOMETHING_WENT_WRONG)
	}

	if errors.Is(err, pgx.ErrNoRows) || bcrypt.CompareHashAndPassword([]byte(hash), []byte(c.Password)) != nil {
		writeError(w, http.StatusUnauthorized, HTTP_INVALID_CREDENTIALS, "Wrong email or password")
		return
	}

	token, err := a.newToken(id)
	if err != nil {
		writeError(w, http.StatusInternalServerError, HTTP_CODE_INTERNAL, MSG_SOMETHING_WENT_WRONG)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"access_token": token,
		"token_type":   "Bearer",
		"expires_in":   3600,
	})
}

func (a *App) newToken(userID int64) (string, error) {
	now := time.Now()
	claims := jwt.RegisteredClaims{
		Subject:   strconv.FormatInt(userID, 10),
		IssuedAt:  jwt.NewNumericDate(now),
		ExpiresAt: jwt.NewNumericDate(now.Add(time.Hour)),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(a.jwtSecret)
}

type ctxKey string

const userIDKey ctxKey = "userID"

// auth middleware
func (a *App) auth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		tokenStr, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
		if !ok || tokenStr == "" {
			writeError(w, http.StatusUnauthorized, HTTP_UNAUTHORIZED, "Token not found")
			return
		}

		claims := &jwt.RegisteredClaims{}
		_, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (any, error) {
			return a.jwtSecret, nil
		}, jwt.WithValidMethods([]string{"HS256"}))
		if err != nil {
			writeError(w, http.StatusUnauthorized, HTTP_UNAUTHORIZED, "Invalid token or expired")
			return
		}
		uid, err := strconv.ParseInt(claims.Subject, 10, 64)
		if err != nil {
			writeError(w, http.StatusUnauthorized, HTTP_UNAUTHORIZED, "Invalid token")
			return
		}

		ctx := context.WithValue(r.Context(), userIDKey, uid)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func currentUserID(r *http.Request) int64 {
	return r.Context().Value(userIDKey).(int64)
}
