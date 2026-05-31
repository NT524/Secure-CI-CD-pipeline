#!/usr/bin/env python3

import json
import os
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer


COSIGN_BIN = os.environ.get("COSIGN_BIN", "/usr/local/bin/cosign")
COSIGN_KEY = os.environ.get("COSIGN_PUBLIC_KEY_PATH", "/keys/cosign.pub")
COSIGN_TIMEOUT = int(os.environ.get("COSIGN_TIMEOUT_SECONDS", "30"))


def verify_image(image: str) -> dict:
    # 1. KIỂM TRA CHỮ KÝ (SIGNATURE)
    cmd_sig = [
        COSIGN_BIN, "verify",
        "--key", COSIGN_KEY,
        "--insecure-ignore-tlog=true",
        image,
    ]
    
    try:
        res_sig = subprocess.run(cmd_sig, capture_output=True, text=True, timeout=COSIGN_TIMEOUT, check=False)
        if res_sig.returncode != 0:
            stderr = (res_sig.stderr or res_sig.stdout or "").strip().replace("\n", " ")
            return {"verified": False, "message": f"Thiếu chữ ký hợp lệ: {stderr[:200]}"}
    except Exception as exc:
        return {"verified": False, "message": f"Lỗi hệ thống khi check chữ ký: {exc}"}

    # 2. KIỂM TRA SBOM ATTESTATION (BỔ SUNG MỚI)
    cmd_sbom = [
        COSIGN_BIN, "verify-attestation",
        "--type", "spdxjson", # Yêu cầu định dạng SBOM là SPDX
        "--key", COSIGN_KEY,
        "--insecure-ignore-tlog=true",
        image,
    ]
    
    try:
        res_sbom = subprocess.run(cmd_sbom, capture_output=True, text=True, timeout=COSIGN_TIMEOUT, check=False)
        if res_sbom.returncode != 0:
            stderr = (res_sbom.stderr or res_sbom.stdout or "").strip().replace("\n", " ")
            return {"verified": False, "message": f"Image có chữ ký nhưng THIẾU SBOM Attestation: {stderr[:200]}"}
    except Exception as exc:
        return {"verified": False, "message": f"Lỗi hệ thống khi check SBOM: {exc}"}

    # Nếu vượt qua cả 2 bài test
    return {"verified": True, "message": "Image hợp lệ: Đã xác thực Chữ ký và SBOM!"}


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
