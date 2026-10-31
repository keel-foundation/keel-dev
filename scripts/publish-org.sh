#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

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

./scripts/create-repos.sh
./scripts/init-local-repos.sh

commit_push() {
  local dir="$1"
  local remote_name="${2:-origin}"
  [[ -d "$dir/.git" ]] || return 0

  if ! git -C "$dir" rev-parse --verify HEAD >/dev/null 2>&1; then
    echo "→ initial commit: $dir"
    git -C "$dir" add -A
    git -C "$dir" commit -m "chore: initial scaffold"
  fi

  git -C "$dir" branch -M main
  echo "→ pushing: $dir"
  git -C "$dir" push -u "$remote_name" main
}

echo "Pushing org community repo first..."
[[ -d dot-github ]] && commit_push "dot-github"

echo "Pushing workspace repo..."
commit_push "."

REPOS=(keel-spec keel-core keel-pipeline keel-web keel-moderation keel-docs keel-governance keel-infra keel-security)
for repo in "${REPOS[@]}"; do
  [[ -d "$repo" ]] && commit_push "$repo"
done

./scripts/create-teams.sh
./scripts/protect-branches.sh

echo "Done. Org repos, teams, access, and branch protection are configured."
echo "Next: add people to the repo-scoped team, never to org-wide write."
