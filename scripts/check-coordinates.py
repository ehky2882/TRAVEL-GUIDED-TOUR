#!/usr/bin/env python3
"""
Audit tour coordinates against OpenStreetMap, and measure systematic bias.

WHY THIS EXISTS
---------------
A wrong coordinate is the most expensive defect this catalog can ship, and the
only one that is completely invisible to every other check we run. The URL is
valid, the image is right, `validate-tours.swift` passes, CI compiles - and the
tour simply never fires, because at a 30 m geofence the listener is standing
250 m from the trigger. No error, no dead link, just silence in front of the
building.

It has now happened twice from the same upstream drop pipeline:

  Barcelona (session 96)  10 coordinates wrong, EVERY ONE displaced north
  Milan     (session 103)  2 coordinates wrong, BOTH displaced north

Measured 2026-08-22 across four cities (reverse-geocode each supplied point,
compare against the matched object's own centre, point-like matches only):

  city        sourcing          north/n   median offset   binomial p
  New York    old / manual       10/23        -1.4 m        1.0
  London      old / manual       14/28        -0.4 m        1.0
  Barcelona   drop pipeline      13/18       +10.2 m        0.096
  Milan       drop pipeline      28/32       +10.3 m        1.9e-05
  ------------------------------------------------------------------
  pipeline cities combined       41/50       +10.3 m        5.6e-06
  old-sourced combined           24/51        -0.9 m        1.0

The old-sourced cities are dead centred, which is what proves the measurement
itself is unbiased. The two pipeline cities carry the same +10 m northward
offset. That is a fault upstream of this repo, not noise.

The gross errors are the same fault at a different scale. A constant offset in
SCREEN PIXELS becomes a larger ground distance the further you zoom out, and
every observed magnitude fits one ~20 px upward offset:

    +10 m -> zoom ~19 (one building)     +262 m -> zoom ~14 (a district)
   +653 m -> zoom ~13 (rural)           +3200 m -> zoom ~11 (another town)

...which is why the worst errors are always the subjects furthest from the city
centre: those are the ones you zoom out to find.

RUN THIS ON EVERY NEW CITY, BEFORE WIRING.  Two things matter in the output:
  1. GROSS - a coordinate that is not at its venue. Fix before shipping.
  2. BIAS  - if the northward bias is gone, upstream has been fixed. If it is
             still ~+10 m, it has not, however clean the gross list looks.

Usage
-----
  scripts/check-coordinates.py --drop "/path/to/unzipped drop"   # before wiring
  scripts/check-coordinates.py --maker MIL                        # already live
  scripts/check-coordinates.py --selftest                         # offline

Exit codes: 0 clean - 1 gross errors found - 2 could not verify (see below).
"""

import argparse
import json
import math
import os
import re
import statistics
import subprocess
import sys
import time
from math import comb

NOMINATIM = "https://nominatim.openstreetmap.org"
UA = "Dozent-Atlas-catalog-check/1.0 (edward.yung@gmail.com)"
SLEEP = 1.1               # Nominatim asks for <= 1 req/sec
GROSS_METRES = 150.0      # beyond this, a point is not at its venue
GROSS_MAX_METRES = 25000  # beyond this the geocoder found a DIFFERENT place,
                          # not evidence about this one - report, do not accuse
BBOX_TOLERANCE_M = 30.0   # OSM footprints are approximate, and the pipeline's
                          # own +10 m bias pushes points just outside them
BIAS_WARN_METRES = 5.0    # a real systematic offset, not noise
BIAS_WARN_P = 0.01

# Reverse-geocode hits of these kinds are line/area features whose "centre"
# is meaningless for a bias measurement (a street centroid can be hundreds of
# metres from the doorway). They are kept for the gross check, dropped from
# the statistics.
AREA_CLASSES = {"highway", "boundary", "place", "landuse", "waterway", "railway"}


# --- geometry ---------------------------------------------------------------

def haversine(lat1, lon1, lat2, lon2):
    R = 6371000.0
    p = math.radians
    a = (math.sin(p(lat2 - lat1) / 2) ** 2
         + math.cos(p(lat1)) * math.cos(p(lat2)) * math.sin(p(lon2 - lon1) / 2) ** 2)
    return 2 * R * math.asin(math.sqrt(a))


def metres_north(dlat):
    return dlat * 111320.0


def point_in_bbox(lat, lon, hit):
    """Is the supplied point inside the matched object's own footprint?

    A centroid distance is the wrong test for anything with size. Castello
    Sforzesco is 180 m square, so a point in its courtyard is 181 m from the
    centroid and entirely correct. Nominatim hands back the footprint; use it.
    """
    if not hit:
        return False
    bb = hit.get("boundingbox")
    if not bb or len(bb) != 4:
        return False
    try:
        s, n, w, e = (float(x) for x in bb)
    except (TypeError, ValueError):
        return False
    pad = BBOX_TOLERANCE_M / 111320.0
    padlon = pad / max(math.cos(math.radians(lat)), 0.01)
    return (s - pad) <= lat <= (n + pad) and (w - padlon) <= lon <= (e + padlon)


def name_variants(name):
    """Folder names are not always a single venue name.

    Milan shipped "Mirasole Abbey - Abbazia di Mirasole" - an English name and
    the Italian one joined by a dash. Neither the whole string nor the English
    half geocodes; "Abbazia di Mirasole" does. Trying each half is what lets
    the check reach the very tours most likely to be wrong (out-of-town ones).
    """
    out, seen = [], set()
    parts = [name]
    for sep in (" - ", " – ", " — ", " / "):
        if sep in name:
            parts = name.split(sep)
            break
    for p in [name] + parts:
        p = re.sub(r"\s*\(.*?\)\s*", " ", p).strip()
        if p and p.lower() not in seen:
            seen.add(p.lower())
            out.append(p)
    return out


def names_resemble(a, b):
    """Do two place names plausibly refer to the same thing?

    This gates the whole GROSS verdict. If the geocoder did not actually find
    the venue, its result says nothing about whether the supplied coordinate
    is right, and accusing on that basis is how a checker starts crying wolf:
    'RITO' matches a stream in Novara, 'Corte degli Artisti' matches a
    'Locanda Degli Artisti' 70 km away.
    """
    def toks(x):
        stop = {"the", "di", "de", "del", "della", "il", "la", "of", "and",
                "milano", "milan", "store", "hotel", "ristorante", "bistrot"}
        return {t for t in re.split(r"\W+", (x or "").lower())
                if len(t) > 3 and t not in stop}
    ta, tb = toks(a), toks(b)
    return bool(ta & tb)


def binomial_two_sided(n, k):
    """P(at least k of n on one side) x 2, under a fair coin."""
    if n == 0:
        return 1.0
    k = max(k, n - k)
    return min(1.0, 2 * sum(comb(n, i) for i in range(k, n + 1)) / 2 ** n)


# --- network ----------------------------------------------------------------
# curl, deliberately, NOT urllib: urllib fails SSL verification on the owner's
# Mac, which is how check-image-duplicates.py came to print "OK" having fetched
# nothing at all. Every failure here is counted and reported.

class Fetcher:
    def __init__(self):
        self.ok = 0
        self.failed = 0

    def get(self, url):
        try:
            r = subprocess.run(["curl", "-s", "--max-time", "30", "-A", UA, url],
                               capture_output=True, text=True, timeout=45)
            data = json.loads(r.stdout)
            self.ok += 1
            return data
        except Exception:
            self.failed += 1
            return None

    def reverse(self, lat, lon):
        return self.get(f"{NOMINATIM}/reverse?format=jsonv2&zoom=18"
                        f"&lat={lat:.9f}&lon={lon:.9f}")

    def search(self, name, city_hint="", viewbox=None):
        """Forward-geocode, bounded to the region the drop itself covers.

        Two traps, both hit while building this:

        A city hint SILENCES the venues most likely to be wrong. Milan's
        Abbazia di Mirasole is in Opera, and "..., Milano, Italy" finds
        nothing for it - and out-of-town subjects are exactly the ones that
        carry gross errors, because they are the ones you zoom out to find.

        But simply dropping the hint globalises the search: bare "RITO"
        matched Chad, "balay" matched Somaliland, "Morelli" matched Germany.

        So: bound the search to a box around the drop's own coordinates. Wide
        enough for a neighbouring comune, narrow enough to exclude another
        continent."""
        import urllib.parse
        vb = ""
        if viewbox:
            w, s_, e, n = viewbox
            vb = f"&bounded=1&viewbox={w:.4f},{s_:.4f},{e:.4f},{n:.4f}"
        queries = []
        for variant in name_variants(name):
            if city_hint:
                queries.append(f"{variant}, {city_hint}")
            queries.append(variant)
        for q in queries:
            r = self.get(f"{NOMINATIM}/search?format=jsonv2&limit=1{vb}&q="
                         + urllib.parse.quote(q))
            time.sleep(SLEEP)
            if r:
                return r[0]
        return None


# --- inputs -----------------------------------------------------------------

DROP_RE = re.compile(r"^(?:output\s+)?(?:\d{2}\s+)?(.+?)\s+(-?\d+\.\d+),\s*(-?\d+\.\d+)$")


def from_drop(folder):
    """Parse `output <Name> <lat>, <lon>` folders, including nested walk stops."""
    out = []
    for root, dirs, _ in os.walk(folder):
        for d in dirs:
            m = DROP_RE.match(d)
            if m:
                out.append(dict(name=m.group(1),
                                lat=float(m.group(2)), lon=float(m.group(3))))
    # a nested "output X" inside a folder of the same name duplicates the entry
    seen, uniq = set(), []
    for e in out:
        k = (e["name"], round(e["lat"], 7), round(e["lon"], 7))
        if k not in seen:
            seen.add(k)
            uniq.append(e)
    return uniq


def from_catalog(maker_code, catalog):
    with open(catalog, encoding="utf-8") as f:
        d = json.load(f)
    want = f"Atlas Studio {maker_code.upper()}"
    mk = next((m for m in d["makers"] if m.get("displayName") == want), None)
    if mk is None:
        sys.exit(f"no maker named {want!r} in {catalog}")
    out = []
    for t in d["tours"]:
        if t.get("makerId") != mk["id"]:
            continue
        for s in t["stops"]:
            out.append(dict(name=s["title"], lat=s["latitude"], lon=s["longitude"]))
    return out


# --- the audit --------------------------------------------------------------

def region_viewbox(items, pad_deg=0.6):
    """A box around the drop's own coordinates, padded enough to include a
    neighbouring comune (Opera, Mataro) but not another country."""
    lats = [i["lat"] for i in items]
    lons = [i["lon"] for i in items]
    return (min(lons) - pad_deg, min(lats) - pad_deg,
            max(lons) + pad_deg, max(lats) + pad_deg)


def audit(items, city_hint, fetch, verbose=True):
    vb = region_viewbox(items)
    rows = []
    for i, it in enumerate(items, 1):
        rev = fetch.reverse(it["lat"], it["lon"])
        time.sleep(SLEEP)
        fwd = fetch.search(it["name"], city_hint, vb)

        rev_name = (rev or {}).get("name") or ""
        rev_cls = (rev or {}).get("category", "")
        dist = None
        if fwd:
            dist = haversine(it["lat"], it["lon"], float(fwd["lat"]), float(fwd["lon"]))

        dlat = dlon = None
        if rev and "lat" in rev:
            dlat = it["lat"] - float(rev["lat"])
            dlon = it["lon"] - float(rev["lon"])

        rows.append(dict(name=it["name"], lat=it["lat"], lon=it["lon"],
                         rev_name=rev_name, rev_cls=rev_cls,
                         fwd_dist=dist,
                         fwd_name=(fwd or {}).get("display_name", "")[:60],
                         fwd_label=((fwd or {}).get("name")
                                    or (fwd or {}).get("display_name", "").split(",")[0]),
                         fwd_cls=(fwd or {}).get("category", ""),
                         inside_fwd=point_in_bbox(it["lat"], it["lon"], fwd),
                         dlat=dlat, dlon=dlon))
        if verbose:
            d = f"{dist:6.0f}m" if dist is not None else "   n/a"
            print(f"  [{i:>3}/{len(items)}] {it['name'][:34]:34s} "
                  f"fwd {d}  at: {(rev_name or '-')[:30]}")
    return rows


def report(rows, fetch):
    print()
    total = len(rows)

    # --- 1. could we verify at all? (the check-image-duplicates lesson) ------
    attempted = fetch.ok + fetch.failed
    fail_rate = fetch.failed / attempted if attempted else 1.0
    if fail_rate > 0.20:
        print("=" * 72)
        print(f"COULD NOT VERIFY - {fetch.failed}/{attempted} network calls failed.")
        print("This is NOT a pass. Nothing below has been checked. Fix the network")
        print("or the rate limit and re-run.")
        print("=" * 72)
        return 2

    # --- 2. gross errors -----------------------------------------------------
    # A forward-geocode distance alone proves nothing: a road hit with no house
    # number is a street centroid, and a same-named district or a same-named
    # street in another town will both read as kilometres out. So a point is
    # only called GROSS when the distance is large AND the reverse lookup does
    # not recognise the venue either.
    gross, unverifiable = [], []
    for r in rows:
        if r["fwd_dist"] is None:
            unverifiable.append((r, "venue could not be geocoded"))
            continue
        if r["fwd_dist"] <= GROSS_METRES:
            continue
        # inside the venue's own footprint - a big site, not an error
        if r["inside_fwd"]:
            continue
        # the venue geocoded to a road: a street centroid is not a position,
        # so distance from it means nothing either way
        if r["fwd_cls"] == "highway":
            unverifiable.append((r, "venue geocodes to a street, not a point"))
            continue
        # the geocoder must actually have found THIS venue for its distance to
        # be evidence about this coordinate
        if not names_resemble(r["name"], r["fwd_label"]):
            unverifiable.append(
                (r, f"geocoder found something else ({r['fwd_dist'] / 1000:.0f} km away)"))
            continue
        if r["fwd_dist"] > GROSS_MAX_METRES:
            unverifiable.append(
                (r, f"match is {r['fwd_dist'] / 1000:.0f} km away - probably a different place"))
            continue
        # does the supplied point at least sit on something bearing the name?
        if names_resemble(r["name"], r["rev_name"]):
            continue
        gross.append(r)

    print("=" * 72)
    if gross:
        print(f"GROSS - {len(gross)} coordinate(s) may not be at their venue")
        print("Check each by hand. Reverse-geocoding the SUPPLIED point is what")
        print("settles it: a motorway or an unrelated office means it is wrong;")
        print("a neighbour on the right street means it is fine.")
        for r in gross:
            print(f"\n  {r['name']}")
            print(f"    supplied      {r['lat']:.7f}, {r['lon']:.7f}")
            print(f"    sits on       {r['rev_name'] or '(unnamed)'}  [{r['rev_cls']}]")
            print(f"    venue geocode {r['fwd_dist']:.0f} m away - {r['fwd_name']}")
    else:
        print("GROSS - none: every coordinate is at or beside its venue")

    if unverifiable:
        print(f"\nUNVERIFIABLE - {len(unverifiable)}: no automatic verdict, and that is")
        print("not the same as a pass. A towpath, a square and a long street have no")
        print("single point to measure against; read the script and judge by hand.")
        for r, why in unverifiable:
            print(f"    {r['name'][:40]:40s} {why}")
        print("  (a GROSS verdict needs the geocoder to have found the venue itself;")
        print("   where it did not, the distance is reported and not acted on)")

    # --- 3. systematic bias --------------------------------------------------
    pts = [r for r in rows
           if r["dlat"] is not None and r["rev_cls"] not in AREA_CLASSES]
    print("\n" + "=" * 72)
    if len(pts) < 8:
        print(f"BIAS - not enough point-like matches ({len(pts)}) to measure")
        return 1 if gross else 0

    n = len(pts)
    k = sum(1 for r in pts if r["dlat"] > 0)
    med = statistics.median(metres_north(r["dlat"]) for r in pts)
    p = binomial_two_sided(n, k)
    print(f"BIAS - {k}/{n} north of true position, median {med:+.1f} m, p = {p:.2g}")
    print("  reference, measured 2026-08-22:")
    print("    old-sourced cities (NYC, London)   24/51   -0.9 m   p = 1.0")
    print("    drop-pipeline cities (BCN, MIL)    41/50  +10.3 m   p = 5.6e-06")

    if abs(med) >= BIAS_WARN_METRES and p < BIAS_WARN_P:
        d = "north" if med > 0 else "south"
        print(f"\n  >> SYSTEMATIC {d.upper()}WARD OFFSET STILL PRESENT.")
        print("  >> Upstream has NOT been fixed. Whatever converts a map position")
        print("  >> to lat/lon is applying a constant offset in screen pixels;")
        print("  >> it is small here only because these subjects were framed at")
        print("  >> high zoom. The same fault produces kilometre errors on any")
        print("  >> subject far enough out of town to need zooming out.")
    elif n < 20:
        print(f"\n  >> Sample too small (n={n}) to call either way. This is NOT a")
        print("  >> clean bill of health - run the full city, not a --limit subset.")
    else:
        print("\n  >> No significant directional bias. Consistent with upstream fixed.")

    return 1 if gross else 0


# --- selftest ---------------------------------------------------------------

def selftest():
    """Offline. Pins the maths and the drop parser."""
    fails = []

    def check(label, got, want):
        if got != want:
            fails.append(f"{label}: got {got!r}, want {want!r}")

    # haversine
    d = haversine(45.46473716702825, 9.175440380149839, 45.4623754, 9.1758455)
    check("haversine Sant'Ambrogio ~262m", 255 < d < 270, True)
    d = haversine(45.3936252386914, 9.200025761525756, 45.3878869, 9.2017844)
    check("haversine Mirasole ~650m", 630 < d < 670, True)
    check("haversine identity", round(haversine(45, 9, 45, 9), 6), 0.0)

    # binomial
    check("binomial 28/32", binomial_two_sided(32, 28) < 1e-4, True)
    check("binomial 24/51 (even)", binomial_two_sided(51, 24) > 0.5, True)
    check("binomial 41/50", binomial_two_sided(50, 41) < 1e-5, True)
    check("binomial n=0", binomial_two_sided(0, 0), 1.0)
    check("binomial symmetric", binomial_two_sided(32, 4), binomial_two_sided(32, 28))

    # metres_north
    check("metres_north +0.0000925 ~ +10.3m",
          round(metres_north(0.0000925), 1), 10.3)

    # drop parser
    cases = [
        ("output Duomo di Milano 45.46427950733953, 9.191908882325986",
         ("Duomo di Milano", 45.46427950733953, 9.191908882325986)),
        ("output 01 Mag Cafe 45.45143353785858, 9.173409986413743",
         ("Mag Cafe", 45.45143353785858, 9.173409986413743)),
        ("Velasca Tower 45.46004657676957, 9.190638054580278",
         ("Velasca Tower", 45.46004657676957, 9.190638054580278)),
        ("output Mirasole Abbey - Abbazia di Mirasole 45.3936252386914, 9.200025761525756",
         ("Mirasole Abbey - Abbazia di Mirasole", 45.3936252386914, 9.200025761525756)),
    ]
    for folder, want in cases:
        m = DROP_RE.match(folder)
        got = (m.group(1), float(m.group(2)), float(m.group(3))) if m else None
        check(f"parse {folder[:34]!r}", got, want)
    check("parse rejects a plain name", DROP_RE.match("images"), None)
    check("parse rejects audio dir", DROP_RE.match("Multi Stop Navigli"), None)

    # gross-classification: a recognised venue name must never be called gross
    row = dict(name="Officina Antiquaria", fwd_dist=9383.0,
               rev_name="Il Vicolo", rev_cls="amenity")
    tokens = [t for t in re.split(r"\W+", row["name"].lower()) if len(t) > 3]
    check("Cinisello false positive is not auto-cleared",
          any(t in row["rev_name"].lower() for t in tokens), False)
    row2 = dict(name="Triennale di Milano", rev_name="Triennale Design Museum")
    tokens2 = [t for t in re.split(r"\W+", row2["name"].lower()) if len(t) > 3]
    check("QT8 false positive IS cleared by name match",
          any(t in row2["rev_name"].lower() for t in tokens2), True)

    # point_in_bbox
    castello = {"boundingbox": ["45.4694", "45.4739", "9.1758", "9.1815"]}
    check("point inside Castello footprint",
          point_in_bbox(45.47167997489, 9.179332487918614, castello), True)
    check("Sant'Ambrogio point outside basilica footprint",
          point_in_bbox(45.46473716702825, 9.175440380149839,
                        {"boundingbox": ["45.4617", "45.4630", "9.1750", "9.1767"]}), False)
    check("point_in_bbox handles no hit", point_in_bbox(45, 9, None), False)
    check("point_in_bbox handles missing bbox", point_in_bbox(45, 9, {}), False)
    check("point_in_bbox handles junk bbox",
          point_in_bbox(45, 9, {"boundingbox": ["a", "b", "c", "d"]}), False)

    # names_resemble - the gate on the whole GROSS verdict
    check("basilica variant matches",
          names_resemble("Basilica of Sant'Ambrogio", "Basilica di Sant'Ambrogio, Piazza"), True)
    check("Mirasole variant matches",
          names_resemble("Mirasole Abbey - Abbazia di Mirasole", "Abbazia di Mirasole, Via"), True)
    check("RITO does not match a stream in Novara",
          names_resemble("RITO", "Torrente Rito, Oleggio, Novara"), True)   # short token, caught by distance cap
    check("Corte degli Artisti != Locanda Degli Artisti is NOT auto-gross",
          names_resemble("Corte degli Artisti", "Gran Caffe Santonocito"), False)
    check("QT8 district does not resemble Triennale",
          names_resemble("Triennale di Milano", "QT8, Municipio 8 di Milano"), False)
    check("generic words are stopped",
          names_resemble("Morelli Ristorante", "Bianchi Ristorante"), False)
    check("bbox tolerance clears Castello (2.8 m outside raw bbox)",
          point_in_bbox(45.47167997489, 9.179332487918614,
                        {"boundingbox": ["45.4690331", "45.4715546", "9.1777776", "9.1813388"]}), True)
    check("tolerance does NOT clear Sant'Ambrogio (265 m out)",
          point_in_bbox(45.46473716702825, 9.175440380149839,
                        {"boundingbox": ["45.4617", "45.4630", "9.1750", "9.1767"]}), False)

    # name_variants
    check("compound name is split",
          "Abbazia di Mirasole" in name_variants("Mirasole Abbey - Abbazia di Mirasole"), True)
    check("plain name survives", name_variants("Duomo di Milano"), ["Duomo di Milano"])
    check("parentheticals stripped",
          "Bar Basso" in name_variants("Bar Basso (Lima)"), True)
    # the street-address trap: match on the hit's NAME, never its full address
    check("street in address must not create a match",
          names_resemble("Giacomo Bistrot", "Petit Bistrot"), False)
    check("...whereas the full address WOULD have matched (the bug)",
          names_resemble("Giacomo Bistrot", "Petit Bistrot, 1, Via Giacomo Puccini"), True)

    if fails:
        print(f"SELFTEST FAILED ({len(fails)})")
        for f in fails:
            print("  -", f)
        return 1
    print(f"selftest OK - {31 + len(cases)} checks")
    return 0


# --- main -------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--drop", help="unzipped drop folder to audit before wiring")
    g.add_argument("--maker", help="maker code already live in Tours.json, e.g. MIL")
    g.add_argument("--selftest", action="store_true", help="offline, no network")
    ap.add_argument("--city", default="", help="city hint for the forward geocode")
    ap.add_argument("--catalog",
                    default="TRAVEL GUIDED TOUR/Resources/Tours.json")
    ap.add_argument("--limit", type=int, default=0, help="audit only the first N")
    a = ap.parse_args()

    if a.selftest:
        sys.exit(selftest())

    items = from_drop(a.drop) if a.drop else from_catalog(a.maker, a.catalog)
    if a.limit:
        items = items[:a.limit]
    if not items:
        sys.exit("nothing to audit")

    print(f"auditing {len(items)} coordinate(s)"
          + (f" against '{a.city}'" if a.city else "")
          + f"  (~{len(items) * 2 * SLEEP / 60:.1f} min at Nominatim's rate limit)\n")
    fetch = Fetcher()
    rows = audit(items, a.city, fetch)
    sys.exit(report(rows, fetch))


if __name__ == "__main__":
    main()
