#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -d keel-web || ! -d keel-moderation ]]; then
  echo "Sibling repos are missing. Run ./scripts/bootstrap-dev.sh first." >&2
  exit 1
fi

mkdir -p .demo
PIDS=()
cleanup() {
  for pid in "${PIDS[@]:-}"; do
    pkill -P "$pid" 2>/dev/null || true
    kill "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT INT TERM

port_in_use() {
  nc -z 127.0.0.1 "$1" >/dev/null 2>&1
}

USED_PORTS=()
pick_port() {
  local port="$1"
  while port_in_use "$port" || [[ " ${USED_PORTS[*]:-} " == *" $port "* ]]; do
    port=$((port + 1))
  done
  USED_PORTS+=("$port")
  printf '%s' "$port"
}

CORE_PORT="$(pick_port 8080)"
PIPELINE_PORT="$(pick_port 8081)"
MODERATION_PORT="$(pick_port 8082)"
WEB_PORT="$(pick_port 3000)"
export CORE_PORT PIPELINE_PORT MODERATION_PORT WEB_PORT

export TUBEKEEL_CORE_ADDR=":$CORE_PORT"
export TUBEKEEL_PIPELINE_ADDR=":$PIPELINE_PORT"
export TUBEKEEL_PIPELINE_PUBLIC_URL="http://localhost:$PIPELINE_PORT"
export NEXT_PUBLIC_CORE_URL="http://localhost:$CORE_PORT"
export NEXT_PUBLIC_MODERATION_URL="http://localhost:$MODERATION_PORT"

if [[ ! -x keel-moderation/.venv/bin/uvicorn ]]; then
  echo "→ creating moderation venv"
  python3 -m venv keel-moderation/.venv
  keel-moderation/.venv/bin/pip install --quiet --upgrade pip
  keel-moderation/.venv/bin/pip install --quiet -e keel-moderation
fi

if [[ ! -d keel-web/node_modules ]]; then
  echo "→ installing web dependencies"
  (cd keel-web && npm install --no-audit --no-fund)
fi

if command -v go >/dev/null 2>&1; then
  echo "→ starting core and pipeline"
  (cd keel-core && go run ./cmd/api) > .demo/core.log 2>&1 &
  PIDS+=($!)
  (cd keel-pipeline && go run ./cmd/worker) > .demo/pipeline.log 2>&1 &
  PIDS+=($!)
else
  echo "⚠ Go not found: core and pipeline are skipped; the UI uses the bundled sample clip."
fi

echo "→ starting moderation"
(cd keel-moderation && .venv/bin/uvicorn app.main:app --host 127.0.0.1 --port "$MODERATION_PORT") > .demo/moderation.log 2>&1 &
PIDS+=($!)

echo "→ starting web"
rm -rf keel-web/.next
(cd keel-web && PORT="$WEB_PORT" npm run dev) > .demo/web.log 2>&1 &
PIDS+=($!)

wait_for() {
  local name="$1" url="$2" tries=60
  for _ in $(seq 1 "$tries"); do
    if curl -sf "$url" >/dev/null 2>&1; then
      echo "  $name ready"
      return 0
    fi
    sleep 1
  done
  echo "  $name did not become ready; see .demo/${name}.log" >&2
  return 1
}

wait_for moderation "http://localhost:$MODERATION_PORT/health"
if command -v go >/dev/null 2>&1; then
  wait_for core "http://localhost:$CORE_PORT/health"
  wait_for pipeline "http://localhost:$PIPELINE_PORT/health"
fi
wait_for web "http://localhost:$WEB_PORT/demo"

echo ""
echo "Demo:  http://localhost:$WEB_PORT/demo"
echo "Logs:  .demo/*.log"
echo "Press Ctrl-C to stop."
if [[ "${1:-}" == "--open" ]] && command -v open >/dev/null 2>&1; then
  open "http://localhost:$WEB_PORT/demo"
fi

wait
