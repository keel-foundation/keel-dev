#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf 'would run:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required: brew install gh && gh auth login" >&2
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated: run gh auth login" >&2
  exit 1
fi
if ! git config user.email >/dev/null 2>&1; then
  echo "Set git identity first: git config --global user.name '...' && git config --global user.email '...'" >&2
  exit 1
fi

run ./scripts/create-repos.sh
run ./scripts/init-local-repos.sh

commit_push() {
  local dir="$1"
  local remote_name="${2:-origin}"
  [[ -d "$dir/.git" ]] || return 0

  if ! git -C "$dir" rev-parse --verify HEAD >/dev/null 2>&1; then
    echo "→ initial commit: $dir"
    run git -C "$dir" add -A
    run git -C "$dir" commit -m "chore: initial scaffold"
  fi

  run git -C "$dir" branch -M main
  echo "→ pushing: $dir"
  run git -C "$dir" push -u "$remote_name" main
}

echo "Pushing org community repo first..."
if [[ -d dot-github ]]; then
  commit_push "dot-github"
fi

echo "Pushing workspace repo..."
commit_push "."

REPOS=(keel-spec keel-core keel-pipeline keel-web keel-moderation keel-docs keel-governance keel-infra keel-security)
for repo in "${REPOS[@]}"; do
  if [[ -d "$repo" ]]; then
    commit_push "$repo"
  fi
done

run ./scripts/create-teams.sh
run ./scripts/protect-branches.sh
if [[ "${HARDEN:-0}" == "1" ]]; then
  run ./scripts/harden-org.sh
fi

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry run complete. No repositories, teams, branches, or org settings were changed."
else
  echo "Done. Org repos, teams, access, and branch protection are configured."
  echo "Next: add people to the repo-scoped team, never to org-wide write."
  echo "Run HARDEN=1 ./scripts/publish-org.sh to also apply organization hardening."
  echo "For existing repos with local changes, use ./scripts/sync-remotes.sh --apply instead."
fi
