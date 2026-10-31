# Repository map

Organization: `keel-foundation`

## Visibility and ownership

| Repo | Visibility | Purpose | License | Maintainer team | Contributor team |
|---|---|---|---|---|---|
| `keel-spec` | Public | Protocol, RFCs, schemas, policy language | CC-BY-4.0 | `spec-maintainers` | `spec-contributors` |
| `keel-core` | Public | API, identity, channels, videos, subscriptions | AGPL-3.0 | `core-maintainers` | `core-contributors` |
| `keel-pipeline` | Public | Ingest, transcode, package, thumbnails | AGPL-3.0 | `pipeline-maintainers` | `pipeline-contributors` |
| `keel-web` | Public | Viewer, creator studio, moderation console | AGPL-3.0 | `web-maintainers` | `web-contributors` |
| `keel-moderation` | Public | Signals, cases, appeals, audit ledger, content protection | AGPL-3.0 | `moderation-maintainers` | `moderation-contributors` |
| `keel-dev` | Public | Workspace, local stack, onboarding, org automation | AGPL-3.0 | `dev-maintainers` | `dev-contributors` |
| `keel-docs` | Public | Public creator and developer documentation | CC-BY-4.0 | `docs-maintainers` | `docs-contributors` |
| `.github` | Public | Org profile, community health, reusable CI | CC-BY-4.0 | `dev-maintainers` | `dev-contributors` |
| `keel-governance` | Private | Constitution, whitepaper, board, finance, legal | Private until publication | `governance-maintainers` | `governance-contributors` |
| `keel-infra` | Private | Production infrastructure, environments, runbooks | Private | `infra-maintainers` | `infra-contributors` |
| `keel-security` | Private | Threat model, incidents, audits, disclosure | Private | `security-maintainers` | `security-contributors` |

## Team roles

| Team | Org role | Repository access |
|---|---|---|
| `owners` | Org owner | Admin on every repo |
| `steering` | Member | Read on all private repos; no default write |
| `*-maintainers` | Member | `maintain` on the matching repo |
| `*-contributors` | Member | `write` on the matching repo (branch protection still requires PRs) |
| `security-reporters` | Member | `triage` on `keel-security` only |

Do not use org-wide write. Do not add a contributor to a team they do not need. The repo-scoped team is the access boundary.

## Repos that must never be public

- `keel-governance` — contains the Constitution and whitepaper, which are not public.
- `keel-infra` — production configuration and runbooks.
- `keel-security` — vulnerability reports, threat model, and incident records.

If any of these is accidentally made public, treat it as a security incident and rotate any exposed credentials immediately.
