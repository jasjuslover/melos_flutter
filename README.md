# Toko: Flutter + Go Monorepo with Melos

A practical example of a **Melos monorepo**: a Flutter app built with clean domain/data/presentation layers, a shared Dart API client, and a minimal **Go + PostgreSQL** backend with JWT auth and product CRUD. One repository, one set of commands for the whole team.

```text
┌──────────── Flutter app (apps/customer_app) ────────────┐
│  presentation  →  domain  ←  data  →  api_client (Dio)   │ ──HTTP/JSON──► Go API (backend/) ──► PostgreSQL
└──────────────────────────────────────────────────────────┘
```

## Features

- **Auth:** register, login, session restore on app start, automatic logout when the token expires (HTTP 401).
- **Products:** list with infinite scroll, pull to refresh, create, edit and delete. Users only ever see their own products.
- **Repository pattern:** UI and controllers depend on interfaces, not on HTTP. Errors are mapped to typed `Failure` classes.
- **Fake mode:** run the app with in-memory repositories, no backend required.
- **Layer check:** a lint step fails the build if domain or presentation code imports the API client directly.

## Tech stack

| Part | Tools |
| --- | --- |
| Monorepo | [Melos](https://melos.invertase.dev) 8, Dart pub workspaces |
| App | Flutter, Riverpod 3, go_router, Dio, flutter_secure_storage |
| Backend | Go (`net/http` routing), pgx v5, bcrypt, JWT (HS256) |
| Database | PostgreSQL 16 (Docker Compose) |

## Repository structure

```text
toko/
├── apps/
│   └── customer_app/          # Flutter app
├── packages/
│   ├── api_client/            # Dart client for the Go API (shared by apps)
│   └── design_system/         # Shared UI components
├── backend/                   # Go API (not part of the Dart workspace)
│   ├── main.go                # config, routing, server
│   ├── auth.go                # register, login, JWT middleware
│   ├── products.go            # product CRUD
│   ├── helpers.go             # JSON and error helpers
│   ├── migrations/            # SQL schema, applied on first DB start
│   └── docker-compose.yml
├── .github/workflows/ci.yml
└── pubspec.yaml               # Dart workspace + Melos scripts
```

### App architecture

```text
apps/customer_app/lib/
├── core/            # config, token storage, providers, Failure, guardApi
├── features/
│   ├── auth/
│   │   ├── domain/        # AuthRepository (interface)
│   │   ├── data/          # ApiAuthRepository (talks to api_client)
│   │   └── presentation/  # AuthController, splash/login/register pages
│   └── products/
│       ├── domain/        # Product entity, ProductInput, ProductRepository
│       ├── data/          # ApiProductRepository, DTO → entity mapping
│       └── presentation/  # ProductsController, list/form pages
├── shared/          # error view, formatters, user-facing messages
├── dev/             # fake repositories (used by main_fake.dart only)
├── router.dart      # go_router with auth guard
├── main.dart
└── main_fake.dart
```

Dependency rule: `presentation → domain ← data`. Domain is pure Dart, with no Flutter, Riverpod or Dio imports.

## Prerequisites

- Flutter 3.35+ (Dart 3.9+)
- Go 1.24+
- Docker with Docker Compose
- Melos: `dart pub global activate melos`

## Getting started

```bash
git clone <repo-url> toko && cd toko

# Install dependencies for every package in the workspace
melos bootstrap

# Start PostgreSQL (the schema is created automatically)
melos backend:db

# Terminal 1: run the API at http://localhost:8080
melos backend:run

# Terminal 2: run the app on a running emulator/simulator
melos app:run
```

Want to work on the UI without a backend? Use `melos app:run:fake`.

### API address per device

| Running on | API address | What to do |
| --- | --- | --- |
| Android emulator | `http://10.0.2.2:8080` | Nothing (default) |
| Android phone (USB) | `http://localhost:8080` | `adb reverse tcp:8080 tcp:8080`, then `API_URL=http://localhost:8080 melos app:run:device` |
| iOS simulator | `http://localhost:8080` | Nothing (default) |
| Physical iPhone | HTTPS tunnel URL | Start a tunnel (ngrok, Cloudflare) to port 8080, then set `API_URL` |
| Desktop | `http://localhost:8080` | Nothing |

## Melos scripts

| Command | What it does |
| --- | --- |
| `melos bootstrap` | Resolve dependencies for all packages |
| `melos backend:db` | Start PostgreSQL with Docker Compose |
| `melos backend:run` | Run the Go API on port 8080 |
| `melos backend:test` | `go vet` and `go test` for the backend |
| `melos app:run` | Run the Flutter app |
| `melos app:run:device` | Run the app with a custom `API_URL` |
| `melos app:run:fake` | Run the app with in-memory fake repositories |
| `melos gen` | Run `build_runner` in packages that use it |
| `melos test:dart` | Test all Dart/Flutter packages |
| `melos check:layers` | Fail if domain/presentation imports `api_client` |
| `melos lint` | Format check, analyze, layer check, `gofmt` and `go vet` |
| `melos test:all` | Backend tests + all Dart/Flutter tests (run before a PR) |

## Configuration

**Backend** (environment variables):

| Variable | Default | Notes |
| --- | --- | --- |
| `DATABASE_URL` | `postgres://app:secret@localhost:5432/appdb?sslmode=disable` | Matches `docker-compose.yml` |
| `JWT_SECRET` | none (required) | `melos backend:run` sets a dev value. Use a long random secret in production |
| `ADDR` | `:8080` | Listen address |

**App:** `--dart-define=API_URL=...` overrides the default address chosen per platform.

## API reference

All errors use the same shape: `{"code": "NOT_FOUND", "message": "Produk tidak ditemukan"}`.

| Method | Path | Auth | Description |
| --- | --- | --- | --- |
| `GET` | `/health` | No | Health check |
| `POST` | `/auth/register` | No | Create an account (`email`, `password` min. 8 chars) |
| `POST` | `/auth/login` | No | Returns `access_token` (JWT, valid for 1 hour) |
| `GET` | `/products?limit=20&offset=0` | Bearer | List your products, newest first |
| `POST` | `/products` | Bearer | Create a product (`name`, `price`, `stock`) |
| `GET` | `/products/{id}` | Bearer | Get one product |
| `PUT` | `/products/{id}` | Bearer | Update a product |
| `DELETE` | `/products/{id}` | Bearer | Delete a product (`204 No Content`) |

Quick check with curl:

```bash
curl -X POST localhost:8080/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"budi@example.com","password":"rahasia123"}'

TOKEN=$(curl -s -X POST localhost:8080/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"budi@example.com","password":"rahasia123"}' | jq -r .access_token)

curl -X POST localhost:8080/products \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"Kopi Arabika 250g","price":85000,"stock":12}'
```

Prices are stored as integers in rupiah, never as floats.

## Testing

```bash
melos test:all      # everything
melos backend:test  # Go only
melos test:dart     # Dart/Flutter only
```

- **Controllers** are tested with mocked repositories, so no server and no UI are needed.
- **Repositories** are tested against a mocked `api_client` to verify error mapping and DTO conversion.
- **`guardApi`** has its own tests for every HTTP status → `Failure` mapping.

CI runs `melos lint` and `melos test:all` on every pull request.

## Troubleshooting

- **`Connection refused` from the app:** check the API address table above. On an Android emulator, `localhost` points to the emulator itself.
- **`JWT_SECRET wajib diisi`:** start the API with `melos backend:run`, or export `JWT_SECRET` yourself.
- **Logged out unexpectedly:** tokens expire after 1 hour, and changing `JWT_SECRET` invalidates all existing tokens.
- **Schema changes not applied:** migrations only run when the database volume is created. Reset with `docker compose down -v` inside `backend/`, then `melos backend:db`.

## License

MIT. See [LICENSE](LICENSE).