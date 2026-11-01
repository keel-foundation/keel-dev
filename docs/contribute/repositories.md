# Repositories

Clone only the public repository you need. Private repositories are maintainer-only.

| Repository | Purpose |
|---|---|
| [`keel-spec`](https://github.com/keel-foundation/keel-spec) | Protocol, RFCs, JSON Schemas, and OpenAPI. |
| [`keel-core`](https://github.com/keel-foundation/keel-core) | API, identity, channels, videos, subscriptions. |
| [`keel-pipeline`](https://github.com/keel-foundation/keel-pipeline) | Ingest, transcode, package, thumbnails. |
| [`keel-moderation`](https://github.com/keel-foundation/keel-moderation) | Signals, cases, appeals, audit ledger, content protection. |
| [`keel-dev`](https://github.com/keel-foundation/keel-dev) | This demo and contribution hub. |
| [`keel-docs`](https://github.com/keel-foundation/keel-docs) | Public creator and developer documentation. |
| [`.github`](https://github.com/keel-foundation/.github) | Organization profile, community health, reusable CI. |

## Private repositories

These repositories are maintainer-only. Access is granted by maintainers. They are separate
repositories. Do not clone, mirror, copy, or redistribute their contents without maintainer
approval. Run `make boundary` before pushing changes from this workspace.

| Repository | Purpose |
|---|---|
| [`keel-web`](https://github.com/keel-foundation/keel-web) | Viewer, creator studio, and creator moderation record. Private until the maintainer pool is established. |
| `keel-governance` | Constitution, whitepaper, board, finance, legal. |
| `keel-infra` | Production infrastructure, environments, runbooks, dev stack. |
| `keel-security` | Threat model, incident response, audits. |
| `keel-branding` | Brand system, source assets, and decisions. |

## Full-stack setup

The author and maintainer group use a private full-stack guide and local stack in `keel-infra`. Public contributors do not need it. Run the module you are changing and use stage endpoints for everything else.
