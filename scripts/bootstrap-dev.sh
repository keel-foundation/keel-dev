#!/usr/bin/env bash
set -euo pipefail

ORG="${ORG:-keel-foundation}"
PUBLIC_REPOS=(keel-spec keel-core keel-pipeline keel-web keel-moderation keel-docs)
PRIVATE_REPOS=(keel-governance keel-infra keel-security)

clone_all=false
if [[ "${1:-}" == "--all" ]]; then
  clone_all=true
fi

clone_repo() {
  local repo="$1"
  if [[ -d "$repo/.git" ]]; then
    echo "→ $repo already present"
    git -C "$repo" fetch --quiet || true
    return
  fi
  echo "→ cloning $repo"
  if ! git clone "https://github.com/$ORG/$repo.git" "$repo"; then
    echo "  skipped $repo (no access or repo not created yet)"
  fi
}

for repo in "${PUBLIC_REPOS[@]}"; do
  clone_repo "$repo"
done

if $clone_all; then
  for repo in "${PRIVATE_REPOS[@]}"; do
    clone_repo "$repo"
  done
fi

if command -v go >/dev/null 2>&1 && [[ -d keel-core ]] && [[ -d keel-pipeline ]]; then
  go work init ./keel-core ./keel-pipeline 2>/dev/null || true
  echo "→ go.work ready"
fi

echo "Done. Start the local stack with: make infra-up"
