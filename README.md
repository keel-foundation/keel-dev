# keel-dev

The workspace and developer operations repo for **TubeKeel** under the [`keel-foundation`](https://github.com/keel-foundation) organization.

TubeKeel is an open, federated video protocol built around creator ownership, real due process, content protection, and transparent payouts. This repo is the front door for local development, repo onboarding, and org automation.

## Repositories

| Repo | Visibility | Purpose |
|---|---|---|
| `keel-spec` | Public | Protocol, RFCs, schemas, policy language |
| `keel-core` | Public | API, identity, channels, videos, subscriptions |
| `keel-pipeline` | Public | Ingest, transcode, package, thumbnails |
| `keel-web` | Public | Viewer, creator studio, moderation console |
| `keel-moderation` | Public | Signals, cases, appeals, audit ledger, content protection |
| `keel-dev` | Public | This workspace: local stack, scripts, onboarding |
| `keel-docs` | Public | Public creator and developer documentation |
| `.github` | Public | Org profile, community health, reusable CI |
| `keel-governance` | Private | Constitution, whitepaper, board, finance, legal |
| `keel-infra` | Private | Production infrastructure and runbooks |
| `keel-security` | Private | Threat model, incidents, security audits |

The full matrix, including teams and licenses, is in [REPOS.md](REPOS.md). The access policy is in [ACCESS.md](ACCESS.md).

## Quick start

Prerequisites for the appeal demo: Node.js 22+, Python 3.9+, `curl`, and `nc`. Go 1.23+ is optional; without it the UI uses the bundled sample clip. Docker is only needed for the local PostgreSQL/LocalStack S3/NATS stack.

```sh
git clone https://github.com/keel-foundation/keel-dev.git
cd keel-dev
./scripts/bootstrap-dev.sh
make demo
```

Open the URL printed by the script (usually `http://localhost:3000/demo`). The demo installs the moderation venv and web dependencies on first run. It binds all services to `127.0.0.1`, restricts CORS to the web origin, and verifies the ledger chain before showing it.

### Full development setup

```sh
./scripts/bootstrap-dev.sh --all   # also clone the private repos you can access
make infra-up                      # PostgreSQL, LocalStack S3, NATS (not required by the demo)
(cd keel-web && npm install)
(cd keel-moderation && python3 -m venv .venv && .venv/bin/pip install -e '.[dev]')
```

Run services in separate terminals:

```sh
make core-dev
make pipeline-dev
make moderation-dev
make web-dev
```

`make moderation-dev` uses `keel-moderation/.venv/bin/uvicorn` when it exists, so activating the venv in every terminal is not required.

The bootstrap script clones the public repos plus the `.github` repo into `dot-github`. Private repos are cloned only with `--all`. They are ignored by this repo's `.gitignore`; each has its own git history and GitHub remote.

## Local demo

`make demo` runs the creator-appeal flow:

1. **Issue false positive** — a synthetic automated classifier signal is attached to an original documentary.
2. **File appeal** — the creator submits grounds and a statement.
3. **Reverse on human review** — an independent appeals reviewer reverses the action with written reasoning.
4. **Inspect the ledger** — every step is appended to a hash-chained JSONL ledger that can be verified and exported.

Expected states: `active` → appeal `pending` → appeal `decided` / action `reversed`. The 90-second recording shot list is in [docs/demo-script.md](docs/demo-script.md). The launch thread draft is in [docs/x-post.md](docs/x-post.md).

The demo is **local-only**. It has a synthetic classifier, a demo token option, and no production authentication. Do not expose it to the public internet without adding real auth and rate limiting.

## Checks

```sh
make test              # Go tests, Python tests, web tests/typecheck, schema validation
make test-demo         # End-to-end moderation smoke test
make validate-schemas  # JSON Schema, examples, and OpenAPI
make check             # tests, formatting, lint, and local Markdown links
```

## Organization automation

```sh
DRY_RUN=1 make harden-org  # preview base permissions, 2FA, scanning, DCO, secure new-repo defaults
make harden-org        # apply those settings
make sync-remotes      # dry-run commit/push plan for every repo
./scripts/protect-branches.sh
ENFORCE_ADMINS=true ./scripts/protect-branches.sh  # once at least two maintainers are active
./scripts/publish-org.sh --dry-run
```

Org hardening requires an owner token with `admin:org` and repository administration permission. The full remote rollout order is in [docs/remote-rollout.md](docs/remote-rollout.md).

## RFC and alpha backlog

```sh
make rfc-discussion   # open RFC-0001 in keel-spec Discussions
make seed-alpha       # create alpha-0.1 milestones, labels, and issues
```

Both commands are idempotent: existing discussions, milestones, labels, and issues are skipped. Both support `--dry-run`.

## Public/private boundary

Public by default: protocol, code, developer docs, community health.

Private: the Constitution, the whitepaper, board minutes, finance, legal, production infrastructure, and security operations. Public code repos must not contain private governance text or secrets.

The public Creator Covenant summary and appeal guide live in `keel-docs`. The licensing terms are public in each repo's `LICENSE` file; licensing is never private.

## Licensing

- Code repos: [AGPL-3.0](LICENSE).
- Spec, RFCs, and public docs: [CC-BY-4.0](https://github.com/keel-foundation/keel-spec/blob/main/LICENSE).
- SDKs and client libraries: Apache-2.0 when introduced.
- Creator content remains the creator's property.

## Current limitations

- The classifier in the demo is synthetic. Real signal ingestion and model adapters are backlog work.
- The ledger is append-only JSONL with a verifiable hash chain. It does not yet have an external anchor or a database-backed ledger.
- Federation, payouts, content protection, upload, and transcoding are specified or scaffolded, not implemented.
- The governance structure is an interim draft. The public summary is in `keel-docs/governance`.

See `keel-spec` for the protocol direction and `keel-docs` for creator and developer guidance.
