#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

for tool in curl jq python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "$tool is required for the demo smoke test" >&2
    exit 1
  fi
done

if [[ ! -x keel-moderation/.venv/bin/uvicorn ]]; then
  echo "Create keel-moderation/.venv first: (cd keel-moderation && python3 -m venv .venv && .venv/bin/pip install -e '.[dev]')" >&2
  exit 1
fi

TMP="$(mktemp -d)"
PORT="$(python3 - <<'PY'
import socket
sock = socket.socket()
sock.bind(("127.0.0.1", 0))
print(sock.getsockname()[1])
sock.close()
PY
)"
SERVER_PID=""
cleanup() {
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT INT TERM

(
  cd keel-moderation
  TUBEKEEL_LEDGER_PATH="$TMP/ledger.jsonl" \
  TUBEKEEL_RATE_LIMIT=0 \
  TUBEKEEL_DEMO_TOKEN= \
  TUBEKEEL_CORS_ORIGINS=http://localhost:3000 \
  .venv/bin/uvicorn app.main:app --host 127.0.0.1 --port "$PORT"
) >"$TMP/server.log" 2>&1 &
SERVER_PID=$!

for _ in $(seq 1 80); do
  if curl -sf "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

if ! curl -sf "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
  cat "$TMP/server.log" >&2
  exit 1
fi

BASE="http://127.0.0.1:$PORT"

ACTION="$(curl -sS -X POST "$BASE/v1/actions" \
  -H 'Content-Type: application/json' \
  -d '{"video_id":"vid_demo_001","policy_clause":"spam.mass_production","reason":"Automated classifier false positive.","evidence":["model: spam-v0.1","confidence: 0.91"]}')"
ACTION_ID="$(jq -r '.id' <<<"$ACTION")"
jq -e '.status == "active" and .statement_of_reasons.policy_version == "demo-0.1"' <<<"$ACTION" >/dev/null

APPEAL="$(curl -sS -X POST "$BASE/v1/actions/$ACTION_ID/appeal" \
  -H 'Content-Type: application/json' \
  -d '{"grounds":"policy_misapplication","statement":"Original documentary. All footage is owned and edited by the creator."}')"
APPEAL_ID="$(jq -r '.id' <<<"$APPEAL")"
jq -e '.status == "pending" and .reviewer == null' <<<"$APPEAL" >/dev/null

DECIDED="$(curl -sS -X POST "$BASE/v1/appeals/$APPEAL_ID/decide" \
  -H 'Content-Type: application/json' \
  -d '{"decision":"reverse","reasoning":"Human review confirmed original production."}')"
jq -e '.action.status == "reversed" and .appeal.reviewer == "demo-appeals-reviewer"' <<<"$DECIDED" >/dev/null

VERIFY="$(curl -sf "$BASE/v1/ledger/verify")"
jq -e '.valid == true and .records >= 5' <<<"$VERIFY" >/dev/null
COUNT="$(jq -r '.records' <<<"$VERIFY")"

EXPORTED="$(curl -sf "$BASE/v1/ledger/export?format=jsonl")"
LINES="$(jq -s 'length' <<<"$EXPORTED")"
if [[ "$LINES" != "$COUNT" ]]; then
  echo "exported $LINES lines but verification reported $COUNT records" >&2
  exit 1
fi

RESET="$(curl -sS -X POST "$BASE/v1/demo/reset")"
jq -e '.action == null and .appeal == null and .verification.valid == true' <<<"$RESET" >/dev/null
jq -e --argjson before "$COUNT" '.verification.records == ($before + 1)' <<<"$RESET" >/dev/null

echo "demo smoke test ok ($COUNT records before reset)"
