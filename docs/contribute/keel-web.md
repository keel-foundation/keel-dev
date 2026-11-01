# Contributing to `keel-web`

Repository: [keel-foundation/keel-web](https://github.com/keel-foundation/keel-web)

This repository is the full web client: public feed, watch page, channels, search, library, creator
studio, and moderation console. The UI is fully built against local preview data; the core and
moderation services are not wired yet.

## Run only this module

```sh
git clone https://github.com/keel-foundation/keel-web.git
cd keel-web

npm ci
npm run lint
npm test
npm run typecheck
npm run build
npm run format:check
npm run dev
```

The public feed, watch page, channel page, search, library, studio, and moderation console use
local preview data and need no backend. API mode is reserved for when the core read APIs are
connected.

End-to-end tests start the Vite dev server and use preview data; no backend stack is required:

```sh
npx playwright install chromium
npm run test:e2e
```

Maintainers can start the backend stack with:

```sh
docker compose -f keel-infra/devstack/apps.compose.yml up -d --build
```

## Configuration

| Variable | Status |
|---|---|
| `VITE_DATA_SOURCE` | Reserved for the API phase; not read by this build |
| `VITE_CORE_URL` | Reserved for the API phase; not read by this build |
| `VITE_MODERATION_URL` | Reserved for the API phase; not read by this build |

Use stage URLs when you are not changing the backend. The current build still reads local preview
data.

Do not put a moderation token in a `VITE_*` variable; public variables are shipped to the browser.
The moderation console must use a server-side session.

## PR checklist

- `npm run lint`, `npm test`, `npm run typecheck`, `npm run build`, and `npm run format:check` pass.
- Route and player changes have a Playwright test (`npm run test:e2e`) where practical.
- New behavior has tests where practical.
- Accessibility is checked: keyboard access, labels, focus, captions, and errors announced to assistive technology.
- The UI does not invent moderation decisions or bypass human-review gates.
- The trust record keeps the policy version, content hash, reviewer, deadline, and audit hash.
- No secrets, customer data, or private governance text are committed.
- Commits are signed off with `git commit -s`.

See [PR guidelines](pr-guidelines.md).
