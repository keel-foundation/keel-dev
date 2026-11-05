# keel-dev

The public front door for **KeelTube**.

This repository is intentionally small. It contains:

- a minimal, standalone **creator-appeal demo**;
- contribution guides for the public repositories;
- staging integration notes for connecting the demo to real services.

It does **not** contain or require the full KeelTube ecosystem. You do not need to clone every repository or start every service to contribute.

Full-stack local setup is reserved for the author and maintainer group. That guide lives in the private `keel-infra` repository. Public contributors should run the single module they are changing and use stage endpoints or the mocked demo for everything else.

## Run the demo

Requires Python 3.9+.

```sh
make demo
```

Open `http://localhost:3000`.

The demo is mocked by default. It simulates the signal, case, enforcement action, appeal, independent review, and hash-chained ledger entirely in the browser. No backend is required.

The standalone demo uses the approved KeelTube brand system: Manrope, Inter, IBM Plex Mono, the primary purple palette, and a dark/light theme toggle. To run it beside `keel-web` on port 3000, use `PORT=3001 make demo`.

## Connect to stage

When stage endpoints are available, run the demo in stage mode:

```sh
KEELTUBE_MODE=remote \
KEELTUBE_API_BASE_URL=https://stage-api.example.org \
KEELTUBE_MODERATION_BASE_URL=https://stage-moderation.example.org \
KEELTUBE_OPENAPI_URL=https://stage-api.example.org/openapi.yaml \
make demo
```

Set `KEELTUBE_OIDC_TOKEN` to the stage OIDC bearer token before running the command. The local demo
server proxies `/api/*` and `/moderation/*` to those services. The token stays on the server and is
never placed in browser JavaScript. See [docs/staging.md](docs/staging.md).

## Contribute

Pick one repository. Do not clone the ecosystem.

| Area | Start here |
|---|---|
| General workflow | [docs/contribute/get-started.md](docs/contribute/get-started.md) |
| `keel-core` | [docs/contribute/keel-core.md](docs/contribute/keel-core.md) |
| `keel-moderation` | [docs/contribute/keel-moderation.md](docs/contribute/keel-moderation.md) |
| Policy and appeals | [docs/contribute/policy.md](docs/contribute/policy.md) |
| `keel-spec` | [docs/contribute/keel-spec.md](docs/contribute/keel-spec.md) |
| `keel-web` (private) | Maintainers only. See [docs/contribute/keel-web.md](docs/contribute/keel-web.md). |
| `keel-docs` | [docs/contribute/keel-docs.md](docs/contribute/keel-docs.md) |
| PR rules | [docs/contribute/pr-guidelines.md](docs/contribute/pr-guidelines.md) |
| Repository map | [docs/contribute/repositories.md](docs/contribute/repositories.md) |

The short version:

1. Find an issue or open a discussion.
2. Clone only the repository you need.
3. Run its tests and the checks for the module you changed.
4. Sign off commits with the DCO.
5. Open a focused pull request.

## Production readiness

`keel-core`, `keel-moderation`, and `keel-moderation-web` form the production stack. Core has no
demo routes, fixtures, seed command, demo defaults, or dev auth fallback; it passes `gofmt`,
`go vet`, and `go test -p 1 ./...` against PostgreSQL + pgvector. Moderation passes `pytest` and
`ruff`; the staff portal passes its BFF tests, typecheck, and production build.

`keel-moderation` now includes a bundled model-based classifier, optional transformer and HTTP
classifier adapters, and a public transparency report generated from workflow state and the audit
ledger. The devstack includes MinIO for local media storage and a cross-service acceptance harness
(`keel-infra/maintainers/scripts/acceptance.sh`).

`keel-web` is the remaining integration point. Its UI is complete against local mock data and its
Cloudflare Worker BFF already proxies core and creator-safe moderation requests. Production wiring
can begin immediately against the cleaned core API.

Viewer memberships, Stripe Tax handling, invoice receipts, and automatic monthly creator
settlement are implemented. Production-only work still includes deploying a calibrated transformer
classifier, an externally anchored moderation ledger, server-signed creator export bundles,
content-protection fingerprinting, and non-core OIDC token forwarding.

## Workspace boundary

`keel-web`, `keel-moderation-web`, `keel-embeddings`, `keel-governance`, `keel-infra`,
`keel-security`, and `keel-branding` are private repositories.
They are separate checkouts. When they are placed inside this working tree, this repository
ignores them. Never copy, commit, or push their contents into `keel-dev` or any other public
repository.

Run the boundary check before pushing:

```sh
make boundary
```

`make test` runs the same check. It verifies that private paths are ignored and that no private
path is tracked here.

## Demo files

| Path | Purpose |
|---|---|
| `demo/index.html` | Demo layout |
| `demo/styles.css` | Demo styles |
| `demo/app.js` | Mock adapter, stage adapter, ledger, and UI |
| `demo/config.js` | Static mock-mode configuration |
| `demo/sample.mp4` | Eight-second demo clip |
| `scripts/serve.py` | Zero-dependency static server and stage proxy |
| `scripts/check_demo.py` | Asset and adapter checks |
| `scripts/check-doc-links.py` | Local documentation link check |

## Status

The public demo in this repository is mocked. The KeelTube web client is fully built against a
local data adapter: email/password sign-in, sign-up, email verification, password reset, home,
Explore, watch page, channel pages, search, library, creator studio, and the creator moderation
record, including trust records, cases, appeals, and a browser-verified audit ledger. A Cloudflare
Worker BFF is implemented for the web client; its core and moderation data adapters are the next
step. The authentication UI also shows Google, Apple, and X provider options. Core implements social
OIDC/OAuth sign-in, account linking, PKCE, and single-use authorization state; the demo buttons
still offer the demo account until provider credentials are configured in the web client. The web
client is private while the maintainer pool is established. The core service has PostgreSQL-backed
actors, channels, videos, subscriptions, creator uploads, FFmpeg/HLS processing in a separate
worker, watch telemetry, analytics, notifications, viewer report ingestion, semantic search,
playlists, channel profiles, scheduled publishing, public trust records, irreversible archived-video
media purge, ActivityPub federation, Stripe Connect creator onboarding and settlement, and a
read-only finance view. Moderation uses PostgreSQL
workflow state with versioned migrations and an append-only JSONL audit ledger. The private
`keel-moderation-web` staff portal implements the moderation queue, enforcement, independent appeal
decisions, actions, ledger, and federation status; the creator app does not expose moderator
actions. Viewer memberships, tax handling, and automatic settlement are implemented; content-protection fingerprinting is not.

The demo is local-only. Do not expose it to the public internet without adding real authentication and a reverse proxy.

## Licensing

AGPL-3.0. See [LICENSE](LICENSE).
