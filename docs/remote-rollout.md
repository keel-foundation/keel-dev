# Remote rollout plan

The public organization already contains the earlier scaffold. These local changes are not reflected remotely until they are committed and pushed deliberately. Do not run the destructive or org-wide steps until the local diff has been reviewed.

## Current remote state (pre-change)

As of 31 October 2026:

- all 11 repositories exist; the three private repos are private;
- `default_repository_permission` is `read`;
- members may create repositories;
- 2FA is not required;
- secret scanning, push protection, and Dependabot are disabled on public repos;
- public branch protection exists with the configured approval counts, but required status checks are not set and admins can bypass;
- private branch protection is unavailable on GitHub Free;
- team repository roles are correct;
- RFC discussion #1 exists;
- the old `good-first-issue` and org-discussions links are broken until the pushed docs land.

These are the rollback values to restore if a change is reversed.

## Preconditions

- Every local check passes: `make check`, `make test-demo`, `make validate-schemas`.
- The owner has reviewed `git status` and `git diff` in every repo.
- The owner has an owner token with `admin:org` for hardening: `gh auth refresh -s admin:org`.
- The owner account has two-factor authentication enabled.
- No production credentials or private governance text have been added to a public repo.

## 1. Commit and push order

The `.github` repo must go first because `keel-spec`, `keel-docs`, `keel-core`, `keel-pipeline`, `keel-moderation`, `keel-web`, `keel-governance`, `keel-infra`, `keel-security`, and `keel-dev` reference its reusable `docs-ci.yml` workflow at `main`.

```sh
./scripts/sync-remotes.sh              # dry run; inspect every repo
./scripts/sync-remotes.sh --apply      # commit -s and push main, no force push
```

The script pushes in this order:

1. `dot-github` → `keel-foundation/.github`
2. `keel-spec`
3. `keel-core`
4. `keel-pipeline`
5. `keel-moderation`
6. `keel-web`
7. `keel-docs`
8. `keel-governance` (private)
9. `keel-infra` (private)
10. `keel-security` (private)
11. `keel-dev` workspace

If the remote has commits the local branch does not have, stop and rebase manually. The script never force-pushes.

## 2. Let CI publish the check contexts

After the push:

1. Open each repo's Actions tab and confirm the new workflows run.
2. Confirm the check names:
   - `keel-dev`: `compose / validate`
   - `keel-core`, `keel-pipeline`: `test / test`
   - `keel-web`: `typecheck / typecheck`
   - `keel-moderation`: `compile / compile`
   - `keel-spec`: `schemas` and `docs / links`
   - `keel-docs`, `.github`: `docs / links`
3. Only after the checks exist on `main`, add them as required checks:

```sh
REQUIRE_CHECKS=1 ./scripts/protect-branches.sh
```

Private-repo branch protection is still unavailable on GitHub Free. Upgrade to GitHub Team or enforce the private-repo rules manually until then.

Do not set `ENFORCE_ADMINS=true` until at least two maintainers are active; with one maintainer and two required approvals, normal merges are impossible.

## 3. Apply organization hardening

Preview first:

```sh
DRY_RUN=1 make harden-org
```

Apply:

```sh
make harden-org
```

This sets:

- base repository permission to `none`;
- member repository creation off;
- 2FA required;
- DCO sign-off required on the web;
- secure defaults for new repositories;
- secret scanning, push protection, Dependabot, and private vulnerability reporting on public repos where available.

If a setting is unavailable on GitHub Free, the script prints a warning and continues.

## 4. Seed labels and links

The issue templates use `bug`, `enhancement`, and `triage`. `bug` and `enhancement` are GitHub defaults; `triage` is created by the seed script.

```sh
python3 scripts/seed-alpha.py
```

This is idempotent and skips existing issues and milestones. It adds the `triage` label to every active repo.

## 5. Close or update stale issues

- `keel-dev#2` (“One-command demo”) is implemented, including the fallback and cleanup behavior. Close it after the push.
- `keel-dev#1` (“Seed data and demo reset”) is partially implemented: reset exists and appends a ledger record, but deterministic seeding is still open. Update the acceptance criteria rather than closing it.
- `keel-moderation#2` (“Hash-chained audit ledger with export”) is implemented in the demo (append-only JSONL, verification, JSONL/CSV export). Update it to reflect that PostgreSQL and an external anchor remain open.

## 6. Update the live RFC discussion

Post a comment on RFC discussion #1 that links the new schemas, examples, and OpenAPI, and notes that the current demo implements six schemas and a verified ledger. Do not rewrite the original discussion body; keep the history.

## 7. Verify public links

```sh
curl -s -o /dev/null -w '%{http_code}\n' \
  'https://github.com/search?q=org%3Akeel-foundation+label%3Agood-first-issue+state%3Aopen&type=issues'
curl -s -o /dev/null -w '%{http_code}\n' \
  'https://github.com/keel-foundation/keel-spec/discussions'
curl -s -o /dev/null -w '%{http_code}\n' \
  'https://github.com/keel-foundation/keel-dev/security/policy'
```

All should return `200`.

## 8. Post-push checks

```sh
make check
make test-demo
make validate-schemas
```

Then open the demo and verify:

- the action has a case, signal, Statement of Reasons, and deadline;
- the appeal reviewer differs from the original reviewer;
- the ledger shows previous hashes and record hashes;
- **Verify ledger** reports a valid chain;
- **Export JSONL** downloads a file whose record count matches the verification count.

## Rollback

- If a push is wrong, revert the merge commit or push a corrective commit. Do not force-push `main`.
- If an org setting is wrong, rerun the relevant `gh api --method PATCH` with the previous value. Record the change in the private governance access log.
- If a branch protection change blocks work, an owner can temporarily disable admin enforcement only as a logged break-glass action.
