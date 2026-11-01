# `keel-web` (private)

Repository: [keel-foundation/keel-web](https://github.com/keel-foundation/keel-web)

**Status: private, maintainers only.** Access is limited to the maintainer group while the
maintainer pool is established. Do not clone, fork, mirror, redistribute, or publish this
repository or its contents without maintainer approval.

The repository contains the KeelTube web client: the public video site, Creator Studio, Cases &
appeals, the global upload modal, and the versioned video editor. The source of truth for setup,
architecture, commands, and checks is the repository's own `README.md` and `AGENTS.md`.

## Maintainer checks

If you have access, run the checks in the repository:

```sh
npm ci
npm run lint
npm test
npm run typecheck
npm run build
npm run format:check
npm run test:e2e
```

Public contributors should use the public demo in `keel-dev` and the public modules. They do not
need access to `keel-web`.
