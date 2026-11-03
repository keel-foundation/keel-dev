# Pull request guidelines

## Scope

- One logical change per pull request.
- Link the issue, discussion, or RFC.
- For cross-repository changes, open linked PRs and name the dependencies in each description.
- Do not combine refactoring, behavior changes, and dependency upgrades unless they are inseparable.

## Tests and checks

Run the checks for the repository you changed:

| Repository | Required checks |
|---|---|
| `keel-core` | `KEELTUBE_TEST_DATABASE_URL=... go test -p 1 ./...`, `go vet ./...`, `gofmt -l .` |
| `keel-moderation` | `pytest`, `ruff check app tests` |
| `keel-web` (private) | `npm test`, `npm run typecheck`, `npm run build`, `npm run format:check`; `npm run test:e2e` for watch/player changes |
| `keel-spec` | `python scripts/validate_schemas.py`, docs link check |
| `keel-dev` | `make test` |
| `keel-docs` | docs link check |

Add tests for new behavior. If a change cannot be tested, explain why in the PR.

## DCO

Sign off every commit:

```sh
git commit -s
```

The sign-off certifies that you have the right to submit the contribution under the repository's license.

## Review

- Protected branches require approval.
- `keel-core`, `keel-spec`, and `keel-moderation` require two approvals.
- CODEOWNERS review is required for protected paths.
- Required CI checks must pass.
- Main is linear; rebase rather than merge.
- Do not force-push main.

## Security and privacy

- Never commit secrets, tokens, private keys, customer data, or private governance text.
- Do not test against production without written permission.
- Do not include real creator evidence in public issues or PRs.
- Use stage endpoints and synthetic data for demos.

## Documentation

Update the README, schema, OpenAPI document, or guide affected by the change. Add a decision-log entry for substantive protocol or policy changes.

## Merging

A maintainer may close a PR that is out of scope, unsafe, unmaintainable, or inconsistent with the Creator Covenant. A rejected change can be reopened with a new approach.
