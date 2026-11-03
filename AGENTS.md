# AGENTS.md

This file is the workspace map for future agents. Read it before searching the tree. It describes
the repositories, their current state, the data flow, the test commands, and the rules that must not
be broken.

## Workspace shape

`/Users/victor/www/OpenSource` is the public `keel-dev` repository. The sibling repositories are
separate git checkouts. Private repositories are ignored by the root `.gitignore` and checked by
`scripts/check_public_boundary.py`.

| Path | Visibility | Language | Purpose | Current state |
|---|---|---|---|---|
| `keel-dev` (root) | public | Python/Markdown | Public demo, contribution hub, workspace boundary | Mocked creator-appeal demo; docs |
| `keel-core` | public | Go | Identity, catalog, engagement, discovery API | PostgreSQL + pgvector; auth, catalog, engagement, discovery |
| `keel-pipeline` | public | Go | Media ingest/transcode/package | Demo media server only; no upload/transcode/HLS |
| `keel-moderation` | public | Python/FastAPI | Signals, cases, actions, appeals, ledger | SQLite workflow state + append-only JSONL ledger |
| `keel-spec` | public | YAML/JSON | Protocol, RFCs, schemas, OpenAPI | Contract source of truth |
| `keel-docs` | public | Markdown | Creator and developer docs | Governance and API docs |
| `keel-web` | private | React/TypeScript | Viewer, creator studio, creator moderation record | Fully built against local mock data; API adapters pending |
| `keel-embeddings` | private | Python/FastAPI | Embedding and semantic-retrieval service | Token-protected; hash and sentence-transformers backends |
| `keel-infra` | private | Docker/Terraform | Devstack and infrastructure | Compose stack includes pgvector, core, embeddings, pipeline, moderation |
| `keel-governance` | private | Markdown | Constitution, board, finance, legal | Docs |
| `keel-security` | private | Markdown | Threat model, audits, incident response | Docs |
| `keel-branding` | private | Assets/Markdown | Brand system and assets | Assets/decisions |

Do not copy private repository contents into a public repository. Do not add private repositories to
the root git index. Run `make boundary` before pushing root changes.

## Ports and services

| Service | Default | Notes |
|---|---|---|
| Web (`keel-web`) | `http://localhost:3000` | Runs on the host, not in Compose |
| Core (`keel-core`) | `127.0.0.1:8080` | `/health`, `/api/v1/*` |
| Pipeline (`keel-pipeline`) | `127.0.0.1:8081` | Serves demo media |
| Moderation (`keel-moderation`) | `127.0.0.1:8082` | `/v1/*`, `/health` |
| Embeddings (`keel-embeddings`) | `127.0.0.1:8090` | Every endpoint requires a bearer token |
| PostgreSQL | internal only | `pgvector/pgvector:pg16` in the app stack |

The devstack Compose file is `keel-infra/devstack/apps.compose.yml`. It runs PostgreSQL, the
embeddings service, a one-shot seed job, core, pipeline, and moderation. The web app stays on the
host for hot reload.

## Data flow

```text
keel-web (mock data today)
  -> keel-core /api/v1/*                 (future adapter)
  -> keel-moderation /moderation/*       (future adapter; creator-safe endpoints only)

keel-core
  -> PostgreSQL + pgvector               (actors, channels, videos, auth, engagement, embeddings)
  -> keel-embeddings /v1/embed           (HTTP, bearer token)
  -> hash embedder fallback              (when KEELTUBE_EMBEDDINGS_URL is unset)

keel-pipeline
  -> media files                         (demo sample only)

keel-moderation
  -> SQLite                              (cases, actions, appeals)
  -> append-only JSONL ledger            (hash chain)
```

Core never makes moderation decisions. Moderation decisions never live in the creator web app. The
staff moderation portal is not built; the creator app only reads its own record and files appeals.

## keel-core

Go 1.23+. PostgreSQL is required. Discovery requires the `vector` extension and a pgvector-enabled
PostgreSQL image.

### Implemented

- Identity: register, email verification, login/logout, session cookies, CSRF, password reset,
  lockout, Argon2id, auth events.
- Catalog: actors, channels, videos, feed, explore, shorts, search, categories, related videos,
  visibility rules (removed → 410, private → 404 unless owner, unlisted by link).
- Engagement: subscriptions, subscription feed, reactions, saves, watch history, library, comments,
  one-level replies, comment likes, clear history.
- Discovery: video/actor embeddings in pgvector, personalized feed, personalized Explore sections
  with reasons, cold-start trending/latest mix, diversity, actor cache invalidation.
- Creator Studio: creator-scoped video CRUD, visibility/publish transitions, immutable versions,
  studio stats, S3 multipart upload intents, deterministic copyright/policy scans, PostgreSQL media
  job queue, ffmpeg HLS/MP4/thumbnail processing, private media playback gateway.
- Seed: demo actor/channel/videos, optional demo account, refreshes video embeddings.

### Key locations

| Area | Files |
|---|---|
| HTTP server/routes | `internal/api/server.go`, `internal/api/catalog.go`, `internal/api/auth.go`, `internal/api/engagement.go` |
| Identity/auth | `internal/identity`, `internal/auth` |
| Store/catalog | `internal/store/store.go`, `internal/store/catalog.go` |
| Engagement store | `internal/store/engagement.go`, `internal/store/comments.go` |
| Discovery store | `internal/store/discovery.go` |
| Discovery engine | `internal/discovery/embedder.go`, `internal/discovery/engine.go` |
| Studio store | `internal/store/studio.go` |
| Media engine | `internal/media/*` (S3, scanner, ffmpeg processor, job worker) |
| Migrations | `internal/db/migrations/0001…0008` |
| Seed | `internal/seed/seed.go`, `cmd/seed/main.go` |
| Tests | `internal/*/*_test.go` |

### Core API surface

- Public: `/health`, `/api/v1/feed`, `/api/v1/explore`, `/api/v1/videos`, `/api/v1/videos/{id}`,
  `/api/v1/videos/{id}/related`, `/api/v1/shorts`, `/api/v1/search`, `/api/v1/categories`,
  `/api/v1/channels/{id}`, `/api/v1/channels/{id}/videos`, `/api/v1/demo`.
- Auth: `/api/v1/auth/register`, `/verify-email`, `/resend-verification`, `/login`, `/logout`,
  `/session`, `/csrf`, `/forgot-password`, `/reset-password`.
- Viewer state (session + CSRF): `/api/v1/me`, `/api/v1/me/subscriptions`, `/api/v1/me/feed`,
  `/api/v1/me/library`, `/api/v1/me/history`, channel subscription, video reaction/save/view,
  comments, comment likes.
- `GET /api/v1/feed` personalizes when the viewer has signals; otherwise cold start. Discovery
  results include `reason` objects (`subscription`, `category`, `because_you_watched`,
  `because_you_liked`, `because_you_saved`, `recently_watched`, `trending`, `new`, `recommended`).
- `GET /api/v1/explore` returns personalized sections when signals exist, otherwise the editorial
  collections.
- Studio: `/api/v1/studio/channel`, `/api/v1/studio/videos`, `/api/v1/studio/videos/{id}`,
  `/api/v1/studio/videos/{id}/publish`, `/api/v1/studio/videos/{id}/unpublish`,
  `/api/v1/studio/videos/{id}/versions`, `/api/v1/studio/videos/{id}/subtitles`,
  `/api/v1/studio/videos/{id}/thumbnail`, `/api/v1/studio/stats`, `/api/v1/studio/uploads`,
  `/api/v1/studio/uploads/{id}/scans`.
- Media playback gateway: `/api/v1/media/{id}/video.mp4`, `/api/v1/media/{id}/thumbnail.jpg`,
  `/api/v1/media/{id}/captions.vtt`, `/api/v1/media/{id}/subtitles/{track_id}`,
  `/api/v1/media/{id}/hls/master.m3u8`, and HLS variants/segments.

### Discovery details

- `0006_discovery.sql` creates `video_embeddings` and `actor_embeddings` with `vector(384)` and an
  HNSW cosine index.
- The default devstack uses the hash embedder (`hash-embedder`, 384 dimensions) to avoid model
  downloads. The real service uses `BAAI/bge-small-en-v1.5` (384 dimensions).
- Changing the embedding model dimension requires a matching migration.
- `KEELTUBE_EMBEDDINGS_URL` selects the HTTP embedder. If unset, core uses the in-process hash
  embedder. If the HTTP service is unavailable, feed/Explore fall back to cold start/editorial.
- Video embeddings are refreshed by the seed and lazily before discovery requests. Actor embeddings
  are cached in PostgreSQL and invalidated on watch/reaction/save/subscription writes.
- Creator Studio media requires an S3-compatible bucket (`KEELTUBE_MEDIA_S3_*`), ffmpeg/ffprobe,
  and a private bucket. There is no local filesystem storage fallback. Uploads use presigned
  multipart URLs; core checks ownership and serves playback through short-lived presigned redirects.
  See `keel-core/README.md` for the full media configuration and bucket policy.
- `internal/discovery` has tests for the HTTP embedder, hash embedder, cold start, personalization,
  reasons, and invalidation.

### Core commands

```sh
cd keel-core
cp .env.example .env          # fill KEELTUBE_DATABASE_URL and other values
go run ./cmd/seed
go run ./cmd/api

gofmt -l .
go vet ./...
KEELTUBE_TEST_DATABASE_URL='postgres://USER:PASSWORD@HOST:PORT/DB?sslmode=disable' \
  go test -p 1 ./...
```

Database tests require a pgvector-enabled PostgreSQL. Use `pgvector/pgvector:pg16`. Run packages
sequentially (`-p 1`) because the test helper truncates shared tables. The Go toolchain may not be on
`PATH` in every environment; install or use a local Go 1.23+ toolchain rather than modifying the
repository.

## keel-embeddings

Python 3.11+. FastAPI service for text → normalized vectors. Every endpoint requires
`Authorization: Bearer <KEELTUBE_EMBEDDINGS_TOKEN>`. The service fails closed if the token is unset.
`/metrics`, `/docs`, `/redoc`, and `/openapi.json` are intentionally not exposed.

### API

- `POST /v1/embed` with `{"texts": [...], "input_type": "passage|query", "normalize": true}`.
- `GET /v1/models` returns model, revision, dimensions, device, limits, input types.
- `GET /health`, `GET /ready` require the token; `/ready` reports model/device/dimensions.
- Response includes `vectors`, `model`, `dimensions`, `normalized`, and `usage`.

### Backends

- `sentence-transformers` (default model `BAAI/bge-small-en-v1.5`, 384 dimensions).
- `hash` deterministic backend for offline/dev/test use (384 dimensions by default).
- BGE/E5 query/passage prefixes are applied automatically.
- Batching, request deduplication, TTL/LRU cache, normalized vectors, structured logs, request IDs.

### Key locations

| Area | Files |
|---|---|
| App/API | `app/main.py`, `app/schemas.py`, `app/auth.py` |
| Backends | `app/backend.py` |
| Batching/cache | `app/service.py`, `app/cache.py` |
| Prefixes | `app/prefixes.py` |
| Config | `app/config.py` |
| Tests | `tests/` |

### Commands

```sh
cd keel-embeddings
python3.11 -m venv .venv
. .venv/bin/activate
pip install -r requirements-dev.lock
pip install -e . --no-deps
ruff check app tests
ruff format --check app tests
mypy app
pytest -q
```

Install `.[model]` for the real sentence-transformers runtime. The devstack defaults to hash mode:
`KEELTUBE_EMBEDDINGS_INSTALL_MODEL=false`, `KEELTUBE_EMBEDDINGS_BACKEND=hash`,
`KEELTUBE_EMBEDDINGS_MODEL=hash-embedder`. For the real model, set
`KEELTUBE_EMBEDDINGS_INSTALL_MODEL=true`, `KEELTUBE_EMBEDDINGS_BACKEND=sentence-transformers`, and
`KEELTUBE_EMBEDDINGS_MODEL=BAAI/bge-small-en-v1.5`.

## keel-moderation

Python/FastAPI. Local demo with durable SQLite workflow state and an append-only JSONL audit ledger.
Roles: `creator`, `moderator`, `appeals`. Reviewer independence is enforced. Read endpoints are
unauthenticated in open local mode; do not expose to a shared network.

Key endpoints: `/health`, `/v1/policies`, `/v1/demo/state`, `/v1/demo/reset`, `/v1/whoami`,
`/v1/actions`, `/v1/actions/{id}/appeal`, `/v1/appeals/{id}/decide`, `/v1/appeals`,
`/v1/appeals/{id}`, `/v1/ledger`, `/v1/ledger/verify`, `/v1/ledger/export`.

Commands:

```sh
cd keel-moderation
python3 -m venv .venv
. .venv/bin/pip install -r requirements-dev.lock
. .venv/bin/pip install -e . --no-deps
. .venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8082
. .venv/bin/pytest -q
. .venv/bin/ruff check app tests
```

Known next steps: PostgreSQL persistence, signed external ledger anchor, policy bundle loader, SLA
timers, real signal ingestion, transparency generator. Reports belong here, not in core.

## keel-pipeline

Go demo media server. Serves `/health` and `/demo/sample.mp4`. Resumable upload, ffmpeg/ffprobe,
HLS packaging, content hashes, and NATS jobs are not implemented.

```sh
cd keel-pipeline
go run ./cmd/worker
go test ./...
go vet ./...
gofmt -l .
```

## keel-web

Private React 19 + Vite + TypeScript + Tailwind v4 SPA. Read `keel-web/AGENTS.md` for frontend rules.
The app is fully built against local mock data. `src/data/source.ts` is the data seam; replace it
with API adapters. `src/state/workspace-store.tsx` owns cross-page state and persists to
`sessionStorage`. `src/context/auth.tsx` is a local session mock.

Routes: public home, explore, watch, channel, search, shorts, library; auth sign-in/sign-up/
verify/forgot/reset; guarded settings, studio, and `/studio/moderation` creator record. Staff
moderation is intentionally not routed in this app.

Rules that matter: no backend calls in the mock phase; never put moderation tokens in `VITE_*` or
browser state; creator app must never expose moderator decision controls; watch-page trust record is
owner-only; comments have one reply level; upload is a global modal; keep the versioned video editor.

Commands:

```sh
cd keel-web
npm ci
npm run lint
npm test
npm run typecheck
npm run build
npm run test:e2e
```

## keel-spec

Contract source of truth. JSON Schemas, examples, and `schemas/openapi.yaml`. Public API response
changes should update the schema/OpenAPI in a linked PR. Moderation v0.1 is frozen; additive changes
only until v0.2.

## keel-infra

Private devstack. `devstack/apps.compose.yml` runs PostgreSQL (`pgvector/pgvector:pg16`), embeddings,
seed, core, pipeline, and moderation. The web app runs on the host.

Default embeddings mode is hash, so the stack builds quickly. The embeddings service requires
`KEELTUBE_EMBEDDINGS_TOKEN`; the Compose healthcheck sends it. Core and seed receive the same token.
The token is required by the Compose file (`:?`), so the stack fails early if it is missing.

```sh
cd /Users/victor/www/OpenSource
docker compose --env-file keel-infra/devstack/.env \
  -f keel-infra/devstack/apps.compose.yml up -d --build
docker compose --env-file keel-infra/devstack/.env \
  -f keel-infra/devstack/apps.compose.yml config
```

Do not commit `devstack/.env`. Keep real tokens and credentials there or in a secrets manager.

## Security and boundary rules

- Never commit `.env`, real tokens, API keys, passwords, or private repository contents.
- `.env.example` files contain placeholders only.
- Private repos are separate git repositories and are ignored by the root `.gitignore`.
- `make boundary` must pass before pushing root changes.
- Embeddings service: every endpoint requires the bearer token; health endpoints are not public.
- Moderation: creator app never receives moderator tokens or decision controls. Staff portal is a
  separate privileged UI.
- Core: no moderation decision logic; no moderation tokens in browser state.
- Do not expose the local moderation demo or open local mode to a shared network.

## Current limitations / likely next work

- Wire `keel-web` to `keel-core`, `keel-moderation`, and `keel-embeddings`; remove the mock data seam.
- `keel-pipeline` remains a demo media server; Creator Studio upload, transcoding, HLS, and
  thumbnails are handled by the core media engine.
- Staff moderation portal, real signal ingestion, reports, and transparency aggregates.
- Moderation PostgreSQL persistence and signed ledger anchor.
- Monetization, payouts, federation, and production OIDC/social providers.
- Discovery: view-completion signals, impression/click tracking, cross-encoder reranking, evaluation.
- Comment moderation/pin actions and view deduplication.

## Quick test matrix

| Project | Command | Requirements |
|---|---|---|
| Root | `make test`, `make boundary` | Python 3 |
| Core | `go test -p 1 ./...` | Go 1.23+, pgvector PostgreSQL, `KEELTUBE_TEST_DATABASE_URL` |
| Embeddings | `pytest -q` | Python 3.11+, dev lock; no model download for unit tests |
| Moderation | `pytest -q` | Python 3.9+, dev lock |
| Pipeline | `go test ./...` | Go 1.23+ |
| Web | `npm test`, `npm run test:e2e` | Node 22+ |
| Infra | `docker compose … config` | Docker Compose |
