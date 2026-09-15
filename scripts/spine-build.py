#!/usr/bin/env python3
"""Build the place spine — a local gazetteer of visit-worthy real-world places.

WHY THIS EXISTS
---------------
`scripts/make-link-pin.py` has no geocoder. Every pin's coordinate, city,
country and category is typed by a human, which is ~3,300 hours at 100,000 pins
and the step that goes wrong most often. This builds the table those four fields
can be JOINED against instead. See `docs/place-spine-design.md`.

🔴 WHY WIKIDATA AND NOT OPENSTREETMAP, MEASURED 2026-09-15
----------------------------------------------------------
The design doc originally specified Geofabrik `.osm.pbf` extracts. From a web
session that does not work, and neither does the obvious fallback:

    download.geofabrik.de   http=000  (blocked by the egress proxy)
    overpass-api.de         no response (blocked; also recorded by #913)
    query.wikidata.org      http=200  ✅

So the source is the Wikidata Query Service. It is a smaller universe than OSM
— a corner café is not in Wikidata — but it is strong exactly where this
catalogue lives (museums, churches, bridges, monuments, towers), it carries
notability natively as sitelink count, and it needs no multi-gigabyte download.
⚠️ A local OSM extract remains the better long-run source for precision; this
is the source that is REACHABLE, which is a different claim.

🔴 USE THE RADIUS SERVICE, NEVER ADMIN CONTAINMENT. THIS IS THE WHOLE TRAP.
---------------------------------------------------------------------------
The natural query is "things whose P131* chain reaches this city". Measured on
the same nine types, same day:

    city         wdt:P131* containment      wikibase:around (15 km)
    London                          557                     27,295
    New York                      6,093                      7,294

**London undercounts by 49x.** Cities model their administrative hierarchy
differently — London's landmarks sit in boroughs and in the City of London,
whose chains do not all walk up to Q84 — so containment silently returns a
plausible-looking number that is mostly wrong. A spine built that way would
have left London near-empty, and nothing downstream would have flagged it:
pins would simply have failed to match, looking like thin Wikidata coverage.

The radius service is model-independent, and it is also the shape actually
wanted later — a pin HAS a coordinate, so the real question is "what is near
this point?", not "what is in this administrative area?".

⚠️ CHUNKING IS NOT OPTIONAL. WDQS enforces a 60-second query timeout, and a
15 km radius over a dense city exceeds it (Tokyo returned an error where London
and New York succeeded). This walks a grid of small tiles and unions the
results, so no single query is near the limit.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
import time
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402

WDQS = "https://query.wikidata.org/sparql"

# A descriptive User-Agent is REQUIRED by the WDQS policy; an anonymous or
# library-default agent is throttled or refused.
UA = "AtlasPlaceSpine/1.0 (https://dozent.world; edward.yung@gmail.com)"

# WDQS enforces 60 s. Stay well under it — a tile that times out returns
# nothing, and a silently empty tile is the failure this script exists to
# avoid, so the budget is deliberately conservative.
TIMEOUT_S = 55
SLEEP_S = 1.0          # be a good citizen; WDQS is a free shared service.
MAX_RETRY = 3

# Visit-worthy classes. Each is a Wikidata QID used with P31/P279* so subclasses
# come along (a "art museum" is a "museum"). Deliberately broad: ranking decides
# what to offer first, never what to exclude.
TYPES = {
    "Q33506": "museum",
    "Q16970": "church building",
    "Q12280": "bridge",
    "Q4989906": "monument",
    "Q24354": "theatre",
    "Q811979": "architectural structure",
    "Q22698": "park",
    "Q41176": "building",
    "Q22746": "historic house",
    "Q57821": "fortification",
    "Q2065736": "cultural property",
    "Q839954": "archaeological site",
}


def sparql(query: str, *, timeout: int = TIMEOUT_S) -> dict:
    """POST a query and return parsed JSON. Raises on failure — never returns {}.

    🔴 An empty result and a failed request must not be indistinguishable. A
    caller that cannot tell them apart writes an empty tile into the spine and
    reports success, which is exactly the class of bug `runstamp.py` documents.
    """
    body = urllib.parse.urlencode({"query": query}).encode()
    req = urllib.request.Request(
        WDQS,
        data=body,
        headers={
            "Accept": "application/sparql-results+json",
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": UA,
        },
    )
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def tile_query(lat: float, lon: float, radius_km: float) -> str:
    """Features within `radius_km` of a point, with notability and OSM ids.

    ⚠️ `wikibase:around`, NOT `wdt:P131*` — see the module docstring. The
    sitelink count comes from `wikibase:sitelinks`, which is a statement on the
    item itself and costs nothing extra.
    """
    values = " ".join(f"wd:{q}" for q in TYPES)
    return f"""
SELECT ?item ?itemLabel ?coord ?sitelinks ?osmRel ?admin ?adminLabel ?country ?countryLabel
       (GROUP_CONCAT(DISTINCT ?tq; separator=",") AS ?types)
WHERE {{
  SERVICE wikibase:around {{
    ?item wdt:P625 ?coord .
    bd:serviceParam wikibase:center "Point({lon} {lat})"^^geo:wktLiteral .
    bd:serviceParam wikibase:radius "{radius_km}" .
  }}
  ?item wdt:P31/wdt:P279* ?tq .
  VALUES ?tq {{ {values} }}
  ?item wikibase:sitelinks ?sitelinks .
  OPTIONAL {{ ?item wdt:P402 ?osmRel }}
  OPTIONAL {{ ?item wdt:P131 ?admin }}
  OPTIONAL {{ ?item wdt:P17  ?country }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en,mul" }}
}}
GROUP BY ?item ?itemLabel ?coord ?sitelinks ?osmRel ?admin ?adminLabel ?country ?countryLabel
"""


def parse_point(wkt: str):
    """`Point(lon lat)` -> (lat, lon). Returns None on anything unexpected."""
    if not wkt or not wkt.startswith("Point("):
        return None
    try:
        lon_s, lat_s = wkt[6:-1].split()
        return float(lat_s), float(lon_s)
    except ValueError:
        return None


def tiles(lat: float, lon: float, span_km: float, tile_km: float):
    """Grid of tile centres covering a square of `span_km` around a point.

    Tiles overlap slightly by construction (a circle of radius `tile_km`
    inscribed on a grid of step `tile_km` leaves no gap only if the step is
    <= r*sqrt(2)); dedupe downstream handles the overlap, a gap would be
    silent data loss.
    """
    step = tile_km * 1.2                      # < r*sqrt(2) ~= 1.41r, so no gaps
    km_per_deg_lat = 110.574
    km_per_deg_lon = 111.320 * max(math.cos(math.radians(lat)), 0.01)
    n = max(1, int(math.ceil(span_km / step)))
    half = (n - 1) / 2.0
    for i in range(n):
        for j in range(n):
            yield (
                lat + (i - half) * step / km_per_deg_lat,
                lon + (j - half) * step / km_per_deg_lon,
            )


def harvest(lat, lon, span_km, tile_km, *, log=print):
    """Collect deduped features over a tiled area. Returns (rows, n_failed)."""
    seen: dict[str, dict] = {}
    failed = 0
    centres = list(tiles(lat, lon, span_km, tile_km))
    for idx, (tlat, tlon) in enumerate(centres, 1):
        q = tile_query(tlat, tlon, tile_km)
        got = None
        for attempt in range(1, MAX_RETRY + 1):
            try:
                got = sparql(q)
                break
            except Exception as exc:                      # noqa: BLE001
                if attempt == MAX_RETRY:
                    failed += 1
                    log(f"  tile {idx}/{len(centres)} FAILED after "
                        f"{MAX_RETRY} tries: {type(exc).__name__}: {exc}")
                else:
                    time.sleep(SLEEP_S * 2 * attempt)
        if got is None:
            continue
        n_new = 0
        for b in got["results"]["bindings"]:
            qid = b["item"]["value"].rsplit("/", 1)[-1]
            pt = parse_point(b.get("coord", {}).get("value", ""))
            if pt is None:
                continue
            if qid in seen:
                continue
            seen[qid] = {
                "spine_id": f"wd:{qid}",
                "wikidata_id": qid,
                "name": b.get("itemLabel", {}).get("value") or qid,
                "lat": pt[0],
                "lon": pt[1],
                "sitelinks": int(b.get("sitelinks", {}).get("value", 0) or 0),
                "osm_relation": b.get("osmRel", {}).get("value"),
                "admin": b.get("adminLabel", {}).get("value"),
                "country": b.get("countryLabel", {}).get("value"),
                "types": [t.rsplit("/", 1)[-1]
                          for t in (b.get("types", {}).get("value") or "").split(",") if t],
            }
            n_new += 1
        log(f"  tile {idx}/{len(centres)} +{n_new} new (total {len(seen)})")
        time.sleep(SLEEP_S)
    return list(seen.values()), failed


def selftest() -> int:
    """Offline checks only — no network, so this can gate a commit."""
    fails = []

    def check(name, ok):
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    check("parse_point basic", parse_point("Point(-0.1278 51.5074)") == (51.5074, -0.1278))
    check("parse_point rejects junk", parse_point("MULTIPOINT(1 2)") is None)
    check("parse_point rejects empty", parse_point("") is None)
    check("parse_point rejects non-numeric", parse_point("Point(a b)") is None)

    t = list(tiles(51.5, -0.13, 10, 5))
    check("tiles cover a span", len(t) >= 4)
    check("tiles centred", any(abs(a - 51.5) < 4 and abs(b + 0.13) < 4 for a, b in t))
    single = list(tiles(0, 0, 1, 5))
    check("tiles: span < tile -> one tile", len(single) == 1)

    q = tile_query(51.5, -0.13, 5)
    check("query uses wikibase:around", "wikibase:around" in q)
    check("🔴 query does NOT use admin containment", "P131*" not in q)
    check("query asks for sitelinks", "wikibase:sitelinks" in q)
    check("query passes lon then lat", "Point(-0.13 51.5)" in q)
    check("every TYPE appears in the query", all(f"wd:{t}" in q for t in TYPES))

    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — "
          f"{13 - len(fails)}/13")
    return 1 if fails else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--city", help='label for the run, e.g. "London"')
    ap.add_argument("--at", help="lat,lon centre")
    ap.add_argument("--span-km", type=float, default=20.0)
    ap.add_argument("--tile-km", type=float, default=5.0)
    ap.add_argument("--json", help="write harvested rows here")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        if not (a.city and a.at):
            print("need --city and --at lat,lon (or --selftest)")
            return 2
        lat, lon = (float(x) for x in a.at.split(","))
        print(f"{a.city}: span {a.span_km} km in {a.tile_km} km tiles "
              f"around {lat},{lon}")
        rows, failed = harvest(lat, lon, a.span_km, a.tile_km)

        print(f"\n{a.city}: {len(rows)} distinct features, {failed} tile(s) failed")
        if failed:
            # 🔴 A partial harvest must not read as a complete one.
            print("COULD NOT VERIFY — some tiles failed; this harvest is INCOMPLETE")
        ranked = sorted(rows, key=lambda r: -r["sitelinks"])
        print("\nmost notable 10 (sitelinks — the ranking signal):")
        for r in ranked[:10]:
            print(f"  {r['sitelinks']:4d}  {r['name'][:46]:46s} {r['lat']:.4f},{r['lon']:.4f}")
        if a.json:
            with open(a.json, "w") as fh:
                json.dump(ranked, fh, indent=1)
            print(f"\nwrote {a.json}")
        return 2 if failed else 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
