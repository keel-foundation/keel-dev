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
| `keel-core` | public | Go | Identity, catalog, engagement, discovery API | PostgreSQL + pgvector; auth, catalog, engagement, discovery, studio, federation; UAT-ready |
| `keel-moderation` | public | Python/FastAPI | Signals, cases, actions, appeals, ledger | PostgreSQL workflow state + append-only JSONL ledger; UAT-ready |
| `keel-moderation-web` | private | React/TypeScript + Node BFF | Staff moderation portal | Cases, enforcement, appeals, actions, ledger, federation status; UAT-ready |
| `keel-spec` | public | YAML/JSON | Protocol, RFCs, schemas, OpenAPI | Contract source of truth; 156 OpenAPI paths validated |
| `keel-docs` | public | Markdown | Creator and developer docs | Governance and API docs |
| `keel-web` | private | React/TypeScript + Cloudflare Worker | Viewer, creator studio, creator moderation record | UI complete on local mock data; Worker BFF ready; data adapters pending |
| `keel-embeddings` | private | Python/FastAPI | Embedding and semantic-retrieval service | Token-protected; hash and sentence-transformers backends |
| `keel-infra` | private | Docker/Terraform | Devstack and infrastructure | Compose stack includes pgvector, core, embeddings, moderation, and an optional media worker |
| `keel-governance` | private | Markdown | Constitution, board, finance, legal | Docs |
| `keel-security` | private | Markdown | Threat model, audits, incident response | Docs |
| `keel-branding` | private | Assets/Markdown | Brand system and assets | Assets/decisions |

## UAT status

`keel-core`, `keel-moderation`, and `keel-moderation-web` are feature-complete for UAT as a
coordinated backend and staff-portal stack:

- `keel-core`: `gofmt -l .`, `go vet ./...`, and `go test -p 1 ./...` pass against PostgreSQL +
  pgvector.
- `keel-moderation`: `pytest` and `ruff check app tests` pass. OIDC claims, PostgreSQL workflow
  state, creator/staff scopes, signals, notifications, the ledger, a bundled model-based classifier,
  optional transformer/HTTP classifiers, and the public transparency report are implemented.
- `keel-moderation-web`: BFF tests, TypeScript typecheck, and the production build pass. The staff
  cases, enforcement, appeals, actions, ledger, and federation surfaces are implemented.

The remaining UAT integration point is `keel-web`: its UI is complete on local mock data and its
Cloudflare Worker BFF is implemented, but the core/moderation data adapters are still pending. The
cross-service acceptance harness (`keel-infra/maintainers/scripts/acceptance.sh`) exercises core,
moderation, embeddings, MinIO, and the worker. Production-only work remains: calibrated production
classifier models, an externally anchored ledger, server-signed creator export bundles, viewer
billing and automatic settlement scheduling, and non-core OIDC token forwarding.

Do not copy private repository contents into a public repository. Do not add private repositories to
the root git index. Run `make boundary` before pushing root changes.

## Ports and services

| Service | Default | Notes |
|---|---|---|
| Web (`keel-web`) | `http://localhost:3000` | Runs on the host, not in Compose |
| Core (`keel-core`) | `127.0.0.1:8080` | `/health`, `/api/v1/*` |
| Media worker (`keel-core/cmd/worker`) | `127.0.0.1:8083` | `/health`, `/status`; optional Compose `media` profile |
| Moderation (`keel-moderation`) | `127.0.0.1:8082` | `/v1/*`, `/health` |
| Staff portal (`keel-moderation-web`) | `127.0.0.1:8095` | Node BFF plus Vite dev server on `:3100` |
| Embeddings (`keel-embeddings`) | `127.0.0.1:8090` | Every endpoint requires a bearer token |
| PostgreSQL | internal only | `pgvector/pgvector:pg16` in the app stack |
| MinIO (`keel-infra` devstack) | `127.0.0.1:9000` | Private S3 bucket for uploads/playback; console `:9001` |

The devstack Compose file is `keel-infra/devstack/apps.compose.yml`. It runs PostgreSQL, MinIO
(with a private bucket), the embeddings service, a one-shot seed job, core, moderation, and an
optional media worker. The web app stays on the host for hot reload. Production uses Cloudflare R2
(or another private S3-compatible store).

## Data flow

```text
keel-web (mock data today; Cloudflare Worker BFF ready)
  -> Worker /api/*                       (forwards the viewer session cookie to core)
  -> Worker /moderation/*                (creator-safe moderation allowlist; server-side token)
  -> keel-core /api/v1/studio/moderation/* (creator-safe gateway; no browser moderation token)

keel-core
  -> PostgreSQL + pgvector               (actors, channels, videos, auth, engagement, embeddings,
                                          creator finance billing data)
  -> keel-embeddings /v1/embed           (HTTP, bearer token)
  -> keel-moderation /v1/creator/*       (HTTP, server-side OIDC-style claims)
  -> keel-moderation /v1/signals         (HTTP, server-side ingest token for viewer reports)
  -> hash embedder fallback              (when KEELTUBE_EMBEDDINGS_URL is unset)

keel-moderation
  -> PostgreSQL                          (cases, actions, appeals; SQLite offline fallback)
  -> append-only JSONL ledger            (hash chain)
  -> keel-core /internal/v1/notifications (creator-safe moderation events)

keel-moderation-web (staff portal, private)
  -> Node BFF /api/*                      (signed HttpOnly staff session)
  -> keel-moderation /v1/*                (moderator or appeals token, server-side only)
  -> keel-core /internal/v1/federation    (optional internal-token federation panel)
```

Core never makes moderation decisions. Moderation decisions never live in the creator web app. The
staff moderation portal is `keel-moderation-web`; the creator app only reads its own record and
files appeals.

## keel-core

Go 1.23+. PostgreSQL is required. Discovery requires the `vector` extension and a pgvector-enabled
PostgreSQL image.

### Implemented

- Identity: register, email verification, login/logout, session cookies, CSRF, password reset,
  lockout, Argon2id, auth events, and Google/Apple/X social OIDC/OAuth sign-in with PKCE and
  account linking.
- Catalog: actors, channels, videos, feed, explore, shorts, search, semantic search, search
  suggestions, categories, related videos, bulk channel lookup, channel profiles, visibility rules
  (removed → 410 with tombstone, private → 404 unless owner, unlisted by link, archived excluded).
- Engagement: subscriptions, subscription feed, reactions, saves, watch history, library, comments,
  one-level replies, comment likes, comment pin/unpin/remove, clear history, playlists/collections.
- Discovery: video/actor embeddings in pgvector, personalized feed, personalized Explore sections
  with reasons, cold-start trending/latest mix, diversity, actor cache invalidation, semantic
  search, search suggestions, optional cross-encoder reranking, and interest signals from
  comments and impression/click telemetry.
- Creator Studio: creator-scoped video CRUD, archive/restore/delete, irreversible archived-video
  media purge, scheduled publishing,
  visibility/publish transitions, studio search, immutable versions, comment moderation, channel
  profile updates, studio stats, S3 multipart upload intents, deterministic copyright/policy scans,
  PostgreSQL media job queue, ffmpeg HLS/MP4/thumbnail processing, private media playback gateway.
- Watch telemetry: anonymous visitor cookies, deduplicated view sessions, idempotent playback
  heartbeats, impression/click events, 90-day raw retention, permanent daily aggregates, and
  creator analytics endpoints.
- Notifications: creator-scoped notification list, unread count, mark-one/read-all, comment/reply,
  upload published/failed, and moderation event producers, plus an internal ingest route for
  moderation and finance events. The ingest route derives the owner from `channel_id` when
  `actor_id` is omitted.
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
| Analytics store | `internal/store/analytics.go` |
| Analytics API | `internal/api/analytics.go`, `internal/api/telemetry.go` |
| Notifications | `internal/notifications/service.go`, `internal/store/notifications.go`, `internal/api/notifications.go` |
| Creator moderation gateway | `internal/moderation/client.go`, `internal/api/moderation.go` |
| Stripe billing/settlement | `internal/billing/*`, `internal/api/billing.go`, `internal/store/billing.go` |
| Media engine | `internal/media/*` (S3, scanner, ffmpeg processor, job worker) |
| Media worker | `cmd/worker/main.go` (separate FFmpeg process; `/health`, `/status`) |
| Migrations | `internal/db/migrations/0001…0022` |
| Seed | `internal/seed/seed.go`, `cmd/seed/main.go` |
| Tests | `internal/*/*_test.go` |

### Core API surface

- Public: `/health`, `/api/v1/feed`, `/api/v1/explore`, `/api/v1/videos`, `/api/v1/videos/{id}`,
  `/api/v1/videos/{id}/related`, `/api/v1/shorts`, `/api/v1/search`, `/api/v1/categories`,
  `/api/v1/channels/{id}`, `/api/v1/channels/{id}/videos`, `/api/v1/demo`.
  `/api/v1/channels/{id}` accepts a channel ID, a handle such as `@maravale`, or a bare handle.
- Auth: `/api/v1/auth/register`, `/verify-email`, `/resend-verification`, `/login`, `/logout`,
  `/session`, `/csrf`, `/forgot-password`, `/reset-password`, plus account password change and
  session list/revoke endpoints under `/api/v1/me`.
- Viewer state (session + CSRF): `/api/v1/me`, `/api/v1/me/subscriptions`, `/api/v1/me/feed`,
  `/api/v1/me/library`, `/api/v1/me/history`, `/api/v1/me/notifications`,
  `/api/v1/me/notifications/unread-count`, notification read/read-all, channel subscription, video
  reaction/save/view, comments, comment likes.
- `GET /api/v1/feed` personalizes when the viewer has signals; otherwise cold start. Discovery
  results include `reason` objects (`subscription`, `category`, `because_you_watched`,
  `because_you_liked`, `because_you_saved`, `recently_watched`, `trending`, `new`, `recommended`).
- `GET /api/v1/explore` returns personalized sections when signals exist, otherwise the editorial
  collections.
- Studio: `/api/v1/studio/channel`, `/api/v1/studio/videos`, `/api/v1/studio/videos/{id}` (edit
  aggregate with `rights`, `subtitles`, and `versions`),
  `/api/v1/studio/videos/{id}/publish`, `/api/v1/studio/videos/{id}/unpublish`,
  `/api/v1/studio/videos/{id}/versions`, `/api/v1/studio/videos/{id}/subtitles`,
  `/api/v1/studio/videos/{id}/thumbnail`, `/api/v1/studio/stats`, `/api/v1/studio/comments`,
  `/api/v1/studio/uploads` (list/create), `/api/v1/studio/uploads/{id}/scans`,
  `/api/v1/studio/monetization`, `/api/v1/studio/earnings`, `/api/v1/studio/payouts`.
- Creator moderation gateway (session + CSRF; channel derived from the session, never from the
  client): `/api/v1/studio/moderation/summary`, `/cases`, `/cases/{id}`, `/actions`,
  `/actions/{id}`, `/appeals`, `/appeals/{id}`, `/ledger`, `/ledger/verify`, `/ledger/export`,
  and `POST /actions/{id}/appeal`. Cases and actions accept a `video_id` filter. Core calls
  `keel-moderation` with short-lived OIDC-style claims (`sub`, `role`, `channel_ids`) signed by
  `KEELTUBE_MODERATION_CLAIMS_SECRET`; the static `KEELTUBE_MODERATION_TOKEN` is the legacy
  fallback. Moderation verifies the claims in OIDC mode. The appeal write path is channel-scoped and
  rejects cross-channel action IDs.
- Media playback gateway: `/api/v1/media/{id}/video.mp4`, `/api/v1/media/{id}/thumbnail.jpg`,
  `/api/v1/media/{id}/captions.vtt`, `/api/v1/media/{id}/subtitles/{track_id}`,
  `/api/v1/media/{id}/hls/master.m3u8`, and HLS variants/segments.
- Analytics: `/api/v1/videos/{id}/view`, `/api/v1/videos/{id}/view/progress`,
  `/api/v1/telemetry/events`, `/api/v1/studio/analytics/summary`,
  `/api/v1/studio/analytics/timeseries`, `/api/v1/studio/videos/{id}/analytics`.
- Reports: `POST /api/v1/reports` persists a report, forwards it to `keel-moderation` as a signal
  using `KEELTUBE_MODERATION_SIGNAL_TOKEN`, and links the moderation case/signal. Reporters can read
  their own reports with `GET /api/v1/reports/{id}` and `GET /api/v1/me/reports`.
- Search: `GET /api/v1/search` accepts `channel_id`; `GET /api/v1/search/semantic` uses pgvector
  embeddings and an optional cross-encoder reranker; `GET /api/v1/search/suggestions` returns
  videos, shorts, and channels.
- Playlists: `/api/v1/me/playlists` and `/api/v1/playlists/{id}` support playlists and collections,
  including add/remove video items.
- Public trust record: `GET /api/v1/videos/{id}/trust` proxies moderation's public video record.
- Removed videos return `410` with a canonical `video` tombstone (playback omitted) so clients can
  render the removal record without a second request. Private videos remain `404` unless owner.

### Federation

Core exposes a PeerTube-compatible ActivityPub v0.1 surface when
`KEELTUBE_FEDERATION_DOMAIN` is set:

- `GET /.well-known/webfinger` resolves `acct:handle@domain` to a local actor.
- `GET /federation/actors/{id}` returns an ActivityPub `Group` actor with inbox, outbox,
  followers, following, and an RSA public key.
- `GET /federation/actors/{id}/outbox` publishes local public videos as `Create` activities.
- `POST /federation/actors/{id}/inbox` verifies HTTP Signatures and handles Follow, Undo, Accept,
  Reject, Create/Update Video, Delete, and Flag. Unsolicited video activities are ignored unless the
  instance follows the sender.
- `GET /federation/videos/{id}` returns a PeerTube-compatible Video object with `keeltube:*`
  extensions for content hashes and policy versions.
- `GET /federation/policy` publishes a signed instance policy document.

Remote follows, peers, inbox idempotency, and signed outbound deliveries are stored in PostgreSQL.
Remote actors and videos use deterministic `*_remote_*` identifiers in the catalog. Delivery uses
RSA-SHA256 HTTP Signatures with a `Digest` header and retries with exponential backoff. Internal
operator routes under `/internal/v1/federation` require `KEELTUBE_INTERNAL_TOKEN`.

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
go run ./cmd/worker          # separate process; requires KEELTUBE_MEDIA_S3_*

gofmt -l .
go vet ./...
KEELTUBE_TEST_DATABASE_URL='postgres://USER:PASSWORD@HOST:PORT/DB?sslmode=disable' \
  go test -p 1 ./...
```

The API process never starts FFmpeg workers. Run `cmd/worker` separately against the same database
and object store. Database tests require a pgvector-enabled PostgreSQL. Use `pgvector/pgvector:pg16`.
Run packages sequentially (`-p 1`) because the test helper truncates shared tables. The Go toolchain may not be on
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

Python/FastAPI. Local demo with durable PostgreSQL workflow state (versioned migrations) and an
append-only JSONL audit ledger. SQLite remains an explicit offline/test fallback.
Roles: `creator`, `moderator`, `appeals`, `operator`. Reviewer independence is enforced. The demo
read endpoints `/v1/demo/state` and `/v1/ledger*` remain unauthenticated; authenticated endpoints
require OIDC claims or all three role tokens and fail closed otherwise. Creator records are
channel-scoped.

Key endpoints: `/health`, `/v1/policies`, `/v1/demo/state`, `/v1/demo/reset`, `/v1/whoami`,
`/v1/signals`, `/v1/public/videos/{video_id}/record`, `/v1/actions`,
`/v1/actions/{id}/appeal`, `/v1/appeals/{id}/decide`,
`/v1/appeals`, `/v1/appeals/{id}`, `/v1/creator/summary`, `/v1/creator/cases`,
`/v1/creator/actions`, `/v1/creator/appeals`, `/v1/creator/ledger`,
`/v1/creator/ledger/verify`, `/v1/creator/ledger/export`, `/v1/ledger`, `/v1/ledger/verify`,
`/v1/ledger/export`. Creator cases and actions accept `video_id`.

Creator scoping uses authenticated principal channel claims. OIDC mode reads the `channel_ids`
claim; role-token mode reads `KEELTUBE_CREATOR_CHANNEL_MAP` (default
`{"creator:demo":["ch_demo"]}`). Authentication is required and fails closed when unconfigured.
Explicit `channel_id` columns on cases, actions, and appeals back the queries. Ledger records carry
`channel_id` inside `payload`; creator ledger reads filter on that field and never use string
matching against case, action, or appeal IDs.

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

Known next steps: signed external ledger anchor, policy bundle loader, SLA timers, calibrated
production classifier models, and signed/archived transparency artifacts. Viewer reports reach
moderation through
`POST /v1/signals` using `KEELTUBE_SIGNAL_INGEST_TOKEN`; core validates the subject and forwards the
report. The devstack runs `python -m app.seed` before moderation starts to create the demo record.

## keel-moderation-web

Private React 19 + Vite + TypeScript + Tailwind v4 staff portal with a same-origin Node BFF.
Read `keel-moderation-web/AGENTS.md` before changing it. The moderator and appeals tokens stay on
the server; the browser receives only a signed HttpOnly staff session cookie. Moderator and appeals
capabilities are role-separated in both the BFF and the UI.

Implemented surfaces: overview with queue counts and ledger status, cases and evidence, enforcement
and dismissal, independent appeal decisions, actions with Statements of Reasons, ledger verification
and export, and the optional federation panel. The BFF calls `/v1/*` on `keel-moderation`; the
federation panel uses the core internal token.

Commands:

```sh
cd keel-moderation-web
npm ci
npm run typecheck
npm test
npm run build
npm start
```

## keel-web

Private React 19 + Vite + TypeScript + Tailwind v4 SPA. Read `keel-web/AGENTS.md` for frontend rules.
The app is fully built against local mock data. `src/data/source.ts` is the data seam; replace it
with API adapters. `src/state/workspace-store.tsx` owns cross-page state and persists to
`sessionStorage`. `src/context/auth.tsx` is a local session mock.

A Cloudflare Worker BFF in `worker/` already proxies `/api/*` to core with the viewer session
cookie and `/moderation/*` to the creator-safe moderation allowlist with a server-side token. The
browser must call the BFF, never a backend directly, and moderation tokens must never reach the
browser.

Routes: public home, explore, watch, channel, search, shorts, library; auth sign-in/sign-up/
verify/forgot/reset; guarded settings, studio, and `/studio/moderation` creator record. Staff
moderation is intentionally not routed in this app; it lives in `keel-moderation-web`.

Rules that matter: the data seam remains mock-only until the adapters land; never put moderation
tokens in `VITE_*` or browser state; creator app must never expose moderator decision controls;
watch-page trust record is owner-only; comments have one reply level; upload is a global modal; keep
the versioned video editor.

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
seed, core, and moderation. The web app runs on the host. The media worker is an optional Compose
profile (`--profile media`) and requires an S3-compatible bucket.

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
- `.env.example` files contain local development values only; never put production secrets in them.
- Private repos are separate git repositories and are ignored by the root `.gitignore`.
- `make boundary` must pass before pushing root changes.
- Embeddings service: every endpoint requires the bearer token; health endpoints are not public.
- Moderation: creator app never receives moderator tokens or decision controls. Staff portal is a
  separate privileged UI.
- Core: no moderation decision logic; no moderation tokens in browser state.
- Do not expose the unauthenticated moderation demo read endpoints to a shared network.

## Current limitations / likely next work

- Wire `keel-web` to `keel-core`, `keel-moderation`, and `keel-embeddings`; remove the mock data seam.
- Media processing runs in `keel-core/cmd/worker`; the API process never starts FFmpeg workers.
- Deploy and calibrate a production transformer classifier; the bundled model and public
  transparency endpoint are implemented. Add signed/archived transparency artifacts.
- Signed external moderation ledger anchor.
- Stripe Connect onboarding and manual settlement are implemented in core. Viewer billing,
  subscriptions, tax handling, and automatic payout scheduling are future work.
- Non-core OIDC token forwarding.
- Discovery: evaluation on top of completion and impression data; production reranker deployment.
- Production media player hardening and larger-scale federation testing.

## Quick test matrix

| Project | Command | Requirements |
|---|---|---|
| Root | `make test`, `make boundary` | Python 3 |
| Core | `go test -p 1 ./...` | Go 1.23+, pgvector PostgreSQL, `KEELTUBE_TEST_DATABASE_URL` |
| Embeddings | `pytest -q` | Python 3.11+, dev lock; no model download for unit tests |
| Moderation | `pytest -q` | Python 3.9+, dev lock |
| Worker | `go test ./cmd/worker` | Go 1.23+ |
| Web | `npm test`, `npm run test:e2e` | Node 22+ |
| Moderation portal | `npm test`, `npm run typecheck`, `npm run build` | Node 22+ |
| Infra | `docker compose … config` | Docker Compose |
