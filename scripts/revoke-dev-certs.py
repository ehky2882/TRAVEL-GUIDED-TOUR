#!/usr/bin/env python3
"""Free up Apple Development certificate slots before a build.

WHY THIS EXISTS
---------------
Every cloud build machine is a fresh throwaway Mac, and Xcode's automatic
signing mints a NEW "Apple Development" certificate on each one. They pile up
in the Apple Developer account until they hit Apple's cap, and then archiving
fails fast (~40s) with:

    Your account has reached the maximum number of certificates
    No profiles for 'com.ehky.TRAVEL-GUIDED-TOUR' were found

Revoking the development certificates before archiving keeps the account under
the cap; automatic signing then regenerates exactly the one certificate it
needs. DISTRIBUTION certificates — the identity that signs App Store uploads —
are never touched.

This is a workaround, not the final answer. The durable fix is fastlane `match`
(see the `certificates` lane in fastlane/Fastfile), which is deliberately
deferred until after launch.

USAGE
-----
    APP_STORE_CONNECT_KEY_ID=... APP_STORE_CONNECT_ISSUER_ID=... \\
        python3 scripts/revoke-dev-certs.py

The .p8 key is read from ~/private_keys/AuthKey_<KEY_ID>.p8, which the fastlane
lane writes before calling this.

Requires: PyJWT, cryptography.
"""

import glob
import json
import os
import sys
import time
import urllib.error
import urllib.request

try:
    import jwt  # PyJWT
except ImportError:
    sys.exit("PyJWT is not installed. Run: python3 -m pip install 'PyJWT>=2' cryptography")

API_BASE = "https://api.appstoreconnect.apple.com/v1/certificates"


def bearer_token(key_id: str, issuer_id: str, private_key: str) -> str:
    """Apple's API wants a short-lived ES256 token rather than a static secret."""
    now = int(time.time())
    return jwt.encode(
        {"iss": issuer_id, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )


def call(url: str, token: str, method: str = "GET"):
    request = urllib.request.Request(
        url, method=method, headers={"Authorization": f"Bearer {token}"}
    )
    try:
        with urllib.request.urlopen(request) as response:
            raw = response.read()
            return response.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as error:
        return error.code, {}


def main() -> int:
    try:
        key_id = os.environ["APP_STORE_CONNECT_KEY_ID"]
        issuer_id = os.environ["APP_STORE_CONNECT_ISSUER_ID"]
    except KeyError as missing:
        sys.exit(f"Missing environment variable: {missing}")

    matches = glob.glob(os.path.expanduser(f"~/private_keys/AuthKey_{key_id}.p8"))
    if not matches:
        sys.exit(f"No key file at ~/private_keys/AuthKey_{key_id}.p8")

    with open(matches[0]) as handle:
        # A key pasted through a web form can arrive with literal "\n" rather
        # than real line breaks, which fails to parse in a confusing way.
        private_key = handle.read().replace("\\n", "\n")

    token = bearer_token(key_id, issuer_id, private_key)

    status, body = call(f"{API_BASE}?filter[certificateType]=DEVELOPMENT&limit=200", token)
    if status != 200:
        print(f"Could not list certificates (HTTP {status}) — skipping cleanup.")
        return 1

    certificates = body.get("data", [])
    print(f"Found {len(certificates)} Apple Development certificate(s) to revoke.")

    failures = 0
    for certificate in certificates:
        cert_id = certificate["id"]
        code, _ = call(f"{API_BASE}/{cert_id}", token, method="DELETE")
        ok = code in (200, 204)
        failures += 0 if ok else 1
        print(f"  revoke {cert_id}: HTTP {code}{'' if ok else '  (ignored)'}")

    print("Done freeing certificate slots.")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
