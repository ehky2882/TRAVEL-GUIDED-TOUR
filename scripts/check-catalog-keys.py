#!/usr/bin/env python3
"""Ask the LIVE catalog RPC what it returns, and fail if anything is missing.

This exists because a single migration could silently strip features out of
the catalog and nothing anywhere would notice. The live RPC is a composition —

    get_catalog()      = get_catalog_core()      || { places: catalog_places() }
    get_catalog_core() = get_catalog_core_base() with link pins lifted out of `tours`

— so a `create or replace function public.get_catalog()` severs the call to
the core and drops places plus every key the core carries. No error is raised.
The app simply stops receiving them, and the next person to look is a user.

Run it after ANY migration that touches the catalog, and in CI if you like.

    python3 scripts/check-catalog-keys.py
    python3 scripts/check-catalog-keys.py --selftest   # offline, no network

⚠️ Uses curl, not urllib: urllib fails SSL verification on the owner's Mac,
which is how `check-image-duplicates.py` once printed "OK" having fetched
nothing at all. And a run that cannot reach the network exits 2 —
COULD NOT VERIFY is not a pass.
"""
import json
import subprocess
import sys
from pathlib import Path

# Every key the app decodes. Adding one here without adding it to the RPC
# turns this check red, which is the point: the contract is written down.
REQUIRED_TOP = {"makers", "tours", "places", "linkPins"}
REQUIRED_TOUR = {
    "id", "title", "shortDescription", "longDescription", "makerId",
    "heroImageURL", "additionalImageURLs", "videoURLs", "videoRole", "kind",
    "sourceURL", "sourceAuthor",
    "introAudioURL", "totalDurationSeconds", "walkingDistanceMeters",
    "centroidLatitude", "centroidLongitude", "city", "country",
    "primaryCategory", "tags", "priceUSD", "priceTier", "stops",
}
REQUIRED_MAKER = {
    "id", "displayName", "avatarURL", "avatarEmoji", "avatarInitials",
    "avatarColor", "bio", "websiteURL", "link2URL", "link3URL", "userId",
    "isPrivate",
}
REQUIRED_STOP = {
    "id", "order", "title", "caption", "latitude", "longitude", "audioURL",
    "audioDurationSeconds", "triggerMode", "triggerRadiusMeters", "imageURL",
    "transcriptText",
}
# A floor, not an assertion about content: places existing at all is what the
# composition provides, and zero would mean the wrapper had been clobbered.
MIN_PLACES = 1


def missing(sample: dict, required: set, label: str) -> list:
    absent = sorted(required - set(sample.keys()))
    return [f"{label} is missing: {', '.join(absent)}"] if absent else []


def check(catalog: dict) -> list:
    """Pure — the whole rule, so `--selftest` can exercise it with no network."""
    problems = []
    problems += missing(catalog, REQUIRED_TOP, "the catalog")
    if catalog.get("tours"):
        problems += missing(catalog["tours"][0], REQUIRED_TOUR, "tours[]")
        stops = catalog["tours"][0].get("stops") or []
        if stops:
            problems += missing(stops[0], REQUIRED_STOP, "tours[].stops[]")
    else:
        problems.append("the catalog returned no tours at all")
    if catalog.get("makers"):
        problems += missing(catalog["makers"][0], REQUIRED_MAKER, "makers[]")
    else:
        problems.append("the catalog returned no makers at all")
    if len(catalog.get("places") or []) < MIN_PLACES:
        problems.append(
            f"places is empty or absent — the strongest sign get_catalog() has "
            f"been replaced wholesale, severing catalog_places()"
        )

    # 🔴 The split is the whole reason older builds can still read the catalog.
    # A link pin back inside `tours` fails the entire decode on every build
    # predating TourKind.link — silently, because RemoteCatalogLoader's `try?`
    # reads a throw as a failed fetch and keeps its last good copy. This is the
    # check whose absence let that sit undetected for a day.
    stray = [t.get("id") for t in (catalog.get("tours") or [])
             if t.get("kind") == "link"]
    if stray:
        problems.append(
            f"{len(stray)} link pin(s) are inside tours (first: {stray[0]}) — "
            f"every build predating TourKind.link will fail the whole catalog decode"
        )
    return problems


def audit_migration_files(root: Path) -> list:
    """Every file that replaces `get_catalog` wholesale must warn that it does.

    A banner is not a fix — those files still contain the destructive
    statement — but an unbannered one is a loaded gun with no trigger guard,
    and this is what stops a new one being added quietly.

    Legitimate: files whose new body CALLS `get_catalog_core()` (they are the
    wrapper), and `schema.sql`, which is the base and runs before the rename.
    """
    import glob
    problems = []
    for f in sorted(glob.glob(str(root / "backend" / "*.sql"))):
        raw = Path(f).read_text()
        code = "\n".join(l for l in raw.splitlines() if not l.strip().startswith("--"))
        marker = "create or replace function public.get_catalog()"
        if marker not in code:
            continue
        body = code[code.index(marker):code.index(marker) + 900]
        name = Path(f).name
        if "get_catalog_core()" in body or name == "schema.sql":
            continue  # the wrapper itself, or the base
        if "NO LONGER SAFE TO RE-RUN" not in raw:
            problems.append(
                f"backend/{name} replaces get_catalog() with an inline body and "
                f"carries no warning — re-running it would sever get_catalog_core() "
                f"and drop places, priceTier and isPrivate"
            )
    return problems


def selftest() -> int:
    good = {
        "makers": [{k: 1 for k in REQUIRED_MAKER}],
        "tours": [{**{k: 1 for k in REQUIRED_TOUR},
                   "stops": [{k: 1 for k in REQUIRED_STOP}]}],
        "places": [{"id": 1}],
        "linkPins": [],
    }
    cases = []
    cases.append(("a complete catalog passes", good, 0))

    # The exact failure this was written for.
    clobbered = json.loads(json.dumps(good))
    clobbered.pop("places")
    for k in ("priceTier", "videoRole"):
        clobbered["tours"][0].pop(k)
    clobbered["makers"][0].pop("isPrivate")
    clobbered.pop("linkPins")
    # Five: the two missing top-level keys (places, linkPins) report as one
    # finding, plus the tour keys, the maker key, the places-count floor.
    cases.append(("get_catalog replaced wholesale is caught", clobbered, 4))

    no_places = json.loads(json.dumps(good)); no_places["places"] = []
    cases.append(("places emptied is caught", no_places, 1))

    no_role = json.loads(json.dumps(good)); no_role["tours"][0].pop("videoRole")
    cases.append(("a single dropped tour key is caught", no_role, 1))

    no_stop_key = json.loads(json.dumps(good))
    no_stop_key["tours"][0]["stops"][0].pop("transcriptText")
    cases.append(("a dropped stop key is caught", no_stop_key, 1))

    empty = {"makers": [], "tours": [], "places": [], "linkPins": []}
    cases.append(("an empty catalog is caught", empty, 3))

    # The regression this whole change exists to prevent, in both directions.
    regressed = json.loads(json.dumps(good))
    regressed["tours"][0]["kind"] = "link"
    cases.append(("a link pin back inside tours is caught", regressed, 1))

    no_pins_key = json.loads(json.dumps(good)); no_pins_key.pop("linkPins")
    cases.append(("linkPins dropped from the payload is caught", no_pins_key, 1))

    failed = 0
    for name, payload, expected in cases:
        got = len(check(payload))
        ok = got == expected
        print(f"  {'PASS' if ok else 'FAIL'}  {name}  (expected {expected} problems, got {got})")
        if not ok:
            failed += 1
    print(f"\n{len(cases) - failed}/{len(cases)} self-tests passed")
    return 1 if failed else 0


def fetch() -> dict:
    root = Path(__file__).resolve().parent.parent
    cfg = (root / "TRAVEL GUIDED TOUR" / "Data" / "SupabaseConfig.swift").read_text()
    import re
    key = re.search(r"sb_publishable_[A-Za-z0-9_-]+", cfg)
    host = re.search(r"https://([a-z0-9]+)\.supabase\.co", cfg)
    if not key or not host:
        print("COULD NOT VERIFY: no Supabase URL/key in SupabaseConfig.swift")
        sys.exit(2)
    url = f"https://{host.group(1)}.supabase.co/rest/v1/rpc/get_catalog"
    proc = subprocess.run(
        ["curl", "-s", "-X", "POST", url,
         "-H", f"apikey: {key.group(0)}",
         "-H", "Content-Type: application/json",
         "-d", "{}"],
        capture_output=True, text=True,
    )
    if proc.returncode != 0 or not proc.stdout.strip():
        print(f"COULD NOT VERIFY: the catalog request failed (curl {proc.returncode}).")
        print("This is NOT a pass.")
        sys.exit(2)
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        print("COULD NOT VERIFY: the catalog did not return JSON.")
        print(proc.stdout[:400])
        sys.exit(2)


def main() -> int:
    if "--selftest" in sys.argv:
        return selftest()
    root = Path(__file__).resolve().parent.parent
    file_problems = audit_migration_files(root)
    catalog = fetch()
    problems = check(catalog) + file_problems
    print(f"live catalog: {len(catalog.get('tours', []))} tours, "
          f"{len(catalog.get('makers', []))} makers, "
          f"{len(catalog.get('places', []))} places")
    if problems:
        print("\nFAIL — the catalog is missing things the app decodes:\n")
        for p in problems:
            print(f"  ERROR  {p}")
        print("\nMost likely cause: a migration ran `create or replace function")
        print("public.get_catalog()`, severing the call to get_catalog_core().")
        print("See backend/README.md.")
        return 1
    print("OK — every key the app decodes is present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
