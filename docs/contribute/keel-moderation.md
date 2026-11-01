# Contributing to `keel-moderation`

Repository: [keel-foundation/keel-moderation](https://github.com/keel-foundation/keel-moderation)

This repository owns signals, cases, policy evaluation, human review, appeals, the audit ledger, and content-protection signals.

## Run only this module

```sh
git clone https://github.com/keel-foundation/keel-moderation.git
cd keel-moderation

python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.lock
.venv/bin/pip install -e . --no-deps
.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8082
.venv/bin/pytest -q
.venv/bin/ruff check app tests
```

You do not need core, the pipeline, the web app, PostgreSQL, NATS, or object storage for the current demo.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `TUBEKEEL_LEDGER_PATH` | `data/ledger.jsonl` | Append-only ledger file |
| `TUBEKEEL_STATE_DB` | `data/state.sqlite3` | SQLite workflow state |
| `TUBEKEEL_CORS_ORIGINS` | `http://localhost:3000` | Comma-separated web origins |
| `TUBEKEEL_RATE_LIMIT` | `30` | Mutating requests per IP per minute |
| `TUBEKEEL_DEMO_TOKEN` | unset | Legacy single-token demo mode |
| `TUBEKEEL_CREATOR_TOKEN` | unset | Creator role token for role-enforced mode |
| `TUBEKEEL_MODERATOR_TOKEN` | unset | Moderator role token for role-enforced mode |
| `TUBEKEEL_APPEALS_TOKEN` | unset | Appeals reviewer token for role-enforced mode |

The service supports open local mode, a legacy single-token demo mode, and role-enforced mode
where the creator, moderator, and appeals tokens are distinct. Reviewer independence is enforced
by the service: an appellant cannot decide their own appeal, and the original decision-maker
cannot decide the appeal.

Cases, actions, and appeals are stored in SQLite and survive a restart. The audit ledger remains
append-only JSONL.

## Connect the demo to local moderation

```sh
TUBEKEEL_MODE=remote \
TUBEKEEL_API_BASE_URL=https://stage-api.example.org \
TUBEKEEL_MODERATION_BASE_URL=http://127.0.0.1:8082 \
make demo
```

Use stage core for the video metadata. If you are also changing core, point `TUBEKEEL_API_BASE_URL` at your local core instead.

## Policy work

Policy is not scattered conditionals. It lives in versioned policy bundles under `app/policies/`, with the format documented in `keel-spec/protocol/policy-language.md`.

See [the policy guide](policy.md) before changing reason codes, review gates, penalties, appeal windows, or content-protection rules.

## Ledger work

The ledger is append-only and hash-chained. Any change to the record shape must include:

- the `audit-record` schema update in `keel-spec`;
- migration or compatibility notes;
- verification and tamper tests;
- export behavior;
- a note on whether an external anchor is affected.

Never truncate the ledger to reset a demo. Append a reset record or use a new ledger path.

## PR checklist

- `pytest` and `ruff` pass.
- The action, appeal, case, and ledger tests cover the change.
- Policy changes include tests and a `policy_version`.
- Schema changes are coordinated with `keel-spec`.
- No secrets or production evidence are committed.
- Commits are signed off with `git commit -s`.

See [PR guidelines](pr-guidelines.md).
