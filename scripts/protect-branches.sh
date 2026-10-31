#!/usr/bin/env bash
set -euo pipefail

ORG="${ORG:-keel-foundation}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required: brew install gh && gh auth login" >&2
  exit 1
fi

PLAN="$(gh api "orgs/$ORG" --jq '.plan.name // "free"' 2>/dev/null || echo "free")"
PRIVATE_REPOS=(keel-governance keel-infra keel-security)

# repo|required approvals
REPOS=(
  "keel-spec|2"
  "keel-core|2"
  "keel-pipeline|1"
  "keel-web|1"
  "keel-moderation|2"
  "keel-dev|1"
  "keel-docs|1"
  ".github|1"
  "keel-governance|2"
  "keel-infra|2"
  "keel-security|2"
)

is_private() {
  local repo="$1"
  local item
  for item in "${PRIVATE_REPOS[@]}"; do
    [[ "$item" == "$repo" ]] && return 0
  done
  return 1
}

for entry in "${REPOS[@]}"; do
  IFS='|' read -r repo approvals <<< "$entry"

  if is_private "$repo" && [[ "$PLAN" == "free" ]]; then
    echo "⚠ skipping $ORG/$repo: native branch protection for private repos requires GitHub Team or Enterprise"
    continue
  fi

  echo "→ protecting $ORG/$repo (main, $approvals approvals)"
  if output=$(gh api --method PUT "repos/$ORG/$repo/branches/main/protection" --input - 2>&1 <<JSON
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": $approvals
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
JSON
  ); then
    echo "  protected"
  else
    if [[ "$output" == *"Upgrade to GitHub Pro"* || "$output" == *"Upgrade to GitHub Team"* ]]; then
      echo "⚠ skipping $ORG/$repo: this GitHub plan does not support branch protection for this repo"
    else
      echo "$output" >&2
      exit 1
    fi
  fi
done

echo "Done. Public repos are protected; private repos are protected only on a plan that supports it."
echo "If private repos were skipped, enforce review manually or upgrade to GitHub Team."
