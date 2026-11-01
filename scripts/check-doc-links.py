#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

SKIP_DIRS = {".git", ".next", ".venv", "node_modules", "__pycache__", ".pytest_cache", ".demo"}
LINK = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
SCHEMES = ("http://", "https://", "mailto:", "tel:", "data:", "javascript:")


def markdown_files(root: Path):
    if root.is_file():
        if root.suffix == ".md":
            yield root
        return
    for path in root.rglob("*.md"):
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        yield path


def check(root: Path) -> int:
    broken: list[tuple[Path, str]] = []
    for path in markdown_files(root):
        text = path.read_text(encoding="utf-8")
        for raw in LINK.findall(text):
            target = raw.strip()
            if not target or target.startswith("#") or target.startswith(SCHEMES):
                continue
            if target.startswith("/"):
                continue
            parsed = urlsplit(target)
            candidate = path.parent / unquote(parsed.path)
            if not candidate.exists():
                broken.append((path, target))
    for path, target in broken:
        print(f"{path}: broken link {target}", file=sys.stderr)
    if broken:
        print(f"{len(broken)} broken link(s)", file=sys.stderr)
        return 1
    print("markdown links valid")
    return 0


def main() -> int:
    roots = [Path(arg) for arg in sys.argv[1:]] or [Path(".")]
    code = 0
    for root in roots:
        code = max(code, check(root.resolve()))
    return code


if __name__ == "__main__":
    raise SystemExit(main())
