#!/usr/bin/env python3
"""
Does the live catalog RPC still emit every key the app decodes?

WHY THIS EXISTS
---------------
On 2026-08-19 `add_country.sql` rebuilt `get_catalog()` from `schema.sql`'s
body. `schema.sql` had never absorbed three later migrations, so the rebuild
silently dropped `places`, `priceTier` and `isPrivate`. Place pages vanished,
all 66 paid walks decoded as free, and every private account was served as
public. It stayed live ~14 hours.

Nothing caught it, and nothing could have:

  * CI builds the app and runs unit tests. It never queries the database.
  * `validate-tours.swift` validates Tours.json — the FILE. Places were fine
    there; it was the RPC that stopped emitting them.
  * Every dropped key is OPTIONAL in Swift, deliberately, so old builds and
    the gh-pages mirror still decode. A missing key becomes nil and the
    feature just stops existing. No crash, no log line, no failed check.

So the only detection is to ask the live RPC what it actually returns and
compare it against what the models declare. That is this script.

HOW IT AVOIDS ROTTING
---------------------
The expected key set is PARSED OUT OF THE SWIFT MODELS, never hardcoded — the
same trick `validate-tours.swift` uses for the tag vocabulary. Add a field to
`Tour` and this starts requiring it on the next run, with no edit here. A
hardcoded list would drift and quietly stop testing anything, which is the
class of bug it is meant to catch.

USAGE
    python3 scripts/check-catalog-contract.py            # human output
    python3 scripts/check-catalog-contract.py --quiet    # only on failure

Exit 0 = contract holds. Exit 1 = a key the app decodes is missing.
Exit 2 = could not check (network/parse) — NOT a pass.

RUN IT: after ANY migration touching get_catalog, and on a schedule.
"""
import json, re, sys, urllib.request, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
QUIET = "--quiet" in sys.argv

def fail(msg, code=2):
    print(f"CANNOT CHECK: {msg}", file=sys.stderr)
    sys.exit(code)

# --- expected keys, parsed from the Swift models -------------------------
def swift_keys(rel):
    """Property names declared on a Codable struct, in declaration order.

    CodingKeys are not used by these models — the JSON keys ARE the property
    names — so the declarations are the contract. Computed properties are
    skipped: they have a `{` on the same line and decode nothing.
    """
    p = ROOT / rel
    if not p.exists():
        fail(f"missing model file {rel}")
    keys, txt = [], p.read_text()
    # Stop at the first extension/computed block so helpers aren't counted.
    for line in txt.splitlines():
        s = line.strip()
        m = re.match(r'^(?:let|var)\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*[^={]+$', s)
        if m:
            keys.append(m.group(1))
    if not keys:
        fail(f"parsed zero properties from {rel} — parser is broken, not the RPC")
    return keys

MODELS = {
    "tours":  "TRAVEL GUIDED TOUR/Models/Tour.swift",
    "makers": "TRAVEL GUIDED TOUR/Models/Maker.swift",
    "places": "TRAVEL GUIDED TOUR/Models/Place.swift",
}
# Declared in Swift but NOT carried by the catalog RPC, by design.
# Keep this list SHORT — it is the escape hatch that could hide a regression.
EXEMPT = {
    "tours":  {"stops"},        # nested; checked separately below
    "makers": set(),
    "places": {"additionalImageURLs"},  # empty everywhere; served by places_photos.sql
}

# Absent, KNOWN, and deliberately not a failure — because the check has to stay
# trustworthy. A check that always fails gets ignored, and then it catches
# nothing. Each entry carries its reason and is printed as a warning every run,
# so it cannot be quietly forgotten either.
KNOWN_GAPS = {
    ("tours", "createdAt"):
        "NEVER served by the RPC - pre-existing, not a regression. Place.ranked "
        "sorts NEWEST FIRST on it, so that rule has no dates to sort on and falls "
        "through to its tiebreaks (single before walk, then title). "
        "DO NOT 'fix' by adding tours.created_at to get_catalog: that column is "
        "`default now()` and the seed never carries the authored date from "
        "Tours.json, so it holds SEED time - most of the catalog shares "
        "2026-06-27, the original bulk seed. Emitting it would look fixed and "
        "rank wrongly. Real fix: make seed_from_toursjson.py carry the authored "
        "createdAt first, then add the key.",
}

# --- the live payload ----------------------------------------------------
CFG = (ROOT / "TRAVEL GUIDED TOUR/Data/SupabaseConfig.swift").read_text()
def cfg(pat):
    m = re.search(pat, CFG)
    if not m:
        fail("could not read Supabase config")
    return m.group(1)

url = cfg(r'projectURL\s*=\s*URL\(string:\s*"([^"]+)"').rstrip("/") + "/rest/v1/rpc/get_catalog"
key = cfg(r'anonKey\s*=\s*"([^"]+)"')

req = urllib.request.Request(url, data=b"{}", method="POST", headers={
    "apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json"})
payload, last = None, None
for attempt in range(3):
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            raw = r.read()              # read fully; json.load(r) can short-read 7MB
        payload = json.loads(raw)
        break
    except Exception as e:              # IncompleteRead is the common one
        last = f"{type(e).__name__}: {e}"
if payload is None:
    fail(f"{last} (3 attempts)")

# --- compare -------------------------------------------------------------
problems, warnings, lines = [], [], []
for coll, rel in MODELS.items():
    rows = payload.get(coll)
    if rows is None:
        problems.append(f"'{coll}' is ABSENT from the payload entirely")
        lines.append(f"  {coll:8} ABSENT")
        continue
    if not rows:
        lines.append(f"  {coll:8} 0 rows — cannot check keys")
        continue
    present = set().union(*(set(r.keys()) for r in rows))
    want = [k for k in swift_keys(rel) if k not in EXEMPT[coll]]
    missing = [k for k in want if k not in present]
    unexpected = [k for k in missing if (coll, k) not in KNOWN_GAPS]
    known      = [k for k in missing if (coll, k) in KNOWN_GAPS]
    note = "  ok" if not missing else ""
    if unexpected: note += f"  MISSING {unexpected}"
    if known:      note += f"  (known gap: {known})"
    lines.append(f"  {coll:8} {len(rows):>5} rows, {len(want)} keys expected" + note)
    for k in missing:
        if (coll, k) in KNOWN_GAPS:
            warnings.append((f"{coll}[].{k}", KNOWN_GAPS[(coll, k)]))
        else:
            problems.append(f"'{coll}[].{k}' is declared in Swift but absent from the RPC")

# Stops are nested and were never at risk here, but a rebuild could drop them.
tours = payload.get("tours") or []
if tours and not any(t.get("stops") for t in tours):
    problems.append("no tour carries any 'stops' — every tour would be unplayable")

if not QUIET or problems:
    print("catalog contract —", url)
    print("\n".join(lines))

if warnings and not QUIET:
    print("\nKnown gaps — expected, tracked, not failures:")
    for name, why in warnings:
        print(f"  !  {name}")
        for sent in why.split(". "):
            if sent.strip():
                print(f"       {sent.strip().rstrip('.')}.")

if problems:
    print("\nFAIL — the live RPC is not serving what the app decodes:", file=sys.stderr)
    for p in problems:
        print(f"  • {p}", file=sys.stderr)
    print("\nThese decode as nil in Swift, so the features silently stop existing.\n"
          "Fix: backend/restore_catalog_keys.sql (refreshes the core, then rewraps places).\n"
          "🔴 Do NOT just re-run places_apply.sql — it would rewrap a stale core.",
          file=sys.stderr)
    sys.exit(1)

if not QUIET:
    print("\nPASS — every key the app decodes is being served.")
