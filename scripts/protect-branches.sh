#!/usr/bin/env bash
set -euo pipefail

ORG="${ORG:-keel-foundation}"
REQUIRE_CHECKS="${REQUIRE_CHECKS:-0}"
ENFORCE_ADMINS="${ENFORCE_ADMINS:-false}"

if [[ "$ENFORCE_ADMINS" != "true" && "$ENFORCE_ADMINS" != "false" ]]; then
  echo "ENFORCE_ADMINS must be true or false" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required: brew install gh && gh auth login" >&2
  exit 1
fi

PLAN="$(gh api "orgs/$ORG" --jq '.plan.name // "free"' 2>/dev/null || echo "free")"
PRIVATE_REPOS=(keel-governance keel-infra keel-security)

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

checks_for_repo() {
  case "$1" in
    keel-dev) echo "compose / validate" ;;
    keel-core|keel-pipeline) echo "test / test" ;;
    keel-web) echo "typecheck / typecheck" ;;
    keel-moderation) echo "compile / compile" ;;
    keel-spec) echo "schemas,docs / links" ;;
    keel-docs|.github) echo "docs / links" ;;
    *) echo "" ;;
  esac
}

checks_json() {
  local repo="$1"
  local raw
  raw="$(checks_for_repo "$repo")"
  if [[ "$REQUIRE_CHECKS" != "1" || -z "$raw" ]]; then
    printf 'null'
    return
  fi
  local output="{\"strict\":true,\"contexts\":["
  local first=1
  local item
  IFS=',' read -ra items <<< "$raw"
  for item in "${items[@]}"; do
    if [[ "$first" -eq 0 ]]; then output+=","; fi
    output+="\"$item\""
    first=0
  done
  output+="]}"
  printf '%s' "$output"
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
  "required_status_checks": $(checks_json "$repo"),
  "enforce_admins": $ENFORCE_ADMINS,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "require_last_push_approval": true,
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
if [[ "$REQUIRE_CHECKS" != "1" ]]; then
  echo "Required status checks were not set. Set REQUIRE_CHECKS=1 after the CI workflows are pushed to every repo."
fi
if [[ "$ENFORCE_ADMINS" != "true" ]]; then
  echo "Admins can still bypass protection. Re-run with ENFORCE_ADMINS=true once two maintainers are active."
fi
