#!/usr/bin/env python3
"""Merge `make-link-pin.py`'s output into `Tours.json` without it passing
through a conversation.

    python3 scripts/make-link-pin.py --batch links.txt --out-dir /tmp/heroes > /tmp/pins.json
    python3 scripts/merge-link-pins.py /tmp/pins.json
    swift scripts/validate-tours.swift

WHY THIS EXISTS
---------------
`make-link-pin.py` prints the entry to stdout, which is right — it keeps the
tool pure and lets a human read one pin before committing to it. But a *batch*
merged that way costs the session twice: once to print the JSON and once to
paste it back in to write it. At ~1.9 KB of emitted JSON per pin that is
roughly 10,000 tokens for a batch of 20 — and, because a conversation re-sends
its whole history on every request, that block is then paid again on every
turn for the rest of the session.

Redirecting to a file and merging from the file costs none of it. The pins go
disk → disk; the session sees a summary of a few lines.

WHAT IT REFUSES TO DO
---------------------
🔴 It never writes into `tours`. A `kind: "link"` entry inside that array fails
the WHOLE catalog decode on every build shipped before `TourKind.link` — the
throw becomes a nil, the loader reads it as a failed fetch and keeps its last
good copy, so the phone silently stops receiving all new content. Pins go in
the sibling top-level `linkPins` array, which older builds simply skip. See
`TRAVEL GUIDED TOUR/Data/ToursData.swift` and `scripts/split-link-pins.py`.

🔴 It refuses a pin with no coordinate, or one at exactly (0, 0). That is the
one defect nothing downstream catches: it validates, it uploads, and it sits in
the Gulf of Guinea. `make-link-pin.py` guards its own input the same way; this
is the second gate, for a hand-edited pins file.

🔴 It refuses to write when `Tours.json` is not already byte-stable under
`indent=2, ensure_ascii=False` + trailing newline — otherwise a two-pin merge
would reformat 11 MB and bury the real change in the diff.

Idempotent. A pin whose id is already in the catalog is left alone rather than
duplicated, so re-running after a partial merge is safe. Ids are uuid5 over the
source URL, so the same post always lands on the same id.
"""

import argparse
import json
import os
import re
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402  (stamps every run; see scripts/runstamp.py)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOURS_JSON = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")


def dumps(data: dict) -> bytes:
    """Byte-for-byte the convention `split-link-pins.py` writes, so the two
    tools cannot fight over formatting."""
    return json.dumps(data, indent=2, ensure_ascii=False).encode() + b"\n"


def validate_incoming(payload: dict) -> list[str]:
    """Everything that must be true of a pins file. Pure, so `--selftest`
    covers it with no catalog and no disk."""
    problems = []

    stray = payload.get("tours")
    if stray:
        problems.append(
            f"the pins file has a `tours` array ({len(stray)} entries). Link pins "
            "belong in `linkPins`; an entry in `tours` breaks the catalog decode "
            "on older builds.")

    pins = payload.get("linkPins")
    if not pins:
        problems.append("the pins file has no `linkPins` array, or it is empty.")
        return problems

    for i, p in enumerate(pins):
        where = f"linkPins[{i}] {p.get('title') or p.get('id') or '?'!r}"
        if p.get("kind") != "link":
            problems.append(f"{where}: kind is {p.get('kind')!r}, expected 'link'.")
        if not p.get("id"):
            problems.append(f"{where}: no id.")
        if not p.get("sourceURL"):
            problems.append(f"{where}: no sourceURL — a link pin with nothing to open.")
        lat, lon = p.get("centroidLatitude"), p.get("centroidLongitude")
        if lat is None or lon is None:
            problems.append(f"{where}: no coordinate. It would validate, upload, "
                            "and never appear anywhere a person is standing.")
        elif lat == 0 and lon == 0:
            problems.append(f"{where}: coordinate is exactly (0, 0) — the Gulf of "
                            "Guinea, i.e. a missing coordinate that survived.")

    return problems


def slugify(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", (s or "").lower()).strip("-")


def derived_id(prefix: str, url: str, fragment: str = "") -> str:
    """The id scheme, in one place. uuid5 over NAMESPACE_URL, uppercased."""
    key = f"{prefix}:link:{url}" + (f"#{fragment}" if fragment else "")
    return str(uuid.uuid5(uuid.NAMESPACE_URL, key)).upper()


def expected_ids(pin: dict, siblings: list) -> tuple[str, str]:
    """(tour id, stop id) this pin should carry, given every pin sharing its URL.

    One post usually means one pin, and the bare key covers it. A post naming
    several places means several pins, disambiguated by city — and when two of
    them are in the SAME city, by city AND subject, because the city alone
    collides. That last case has twice been resolved by inventing a uuid on the
    spot, which nothing could see afterwards: a made-up id looks exactly like a
    derived one.
    """
    if len(siblings) < 2:
        frag = ""
    else:
        frag = slugify(pin.get("city"))
        if sum(1 for q in siblings if slugify(q.get("city")) == frag) > 1:
            frag = f"{frag}-{slugify(pin.get('title'))}"
    return derived_id("atlas-tour", pin.get("sourceURL", ""), frag), \
           derived_id("atlas-stop", pin.get("sourceURL", ""), frag)


def check_ids(payload: dict, catalog: dict) -> list[str]:
    """Every incoming id must be derivable. Grouping spans the catalog too: a
    pin can share its post with one that landed in an earlier batch."""
    incoming = payload.get("linkPins") or []
    # 🔴 Deduplicate by id before grouping. Re-merging a pin that is already in
    # the catalog otherwise counts it twice — the catalog copy and the incoming
    # copy look like two pins sharing one post, so a perfectly ordinary pin is
    # told its bare-key id should have carried a city fragment. That would break
    # the idempotence this tool exists to guarantee.
    groups, seen_ids = {}, set()
    for p in list(catalog.get("linkPins") or []) + incoming:
        pid = p.get("id")
        if pid in seen_ids:
            continue
        seen_ids.add(pid)
        groups.setdefault(p.get("sourceURL"), []).append(p)

    problems = []
    for p in incoming:
        sib = groups.get(p.get("sourceURL"), [p])
        want_t, want_s = expected_ids(p, sib)
        got_t = p.get("id")
        if got_t != want_t:
            problems.append(
                f"{p.get('title') or got_t!r}: id is {got_t}, but the scheme gives "
                f"{want_t}.\n      {len(sib)} pin(s) share this post"
                + (" — same city, so the key is #<city>-<title>"
                   if len(sib) > 1 and sum(1 for q in sib
                       if slugify(q.get('city')) == slugify(p.get('city'))) > 1
                   else "")
                + ".\n      Use the derived id: a hand-minted one cannot be "
                  "reproduced or checked later.")
        stops = p.get("stops") or []
        if stops and stops[0].get("id") != want_s:
            problems.append(
                f"{p.get('title') or got_t!r}: stop id is {stops[0].get('id')}, "
                f"but the scheme gives {want_s}.")
    return problems


def merge(catalog: dict, payload: dict) -> tuple[dict, dict]:
    """Return (catalog, report). Pure — no I/O, so `--selftest` exercises the
    real merge rather than an imitation of it.

    Order is preserved, existing rows are never rewritten, and anything already
    present is skipped rather than duplicated.
    """
    out = dict(catalog)
    pins = list(out.get("linkPins") or [])
    makers = list(out.get("makers") or [])

    have_pins = {p.get("id") for p in pins}
    have_makers = {m.get("id") for m in makers}

    added_pins, skipped_pins = [], []
    for p in payload.get("linkPins") or []:
        if p.get("id") in have_pins:
            skipped_pins.append(p)
        else:
            pins.append(p)
            have_pins.add(p.get("id"))
            added_pins.append(p)

    # A maker id is uuid5 over platform + lowercased handle, so a creator who
    # already has a row must keep it: theirs may carry edits (a corrected
    # display name, a bio) that this run's freshly-derived row would silently
    # revert.
    added_makers, kept_makers = [], []
    for m in payload.get("makers") or []:
        if m.get("id") in have_makers:
            kept_makers.append(m)
        else:
            makers.append(m)
            have_makers.add(m.get("id"))
            added_makers.append(m)

    out["makers"] = makers
    out["linkPins"] = pins
    report = {"added_pins": added_pins, "skipped_pins": skipped_pins,
              "added_makers": added_makers, "kept_makers": kept_makers}
    return out, report


def run(pins_path: str, catalog_path: str, write: bool) -> int:
    with open(pins_path, encoding="utf-8") as fh:
        payload = json.load(fh)

    problems = validate_incoming(payload)
    if problems:
        print(f"\nREFUSED — {len(problems)} problem(s) in {pins_path}. "
              "Nothing was written.")
        for p in problems:
            print(f"  - {p}")
        return 1

    raw = open(catalog_path, "rb").read()
    catalog = json.loads(raw)

    # If the catalog does not already round-trip, a 2-pin merge would rewrite
    # the whole file and hide itself in the diff. Refuse rather than explain.
    if dumps(catalog) != raw:
        print("\nREFUSED — Tours.json is not byte-stable under "
              "`indent=2, ensure_ascii=False` + trailing newline.\n"
              "  Merging would reformat the entire file and bury the pins in "
              "the diff.\n"
              "  Normalise it first, in its own commit, then merge.")
        return 1

    id_problems = check_ids(payload, catalog)
    if id_problems:
        print(f"\nREFUSED — {len(id_problems)} id(s) are not derivable from the "
              "scheme. Nothing was written.")
        for x in id_problems:
            print(f"  - {x}")
        print("\n  See docs/link-pin-runbook.md § the id scheme.")
        return 1

    merged, rep = merge(catalog, payload)

    n_in = len(payload.get("linkPins") or [])
    print(f"\n  pins in {os.path.basename(pins_path):<18} {n_in:>5}")
    print(f"  new pins added                    {len(rep['added_pins']):>5}")
    print(f"  already in catalog, skipped       {len(rep['skipped_pins']):>5}")
    print(f"  new creators added                {len(rep['added_makers']):>5}")
    print(f"  creators already present, kept    {len(rep['kept_makers']):>5}")
    print(f"  catalog linkPins {len(catalog.get('linkPins') or [])} → "
          f"{len(merged['linkPins'])}   ·   makers "
          f"{len(catalog.get('makers') or [])} → {len(merged['makers'])}")

    for m in rep["added_makers"]:
        print(f"    + creator {m.get('displayName')}")

    if not rep["added_pins"] and not rep["added_makers"]:
        print("\nOK — nothing to add; every pin is already in the catalog.")
        return 0

    if not write:
        print("\n--check: nothing written. Re-run without --check to merge.")
        return 0

    out = dumps(merged)
    tmp = catalog_path + ".tmp"
    with open(tmp, "wb") as fh:
        fh.write(out)
    os.replace(tmp, catalog_path)

    print(f"\nOK — merged into {catalog_path}")
    print("  Next: swift scripts/validate-tours.swift")
    print("        python3 scripts/check-image-duplicates.py --pins")
    print("        upload the heroes to gh-pages under images/")
    return 0


def selftest() -> int:
    cases, failed = [], 0

    def check(name, ok):
        nonlocal failed
        cases.append(name)
        if not ok:
            failed += 1
        print(f"  {'PASS' if ok else 'FAIL'}  {name}")

    def pin(pid, lat=41.4, lon=2.1, **kw):
        p = {"id": pid, "kind": "link", "title": f"pin {pid}",
             "sourceURL": f"https://example.com/{pid}",
             "centroidLatitude": lat, "centroidLongitude": lon}
        p.update(kw)
        return p

    cat = {"makers": [{"id": "M1", "displayName": "TikTok @a"}],
           "tours": [{"id": "T1"}], "places": [], "linkPins": [pin("P1")]}

    # The merge itself
    merged, rep = merge(cat, {"makers": [{"id": "M2", "displayName": "TikTok @b"}],
                              "linkPins": [pin("P2")]})
    check("a new pin is appended to linkPins",
          [p["id"] for p in merged["linkPins"]] == ["P1", "P2"])
    check("a new creator is appended to makers",
          [m["id"] for m in merged["makers"]] == ["M1", "M2"])
    check("`tours` is untouched", merged["tours"] == [{"id": "T1"}])
    check("the source catalog is not mutated in place",
          [p["id"] for p in cat["linkPins"]] == ["P1"])

    # Idempotence — the property that makes a re-run after a half-finished
    # merge safe rather than duplicating.
    once, _ = merge(cat, {"linkPins": [pin("P2")]})
    twice, rep2 = merge(once, {"linkPins": [pin("P2")]})
    check("re-merging the same pin adds nothing",
          [p["id"] for p in twice["linkPins"]] == ["P1", "P2"])
    check("a re-merged pin is reported as skipped, not added",
          len(rep2["skipped_pins"]) == 1 and not rep2["added_pins"])

    # An existing creator's row must survive: it may carry hand edits.
    edited = {"makers": [{"id": "M1", "displayName": "Corrected Name"}],
              "tours": [], "places": [], "linkPins": []}
    kept, rep3 = merge(edited, {"makers": [{"id": "M1", "displayName": "TikTok @a"}],
                                "linkPins": []})
    check("an existing creator row is kept, not overwritten",
          kept["makers"] == [{"id": "M1", "displayName": "Corrected Name"}]
          and len(rep3["kept_makers"]) == 1)

    # Everything the incoming file must not be
    check("a pins file with a `tours` array is refused",
          any("`tours` array" in p for p in
              validate_incoming({"tours": [pin("X")], "linkPins": [pin("Y")]})))
    check("an empty pins file is refused",
          validate_incoming({"linkPins": []}) != [])
    check("a pin with no coordinate is refused",
          any("no coordinate" in p for p in validate_incoming(
              {"linkPins": [pin("X", lat=None, lon=None)]})))
    check("a pin at exactly (0, 0) is refused",
          any("Gulf of Guinea" in p for p in validate_incoming(
              {"linkPins": [pin("X", lat=0, lon=0)]})))
    check("a pin at a real coordinate whose lon is 0 is NOT refused",
          validate_incoming({"linkPins": [pin("X", lat=51.5, lon=0.0)]}) == [])
    check("a pin with the wrong kind is refused",
          any("expected 'link'" in p for p in validate_incoming(
              {"linkPins": [pin("X", kind="audio")]})))
    check("a pin with no sourceURL is refused",
          any("nothing to open" in p for p in validate_incoming(
              {"linkPins": [dict(pin("X"), sourceURL=None)]})))
    check("a clean pins file passes", validate_incoming(
        {"makers": [], "linkPins": [pin("X")]}) == [])

    # One post can legitimately be several pins — a video naming several places.
    # Three live posts do this (10 pins). Their ids add `#<slug(city)>` to the
    # hashed key while `sourceURL` stays clean, so a shared sourceURL is NORMAL
    # and must never be mistaken for a duplicate.
    shared = [dict(pin("A"), sourceURL="https://x/p"),
              dict(pin("B"), sourceURL="https://x/p")]
    check("two pins sharing one sourceURL are valid",
          validate_incoming({"linkPins": shared}) == [])
    both, _ = merge({"makers": [], "tours": [], "places": [], "linkPins": []},
                    {"linkPins": shared})
    check("two pins sharing one sourceURL both merge",
          [p_["id"] for p_ in both["linkPins"]] == ["A", "B"])

    # The id scheme, checked against ids that are actually live.
    check("bare key reproduces a real single-post pin",
          derived_id("atlas-tour", "https://www.instagram.com/reel/DFxyNa9xMSm/")
          == "6192A9EC-C601-5145-A600-5F7E8FF6940E")
    check("bare key reproduces its stop id",
          derived_id("atlas-stop", "https://www.instagram.com/reel/DFxyNa9xMSm/")
          == "3C196CA4-53B3-5148-89F5-7089953B2501")
    check("city fragment reproduces a real multi-pin id",
          derived_id("atlas-tour", "https://www.instagram.com/reel/DWHSGzlEZSv/",
                     "vals")
          == "77C43772-4724-5EE3-B291-63FE7469BAEC")

    zum = "https://www.instagram.com/reel/DWHSGzlEZSv/"
    sibs = [{"sourceURL": zum, "city": "Vals", "title": "Therme Vals"},
            {"sourceURL": zum, "city": "Los Angeles", "title": "LACMA"},
            {"sourceURL": zum, "city": "Mechernich", "title": "Bruder Klaus"}]
    check("different cities -> the city key, matching the live id",
          expected_ids(sibs[0], sibs)[0] == "77C43772-4724-5EE3-B291-63FE7469BAEC")

    # The case that twice got an invented uuid instead.
    ed = "https://x/post"
    pair = [{"sourceURL": ed, "city": "Edinburgh", "title": "The Elephant House"},
            {"sourceURL": ed, "city": "Edinburgh", "title": "George Heriot's School"}]
    a, b = expected_ids(pair[0], pair)[0], expected_ids(pair[1], pair)[0]
    check("same city -> distinct ids (the gap this rule closes)", a != b)
    check("same city -> the key carries city AND subject",
          a == derived_id("atlas-tour", ed, "edinburgh-the-elephant-house"))
    check("a lone pin still uses the bare key",
          expected_ids(pair[0], [pair[0]])[0] == derived_id("atlas-tour", ed))

    # The check itself
    def mk(pid, url, city, title, sid=None):
        return {"id": pid, "kind": "link", "title": title, "sourceURL": url,
                "city": city, "centroidLatitude": 1.0, "centroidLongitude": 1.0,
                "stops": [{"id": sid or derived_id("atlas-stop", url)}]}
    good_url = "https://x/solo"
    good = mk(derived_id("atlas-tour", good_url), good_url, "Oslo", "A place")
    check("a derived pin passes the id check",
          check_ids({"linkPins": [good]}, {"linkPins": []}) == [])
    bad = dict(good, id="00000000-0000-0000-0000-000000000000")
    probs = check_ids({"linkPins": [bad]}, {"linkPins": []})
    check("a hand-minted id is refused", len(probs) == 1 and "the scheme gives" in probs[0])
    check("a wrong stop id is refused",
          any("stop id" in x for x in check_ids(
              {"linkPins": [dict(good, stops=[{"id": "DEAD"}])]}, {"linkPins": []})))

    # Grouping must span the catalog: a sibling can already be live.
    u = "https://x/two"
    live = mk(derived_id("atlas-tour", u, "leeds-first"), u, "Leeds", "First",
              derived_id("atlas-stop", u, "leeds-first"))
    new_pin = mk(derived_id("atlas-tour", u, "leeds-second"), u, "Leeds", "Second",
                 derived_id("atlas-stop", u, "leeds-second"))
    check("a sibling already in the catalog is counted when deriving",
          check_ids({"linkPins": [new_pin]}, {"linkPins": [live]}) == [])

    # 🔴 Re-merging an existing pin must not look like a two-pin post.
    solo_url = "https://x/solo2"
    solo = mk(derived_id("atlas-tour", solo_url), solo_url, "Porto", "Only pin")
    check("re-merging a pin already in the catalog still passes",
          check_ids({"linkPins": [solo]}, {"linkPins": [dict(solo)]}) == [])

    # The formatting contract shared with split-link-pins.py
    check("dumps writes indent=2, non-ASCII verbatim, trailing newline",
          dumps({"a": "café"}) == b'{\n  "a": "caf\xc3\xa9"\n}\n')

    total = len(cases)
    print(f"\n{total - failed}/{total} self-tests passed")
    return 1 if failed else 0


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("pins", nargs="?",
                    help="JSON file written by `make-link-pin.py > pins.json`")
    ap.add_argument("--catalog", default=TOURS_JSON,
                    help="Tours.json to merge into (default: the repo's)")
    ap.add_argument("--check", action="store_true",
                    help="report what would be merged; write nothing")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    runstamp.begin(__file__, out_path=a.out)

    if a.selftest:
        return selftest()
    if not a.pins:
        ap.error("give a pins file, or --selftest")
    return run(a.pins, a.catalog, write=not a.check)


if __name__ == "__main__":
    sys.exit(main())
