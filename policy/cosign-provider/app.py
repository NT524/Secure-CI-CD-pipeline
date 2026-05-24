#!/usr/bin/env python3

import json
import os
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer


COSIGN_BIN = os.environ.get("COSIGN_BIN", "/usr/local/bin/cosign")
COSIGN_KEY = os.environ.get("COSIGN_PUBLIC_KEY_PATH", "/keys/cosign.pub")
COSIGN_TIMEOUT = int(os.environ.get("COSIGN_TIMEOUT_SECONDS", "30"))


def verify_image(image: str) -> dict:
    cmd = [
        COSIGN_BIN,
        "verify",
        "--key",
        COSIGN_KEY,
        "--insecure-ignore-tlog=true",
        image,
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=COSIGN_TIMEOUT,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {"verified": False, "message": "cosign verify timed out"}
    except Exception as exc:
        return {"verified": False, "message": f"provider execution error: {exc}"}

    if result.returncode == 0:
        return {"verified": True, "message": "signature verified with cosign public key"}

    stderr = (result.stderr or result.stdout or "").strip().replace("\n", " ")
    return {"verified": False, "message": stderr[:500] or "cosign verify failed"}


class Handler(BaseHTTPRequestHandler):
    def _send(self, payload: dict, status: int = 200) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:
        if self.path != "/validate":
            self._send({"error": "not found"}, 404)
            return

        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length)

        try:
            request = json.loads(raw)
        except json.JSONDecodeError as exc:
            self._send(
                {
                    "apiVersion": "externaldata.gatekeeper.sh/v1beta1",
                    "kind": "ProviderResponse",
                    "response": {},
                    "systemError": f"invalid json: {exc}",
                }
            )
            return

        keys = request.get("request", {}).get("keys", [])
        items = [{"key": image, "value": verify_image(image)} for image in keys]

        self._send(
            {
                "apiVersion": "externaldata.gatekeeper.sh/v1beta1",
                "kind": "ProviderResponse",
                "response": {"items": items},
            }
        )

    def log_message(self, fmt: str, *args) -> None:
        return


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8090), Handler).serve_forever()
