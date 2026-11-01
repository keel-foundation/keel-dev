#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
DEMO = ROOT / "demo"

REQUIRED = [
    "index.html",
    "styles.css",
    "config.js",
    "app.js",
    "sample.mp4",
    "sample.vtt",
]
SKIP_SCHEMES = ("http://", "https://", "mailto:", "tel:", "data:", "javascript:")
LINK = re.compile(r'(?:src|href)="([^"]+)"')


def main() -> int:
    missing = [name for name in REQUIRED if not (DEMO / name).exists()]
    if missing:
        print(f"missing demo files: {', '.join(missing)}", file=sys.stderr)
        return 1

    index = (DEMO / "index.html").read_text(encoding="utf-8")
    broken = []
    for raw in LINK.findall(index):
        target = raw.strip()
        if not target or target.startswith("#") or target.startswith(SKIP_SCHEMES):
            continue
        if target.startswith("/"):
            candidate = DEMO / unquote(urlsplit(target).path.lstrip("/"))
        else:
            candidate = DEMO / unquote(urlsplit(target).path)
        if not candidate.exists():
            broken.append(target)

    if broken:
        for target in broken:
            print(f"index.html references missing asset: {target}", file=sys.stderr)
        return 1

    app = (DEMO / "app.js").read_text(encoding="utf-8")
    for marker in ("mockBackend", "remoteBackend", "sha256Hex"):
        if marker not in app:
            print(f"app.js is missing {marker}", file=sys.stderr)
            return 1

    if 'mode: "mock"' not in (DEMO / "config.js").read_text(encoding="utf-8"):
        print("config.js does not default to mock mode", file=sys.stderr)
        return 1

    print("demo assets and adapters look valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
