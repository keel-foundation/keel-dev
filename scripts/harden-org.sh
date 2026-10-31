#!/usr/bin/env bash
set -euo pipefail

ORG="${ORG:-keel-foundation}"
DRY_RUN="${DRY_RUN:-0}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required: brew install gh && gh auth login" >&2
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated: run gh auth login" >&2
  exit 1
fi

warn() {
  echo "  warning: $*" >&2
}

try_org() {
  local description="$1"
  shift
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "  would set: $description"
    return
  fi
  if "$@" >/dev/null 2>&1; then
    echo "  $description"
  else
    warn "$description"
  fi
}

echo "Hardening organization $ORG"

try_org "base repository permission set to none" \
  gh api --method PATCH "orgs/$ORG" -f default_repository_permission=none
try_org "member repository creation disabled" \
  gh api --method PATCH "orgs/$ORG" -F members_can_create_repositories=false
try_org "public repository creation disabled" \
  gh api --method PATCH "orgs/$ORG" -F members_can_create_public_repositories=false
try_org "private repository creation disabled" \
  gh api --method PATCH "orgs/$ORG" -F members_can_create_private_repositories=false
try_org "two-factor authentication required" \
  gh api --method PATCH "orgs/$ORG" -F two_factor_requirement_enabled=true
try_org "DCO sign-off required on the web" \
  gh api --method PATCH "orgs/$ORG" -F web_commit_signoff_required=true
try_org "Dependabot alerts enabled for new repositories" \
  gh api --method PATCH "orgs/$ORG" -F dependabot_alerts_enabled_for_new_repositories=true
try_org "Dependabot security updates enabled for new repositories" \
  gh api --method PATCH "orgs/$ORG" -F dependabot_security_updates_enabled_for_new_repositories=true
try_org "dependency graph enabled for new repositories" \
  gh api --method PATCH "orgs/$ORG" -F dependency_graph_enabled_for_new_repositories=true
try_org "secret scanning enabled for new repositories" \
  gh api --method PATCH "orgs/$ORG" -F secret_scanning_enabled_for_new_repositories=true
try_org "push protection enabled for new repositories" \
  gh api --method PATCH "orgs/$ORG" -F secret_scanning_push_protection_enabled_for_new_repositories=true

PUBLIC_REPOS=(keel-spec keel-core keel-pipeline keel-web keel-moderation keel-dev keel-docs .github)

echo "Enabling repository security features for public repositories"
for repo in "${PUBLIC_REPOS[@]}"; do
  echo "→ $ORG/$repo"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "  would enable secret scanning, push protection, Dependabot, and private vulnerability reporting"
    continue
  fi
  if gh api --method PATCH "repos/$ORG/$repo" --input - >/dev/null 2>&1 <<'JSON'
{
  "security_and_analysis": {
    "secret_scanning": {"status": "enabled"},
    "secret_scanning_push_protection": {"status": "enabled"}
  }
}
JSON
  then
    echo "  secret scanning and push protection enabled"
  else
    warn "secret scanning/push protection unavailable for $repo"
  fi
  if gh api --method PATCH "repos/$ORG/$repo" --input - >/dev/null 2>&1 <<'JSON'
{
  "security_and_analysis": {
    "dependabot_security_updates": {"status": "enabled"}
  }
}
JSON
  then
    echo "  Dependabot security updates enabled"
  else
    warn "Dependabot security updates unavailable for $repo"
  fi
  if gh api --method PUT "repos/$ORG/$repo/private-vulnerability-reporting" >/dev/null 2>&1; then
    echo "  private vulnerability reporting enabled"
  else
    warn "private vulnerability reporting unavailable for $repo"
  fi
done

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry run complete. No organization or repository settings were changed."
else
  echo "Done. Run ./scripts/protect-branches.sh after the CI workflows are pushed."
fi
