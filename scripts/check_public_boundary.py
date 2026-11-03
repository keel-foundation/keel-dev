#!/usr/bin/env python3
"""Verify that private repositories are not part of the public keel-dev tree."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRIVATE_REPOS = (
    "keel-web",
    "keel-embeddings",
    "keel-governance",
    "keel-infra",
    "keel-security",
    "keel-branding",
)


def git(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(ROOT), *args],
        capture_output=True,
        text=True,
    )


def main() -> int:
    inside = git("rev-parse", "--is-inside-work-tree")
    if inside.returncode != 0:
        print("not a git checkout; skipping public/private boundary check")
        return 0

    errors: list[str] = []

    tracked = git("ls-files")
    if tracked.returncode != 0:
        errors.append(f"git ls-files failed: {tracked.stderr.strip()}")
    else:
        for line in tracked.stdout.splitlines():
            if line.split("/", 1)[0] in PRIVATE_REPOS:
                errors.append(f"tracked private path: {line}")

    for name in PRIVATE_REPOS:
        ignored = git("check-ignore", "-q", "--no-index", f"{name}/README.md")
        if ignored.returncode != 0:
            errors.append(f"{name}/ is not ignored by .gitignore")

        path = ROOT / name
        if path.exists() and not (path / ".git").exists():
            errors.append(f"{name}/ exists but is not a separate git repository")

    gitmodules = ROOT / ".gitmodules"
    if gitmodules.exists():
        contents = gitmodules.read_text(encoding="utf-8")
        for name in PRIVATE_REPOS:
            if name in contents:
                errors.append(f".gitmodules references private repository: {name}")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("public/private boundary is clean")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
