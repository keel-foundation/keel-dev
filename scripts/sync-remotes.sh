#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

APPLY=0
if [[ "${1:-}" == "--apply" ]]; then
  APPLY=1
fi

ORG="${ORG:-keel-foundation}"
MESSAGE="${SYNC_MESSAGE:-chore: close the review gaps across the workspace}"
REPOS=(dot-github keel-spec keel-core keel-pipeline keel-moderation keel-web keel-docs keel-governance keel-infra keel-security)

if [[ "$APPLY" == "1" ]]; then
  if ! git config user.email >/dev/null 2>&1; then
    echo "Set git identity first: git config --global user.name '...' && git config --global user.email '...'" >&2
    exit 1
  fi
fi

sync_repo() {
  local dir="$1"
  if [[ ! -d "$dir/.git" ]]; then
    echo "skip: $dir has no git repository"
    return
  fi
  if [[ -z "$(git -C "$dir" status --porcelain)" ]]; then
    echo "clean: $dir"
    return
  fi

  echo "→ $dir has local changes"
  git -C "$dir" status --short | sed 's/^/    /'
  if [[ "$APPLY" != "1" ]]; then
    echo "  dry run: would commit -s and push origin main"
    return
  fi

  git -C "$dir" add -A
  if git -C "$dir" diff --cached --quiet; then
    echo "  no staged changes"
    return
  fi
  git -C "$dir" commit -s -m "$MESSAGE"
  git -C "$dir" push origin main
  echo "  pushed: $dir"
}

echo "Remote sync plan for $ORG"
echo "Order: .github first, then public repos, then private repos, then the workspace."
for repo in "${REPOS[@]}"; do
  sync_repo "$repo"
done
sync_repo "."

if [[ "$APPLY" != "1" ]]; then
  echo "Dry run complete. Review the changes, then run: ./scripts/sync-remotes.sh --apply"
fi
