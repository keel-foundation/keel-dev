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

## First-time setup

Prerequisites: Docker, Go 1.23+, Node.js 22+, Python 3.9+.

```sh
# 1. Clone this repo, then bootstrap the sibling repos into this workspace
./scripts/bootstrap-dev.sh

# 2. Start PostgreSQL, MinIO, and NATS
make infra-up

# 3. Install web and moderation dependencies
(cd keel-web && npm install)
(cd keel-moderation && python3 -m venv .venv && . .venv/bin/activate && pip install -e .)

# 4. Run services in separate terminals
make core-dev
make pipeline-dev
make moderation-dev
make web-dev
```

The bootstrap script clones the other repos next to this one inside the workspace. They are ignored by this repo's `.gitignore`; each has its own git history and GitHub remote.

## Creating the GitHub org repos

Remote creation requires an authenticated GitHub CLI with org admin rights:

```sh
brew install gh
gh auth login
./scripts/publish-org.sh
```

`publish-org.sh` creates the repos with the correct visibility, initializes remotes, pushes the scaffold, creates the teams, grants repo-scoped access, and applies branch protection. It is idempotent: existing repos and teams are skipped, and repo topics/descriptions are refreshed.

## Public/private boundary

Public by default: protocol, code, developer docs, community health.

Private: the Constitution, the whitepaper, board minutes, finance, legal, production infrastructure, and security operations. Public code repos must not contain private governance text or secrets.

## Licensing

- Code repos: AGPL-3.0.
- Spec, RFCs, and public docs: CC-BY-4.0.
- SDKs and client libraries: Apache-2.0.
- Creator content remains the creator's property.

See the private governance repo for the Constitution, Article X.
