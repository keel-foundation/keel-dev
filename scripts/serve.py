#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import webbrowser
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1] / "demo"
HOST = os.getenv("HOST", "127.0.0.1")
PORT = int(os.getenv("PORT", "3000"))
MODE = "remote" if os.getenv("KEELTUBE_MODE", "mock").lower() == "remote" else "mock"
API_BASE = os.getenv("KEELTUBE_API_BASE_URL", "").rstrip("/")
MOD_BASE = os.getenv("KEELTUBE_MODERATION_BASE_URL", "").rstrip("/")
OPENAPI_URL = os.getenv("KEELTUBE_OPENAPI_URL", "")
TOKEN = os.getenv("KEELTUBE_DEMO_TOKEN", "")


class DemoHandler(SimpleHTTPRequestHandler):
    server_version = "KeelTubeDemo/1.0"

    def do_GET(self) -> None:
        if urlsplit(self.path).path == "/config.js":
            self._send_config()
            return
        if self._is_proxy_path():
            self._proxy()
            return
        super().do_GET()

    def do_HEAD(self) -> None:
        if self._is_proxy_path():
            self._proxy()
            return
        super().do_HEAD()

    def do_POST(self) -> None:
        if self._is_proxy_path():
            self._proxy()
            return
        self.send_error(405, "Method not allowed")

    def do_PUT(self) -> None:
        if self._is_proxy_path():
            self._proxy()
            return
        self.send_error(405, "Method not allowed")

    def do_PATCH(self) -> None:
        if self._is_proxy_path():
            self._proxy()
            return
        self.send_error(405, "Method not allowed")

    def do_DELETE(self) -> None:
        if self._is_proxy_path():
            self._proxy()
            return
        self.send_error(405, "Method not allowed")

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self.send_header("Allow", "GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS")
        self.end_headers()

    def _is_proxy_path(self) -> bool:
        path = urlsplit(self.path).path
        return (
            path == "/api"
            or path.startswith("/api/")
            or path == "/moderation"
            or path.startswith("/moderation/")
        )

    def _send_config(self) -> None:
        config = {
            "mode": MODE,
            "apiBaseUrl": "/api",
            "moderationBaseUrl": "/moderation",
            "openapiUrl": OPENAPI_URL,
            "configured": MODE == "mock" or bool(API_BASE and MOD_BASE),
        }
        body = ("window.KEELTUBE_CONFIG = " + json.dumps(config, separators=(",", ":")) + ";\n").encode(
            "utf-8"
        )
        self.send_response(200)
        self.send_header("Content-Type", "application/javascript; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _proxy(self) -> None:
        parsed = urlsplit(self.path)
        path = parsed.path
        query = f"?{parsed.query}" if parsed.query else ""
        if path == "/api" or path.startswith("/api/"):
            base = API_BASE
            target_path = path
        elif path == "/moderation" or path.startswith("/moderation/"):
            base = MOD_BASE
            target_path = path[len("/moderation") :] or "/"
        else:
            self.send_error(404, "Not found")
            return

        if not base:
            self._send_json(
                503,
                {
                    "detail": (
                        "Stage mode is not configured. Set KEELTUBE_API_BASE_URL "
                        "and KEELTUBE_MODERATION_BASE_URL."
                    )
                },
            )
            return

        target = base + target_path + query
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        headers = {"Accept": self.headers.get("Accept", "application/json")}
        content_type = self.headers.get("Content-Type")
        if content_type:
            headers["Content-Type"] = content_type
        if TOKEN:
            headers["Authorization"] = f"Bearer {TOKEN}"

        request = Request(target, data=body, headers=headers, method=self.command)
        try:
            with urlopen(request, timeout=30) as response:
                status = response.status
                payload = response.read()
                upstream_headers = response.headers
        except HTTPError as error:
            status = error.code
            payload = error.read()
            upstream_headers = error.headers
        except URLError as error:
            self._send_json(502, {"detail": f"Stage proxy failed: {error.reason}"})
            return
        except OSError as error:
            self._send_json(502, {"detail": f"Stage proxy failed: {error}"})
            return

        self.send_response(status)
        self.send_header(
            "Content-Type", upstream_headers.get("Content-Type", "application/json")
        )
        disposition = upstream_headers.get("Content-Disposition")
        if disposition:
            self.send_header("Content-Disposition", disposition)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(payload)

    def _send_json(self, status: int, payload: dict) -> None:
        body = (json.dumps(payload) + "\n").encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def list_directory(self, path: str):
        self.send_error(404, "Not found")
        return None

    def log_message(self, format: str, *args) -> None:
        print(f"{self.address_string()} {self.command} {self.path}")


def main() -> int:
    handler = partial(DemoHandler, directory=str(ROOT))
    server = ThreadingHTTPServer((HOST, PORT), handler)
    display_host = "localhost" if HOST in {"127.0.0.1", "0.0.0.0", "::1"} else HOST
    print(f"KeelTube demo: http://{display_host}:{PORT}")
    if MODE == "remote":
        print(f"Mode: remote")
        print(f"  core proxy: {API_BASE or 'not configured'}")
        print(f"  moderation proxy: {MOD_BASE or 'not configured'}")
        if OPENAPI_URL:
            print(f"  openapi: {OPENAPI_URL}")
        if not (API_BASE and MOD_BASE):
            print("Warning: remote mode requires both base URLs; requests will return 503.")
    else:
        print("Mode: mock (no backend required)")
    if os.getenv("OPEN", "0") == "1":
        webbrowser.open(f"http://{display_host}:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
