package main

import (
	"errors"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
)

type Product struct {
	ID        int64     `json:"id"`
	Name      string    `json:"name"`
	Price     int64     `json:"price"`
	Stock     int       `json:"stock"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type productInput struct {
	Name  string `json:"name"`
	Price int64  `json:"price"`
	Stock int    `json:"stock"`
}

func (in *productInput) validate() string {
	in.Name = strings.TrimSpace(in.Name)
	switch {
	case in.Name == "":
		return "name wajib diisi"
	case len(in.Name) > 200:
		return "name maksimal 200 karakter"
	case in.Price < 0:
		return "price tidak boleh negatif"
	case in.Stock < 0:
		return "stock tidak boleh negatif"
	}
	return ""
}

func internalError(w http.ResponseWriter, where string, err error) {
	log.Printf("%s: %v", where, err)
	writeError(w, http.StatusInternalServerError, "INTERNAL", "Terjadi kesalahan")
}

// GET /products?limit=20&offset=0
func (a *App) listProducts(w http.ResponseWriter, r *http.Request) {
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	if offset < 0 {
		offset = 0
	}

	rows, err := a.db.Query(r.Context(),
		`SELECT id, name, price, stock, created_at, updated_at
		   FROM products
		  WHERE owner_id = $1
		  ORDER BY id DESC
		  LIMIT $2 OFFSET $3`,
		currentUserID(r), limit, offset)
	if err != nil {
		internalError(w, "listProducts", err)
		return
	}
	defer rows.Close()

	items := []Product{} // bukan nil, agar JSON berisi [] bukan null
	for rows.Next() {
		var p Product
		if err := rows.Scan(&p.ID, &p.Name, &p.Price, &p.Stock, &p.CreatedAt, &p.UpdatedAt); err != nil {
			internalError(w, "listProducts scan", err)
			return
		}
		items = append(items, p)
	}
	if err := rows.Err(); err != nil {
		internalError(w, "listProducts rows", err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"items": items, "limit": limit, "offset": offset})
}

// GET /products/{id}
func (a *App) getProduct(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(r)
	if !ok {
		writeError(w, http.StatusBadRequest, "INVALID_ID", "id tidak valid")
		return
	}

	var p Product
	err := a.db.QueryRow(r.Context(),
		`SELECT id, name, price, stock, created_at, updated_at
		   FROM products WHERE id = $1 AND owner_id = $2`,
		id, currentUserID(r),
	).Scan(&p.ID, &p.Name, &p.Price, &p.Stock, &p.CreatedAt, &p.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		writeError(w, http.StatusNotFound, "NOT_FOUND", "Produk tidak ditemukan")
		return
	}
	if err != nil {
		internalError(w, "getProduct", err)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

// POST /products
func (a *App) createProduct(w http.ResponseWriter, r *http.Request) {
	var in productInput
	if err := decodeJSON(r, &in); err != nil {
		writeError(w, http.StatusBadRequest, "INVALID_JSON", "Body request tidak valid")
		return
	}
	if msg := in.validate(); msg != "" {
		writeError(w, http.StatusUnprocessableEntity, "VALIDATION_ERROR", msg)
		return
	}

	p := Product{Name: in.Name, Price: in.Price, Stock: in.Stock}
	err := a.db.QueryRow(r.Context(),
		`INSERT INTO products (owner_id, name, price, stock)
		 VALUES ($1, $2, $3, $4)
		 RETURNING id, created_at, updated_at`,
		currentUserID(r), in.Name, in.Price, in.Stock,
	).Scan(&p.ID, &p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		internalError(w, "createProduct", err)
		return
	}
	writeJSON(w, http.StatusCreated, p)
}

// PUT /products/{id}
func (a *App) updateProduct(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(r)
	if !ok {
		writeError(w, http.StatusBadRequest, "INVALID_ID", "id tidak valid")
		return
	}
	var in productInput
	if err := decodeJSON(r, &in); err != nil {
		writeError(w, http.StatusBadRequest, "INVALID_JSON", "Body request tidak valid")
		return
	}
	if msg := in.validate(); msg != "" {
		writeError(w, http.StatusUnprocessableEntity, "VALIDATION_ERROR", msg)
		return
	}

	p := Product{ID: id, Name: in.Name, Price: in.Price, Stock: in.Stock}
	err := a.db.QueryRow(r.Context(),
		`UPDATE products
		    SET name = $1, price = $2, stock = $3, updated_at = now()
		  WHERE id = $4 AND owner_id = $5
		  RETURNING created_at, updated_at`,
		in.Name, in.Price, in.Stock, id, currentUserID(r),
	).Scan(&p.CreatedAt, &p.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		writeError(w, http.StatusNotFound, "NOT_FOUND", "Produk tidak ditemukan")
		return
	}
	if err != nil {
		internalError(w, "updateProduct", err)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

// DELETE /products/{id}
func (a *App) deleteProduct(w http.ResponseWriter, r *http.Request) {
	id, ok := pathID(r)
	if !ok {
		writeError(w, http.StatusBadRequest, "INVALID_ID", "id tidak valid")
		return
	}
	tag, err := a.db.Exec(r.Context(),
		`DELETE FROM products WHERE id = $1 AND owner_id = $2`, id, currentUserID(r))
	if err != nil {
		internalError(w, "deleteProduct", err)
		return
	}
	if tag.RowsAffected() == 0 {
		writeError(w, http.StatusNotFound, "NOT_FOUND", "Produk tidak ditemukan")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
