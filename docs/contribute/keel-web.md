# Contributing to `keel-web`

Repository: [keel-foundation/keel-web](https://github.com/keel-foundation/keel-web)

This repository is the full web client: home, Explore, watch page, channels, search, library, creator
studio, Cases & appeals, and the published-video editor. The UI is implemented against a local data adapter; the
core and moderation API adapters are the next integration step.

**Creator and staff moderation are separate.** Creators inspect cases about their own videos, read
the evidence and Statement of Reasons, file appeals, and export their audit records under
`/studio/moderation`. Cases & appeals is a separate workspace area from Creator Studio. The Keel team and moderators review cases and perform enforcement actions in
a separate staff portal with its own privileged session. That portal is not part of the
creator-facing application and will be implemented later in `keel-web` or in a separate
repository.

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

The public site, creator studio, and creator moderation record use the local data adapter and need
no backend. API mode is reserved for when the core read APIs are connected.

End-to-end tests start the Vite dev server and need no backend stack:

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

Use stage URLs when you are not changing the backend. The current build reads through the local data
adapter.

Do not put a moderation token in a `VITE_*` variable; public variables are shipped to the browser.
The staff moderation portal must use a server-side session.

## PR checklist

- `npm run lint`, `npm test`, `npm run typecheck`, `npm run build`, and `npm run format:check` pass.
- Route and player changes have a Playwright test (`npm run test:e2e`) where practical.
- Accessibility is checked: keyboard access, labels, focus, captions, and errors announced to
  assistive technology.
- The creator app does not include a role switcher, moderator queue, enforcement decision form, or
  appeal decision form. Staff moderation stays in the separate portal.
- Creator case, appeal, and ledger views are scoped to the owning creator.
- The trust record keeps the policy version, content hash, reviewer, deadline, and audit hash.
- No secrets, customer data, or private governance text are committed.
- Commits are signed off with `git commit -s`.

See [PR guidelines](pr-guidelines.md).
