#!/usr/bin/env bash
set -euo pipefail

ORG="${ORG:-keel-foundation}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required: brew install gh && gh auth login" >&2
  exit 1
fi

# team|privacy
TEAMS=(
  "spec-maintainers|closed"
  "spec-contributors|closed"
  "core-maintainers|closed"
  "core-contributors|closed"
  "pipeline-maintainers|closed"
  "pipeline-contributors|closed"
  "web-maintainers|closed"
  "web-contributors|closed"
  "moderation-maintainers|closed"
  "moderation-contributors|closed"
  "dev-maintainers|closed"
  "dev-contributors|closed"
  "docs-maintainers|closed"
  "docs-contributors|closed"
  "governance-maintainers|secret"
  "governance-contributors|secret"
  "infra-maintainers|secret"
  "infra-contributors|secret"
  "security-maintainers|secret"
  "security-contributors|secret"
  "security-reporters|secret"
  "steering|secret"
)

for entry in "${TEAMS[@]}"; do
  IFS='|' read -r team privacy <<< "$entry"
  if gh api "orgs/$ORG/teams/$team" >/dev/null 2>&1; then
    echo "→ team exists: $team"
  else
    echo "→ creating team: $team"
    gh api --method POST "orgs/$ORG/teams" \
      -f name="$team" \
      -f privacy="$privacy" \
      -f notification_setting="notifications_enabled" >/dev/null
  fi
done

grant() {
  local team="$1" repo="$2" permission="$3"
  gh api --method PUT "orgs/$ORG/teams/$team/repos/$ORG/$repo" \
    -f permission="$permission" >/dev/null
  echo "  $team -> $repo ($permission)"
}

echo "Granting repo-scoped access:"
grant spec-maintainers keel-spec maintain
grant spec-contributors keel-spec push
grant core-maintainers keel-core maintain
grant core-contributors keel-core push
grant pipeline-maintainers keel-pipeline maintain
grant pipeline-contributors keel-pipeline push
grant web-maintainers keel-web maintain
grant web-contributors keel-web push
grant moderation-maintainers keel-moderation maintain
grant moderation-contributors keel-moderation push
grant dev-maintainers keel-dev maintain
grant dev-contributors keel-dev push
grant dev-maintainers .github maintain
grant dev-contributors .github push
grant docs-maintainers keel-docs maintain
grant docs-contributors keel-docs push
grant governance-maintainers keel-governance maintain
grant governance-contributors keel-governance push
grant infra-maintainers keel-infra maintain
grant infra-contributors keel-infra push
grant security-maintainers keel-security maintain
grant security-contributors keel-security push
grant security-reporters keel-security triage
grant steering keel-governance pull
grant steering keel-infra pull
grant steering keel-security pull

echo "Done. Add people to the specific team for the repo they should access."
