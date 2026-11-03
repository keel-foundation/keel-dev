# Get started

You do not need to clone the ecosystem.

## 1. Pick a repository

Use the [repository map](repositories.md). Choose the repository that owns the behavior you want to change.

## 2. Clone only that repository

```sh
git clone https://github.com/keel-foundation/keel-core.git
cd keel-core
```

Replace `keel-core` with the repository you chose.

## 3. Install and test

Use the repository's own README. The common commands are:

```sh
# Go
# keel-core database tests need PostgreSQL and serialized packages:
KEELTUBE_TEST_DATABASE_URL='postgres://...' go test -p 1 ./...
go vet ./...

# Python
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.lock
.venv/bin/pip install -e . --no-deps
.venv/bin/pytest -q
.venv/bin/ruff check .

# Node (keel-web is private; maintainers only)
npm ci
npm run lint
npm test
npm run typecheck
npm run build
npm run format:check
npm run test:e2e       # starts the Vite dev server; no backend required
```

## 4. Make a focused branch

```sh
git checkout -b fix/appeal-deadline
```

## 5. Sign off and commit

```sh
git commit -s -m "fix: enforce the appeal deadline"
```

## 6. Open a pull request

Link the issue or discussion, describe what changed, how you tested it, and any follow-up work. Follow the [PR guidelines](pr-guidelines.md).

## Using the demo while you work

The public demo in this repository is mocked. If your module exposes HTTP endpoints, point the demo at your local service:

```sh
KEELTUBE_MODE=remote \
KEELTUBE_API_BASE_URL=http://127.0.0.1:8080 \
KEELTUBE_MODERATION_BASE_URL=https://stage-moderation.example.org \
make demo
```

Use stage endpoints for services you are not changing. The full local stack is maintainer-only.
