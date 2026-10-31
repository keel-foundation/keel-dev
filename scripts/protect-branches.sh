#!/usr/bin/env bash
set -euo pipefail

ORG="${ORG:-keel-foundation}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required: brew install gh && gh auth login" >&2
  exit 1
fi

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

for entry in "${REPOS[@]}"; do
  IFS='|' read -r repo approvals <<< "$entry"
  echo "→ protecting $ORG/$repo (main, $approvals approvals)"
  gh api --method PUT "repos/$ORG/$repo/branches/main/protection" --input - <<JSON >/dev/null
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
done

echo "Done. Add required status checks once CI workflow names are stable."
