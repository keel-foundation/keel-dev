#!/usr/bin/env bash
set -euo pipefail

ORG="${ORG:-keel-foundation}"

# root workspace repo
if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "https://github.com/$ORG/keel-dev.git"
fi

REPOS=(keel-spec keel-core keel-pipeline keel-web keel-moderation keel-docs keel-governance keel-infra keel-security)
for repo in "${REPOS[@]}"; do
  [[ -d "$repo" ]] || continue
  if [[ ! -d "$repo/.git" ]]; then
    git -C "$repo" init -b main >/dev/null
  fi
  if ! git -C "$repo" remote get-url origin >/dev/null 2>&1; then
    git -C "$repo" remote add origin "https://github.com/$ORG/$repo.git"
  fi
  echo "→ $repo -> $ORG/$repo"
done

# The special .github repo lives in dot-github locally.
if [[ -d dot-github ]]; then
  if [[ ! -d dot-github/.git ]]; then
    git -C dot-github init -b main >/dev/null
  fi
  if ! git -C dot-github remote get-url origin >/dev/null 2>&1; then
    git -C dot-github remote add origin "https://github.com/$ORG/.github.git"
  fi
  echo "→ dot-github -> $ORG/.github"
fi
