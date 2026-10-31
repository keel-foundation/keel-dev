#!/usr/bin/env python3
"""Open RFC-0001 in keel-spec Discussions with reviewers and a 14-day window."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ORG = "keel-foundation"
REPO = "keel-spec"
TITLE = "RFC-0001: Creator-owned video protocol, PeerTube-compatible, moderation-first"
RFC_PATH = Path(__file__).resolve().parent.parent / "keel-spec" / "rfcs" / "0001-creator-owned-video-protocol.md"


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


def graphql(query: str, variables: dict) -> dict:
    payload = json.dumps({"query": query, "variables": variables})
    return json.loads(
        run(["api", "graphql", "--input", "-"], stdin=payload)
    )


def main() -> int:
    try:
        run(["auth", "status"])
    except RuntimeError as exc:
        print(exc, file=sys.stderr)
        print("Run: gh auth login", file=sys.stderr)
        return 1

    if not RFC_PATH.exists():
        print(f"RFC not found: {RFC_PATH}", file=sys.stderr)
        return 1

    repo = json.loads(run(["api", f"repos/{ORG}/{REPO}"]))
    if not repo.get("has_discussions"):
        print("→ enabling Discussions")
        run(
            [
                "api",
                "--method",
                "PATCH",
                f"repos/{ORG}/{REPO}",
                "-F",
                "has_discussions=true",
            ]
        )

    data = graphql(
        """
        query($owner: String!, $name: String!) {
          repository(owner: $owner, name: $name) {
            id
            discussionCategories(first: 20) {
              nodes { id name slug }
            }
            discussions(first: 50) {
              nodes { title url }
            }
          }
        }
        """,
        {"owner": ORG, "name": REPO},
    )["data"]["repository"]

    for discussion in data["discussions"]["nodes"]:
        if discussion["title"] == TITLE:
            print(f"Already open: {discussion['url']}")
            return 0

    categories = data["discussionCategories"]["nodes"]
    if not categories:
        print("No discussion categories found.", file=sys.stderr)
        return 1
    category = next(
        (item for item in categories if item["slug"] == "general"),
        categories[0],
    )

    body = RFC_PATH.read_text().rstrip()
    body += (
        "\n\n---\n\n"
        "**Status:** Draft for review\n\n"
        "**Review window:** 14 days, closing **14 November 2026**.\n\n"
        "**Reviewers:** @olubunmitosin (Founder) and "
        "@keel-foundation/spec-maintainers.\n\n"
        "**How to comment:** Reply in this discussion. Substantive objections "
        "should name a concrete alternative and the tradeoff.\n"
    )

    result = graphql(
        """
        mutation($repo: ID!, $category: ID!, $title: String!, $body: String!) {
          createDiscussion(input: {
            repositoryId: $repo,
            categoryId: $category,
            title: $title,
            body: $body
          }) {
            discussion { url number }
          }
        }
        """,
        {
            "repo": data["id"],
            "category": category["id"],
            "title": TITLE,
            "body": body,
        },
    )

    discussion = result["data"]["createDiscussion"]["discussion"]
    print(f"Opened discussion #{discussion['number']}: {discussion['url']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
