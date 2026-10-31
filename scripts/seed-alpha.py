#!/usr/bin/env python3
"""Create the alpha-0.1 milestone, labels, and seed issues."""

from __future__ import annotations

import json
import subprocess
import sys

ORG = "keel-foundation"
MILESTONE = "alpha-0.1"
DUE = "2026-12-15T00:00:00Z"
MILESTONE_DESCRIPTION = (
    "Walking skeleton: upload -> transcode -> play -> enforcement -> appeal -> "
    "reversal -> audit ledger. Public demo and 90-second recording."
)

LABELS = {
    "alpha": ("0e8a16", "Alpha milestone work"),
    "good-first-issue": ("7057ff", "Scoped for a first contribution"),
    "needs-rfc": ("d4c5f9", "Requires an RFC before implementation"),
}


def run(args: list[str], stdin: str | None = None) -> str:
    result = subprocess.run(
        ["gh", *args],
        input=stdin,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"gh {' '.join(args)} failed:\n{result.stderr.strip() or result.stdout.strip()}"
        )
    return result.stdout.strip()


def ensure_milestone(repo: str) -> int:
    existing = json.loads(
        run(["api", f"repos/{ORG}/{repo}/milestones?state=all&per_page=100"])
    )
    for item in existing:
        if item["title"] == MILESTONE:
            return int(item["number"])
    created = json.loads(
        run(
            [
                "api",
                "--method",
                "POST",
                f"repos/{ORG}/{repo}/milestones",
                "-f",
                f"title={MILESTONE}",
                "-f",
                f"description={MILESTONE_DESCRIPTION}",
                "-f",
                f"due_on={DUE}",
            ]
        )
    )
    return int(created["number"])


def ensure_labels(repo: str) -> None:
    existing = json.loads(run(["api", f"repos/{ORG}/{repo}/labels?per_page=100"]))
    names = {item["name"] for item in existing}
    for name, (color, description) in LABELS.items():
        if name in names:
            continue
        run(
            [
                "label",
                "create",
                name,
                "--repo",
                f"{ORG}/{repo}",
                "--color",
                color,
                "--description",
                description,
                "--force",
            ]
        )


def create_issue(repo: str, title: str, body: str, labels: list[str], milestone: int) -> None:
    existing = json.loads(
        run(
            [
                "issue",
                "list",
                "--repo",
                f"{ORG}/{repo}",
                "--state",
                "all",
                "--limit",
                "200",
                "--json",
                "number,title",
            ]
        )
    )
    for item in existing:
        if item["title"] == title:
            print(f"  skip #{item['number']}: {title}")
            return

    args = [
        "issue",
        "create",
        "--repo",
        f"{ORG}/{repo}",
        "--title",
        title,
        "--body",
        body,
        "--milestone",
        MILESTONE,
    ]
    if labels:
        args.extend(["--label", ",".join(labels)])
    url = run(args)
    print(f"  created: {title} -> {url}")


ISSUES = [
    # keel-spec
    (
        "keel-spec",
        "Lock the v0.1 schema contract",
        "The v0.1 contract is `video.schema.json`, `moderation-case.schema.json`, and `enforcement-action.schema.json`.\n\n"
        "Acceptance:\n"
        "- Add one valid example per schema.\n"
        "- Add a CI check that validates every example against its schema.\n"
        "- Document which fields are required for the walking skeleton.\n"
        "- Resolve any naming mismatch between the schemas and the demo payloads.",
        ["alpha", "good-first-issue"],
    ),
    (
        "keel-spec",
        "PeerTube compatibility matrix v0",
        "Pin a PeerTube release and test the minimum compatibility surface.\n\n"
        "Acceptance:\n"
        "- WebFinger actor discovery works.\n"
        "- A TubeKeel instance can follow a PeerTube channel and receive a video.\n"
        "- A PeerTube instance can follow a TubeKeel channel and receive a video.\n"
        "- Known gaps are documented in `protocol/peertube-compat.md` with versions.",
        ["alpha"],
    ),
    (
        "keel-spec",
        "Draft appeal and audit-record schemas",
        "The walking skeleton already emits appeal and ledger records. Give them a stable contract.\n\n"
        "Acceptance:\n"
        "- Add `appeal.schema.json` and `audit-record.schema.json`.\n"
        "- Include the hash-chain fields (`prev_hash`, `hash`, `seq`).\n"
        "- Validate the moderation service's demo output against both schemas.",
        ["alpha"],
    ),
    # keel-core
    (
        "keel-core",
        "PostgreSQL migrations for actors, channels, and videos",
        "Add the first real persistence layer.\n\n"
        "Acceptance:\n"
        "- Migration for actors, channels, videos, and subscriptions.\n"
        "- Stable opaque IDs matching the schemas.\n"
        "- Seed command for the demo channel and video.\n"
        "- `go test ./...` and a migration up/down test pass.",
        ["alpha"],
    ),
    (
        "keel-core",
        "OIDC authentication and creator sessions",
        "Creators need a real identity before the demo becomes an alpha.\n\n"
        "Acceptance:\n"
        "- OIDC login and signed session cookie.\n"
        "- Creator and viewer roles.\n"
        "- Logout and session rotation.\n"
        "- No secrets in repository config.",
        ["alpha"],
    ),
    (
        "keel-core",
        "Video metadata API and demo seed",
        "Replace the hard-coded demo video with a database-backed endpoint.\n\n"
        "Acceptance:\n"
        "- `GET /api/v1/videos/{id}` returns the schema-shaped video.\n"
        "- `GET /api/v1/channels/{id}` returns the channel.\n"
        "- Demo seed creates the same data the walking skeleton expects.\n"
        "- CORS remains limited to configured origins.",
        ["alpha", "good-first-issue"],
    ),
    (
        "keel-core",
        "Moderation service client contract",
        "Core needs to call moderation without coupling to its internals.\n\n"
        "Acceptance:\n"
        "- Typed client for create action, file appeal, decide appeal, and read ledger.\n"
        "- Timeouts and error mapping.\n"
        "- Contract test against the moderation service.\n"
        "- No moderation decision logic in core.",
        ["alpha"],
    ),
    # keel-pipeline
    (
        "keel-pipeline",
        "Resumable upload session API",
        "The first real media path.\n\n"
        "Acceptance:\n"
        "- Create upload session with checksum and expected size.\n"
        "- Resumable chunks to S3-compatible storage.\n"
        "- Reject mismatched checksums.\n"
        "- Emit `upload.completed` to NATS.",
        ["alpha"],
    ),
    (
        "keel-pipeline",
        "FFmpeg HLS worker with idempotent jobs",
        "Turn an uploaded file into a playable HLS ladder.\n\n"
        "Acceptance:\n"
        "- 240p/480p/720p ladder with a master playlist.\n"
        "- Idempotent job key so retries do not duplicate output.\n"
        "- Thumbnail and storyboard generation.\n"
        "- Emit `video.published` after packaging.",
        ["alpha"],
    ),
    (
        "keel-pipeline",
        "Content hash manifest and thumbnail generation",
        "Content hashes are the anchor for portability and piracy matching.\n\n"
        "Acceptance:\n"
        "- Canonical manifest with SHA-256 per rendition.\n"
        "- Stable `content_hash` for the video.\n"
        "- Thumbnail at a predictable path.\n"
        "- Unit test with a small fixture video.",
        ["alpha", "good-first-issue"],
    ),
    # keel-moderation
    (
        "keel-moderation",
        "Signal, case, action, and appeal domain models",
        "Move the demo's in-memory dicts to typed models.\n\n"
        "Acceptance:\n"
        "- Pydantic models matching the three v0.1 schemas.\n"
        "- Validation and serialization tests.\n"
        "- No model may represent an automated termination without a human reviewer.",
        ["alpha"],
    ),
    (
        "keel-moderation",
        "Hash-chained audit ledger with export",
        "The ledger is the trust primitive.\n\n"
        "Acceptance:\n"
        "- Append-only records with `prev_hash` and `hash`.\n"
        "- Export as JSON Lines and CSV.\n"
        "- Verify a chain and report the first broken record.\n"
        "- Demo endpoint reads from the same implementation.",
        ["alpha"],
    ),
    (
        "keel-moderation",
        "Policy bundle loader and human-review gates",
        "Policy must be versioned code, not scattered conditionals.\n\n"
        "Acceptance:\n"
        "- Load a signed policy bundle from disk.\n"
        "- Enforce human-review gates for channel-level actions.\n"
        "- Record `policy_version` in every action.\n"
        "- Reject an action that violates a gate.",
        ["alpha"],
    ),
    (
        "keel-moderation",
        "Review queue with SLA timers",
        "A case without a timer is a case that disappears.\n\n"
        "Acceptance:\n"
        "- Queue endpoint with status and age.\n"
        "- SLA timers for acknowledgment and decision.\n"
        "- Escalation when a timer expires.\n"
        "- Tests for the timer boundaries.",
        ["alpha"],
    ),
    # keel-web
    (
        "keel-web",
        "Watch page with HLS player",
        "The first real viewer experience.\n\n"
        "Acceptance:\n"
        "- `/watch/[id]` fetches the video and plays HLS.\n"
        "- Accessible controls and captions track support.\n"
        "- Graceful error when the pipeline has not published yet.\n"
        "- Mobile layout works.",
        ["alpha", "good-first-issue"],
    ),
    (
        "keel-web",
        "Creator studio shell",
        "Creators need a home for upload, monetization, appeals, and export.\n\n"
        "Acceptance:\n"
        "- `/studio` shell with navigation.\n"
        "- Upload entry point.\n"
        "- Monetization status panel.\n"
        "- Appeal status and export links.",
        ["alpha"],
    ),
    (
        "keel-web",
        "Appeal status screen",
        "The demo appeal flow should become a real screen.\n\n"
        "Acceptance:\n"
        "- List a creator's enforcement actions and appeals.\n"
        "- Show the Statement of Reasons and evidence.\n"
        "- Show the appeal deadline and decision.\n"
        "- Link to the audit record.",
        ["alpha", "good-first-issue"],
    ),
    (
        "keel-web",
        "Moderation console shell",
        "Reviewers need a queue, not a spreadsheet.\n\n"
        "Acceptance:\n"
        "- `/moderation` shell with queue and case detail.\n"
        "- Evidence bundle view.\n"
        "- Human-review gate confirmation.\n"
        "- No one-click termination.",
        ["alpha"],
    ),
    # keel-dev
    (
        "keel-dev",
        "Seed data and demo reset",
        "Make the demo repeatable.\n\n"
        "Acceptance:\n"
        "- `make demo` seeds the video and resets the moderation state.\n"
        "- Deterministic IDs and hashes for screenshots.\n"
        "- No manual steps after clone beyond dependency install.",
        ["alpha", "good-first-issue"],
    ),
    (
        "keel-dev",
        "One-command demo",
        "The demo must survive a cold clone.\n\n"
        "Acceptance:\n"
        "- `make demo` starts the required services.\n"
        "- Handles missing Go by falling back to the bundled clip.\n"
        "- Picks free ports and prints the URL.\n"
        "- Cleans up child processes on Ctrl-C.",
        ["alpha"],
    ),
    (
        "keel-dev",
        "Record the 90-second demo",
        "The launch post needs a recording, not a promise.\n\n"
        "Acceptance:\n"
        "- Follow `docs/demo-script.md`.\n"
        "- Record at 1440x900, browser only.\n"
        "- Export `docs/demo-90s.mp4`.\n"
        "- Upload it to the launch issue or release.",
        ["alpha"],
    ),
]


def main() -> int:
    try:
        run(["auth", "status"])
    except RuntimeError as exc:
        print(exc, file=sys.stderr)
        print("Run: gh auth login", file=sys.stderr)
        return 1

    for repo in sorted({item[0] for item in ISSUES}):
        print(f"== {repo}")
        milestone = ensure_milestone(repo)
        ensure_labels(repo)
        for issue_repo, title, body, labels in ISSUES:
            if issue_repo == repo:
                create_issue(repo, title, body, labels, milestone)

    print("\nDone. Review the issues and assign owners.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
