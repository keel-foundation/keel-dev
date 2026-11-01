# Contributing to TubeKeel

TubeKeel is a multi-repository project. **Do not clone or bootstrap the whole ecosystem.** Choose the repository that owns the change, clone only that repository, and run only what you need.

## Before you start

1. Read the repository's `README.md` and `CONTRIBUTING` files.
2. Read the relevant guide in [docs/contribute](docs/contribute/README.md).
3. For protocol or policy changes, read RFC-0001 in `keel-spec`.
4. For a large change, open a discussion or RFC before writing code.

## Workflow

1. Find an issue or open a discussion.
2. Fork the repository, or create a branch if you have write access.
3. Keep the change focused. One logical change per pull request.
4. Run the repository's tests and the checks for the module you changed.
5. Add or update tests and documentation when behavior changes.
6. Sign off every commit with the Developer Certificate of Origin:

```sh
git commit -s -m "feat: add video manifest endpoint"
```

Do not add a CLA. Do not commit secrets, credentials, private governance text, or customer data.

## Which repository?

| Change | Repository |
|---|---|
| API, identity, channels, videos, subscriptions | `keel-core` |
| Ingest, transcode, package, thumbnails | [`keel-pipeline`](docs/contribute/keel-pipeline.md) |
| Signals, cases, policy engine, appeals, ledger | `keel-moderation` |
| Viewer, creator studio, moderation console | `keel-web` |
| Protocol, schemas, OpenAPI, RFCs | `keel-spec` |
| Public documentation | [`keel-docs`](docs/contribute/keel-docs.md) |
| The public demo and contribution hub | `keel-dev` |

See [repositories](docs/contribute/repositories.md) for links.

## Local scope

- Working on core? Run `keel-core` only. Point the demo at it with `TUBEKEEL_API_BASE_URL`.
- Working on moderation or policy? Run `keel-moderation` only. Point the demo at it with `TUBEKEEL_MODERATION_BASE_URL`.
- Working on web? Run `keel-web` only.
- Working on schemas? Run the `keel-spec` validator only.
- The full pipeline, federation, payouts, and production infrastructure are maintainer-only and are documented in the private `keel-infra` repository.

## Pull requests

- Protected branches require review; core, spec, and moderation require two approvals.
- CODEOWNERS review is required for protected paths.
- Required CI checks must pass.
- Main is linear; rebase rather than merge.
- Sign off every commit.
- Include tests and documentation.
- Never include secrets, private governance text, or customer data.

See [PR guidelines](docs/contribute/pr-guidelines.md).

## Security and conduct

Do not open a public issue for a vulnerability. Use the affected repository's **Security** tab. Follow the organization Code of Conduct.
