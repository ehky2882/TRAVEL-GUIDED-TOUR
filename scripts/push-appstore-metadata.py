#!/usr/bin/env python3
"""Push fastlane/metadata/ to App Store Connect without fastlane.

WHY THIS EXISTS
---------------
`bundle exec fastlane metadata` is the normal way to do this. But fastlane
cannot be installed on a stock Mac: macOS ships Ruby 2.6, and the current gem
tree needs Ruby >= 3.2. Until a newer Ruby is installed (or you run the lane in
CI, where fastlane is preinstalled), this script is the local fallback.

It makes the same REST calls `deliver` makes underneath, reading the same files,
so the two cannot drift.

USAGE
-----
    python3 scripts/push-appstore-metadata.py            # dry run — shows a diff
    python3 scripts/push-appstore-metadata.py --apply    # actually writes

Credentials, from the environment (same names the fastlane lanes use):

    APP_STORE_CONNECT_KEY_ID
    APP_STORE_CONNECT_ISSUER_ID
    APP_STORE_CONNECT_API_KEY_PATH   path to the .p8
                                     (default: ~/private_keys/AuthKey_<KEY_ID>.p8)

Requires: PyJWT, cryptography, certifi.

TWO TRAPS ALREADY PAID FOR — do not re-enter them
-------------------------------------------------
1. "What's New" (`whatsNew`) CANNOT be set on a first release. Apple answers
   409 STATE_ERROR "Attribute 'whatsNew' cannot be edited at this time", because
   there is no previous version for anything to be new against. Add
   `release_notes.txt` at version 1.1, not before.
2. The version PATCH is ATOMIC. One rejected attribute fails the whole request,
   so a single bad field silently takes the description, keywords and everything
   else down with it. If a push reports a non-200, assume NOTHING landed.
"""

import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.request

try:
    import certifi
    import jwt
except ImportError:
    sys.exit("Missing dependencies. Run: python3 -m pip install --user PyJWT cryptography certifi")

BASE = "https://api.appstoreconnect.apple.com/v1"
BUNDLE_ID = "com.ehky.TRAVEL-GUIDED-TOUR"
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
METADATA = os.path.join(REPO_ROOT, "fastlane", "metadata")
LOCALE = "en-US"

# Which metadata file maps to which App Store Connect attribute. A field with no
# file is left untouched rather than blanked.
VERSION_FIELDS = {
    "description": "description.txt",
    "keywords": "keywords.txt",
    "promotionalText": "promotional_text.txt",
    "supportUrl": "support_url.txt",
    "marketingUrl": "marketing_url.txt",
    # "whatsNew": "release_notes.txt",  # see trap 1 — only from version 1.1 on.
}
INFO_FIELDS = {
    "name": "name.txt",
    "subtitle": "subtitle.txt",
    "privacyPolicyUrl": "privacy_url.txt",
}

EDITABLE_STATES = {
    "PREPARE_FOR_SUBMISSION",
    "DEVELOPER_REJECTED",
    "REJECTED",
    "METADATA_REJECTED",
    "WAITING_FOR_REVIEW",
}

SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())


def build_token() -> str:
    try:
        key_id = os.environ["APP_STORE_CONNECT_KEY_ID"]
        issuer = os.environ["APP_STORE_CONNECT_ISSUER_ID"]
    except KeyError as missing:
        sys.exit(f"Missing environment variable: {missing}")

    path = os.environ.get(
        "APP_STORE_CONNECT_API_KEY_PATH",
        os.path.expanduser(f"~/private_keys/AuthKey_{key_id}.p8"),
    )
    if not os.path.exists(path):
        sys.exit(f"No key file at {path}. Set APP_STORE_CONNECT_API_KEY_PATH.")

    with open(path) as handle:
        # A key pasted through a web form can arrive with literal "\n".
        private_key = handle.read().replace("\\n", "\n")

    now = int(time.time())
    return jwt.encode(
        {"iss": issuer, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )


TOKEN = build_token()


def call(path, method="GET", body=None):
    data = json.dumps(body).encode() if body else None
    headers = {"Authorization": f"Bearer {TOKEN}"}
    if data:
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(f"{BASE}/{path}", method=method, data=data, headers=headers)
    try:
        with urllib.request.urlopen(request, context=SSL_CONTEXT) as response:
            raw = response.read()
            return response.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as error:
        return error.code, {"_error": error.read().decode("utf-8", "replace")[:600]}


def read_metadata(filename):
    path = os.path.join(METADATA, LOCALE, filename)
    if not os.path.exists(path):
        return None
    with open(path) as handle:
        return handle.read().strip()


def diff(current, fields):
    changes = {}
    for attribute, filename in fields.items():
        new = read_metadata(filename)
        if new is None:
            continue
        if new != (current.get(attribute) or ""):
            changes[attribute] = new
    return changes


def brief(text):
    text = (text or "").replace("\n", " / ")
    return (text[:100] + " …") if len(text) > 100 else (text or "(empty)")


def localisation_of(collection_path, locale=LOCALE):
    data = call(collection_path)[1].get("data", [])
    return next((item for item in data if item["attributes"].get("locale") == locale), None)


def main():
    apply_changes = "--apply" in sys.argv

    apps = call(f"apps?filter[bundleId]={BUNDLE_ID}&limit=1")[1]
    if not apps.get("data"):
        sys.exit(f"No app found for bundle id {BUNDLE_ID}.")
    app_id = apps["data"][0]["id"]

    versions = call(f"apps/{app_id}/appStoreVersions?limit=10")[1]
    version = next(
        (
            item
            for item in versions.get("data", [])
            if (item["attributes"].get("appStoreState") or item["attributes"].get("appVersionState"))
            in EDITABLE_STATES
        ),
        None,
    )
    if not version:
        sys.exit("No editable App Store version. Nothing changed.")
    print(f"Editable version: {version['attributes'].get('versionString')}")

    version_loc = localisation_of(f"appStoreVersions/{version['id']}/appStoreVersionLocalizations")
    if not version_loc:
        sys.exit(f"No {LOCALE} version localisation. Nothing changed.")

    infos = call(f"apps/{app_id}/appInfos?limit=5")[1].get("data", [])
    info = next(
        (
            item
            for item in infos
            if (item["attributes"].get("appStoreState") or item["attributes"].get("state"))
            in EDITABLE_STATES
        ),
        infos[0] if infos else None,
    )
    info_loc = localisation_of(f"appInfos/{info['id']}/appInfoLocalizations") if info else None

    version_changes = diff(version_loc["attributes"], VERSION_FIELDS)
    info_changes = diff(info_loc["attributes"], INFO_FIELDS) if info_loc else {}

    if not version_changes and not info_changes:
        print("Already up to date — the listing matches fastlane/metadata/.")
        return 0

    print("\nCHANGES" if apply_changes else "\nPLANNED CHANGES (dry run)")
    for source, changes in ((version_loc, version_changes), (info_loc, info_changes)):
        for attribute, new in changes.items():
            print(f"\n  {attribute}\n    was: {brief(source['attributes'].get(attribute))}"
                  f"\n    now: {brief(new)}")

    if not apply_changes:
        print("\nNothing sent. Re-run with --apply to write these.")
        return 0

    failed = False
    for kind, identifier, changes in (
        ("appStoreVersionLocalizations", version_loc["id"], version_changes),
        ("appInfoLocalizations", info_loc["id"] if info_loc else None, info_changes),
    ):
        if not changes or not identifier:
            continue
        status, body = call(
            f"{kind}/{identifier}",
            method="PATCH",
            body={"data": {"type": kind, "id": identifier, "attributes": changes}},
        )
        print(f"\n{kind}: HTTP {status}")
        if status >= 300:
            failed = True
            print(body.get("_error"))
            print("NOTE: this request is atomic — assume none of its fields were applied.")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
