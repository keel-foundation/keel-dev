# Public demo

The public KeelTube creator-appeal demo. This is the canonical, standalone entry point for
anyone who wants to see the appeal flow without running the real ecosystem.

## Run

Requires Python 3.9+.

```sh
make demo
```

Open `http://localhost:3000`. Use `make demo-open` to open the browser automatically.

The demo uses the approved KeelTube branding: Manrope, Inter, IBM Plex Mono, the primary purple
palette, and a dark/light theme toggle. The theme is stored in `localStorage`.

## Mock mode

The default mode is mocked. State lives in the browser tab. No service, database, or token is required.

The demo simulates:

- a synthetic automated signal;
- a case and Statement of Reasons;
- an enforcement action with a deadline;
- an appeal filed by the creator;
- an independent appeals reviewer;
- reversal and ledger records;
- SHA-256 chained ledger verification and JSONL export.

Resetting the demo appends a reset record and clears the action state. It does not truncate the ledger.

## Stage mode

See [docs/staging.md](../docs/staging.md). The local server proxies stage requests and keeps the token server-side.

## Files

| File | Purpose |
|---|---|
| `index.html` | Layout |
| `styles.css` | Styles |
| `app.js` | Mock adapter, stage adapter, ledger, and UI |
| `config.js` | Static mock-mode configuration |
| `sample.mp4` | Eight-second demo clip |
| `sample.vtt` | Captions |
| `brand/` | Approved KeelTube logo, icon, and favicon assets |

## What is not here

This is not the full `keel-web` app. It does not include the creator studio, watch page, moderation console, upload, HLS playback, or production auth. Those live in `keel-web` and are contributed to separately.
