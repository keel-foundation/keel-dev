# Contributing to `keel-core`

Repository: [keel-foundation/keel-core](https://github.com/keel-foundation/keel-core)

You only need `keel-core` for API, identity, catalog, engagement, discovery, studio/media, and
federation work. Core requires PostgreSQL (with `pgvector` for discovery); you do not need
moderation, the web app, or NATS for most changes.

**Status:** production-oriented. The API covers identity and social sign-in, catalog and discovery, viewer
engagement, creator studio and media processing, watch telemetry and analytics, notifications,
viewer reports and public trust records, playlists, ActivityPub federation, the creator moderation
gateway, and Stripe Connect billing/settlement. `gofmt`, `go vet`, and the database tests pass. The remaining integration work
is the `keel-web` data adapter. Demo routes, fixtures, the seed command, and the dev auth fallback
have been removed; `cmd/bootstrap` creates the first verified creator.

## Run only this module

```sh
git clone https://github.com/keel-foundation/keel-core.git
cd keel-core

cp .env.example .env
# edit KEELTUBE_DATABASE_URL in .env
go run ./cmd/bootstrap   # one-time first account; set KEELTUBE_BOOTSTRAP_*
go run ./cmd/api
go run ./cmd/worker      # media jobs; requires S3 configuration
```

Core listens on `127.0.0.1:8080` by default. Bootstrap is idempotent by email and creates only the
first verified creator account and channel. Create videos through the studio/upload APIs.

### Configuration

| Variable | Default | Purpose |
|---|---|---|
| `KEELTUBE_CORE_ADDR` | `127.0.0.1:8080` | Listen address |
| `KEELTUBE_DATABASE_URL` | required | PostgreSQL DSN (set in `.env`) |
| `KEELTUBE_CORS_ORIGINS` | `http://localhost:3000` | Comma-separated web origins |
| `KEELTUBE_BOOTSTRAP_EMAIL` | unset | First account email for `cmd/bootstrap` |
| `KEELTUBE_BOOTSTRAP_PASSWORD` | unset | First account password |
| `KEELTUBE_WORKER_ADDR` | `127.0.0.1:8083` | Media worker health/status address |

## Endpoints

The full contract is in `keel-spec/schemas/openapi.yaml`. Core surfaces are grouped by area:

| Area | Examples |
|---|---|
| Health and federation | `/health`, `/.well-known/webfinger`, `/federation/*` |
| Catalog and discovery | `/api/v1/feed`, `/api/v1/explore`, `/api/v1/videos`, `/api/v1/search`, `/api/v1/channels` |
| Identity and sessions | `/api/v1/auth/*`, `/api/v1/me`, `/api/v1/me/sessions` |
| Engagement | subscriptions, reactions, saves, history, comments, playlists |
| Creator Studio | `/api/v1/studio/videos`, uploads, subtitles, analytics, monetization |
| Billing and settlement | `/api/v1/studio/billing/*`, `/internal/v1/billing/settlements`, `/webhooks/stripe` |
| Creator moderation gateway | `/api/v1/studio/moderation/*` |
| Media playback | `/api/v1/media/*` |
| Reports and trust | `/api/v1/reports`, `/api/v1/me/reports`, `/api/v1/videos/{id}/trust` |
| Internal services | `/internal/v1/notifications`, `/internal/v1/finance/payouts`, `/internal/v1/billing/settlements`, `/internal/v1/federation` |

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
KEELTUBE_TEST_DATABASE_URL='postgres://USER:PASSWORD@HOST:PORT/DATABASE?sslmode=disable' \
  go test -p 1 ./...
```

If a change crosses packages, run the full command before opening the PR.

## Connect the demo to local core

Start local core, create content through the API, then run the public demo with the stage moderation endpoint:

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

The private dev stack builds core and a one-time bootstrap job with PostgreSQL:

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
