# Public repositories

Clone only the repository you need.

| Repository | Purpose |
|---|---|
| [`keel-spec`](https://github.com/keel-foundation/keel-spec) | Protocol, RFCs, JSON Schemas, and OpenAPI. |
| [`keel-core`](https://github.com/keel-foundation/keel-core) | API, identity, channels, videos, subscriptions. |
| [`keel-pipeline`](https://github.com/keel-foundation/keel-pipeline) | Ingest, transcode, package, thumbnails. |
| [`keel-web`](https://github.com/keel-foundation/keel-web) | Viewer, creator studio, moderation console. |
| [`keel-moderation`](https://github.com/keel-foundation/keel-moderation) | Signals, cases, appeals, audit ledger, content protection. |
| [`keel-dev`](https://github.com/keel-foundation/keel-dev) | This demo and contribution hub. |
| [`keel-docs`](https://github.com/keel-foundation/keel-docs) | Public creator and developer documentation. |
| [`.github`](https://github.com/keel-foundation/.github) | Organization profile, community health, reusable CI. |

`keel-governance`, `keel-infra`, `keel-security`, and `keel-branding` are private. Access is
granted by maintainers. They are separate repositories. Do not copy their contents into a public
repository, and run `make boundary` before pushing changes from this workspace.

## Full-stack setup

The author and maintainer group use a private full-stack guide and local stack in `keel-infra`. Public contributors do not need it. Run the module you are changing and use stage endpoints for everything else.
