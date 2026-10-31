# Access policy

## Principles

1. **Least privilege.** Access is granted to a repository, not to the organization.
2. **Repo-scoped teams.** Every write permission comes through a `*-maintainers`, `*-contributors`, or `*-triagers` team.
3. **No org-wide write.** Organization membership grants no repository permission by default. Public repos are readable by everyone; private repos require a team.
4. **Two-person review.** Protected branches require a pull request and at least one approval; core, spec, moderation, governance, infra, and security require two.
5. **No secrets in git.** Production credentials live in the deployment platform or a secrets manager, never in a repository.
6. **Public by default for code and spec, private by default for governance, infrastructure, and security.**

## Onboarding a contributor

1. Accept the contribution in the relevant repo (issue, PR, or discussion).
2. Add the person to the matching `*-contributors` team, not to `owners` or `steering`.
3. For trusted reviewers, add to `*-maintainers` after two substantive contributions and a maintainer nomination.
4. For issue triage only, grant the `triage` role on the matching `*-contributors` team.
5. Record the access grant in the private governance repo's access log.

A contributor to `keel-web` must not receive access to `keel-core`, `keel-moderation`, `keel-governance`, `keel-infra`, or `keel-security`.

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

Main must be protected on every repo. Direct pushes to main are disabled for everyone except a break-glass owner action, which must be logged.

Branch protection on private repositories requires a GitHub plan that supports it. If the API rejects protection for a private repo, enable the equivalent rules manually in repository settings and record the exception.

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
