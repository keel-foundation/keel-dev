# Access policy

## Principles

1. **Least privilege.** Access is granted to a repository, not to the organization.
2. **Repo-scoped teams.** Every write permission comes through a `*-maintainers`, `*-contributors`, or `*-triagers` team. Specialized teams such as `security-reporters` are scoped the same way.
3. **No org-wide access.** The organization base permission must be `none`. Organization membership must grant no repository permission by default. Public repos are readable by everyone; private repos require a team.
4. **Two-person review.** Protected branches require a pull request and at least one approval; core, spec, moderation, governance, infra, and security require two.
5. **No secrets in git.** Production credentials live in the deployment platform or a secrets manager, never in a repository.
6. **Public by default for code and spec, private by default for governance, infrastructure, and security.**

## Current organization settings

Run `make harden-org` and `./scripts/protect-branches.sh` to apply these settings. The hardening script requires an owner token with `admin:org`: `gh auth refresh -s admin:org`. Run `./scripts/publish-org.sh --dry-run` to preview the repository, team, and protection changes.

Required settings:

- base repository permission: `none`;
- members cannot create public, private, or internal repositories;
- two-factor authentication required for every member. If the API cannot set it, enable it manually in Organization Settings → Authentication security;
- DCO sign-off required on the web; contributors must sign off locally and reviewers verify it. CI enforcement is a follow-up.
- secret scanning, push protection, and Dependabot security updates enabled on public repos;
- private vulnerability reporting enabled where available;
- required CI checks (after the CI workflows are pushed) and last-push approval on protected branches;
- `enforce_admins` enabled once at least two maintainers are active.

The organization currently uses GitHub Free. Native branch protection for private repositories requires GitHub Team or Enterprise. Until the organization upgrades, private repos are protected by policy, CODEOWNERS, and manual review only.

## Onboarding a contributor

1. Accept the contribution in the relevant repo (issue, PR, or discussion).
2. Add the person to the matching `*-contributors` team, not to `owners` or `steering`.
3. For trusted reviewers, add to `*-maintainers` after two substantive contributions and a maintainer nomination.
4. For issue triage only, grant the `triage` role on the matching `*-contributors` team.
5. Record the access grant in the private governance repo's access log.

A contributor to `keel-web` must not receive write access to `keel-core`, `keel-moderation`, `keel-governance`, `keel-infra`, or `keel-security`. With the base permission set to `none`, team membership must not grant read access to private repos either.

## Offboarding

1. Remove the person from every `*-contributors`, `*-maintainers`, and `*-triagers` team.
2. Remove any direct collaborator grants.
3. Revoke personal access tokens and SSH keys if the person had them.
4. Record the removal in the access log.
5. Audit all team memberships quarterly.

## Branch protection

| Repo | Approvals | CODEOWNERS | Force push | Linear history |
|---|---|---|---|---|
| `keel-spec` | 2 | Yes | No | Yes |
| `keel-core` | 2 | Yes | No | Yes |
| `keel-pipeline` | 1 | Yes | No | Yes |
| `keel-web` | 1 | Yes | No | Yes |
| `keel-moderation` | 2 | Yes | No | Yes |
| `keel-dev` | 1 | Yes | No | Yes |
| `keel-docs` | 1 | Yes | No | Yes |
| `.github` | 1 | Yes | No | Yes |
| `keel-governance` | 2 | Yes | No | Yes |
| `keel-infra` | 2 | Yes | No | Yes |
| `keel-security` | 2 | Yes | No | Yes |

Main must be protected on every repo. Direct pushes to main are disabled for everyone except a break-glass owner action, which must be logged. Protected branches require the repository CI checks and approval of the last push.

Branch protection on private repositories requires a GitHub plan that supports it. GitHub Free does not support native branch protection on private repos; the protection script detects this and skips those repos rather than failing.

Until the organization is on GitHub Team or Enterprise, enforce the same rules manually for `keel-governance`, `keel-infra`, and `keel-security`. Record every break-glass push in the private governance access log:

1. Keep write access to maintainers only.
2. Require a pull request and two approvals in the repository's `CONTRIBUTING` guidance.
3. Use `CODEOWNERS` as the review contract.
4. Require environment approval for production deploys.
5. Log any direct push to `main` in the private governance access log.
6. Upgrade the plan when the project can afford it, then rerun `ENFORCE_ADMINS=true ./scripts/protect-branches.sh`.

## CODEOWNERS

Each repo has a `CODEOWNERS` file mapping paths to the matching maintainer team. A PR touching a protected path requires a code-owner review.

## Secrets and environments

- Use GitHub Environments for staging and production.
- Require reviewer approval for production deployments.
- Store secrets in the platform secret store, not in repository variables.
- Enable secret scanning and push protection on all public repos.
- Never put a private governance document, customer data, or production credential in a public repo.

## Repo creation

Only organization owners may create repos. New repos must:

1. be named `keel-*` unless they are the special `.github` repo;
2. default to private until an owner explicitly approves public visibility;
3. include a README, LICENSE, `.gitignore`, `CODEOWNERS`, and branch protection;
4. be added to `REPOS.md` and an access team.

## Quarterly review

The `owners` team audits:

- every team membership;
- every private repo collaborator;
- every deploy key and GitHub App installation;
- every public repo for accidental secrets or private documents.
