# Contributing to `keel-web`

Repository: [keel-foundation/keel-web](https://github.com/keel-foundation/keel-web)

This repository is the full web client: public feed, watch page, channels, creator studio, and moderation console.

## Run only this module

```sh
git clone https://github.com/keel-foundation/keel-web.git
cd keel-web

npm ci
npm test
npm run typecheck
npm run build
npm run dev -- -H 127.0.0.1
```

The public feed, watch page, and channel page use local preview data and need no backend. Set
`NEXT_PUBLIC_DATA_SOURCE=api` when connecting the backend. Maintainers can start the backend
stack with:

```sh
docker compose -f keel-infra/devstack/apps.compose.yml up -d --build
```

End-to-end watch tests:

```sh
npx playwright install chromium
npm run test:e2e
```

## Configuration

| Variable | Purpose |
|---|---|
| `NEXT_PUBLIC_DATA_SOURCE` | `mock` (preview data) or `api` |
| `NEXT_PUBLIC_CORE_URL` | Core API base URL in API mode |
| `NEXT_PUBLIC_MODERATION_URL` | Moderation API base URL in API mode |

Use stage URLs when you are not changing the backend:

```sh
NEXT_PUBLIC_CORE_URL=https://stage-api.example.org \
NEXT_PUBLIC_MODERATION_URL=https://stage-moderation.example.org \
npm run dev -- -H 127.0.0.1
```

Do not put a moderation token in a `NEXT_PUBLIC_*` variable; public variables are shipped to the
browser. The moderation console must use a server-side session.

## PR checklist

- `npm test`, `npm run typecheck`, `npm run build`, and `npm run format:check` pass.
- Route and player changes have a Playwright test (`npm run test:e2e`) where practical.
- New behavior has tests where practical.
- Accessibility is checked: keyboard access, labels, focus, captions, and errors announced to assistive technology.
- The UI does not invent moderation decisions or bypass human-review gates.
- No secrets, customer data, or private governance text are committed.
- Commits are signed off with `git commit -s`.

See [PR guidelines](pr-guidelines.md).
