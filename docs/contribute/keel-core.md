# Contributing to `keel-core`

Repository: [keel-foundation/keel-core](https://github.com/keel-foundation/keel-core)

You only need `keel-core` for API, identity, channel, video, subscription, and feed work. Core now
requires PostgreSQL; you do not need the pipeline, moderation, web app, or NATS for most changes.

## Run only this module

```sh
git clone https://github.com/keel-foundation/keel-core.git
cd keel-core

export KEELTUBE_DATABASE_URL='postgres://keeltube:keeltube-dev@127.0.0.1:5432/keeltube?sslmode=disable'
go run ./cmd/seed
go run ./cmd/api
```

Core listens on `127.0.0.1:8080` by default. The seed is idempotent and creates `usr_demo`,
`ch_demo`, `vid_demo_001`, `vid_removed_001`, and `vid_private_001`.

### Configuration

| Variable | Default | Purpose |
|---|---|---|
| `KEELTUBE_CORE_ADDR` | `127.0.0.1:8080` | Listen address |
| `KEELTUBE_DATABASE_URL` | `postgres://keeltube:keeltube-dev@127.0.0.1:5432/keeltube?sslmode=disable` | PostgreSQL DSN |
| `KEELTUBE_CORS_ORIGINS` | `http://localhost:3000` | Comma-separated web origins |
| `KEELTUBE_DEV_ACTOR_ID` | `usr_demo` | Dev auth principal |
| `KEELTUBE_DEV_ACTOR_TOKEN` | unset | Optional dev bearer token |
| `KEELTUBE_PIPELINE_PUBLIC_URL` | `http://localhost:8081` | Playback URL used by the seed |
| `KEELTUBE_WEB_PUBLIC_URL` | `http://localhost:3000` | Captions URL used by the seed |

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/health` | Liveness and database ping |
| `GET` | `/api/v1/channels/demo` | Demo channel |
| `GET` | `/api/v1/channels/{id}` | Channel by id |
| `GET` | `/api/v1/videos/demo` | Demo video |
| `GET` | `/api/v1/videos/{id}` | Video by id |
| `GET` | `/api/v1/demo` | Demo video and channel |
| `GET` | `/api/v1/me` | Current dev principal |

## Work on a specific area

The module you change should have its own package under `internal/`. Run only that package's
tests while iterating:

```sh
go test ./internal/store/...
go test ./internal/api/...
go test ./internal/db/...
```

Database tests require `KEELTUBE_TEST_DATABASE_URL`. Run packages sequentially because they share
the test tables:

```sh
KEELTUBE_TEST_DATABASE_URL='postgres://keeltube:keeltube-dev@127.0.0.1:5432/keeltube?sslmode=disable' \
  go test -p 1 ./...
```

If a change crosses packages, run the full command before opening the PR.

## Connect the demo to local core

Start local core with the seed, then run the public demo with the stage moderation endpoint:

```sh
KEELTUBE_MODE=remote \
KEELTUBE_API_BASE_URL=http://127.0.0.1:8080 \
KEELTUBE_MODERATION_BASE_URL=https://stage-moderation.example.org \
make demo
```

If you do not have stage moderation access, run `keel-moderation` locally as well. You do not need
the full ecosystem just to work on core.

## OpenAPI

The demo contract is [keel-spec/schemas/openapi.yaml](https://github.com/keel-foundation/keel-spec/blob/main/schemas/openapi.yaml).
Stage maintainers can provide the deployed OpenAPI URL. Use it to check request and response shapes
before changing an endpoint.

If your change alters a public response, update the schema and examples in `keel-spec` in a linked
PR.

## Docker

The private dev stack builds core and a one-shot seed job with PostgreSQL:

```sh
docker compose -f keel-infra/devstack/apps.compose.yml up -d --build
```

## PR checklist

- `go test -p 1 ./...` with `KEELTUBE_TEST_DATABASE_URL`, `go vet ./...`, and `gofmt -l .` are clean.
- New behavior has tests, including migration and endpoint tests where relevant.
- CORS stays limited to configured origins.
- No moderation decision logic lives in core.
- Schema changes are coordinated with `keel-spec` and the moderation client.
- No secrets or production URLs are committed.
- Commits are signed off with `git commit -s`.

See [PR guidelines](pr-guidelines.md).
