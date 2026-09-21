#!/usr/bin/env python3
"""Two entries with the SAME NAME in the SAME CITY, sitting in different places.

WHY
---
`check-place-candidates.py` asks the opposite question — which entries are close
enough together to be one place. Nothing asked the inverse: **we call these two
things by the same name, so why are they 300 metres apart?**

The signal is strong because agreement is the overwhelming norm. Measured on the
catalogue of 2026-09-21: **164 same-name-same-city groups, 158 of them within
100 m.** A disagreement is a real question about one of six, not noise.

🔴 IT IS A QUESTION, NEVER A VERDICT, and the six known cases show exactly why a
distance cannot decide it:

  * **Cheonggyecheon** (Seoul), 5,132 m — an eleven-kilometre stream. Two pins
    at different points along it are both right.
  * **All'Antico Vinaio** (Florence), 1,150 m — a sandwich shop with more than
    one branch. Two names, two real places.
  * **The Barbican** (London), 149 m — one estate, big enough to hold both.
  * **Walden 7**, 335 m — three entries, two agreeing with each other AND with
    Wikidata, one off on its own. That one is a real question.
  * Two groups whose "name" is a creator's boilerplate CAPTION repeated across
    different restaurants — a titling defect, not a coordinate one, and the
    reason caption-shaped titles are flagged separately below.

So an extended site and a chain legitimately span, and the tool says so rather
than pretending otherwise.
"""
import argparse
import collections
import importlib.util
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")
sys.path.insert(0, HERE)
import runstamp  # noqa: E402

# Under this, two entries of one name are simply the same spot.
AGREE_M = 100.0


def _load(name, filename):
    path = os.path.join(HERE, filename)
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_cpc = _load("_place_candidates", "check-place-candidates.py")
display_stem = _cpc.display_stem
marker = _cpc.marker


def entries(catalog):
    return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])


def entry_marker(entry):
    """The stop with `order == 0`, falling back to the only stop it has."""
    found = marker(entry)
    if found is not None:
        return found
    stops = entry.get("stops") or []
    if stops:
        return (stops[0]["latitude"], stops[0]["longitude"])
    return None


def metres(a, b):
    """Equirectangular, which is exact enough well under the earth's curvature.

    🔴 Longitude is scaled by cos(latitude) — without it every distance outside
    the tropics is overstated, and in Reykjavík by a factor of two.
    """
    dlat = (a[0] - b[0]) * 111_320.0
    dlon = (a[1] - b[1]) * 111_320.0 * math.cos(math.radians(a[0]))
    return math.hypot(dlat, dlon)


def captionish(title):
    """Is this a creator's caption rather than a name?

    A repeated caption produces a same-name group that is a TITLING defect, not
    a coordinate one, and the two have different fixes. Saying which is which is
    the difference between a useful report and a confusing one.
    """
    text = (title or "").strip()
    if not text:
        return False
    return (text.endswith("…") or len(text) > 45 or text.count(" ") > 7
            or "#" in text or text.rstrip().endswith(("!", "?")))


def groups(catalog):
    """Key on the display stem and the city, so bilingual tails do not split a
    group and two cities' identically named venues do not merge into one."""
    out = collections.defaultdict(list)
    for entry in entries(catalog):
        at = entry_marker(entry)
        if at is None:
            continue
        stem = display_stem(entry.get("title") or "").strip().lower()
        if not stem:
            continue
        out[(stem, (entry.get("city") or "").strip().lower())].append((entry, at))
    return out


def spread(members):
    """The widest gap in the group — not the distance to a centroid.

    🔴 A centroid would hide the case this tool exists for: two entries agreeing
    exactly and a third far away pulls the centroid toward itself, shrinking
    every measured distance and softening the outlier into the pack.
    """
    return max((metres(a[1], b[1]) for a in members for b in members), default=0.0)


def findings(catalog, agree_m=AGREE_M):
    out = []
    for (stem, city), members in groups(catalog).items():
        if len(members) < 2:
            continue
        span = spread(members)
        if span <= agree_m:
            continue
        out.append({
            "stem": stem, "city": city, "span_m": span, "members": members,
            "caption": any(captionish(e.get("title")) for e, _ in members),
        })
    return sorted(out, key=lambda row: -row["span_m"])


def report(catalog, rows, agree_m=AGREE_M):
    total = sum(1 for m in groups(catalog).values() if len(m) > 1)
    agreed = total - len(rows)
    makers = {m["id"]: m.get("displayName") or m["id"]
              for m in (catalog.get("makers") or [])}
    print(f"{total} name(s) used by 2+ entries in one city · "
          f"{agreed} agree within {agree_m:.0f} m · {len(rows)} do not\n")
    for row in rows:
        flag = "  ⚠️ CAPTION TITLE — a titling defect, not a coordinate one" if row["caption"] else ""
        print(f"  {row['span_m']:8.0f} m  {row['stem'][:44]:44} "
              f"{row['city'][:16]:16} ({len(row['members'])} entries){flag}")
        for entry, at in sorted(row["members"], key=lambda m: m[1]):
            print(f"              {makers.get(entry.get('makerId'), '?')[:26]:26} "
                  f"{at[0]:.5f},{at[1]:.5f}")
    if rows:
        print("\n⚠️  NOT a verdict. An extended site (a stream, a long street) and a "
              "chain with\n    two branches BOTH span legitimately — read the subject "
              "before the number.\n    What is worth acting on is a group where most "
              "members agree and one does not.")
    return len(rows)


def selftest():
    fails = []

    def check(name, ok):
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    def pin(pid, title, lat, lon, city="C"):
        return {"id": pid, "title": title, "city": city, "kind": "link",
                "stops": [{"order": 0, "latitude": lat, "longitude": lon}]}

    check("longitude is scaled by latitude",
          abs(metres((60.0, 0.0), (60.0, 1.0)) - 111_320.0 * math.cos(math.radians(60))) < 1.0)
    check("an unscaled longitude would be about twice that",
          metres((60.0, 0.0), (60.0, 1.0)) < 111_320.0 * 0.6)

    # 🔴 The case the tool exists for: two agree, one does not.
    cat = {"tours": [], "linkPins": [
        pin("a", "Walden 7", 41.380313, 2.067813),
        pin("b", "Walden 7", 41.380313, 2.067813),
        pin("c", "Walden 7", 41.382767, 2.070142)]}
    rows = findings(cat)
    check("🔴 two agreeing and one outlier is reported", len(rows) == 1)
    check("the span is the widest gap, about 335 m",
          330 < rows[0]["span_m"] < 345)
    # 🔴 A centroid would shrink this; the widest gap must not.
    check("🔴 the outlier is measured against the PACK, not a centroid pulled "
          "toward it", rows[0]["span_m"] > metres((41.380313, 2.067813), (41.3815, 2.0690)))

    same = {"tours": [], "linkPins": [
        pin("a", "Fuhang Soy Milk", 25.0, 121.0),
        pin("b", "Fuhang Soy Milk", 25.0003, 121.0003)]}
    check("two entries on one spot are not a finding", findings(same) == [])
    check("a lone entry is never a group",
          findings({"tours": [], "linkPins": [pin("a", "Alone", 1.0, 2.0)]}) == [])

    # Same name, DIFFERENT city, is two different venues — never one group.
    cross = {"tours": [], "linkPins": [
        pin("a", "Central Station", 52.0, 4.0, city="Amsterdam"),
        pin("b", "Central Station", 51.0, 4.0, city="Antwerp")]}
    check("🔴 the same name in two cities is not a group",
          findings(cross) == [])

    # A bilingual tail must not split a group — display_stem is shared with
    # check-place-candidates.py so all three tools agree on what a name is.
    bi = {"tours": [], "linkPins": [
        pin("a", "Cheonggyecheon", 37.57229, 127.03673),
        pin("b", "Cheonggyecheon | 청계천", 37.56982, 126.97865)]}
    check("🔴 a bilingual tail does not split a group", len(findings(bi)) == 1)

    # Tours and pins are one population: the Walden 7 case is a tour and a pin.
    mixed = {"tours": [pin("t", "Walden 7", 41.380313, 2.067813)],
             "linkPins": [pin("p", "Walden 7", 41.382767, 2.070142)]}
    check("🔴 a tour and a pin form a group together", len(findings(mixed)) == 1)

    check("a caption title is flagged as a titling defect",
          findings({"tours": [], "linkPins": [
              pin("a", "Here’s another @michelinguide spot you have to try! This…", 22.98, 120.21),
              pin("b", "Here’s another @michelinguide spot you have to try! This…", 22.99, 120.19)]}
          )[0]["caption"])
    check("a plain name is not flagged as a caption",
          not findings(cat)[0]["caption"])
    check("captionish: a short venue name is a name", not captionish("Fuhang Soy Milk"))
    check("captionish: a truncated caption is not", captionish("This bookstore in Chengdu is absolutely surr…"))
    check("captionish: a hashtag gives it away", captionish("Luce Chapel #taiwan"))
    check("captionish: an empty title is neither", not captionish(""))

    check("an entry with no stops is skipped, not crashed on",
          findings({"tours": [], "linkPins": [
              {"id": "x", "title": "T", "city": "C", "stops": []},
              pin("b", "T", 1.0, 2.0)]}) == [])
    check("a stop numbered other than 0 is still read",
          entry_marker({"stops": [{"order": 7, "latitude": 1.0, "longitude": 2.0}]}) == (1.0, 2.0))
    check("an untitled entry is skipped",
          findings({"tours": [], "linkPins": [pin("a", "", 1.0, 2.0), pin("b", "", 1.0, 3.0)]}) == [])
    check("the agree threshold is honoured",
          findings(same, agree_m=0.0) != [])

    total = 20
    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — {total - len(fails)}/{total}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--agree-m", type=float, default=AGREE_M,
                    help="at or under this, two entries of one name are one spot")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        with open(a.catalog, encoding="utf-8") as fh:
            catalog = json.load(fh)
        rows = findings(catalog, a.agree_m)
        n = report(catalog, rows, a.agree_m)
        if n:
            print(f"\n{n} name(s) to read")
            return 1
        print("\nOK — every repeated name in a city sits in one place")
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
