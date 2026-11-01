# Contributing to `keel-core`

Repository: [keel-foundation/keel-core](https://github.com/keel-foundation/keel-core)

You only need `keel-core` for most API, identity, channel, video, subscription, and feed work.

## Run only this module

```sh
git clone https://github.com/keel-foundation/keel-core.git
cd keel-core

go run ./cmd/api
go test ./...
go vet ./...
gofmt -l .
```

The current demo API listens on `127.0.0.1:8080` by default.

### Configuration

| Variable | Default | Purpose |
|---|---|---|
| `TUBEKEEL_CORE_ADDR` | `127.0.0.1:8080` | Listen address |
| `TUBEKEEL_PIPELINE_PUBLIC_URL` | `http://localhost:8081` | Playback base URL |
| `TUBEKEEL_CORS_ORIGINS` | `http://localhost:3000` | Comma-separated web origins |

You do **not** need the pipeline, moderation, web app, PostgreSQL, or NATS to run `keel-core` for most changes.

## Work on a specific area

The module you change should have its own package under `internal/`. Run only that package's tests while iterating:

```sh
go test ./internal/channels/...
go test ./internal/videos/...
```

Use the repository's README and the issue for the intended package boundary. If a change crosses packages, run `go test ./...` before opening the PR.

## Connect the demo to local core

Start local core, then run the public demo with the stage moderation endpoint:

```sh
TUBEKEEL_MODE=remote \
TUBEKEEL_API_BASE_URL=http://127.0.0.1:8080 \
TUBEKEEL_MODERATION_BASE_URL=https://stage-moderation.example.org \
make demo
```

If you do not have stage moderation access, run `keel-moderation` locally as well. It is a small Python service with no database requirement. That is still only the two modules needed to see the appeal flow.

Do not point the demo at the full ecosystem just to work on core.

## OpenAPI

The demo contract is [keel-spec/schemas/openapi.yaml](https://github.com/keel-foundation/keel-spec/blob/main/schemas/openapi.yaml). Stage maintainers can provide the deployed OpenAPI URL. Use it to check request and response shapes before changing an endpoint.

If your change alters a public response, update the schema and examples in `keel-spec` in a linked PR.

## PR checklist

- `go test ./...`, `go vet ./...`, and `gofmt -l .` are clean.
- New behavior has tests.
- CORS stays limited to configured origins.
- No moderation decision logic lives in core.
- Schema changes are coordinated with `keel-spec` and the moderation client.
- No secrets or production URLs are committed.
- Commits are signed off with `git commit -s`.

See [PR guidelines](pr-guidelines.md).
