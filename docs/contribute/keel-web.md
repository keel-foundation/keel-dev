# Contributing to `keel-web`

Repository: [keel-foundation/keel-web](https://github.com/keel-foundation/keel-web)

This repository is the full web client: viewer, creator studio, and moderation console. The minimal public demo in `keel-dev` is separate and mocked.

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

## Configuration

| Variable | Purpose |
|---|---|
| `NEXT_PUBLIC_CORE_URL` | Core API base URL |
| `NEXT_PUBLIC_MODERATION_URL` | Moderation API base URL |
| `NEXT_PUBLIC_DEMO_TOKEN` | Optional local demo token; never a production secret |

Use stage URLs when you are not changing the backend:

```sh
NEXT_PUBLIC_CORE_URL=https://stage-api.example.org \
NEXT_PUBLIC_MODERATION_URL=https://stage-moderation.example.org \
npm run dev -- -H 127.0.0.1
```

Do not put a production token in a `NEXT_PUBLIC_*` variable. Public variables are shipped to the browser.

## PR checklist

- `npm test`, `npm run typecheck`, `npm run build`, and `npm run format:check` pass.
- New behavior has tests where practical.
- Accessibility is checked: keyboard access, labels, focus, captions, and errors announced to assistive technology.
- The UI does not invent moderation decisions or bypass human-review gates.
- No secrets, customer data, or private governance text are committed.
- Commits are signed off with `git commit -s`.

See [PR guidelines](pr-guidelines.md).
