#!/usr/bin/env python3
"""Decide WHO is wrong when our coordinate and Wikidata's disagree.

WHY
---
`spine-match.py` reports 92 entries whose coordinate is not where Wikidata says
the subject is. That is a finding, not a verdict: **a gazetteer can be the wrong
one.** Of five sampled by hand, two were Wikidata's error and two were a
different place of the same name — only a minority were ours.

The failure mode is specific and common: the lookup is bounded to 100 km of our
own coordinate, so a name like "Hōrin-ji Temple", "Old City Hall" or "Santa
Maria" matches A REAL ENTITY OF THAT NAME THAT IS NOT OURS. Moving our pin onto
it would take a correct coordinate and break it.

THE DISCRIMINATOR
-----------------
The catalogue knows where its own cities are. For an entry in city C, take the
MEDIAN coordinate of every OTHER entry we carry in C, and measure both
candidates against it:

    ours near the cluster, theirs far   -> Wikidata matched something else
    ours far, theirs near the cluster   -> OUR coordinate is wrong
    both near / both far / no cluster   -> undecidable here; a human looks

🔴 MEDIAN, never mean: one pin 200 km out would drag a mean and quietly invert
the answer for every other entry in that city.

⚠️ **"Both far" is a real and legitimate case, not a bug.** The Cu Chi Tunnels
genuinely sit ~40 km from central Ho Chi Minh City, so distance from the city
centre proves nothing there. Those are reported UNDECIDED, never auto-fixed.

⚠️ This tool decides WHO IS WRONG. It does not move anything: a coordinate is
the defect that makes a tour silently never fire, and CLAUDE.md rule 8d forbids
moving a pin on a district-centroid distance. Its output is evidence for a fix
made deliberately, one at a time.
"""
import argparse
import collections
import gzip
import json
import math
import os
import re
import statistics
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import runstamp  # noqa: E402

CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")
LOOKUPS = os.path.join(REPO, "spine", "lookups.json.gz")
ADMIN = os.path.join(REPO, "checks", "spine-admin.json.gz")

AGREE_M = 500.0      # at or under this, our coordinate and Wikidata's agree
MIN_CLUSTER = 3      # fewer than this and the city median means nothing
RATIO = 3.0          # one side must be this many times closer to decide


def metres(lat1, lon1, lat2, lon2):
    return math.hypot((lat1 - lat2) * 111_320.0,
                      (lon1 - lon2) * 111_320.0 * math.cos(math.radians(lat1)))


def city_clusters(entries):
    """city -> [(lat, lon, id)] for every entry we carry there."""
    out = collections.defaultdict(list)
    for e in entries:
        stop = (e.get("stops") or [{}])[0]
        if e.get("city") and stop.get("latitude") is not None:
            out[e["city"]].append((stop["latitude"], stop["longitude"],
                                   (e.get("id") or "").upper()))
    return out


# 🔴 What Wikidata SAYS the thing is. A kilometre means nothing for a tram
# system, a towpath, an island or a conservation district -- a coordinate for
# one of those is a label anchor, not a location, and "disagreeing" by 1.5 km
# is the normal condition rather than a defect. The Hong Kong Tram runs 13 km.
EXTENDED_WORDS = (
    "system", "network", "route", "line", "service", "district", "neighborhood",
    "neighbourhood", "quarter", "area", "region", "island", "park", "garden",
    "cemetery", "campus", "towpath", "canal", "river", "street", "avenue",
    "boulevard", "trail", "range", "beach", "lake", "valley", "mountain",
    "reserve", "forest", "estate", "complex", "chain", "railway", "tramway",
    "cable car", "gondola", "airport", "tunnels", "walk of fame",
    "waterway", "promenade", "boulevard", "harbour", "harbor", "bay",
)


def extent(description):
    """EXTENDED if Wikidata describes something that is not a point."""
    d = (description or "").lower()
    return "EXTENDED" if any(w in d for w in EXTENDED_WORDS) else "POINT"


def same_municipality(our_city, wd_admin):
    """Does Wikidata place this entity in the city we file it under?

    🔴 This beats distance. Casa Costa sat 2.85x -- just inside the ratio, so
    UNDECIDED -- while Wikidata plainly said "a building in Sant Just Desvern"
    and ours is Barcelona's. The gazetteer states the municipality; use it.
    """
    if not our_city or not wd_admin:
        return None
    def key(text):
        # 🔴 Strip the combining marks FIRST. Running the regex first turns the
        # mark into a SPACE, so "Zürich" became "zu rich" and never matched
        # "Zurich" -- the same accent trap this repo has now paid for twice.
        t = unicodedata.normalize("NFKD", text.lower())
        t = "".join(c for c in t if not unicodedata.combining(c))
        return " ".join(re.sub(r"[^a-z0-9 ]", " ", t).split())
    return key(our_city) == key(wd_admin)


def verdict(ours_m, theirs_m, ratio=RATIO):
    """Who is wrong, given each side's distance to the city cluster."""
    if ours_m is None or theirs_m is None:
        return "UNDECIDED"
    if theirs_m > ours_m * ratio:
        return "WIKIDATA-ELSEWHERE"      # their match is a different place
    if ours_m > theirs_m * ratio:
        return "OURS-WRONG"
    return "UNDECIDED"                   # both near, or both far


def triage(lookups, catalog, agree_m=AGREE_M, min_cluster=MIN_CLUSTER, admin=None):
    entries = list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])
    by_id = {(e.get("id") or "").upper(): e for e in entries}
    clusters = city_clusters(entries)

    rows = []
    for key, rec in lookups.items():
        cands = rec.get("candidates") or []
        if not cands:
            continue
        best = min(cands, key=lambda c: c["distance_m"])
        if best["distance_m"] <= agree_m:
            continue
        entry = by_id.get(key.upper())
        if not entry:
            continue
        olat, olon = rec["at"]
        pts = [(a, b) for a, b, i in clusters.get(entry.get("city"), [])
               if i != key.upper()]
        if len(pts) >= min_cluster:
            clat = statistics.median(p[0] for p in pts)
            clon = statistics.median(p[1] for p in pts)
            ours = metres(olat, olon, clat, clon)
            theirs = metres(best["lat"], best["lon"], clat, clon)
        else:
            ours = theirs = None
        rows.append({
            "id": key, "title": entry.get("title"), "city": entry.get("city"),
            "gap_m": round(best["distance_m"]),
            "ours_to_cluster_m": None if ours is None else round(ours),
            "theirs_to_cluster_m": None if theirs is None else round(theirs),
            "cluster_n": len(pts), "wikidata_label": best["label"],
            "qid": best.get("qid"), "sitelinks": best.get("sitelinks"),
            "n_candidates": len(cands),
            "our_coord": [olat, olon],
            "their_coord": [best["lat"], best["lon"]],
            "verdict": verdict(ours, theirs),
        })
        info = (admin or {}).get(key) or {}
        row = rows[-1]
        row["wd_desc"] = info.get("desc", "")
        row["wd_admin"] = info.get("admin", "")
        row["extent"] = extent(row["wd_desc"]) if row["wd_desc"] else ""
        row["same_city"] = same_municipality(entry.get("city"), row["wd_admin"])
        # 🔴 Two signals OVERRIDE the distance ratio, because each is a
        # statement of fact rather than an inference from geometry.
        if row["verdict"] == "UNDECIDED":
            if row["same_city"] is False:
                row["verdict"] = "WIKIDATA-ELSEWHERE"
            elif row["extent"] == "EXTENDED":
                row["verdict"] = "EXTENDED-FEATURE"
    rows.sort(key=lambda r: -r["gap_m"])
    return rows


def selftest():
    ran = failed = 0

    def check(label, ok):
        nonlocal ran, failed
        ran += 1
        if not ok:
            failed += 1
            print(f"  FAIL {label}")

    check("their match far from the city is Wikidata's error",
          verdict(500, 50_000) == "WIKIDATA-ELSEWHERE")
    check("our point far from the city is ours",
          verdict(50_000, 500) == "OURS-WRONG")
    check("both near the city is undecided",
          verdict(800, 900) == "UNDECIDED")
    # 🔴 Cu Chi: genuinely ~40 km out, and Wikidata agrees it is out there.
    check("both FAR from the centre is undecided, not a finding",
          verdict(48_000, 36_000) == "UNDECIDED")
    check("no cluster means undecided", verdict(None, None) == "UNDECIDED")
    check("a missing side means undecided", verdict(100, None) == "UNDECIDED")
    check("exactly at the ratio does not decide", verdict(300, 900) == "UNDECIDED")
    check("just past the ratio decides", verdict(300, 901) == "WIKIDATA-ELSEWHERE")

    lk = {
        "A": {"at": [51.50, -0.12], "candidates": [
            {"distance_m": 90_000, "label": "The Elms", "lat": 52.3, "lon": -1.5,
             "qid": "Q1", "sitelinks": 2}]},
        "B": {"at": [26.95, 75.90], "candidates": [
            {"distance_m": 11_900, "label": "Govind Dev Ji", "lat": 26.92, "lon": 75.82,
             "qid": "Q2", "sitelinks": 9}]},
        "C": {"at": [51.50, -0.12], "candidates": [
            {"distance_m": 40.0, "label": "Near Enough", "lat": 51.5001, "lon": -0.1201,
             "qid": "Q3", "sitelinks": 4}]},
        "D": {"at": [51.50, -0.12], "candidates": []},
    }
    def london(lat, lon, i):
        return {"id": i, "city": "London", "title": i,
                "stops": [{"latitude": lat, "longitude": lon}]}
    cat = {"tours": [
        london(51.50, -0.12, "A"), london(51.501, -0.121, "X"),
        london(51.499, -0.119, "Y"), london(51.502, -0.122, "Z"),
        london(51.498, -0.118, "W"),
        {"id": "B", "city": "Jaipur", "title": "B",
         "stops": [{"latitude": 26.95, "longitude": 75.90}]},
        {"id": "J1", "city": "Jaipur", "title": "J1",
         "stops": [{"latitude": 26.92, "longitude": 75.82}]},
        {"id": "J2", "city": "Jaipur", "title": "J2",
         "stops": [{"latitude": 26.921, "longitude": 75.821}]},
        {"id": "J3", "city": "Jaipur", "title": "J3",
         "stops": [{"latitude": 26.919, "longitude": 75.819}]},
        london(51.50, -0.12, "C"), london(51.50, -0.12, "D"),
    ], "linkPins": []}
    rows = triage(lk, cat)
    got = {r["id"]: r["verdict"] for r in rows}
    check("a far Wikidata match is flagged as theirs",
          got.get("A") == "WIKIDATA-ELSEWHERE")
    check("🔴 our outlier against its own city is flagged as OURS",
          got.get("B") == "OURS-WRONG")
    check("an agreeing row is not a finding at all", "C" not in got)
    check("an entry with no candidates is skipped", "D" not in got)

    # A city with too few other entries cannot be judged.
    thin = {"tours": [
        {"id": "T", "city": "Nowhere", "title": "T",
         "stops": [{"latitude": 1.0, "longitude": 1.0}]}], "linkPins": []}
    rows = triage({"T": {"at": [1.0, 1.0], "candidates": [
        {"distance_m": 9_000, "label": "x", "lat": 1.08, "lon": 1.0,
         "qid": "Q9", "sitelinks": 1}]}}, thin)
    check("a city with no cluster is UNDECIDED, never auto-judged",
          rows and rows[0]["verdict"] == "UNDECIDED")

    # --- 🔴 One fixture per guard, each isolating ONE rule. A realistic city
    # exercises none of them: a tight cluster makes mean and median agree, a
    # single candidate makes min/max agree, and a well-placed entry makes
    # self-exclusion invisible. The mutation harness caught all five.

    # MEDIAN vs MEAN: four tight neighbours plus ONE 200 km outlier. The median
    # ignores the outlier; the mean is dragged far enough to flip the verdict.
    drag = {"tours": [
        {"id": "M", "city": "Dragville", "title": "M",
         "stops": [{"latitude": 10.0, "longitude": 10.0}]},
        *[{"id": f"D{i}", "city": "Dragville", "title": f"D{i}",
           "stops": [{"latitude": 10.0 + i * 1e-4, "longitude": 10.0}]}
          for i in range(4)],
        {"id": "OUT", "city": "Dragville", "title": "OUT",
         "stops": [{"latitude": 11.8, "longitude": 10.0}]},
    ], "linkPins": []}
    rows = triage({"M": {"at": [10.0, 10.0], "candidates": [
        {"distance_m": 60_000, "label": "x", "lat": 10.54, "lon": 10.0,
         "qid": "Q1", "sitelinks": 1}]}}, drag)
    check("🔴 one far neighbour does not drag the city (median, not mean)",
          rows and rows[0]["verdict"] == "WIKIDATA-ELSEWHERE")

    # SELF-EXCLUSION: the entry is itself a far outlier, and the only other
    # entries are tight. Counting itself pulls the median toward it and hides
    # that it is the odd one out.
    selfish = {"tours": [
        {"id": "S", "city": "Selfville", "title": "S",
         "stops": [{"latitude": 20.20, "longitude": 20.0}]},
        *[{"id": f"N{i}", "city": "Selfville", "title": f"N{i}",
           "stops": [{"latitude": 20.0 + i * 1e-4, "longitude": 20.0}]}
          for i in range(3)],
    ], "linkPins": []}
    rows = triage({"S": {"at": [20.20, 20.0], "candidates": [
        {"distance_m": 22_000, "label": "x", "lat": 20.0, "lon": 20.0,
         "qid": "Q2", "sitelinks": 5}]}}, selfish)
    check("🔴 an entry is not measured against itself",
          rows and rows[0]["verdict"] == "OURS-WRONG")

    # MIN_CLUSTER: two neighbours is not a city. With the floor removed this
    # would decide on almost no evidence.
    thin2 = {"tours": [
        {"id": "P", "city": "Thinby", "title": "P",
         "stops": [{"latitude": 30.0, "longitude": 30.0}]},
        {"id": "Q", "city": "Thinby", "title": "Q",
         "stops": [{"latitude": 30.001, "longitude": 30.0}]},
        {"id": "R", "city": "Thinby", "title": "R",
         "stops": [{"latitude": 30.002, "longitude": 30.0}]},
    ], "linkPins": []}
    rows = triage({"P": {"at": [30.0, 30.0], "candidates": [
        {"distance_m": 40_000, "label": "x", "lat": 30.36, "lon": 30.0,
         "qid": "Q3", "sitelinks": 1}]}}, thin2)
    check("two neighbours is below the floor, so UNDECIDED",
          rows and rows[0]["verdict"] == "UNDECIDED")

    # NEAREST candidate: a second, far candidate must not be the one compared.
    multi = {"tours": [
        {"id": "C2", "city": "Multiton", "title": "C2",
         "stops": [{"latitude": 40.0, "longitude": 40.0}]},
        *[{"id": f"K{i}", "city": "Multiton", "title": f"K{i}",
           "stops": [{"latitude": 40.0 + i * 1e-4, "longitude": 40.0}]}
          for i in range(3)],
    ], "linkPins": []}
    rows = triage({"C2": {"at": [40.0, 40.0], "candidates": [
        {"distance_m": 2_000, "label": "near", "lat": 40.018, "lon": 40.0,
         "qid": "Qa", "sitelinks": 3},
        {"distance_m": 90_000, "label": "far", "lat": 40.81, "lon": 40.0,
         "qid": "Qb", "sitelinks": 3}]}}, multi)
    check("the NEAREST candidate is the one judged",
          rows and rows[0]["wikidata_label"] == "near")

    # LONGITUDE SCALING: at 60°N a degree of longitude is half a degree of
    # latitude on the ground. Unscaled, this row's distances double and the
    # verdict flips.
    check("🔴 longitude is scaled by latitude",
          abs(metres(60.0, 0.0, 60.0, 1.0) - 55_700) < 2_000)

    check("a tram SYSTEM is an extended feature",
          extent("tram system in Hong Kong") == "EXTENDED")
    check("a towpath is extended", extent("towpath along Naviglio Grande") == "EXTENDED")
    check("a conservation DISTRICT is extended",
          extent("heritage conservations district in Toronto") == "EXTENDED")
    check("🔴 a skyscraper is a POINT and stays a finding",
          extent("residential skyscraper in Benidorm") == "POINT")
    check("a museum is a point", extent("museum in Dubai") == "POINT")
    check("a waterway is extended",
          extent("waterway in Ho Chi Minh City, Vietnam") == "EXTENDED")
    check("no description means no extent claim", extent("") == "POINT")

    check("the same municipality is recognised",
          same_municipality("Barcelona", "Barcelona") is True)
    check("🔴 a DIFFERENT municipality is recognised",
          same_municipality("Barcelona", "Sant Just Desvern") is False)
    check("accents do not break the comparison",
          same_municipality("Zurich", "Zürich") is True)
    check("a missing side yields no claim",
          same_municipality("Barcelona", "") is None)

    # The two signals must OVERRIDE an undecided distance verdict.
    # ⚠️ Both sides must sit a SIMILAR distance from the cluster, or the
    # distance rule decides on its own and the override under test never runs.
    lk2 = {"E": {"at": [1.0, 1.0], "candidates": [
        {"distance_m": 1500, "label": "x", "lat": 1.0135, "lon": 1.0,
         "qid": "Q7", "sitelinks": 3}]}}
    cat2 = {"tours": [
        {"id": "E", "city": "Hong Kong", "title": "Tram",
         "stops": [{"latitude": 1.0, "longitude": 1.0}]},
        *[{"id": f"H{i}", "city": "Hong Kong", "title": f"H{i}",
           "stops": [{"latitude": 1.0068 + i * 1e-4, "longitude": 1.0}]}
          for i in range(3)]], "linkPins": []}
    r2 = triage(lk2, cat2, admin={"E": {"desc": "tram system in Hong Kong",
                                        "admin": "Hong Kong"}})
    check("🔴 an EXTENDED feature is reclassified out of UNDECIDED",
          r2 and r2[0]["verdict"] == "EXTENDED-FEATURE")
    r3 = triage(lk2, cat2, admin={"E": {"desc": "building in Elsewhere",
                                        "admin": "Elsewhere"}})
    check("🔴 a different municipality overrides an undecided distance",
          r3 and r3[0]["verdict"] == "WIKIDATA-ELSEWHERE")
    r4 = triage(lk2, cat2, admin={})
    check("with no cached description the verdict is untouched",
          r4 and r4[0]["verdict"] == "UNDECIDED")

    # 🔴 The overrides must apply ONLY to UNDECIDED. A real OURS-WRONG row
    # that happens to carry an "extended" description, or a Wikidata admin we
    # do not recognise, must NOT be reclassified out of the queue -- that
    # would bury the only findings worth acting on.
    lk5 = {"F": {"at": [2.0, 2.0], "candidates": [
        {"distance_m": 40_000, "label": "x", "lat": 2.36, "lon": 2.0,
         "qid": "Q8", "sitelinks": 9}]}}
    cat5 = {"tours": [
        {"id": "F", "city": "Faraway", "title": "F",
         "stops": [{"latitude": 2.0, "longitude": 2.0}]},
        *[{"id": f"G{i}", "city": "Faraway", "title": f"G{i}",
           "stops": [{"latitude": 2.36 + i * 1e-4, "longitude": 2.0}]}
          for i in range(3)]], "linkPins": []}
    r5 = triage(lk5, cat5, admin={"F": {"desc": "park in Faraway",
                                        "admin": "Somewhere Else"}})
    check("🔴 an OURS-WRONG row is never buried by an override",
          r5 and r5[0]["verdict"] == "OURS-WRONG")

    print(f"selftest {ran - failed}/{ran} passed")
    return 1 if failed else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--lookups", default=LOOKUPS)
    ap.add_argument("--verdict", choices=("OURS-WRONG", "WIKIDATA-ELSEWHERE",
                                          "EXTENDED-FEATURE", "UNDECIDED"))
    ap.add_argument("--admin", default=ADMIN)
    ap.add_argument("--json", metavar="PATH")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        for path in (a.catalog, a.lookups):
            if not os.path.exists(path):
                print(f"COULD NOT VERIFY — missing {path}")
                return 2
        with open(a.catalog, encoding="utf-8") as fh:
            catalog = json.load(fh)
        with gzip.open(a.lookups, "rt", encoding="utf-8") as fh:
            lookups = json.load(fh)

        admin = {}
        if os.path.exists(a.admin):
            with gzip.open(a.admin, "rt", encoding="utf-8") as fh:
                admin = json.load(fh)
        rows = triage(lookups, catalog, admin=admin)
        counts = collections.Counter(r["verdict"] for r in rows)
        print(f"{len(rows)} entries disagree with Wikidata by more than {AGREE_M:.0f} m\n")
        for name in ("OURS-WRONG", "WIKIDATA-ELSEWHERE", "EXTENDED-FEATURE",
                     "UNDECIDED"):
            print(f"  {name:<20} {counts[name]:>4}")
        if a.verdict:
            print()
            for i, r in enumerate([r for r in rows if r["verdict"] == a.verdict], 1):
                print(f"{i:3d}. {(r['title'] or '')[:52]}  [{r['city']}]")
                print(f"      gap {r['gap_m']} m · ours→city {r['ours_to_cluster_m']} · "
                      f"theirs→city {r['theirs_to_cluster_m']} · n={r['cluster_n']}")
                print(f"      wikidata: {r['wikidata_label']} ({r['qid']}, "
                      f"{r['sitelinks']} sitelinks)")
        if a.json:
            with open(a.json, "w", encoding="utf-8") as fh:
                json.dump(rows, fh, indent=1, ensure_ascii=False)
            print(f"\nwrote {a.json}")
        return 1 if counts["OURS-WRONG"] else 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
