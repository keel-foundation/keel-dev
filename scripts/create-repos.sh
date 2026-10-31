#!/usr/bin/env bash
set -euo pipefail

ORG="${ORG:-keel-foundation}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required: brew install gh && gh auth login" >&2
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated: run gh auth login" >&2
  exit 1
fi

# name|visibility|description
REPOS=(
  "keel-spec|public|TubeKeel protocol, RFCs, schemas, and policy language"
  "keel-core|public|TubeKeel API, identity, channels, videos, and subscriptions"
  "keel-pipeline|public|TubeKeel ingest, transcode, packaging, and thumbnails"
  "keel-web|public|TubeKeel viewer, creator studio, and moderation console"
  "keel-moderation|public|TubeKeel signals, cases, appeals, audit ledger, and content protection"
  "keel-dev|public|TubeKeel workspace, local stack, and org automation"
  "keel-docs|public|TubeKeel public creator and developer documentation"
  ".github|public|TubeKeel organization profile, community health, and reusable CI"
  "keel-governance|private|TubeKeel Constitution, whitepaper, board, finance, and legal"
  "keel-infra|private|TubeKeel production infrastructure and runbooks"
  "keel-security|private|TubeKeel threat model, incidents, and security audits"
)

for entry in "${REPOS[@]}"; do
  IFS='|' read -r name visibility desc <<< "$entry"
  if gh repo view "$ORG/$name" >/dev/null 2>&1; then
    echo "→ exists: $ORG/$name"
  else
    echo "→ creating: $ORG/$name ($visibility)"
    gh repo create "$ORG/$name" "--$visibility" --description "$desc" --disable-wiki
  fi
  gh repo edit "$ORG/$name" \
    --add-topic tubekeel,peertube,creator-economy,video \
    --description "$desc" >/dev/null || true
done
