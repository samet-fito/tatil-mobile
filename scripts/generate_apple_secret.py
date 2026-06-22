#!/usr/bin/env python3
"""Apple OAuth client secret üretir (Supabase için, max 6 ay geçerli)."""
from __future__ import annotations

import os
import sys
import time
from pathlib import Path

try:
    import jwt
except ImportError:
    print("PyJWT gerekli: pip3 install pyjwt cryptography", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    team_id = os.environ.get("APPLE_TEAM_ID", "").strip()
    key_id = os.environ.get("APPLE_KEY_ID", "").strip()
    services_id = os.environ.get("APPLE_SERVICES_ID", "").strip()
    p8_path = os.environ.get("APPLE_P8_KEY_PATH", "").strip()

    missing = [
        name
        for name, val in [
            ("APPLE_TEAM_ID", team_id),
            ("APPLE_KEY_ID", key_id),
            ("APPLE_SERVICES_ID", services_id),
            ("APPLE_P8_KEY_PATH", p8_path),
        ]
        if not val
    ]
    if missing:
        print(f"Eksik env: {', '.join(missing)}", file=sys.stderr)
        sys.exit(1)

    key_file = Path(p8_path).expanduser()
    if not key_file.is_file():
        print(f".p8 dosyası bulunamadı: {key_file}", file=sys.stderr)
        sys.exit(1)

    private_key = key_file.read_text()
    now = int(time.time())
    token = jwt.encode(
        {
            "iss": team_id,
            "iat": now,
            "exp": now + 86400 * 180,
            "aud": "https://appleid.apple.com",
            "sub": services_id,
        },
        private_key,
        algorithm="ES256",
        headers={"kid": key_id, "alg": "ES256"},
    )
    print(token)


if __name__ == "__main__":
    main()
