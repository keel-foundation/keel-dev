# Contributing to `keel-pipeline`

Repository: [keel-foundation/keel-pipeline](https://github.com/keel-foundation/keel-pipeline)

This repository owns ingest, scan, transcode, package, thumbnails, and publish events.

## Run only this module

```sh
git clone https://github.com/keel-foundation/keel-pipeline.git
cd keel-pipeline

go run ./cmd/worker
go test ./...
go vet ./...
gofmt -l .
```

The current demo worker serves the sample clip on `127.0.0.1:8081`. It does not require the pipeline, core, moderation, PostgreSQL, NATS, or object storage for the current tests.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `TUBEKEEL_PIPELINE_ADDR` | `127.0.0.1:8081` | Listen address |
| `TUBEKEEL_DEMO_VIDEO` | `demo/sample.mp4` | Demo clip |
| `TUBEKEEL_CORS_ORIGINS` | `http://localhost:3000` | Comma-separated web origins |

Use the private maintainer stack in `keel-infra` only when your change needs PostgreSQL, NATS, or S3. Public contributors should not need the full stack.

## Connect the public demo

Point the demo at local core and pipeline:

```sh
cd keel-dev
TUBEKEEL_MODE=remote \
TUBEKEEL_API_BASE_URL=http://127.0.0.1:8080 \
TUBEKEEL_MODERATION_BASE_URL=http://127.0.0.1:8082 \
make demo
```

The demo uses core for playback metadata. It does not run the pipeline itself.

## PR checklist

- `go test ./...`, `go vet ./...`, and `gofmt -l .` are clean.
- New jobs are idempotent.
- Content hashes and manifests are deterministic.
- Events are documented and schema-compatible.
- No secrets or customer media are committed.
- Commits are signed off with `git commit -s`.

See [PR guidelines](pr-guidelines.md).
