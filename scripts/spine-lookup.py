#!/usr/bin/env python3
"""Ask Wikidata where each catalogue entry's SUBJECT actually is, and cache it.

WHY THIS EXISTS
---------------
On 2026-09-17 clearing the place-candidate backlog surfaced coordinate errors
that no check in this repo can see, because every one of them was precise,
plausible and in the right city:

    Grace Farms                 6,104 m      Geisel Library     5,412 m
    La Collina                  1,440 m      Casa de Vidro        833 m
    Asakusa Underground Street    718 m      Domino Park          201 m

`check-coordinates.py` finds gross displacement and city outliers. A point that
landed on the wrong BUILDING in the right neighbourhood passes it, and passes
`validate-tours.swift`, and returns 200 for every URL. In 13 of 15 place groups
the thing in the wrong position was the Atlas tour. They were found by a human
noticing, one at a time.

This asks a different question, and it is the only one that catches that class:
**not "is this point plausible?" but "where is the thing this entry is named
after?"**

🔴 WHY A NAME LOOKUP AND NOT A TILED HARVEST — MEASURED 2026-09-17
------------------------------------------------------------------
`docs/place-spine-design.md` § 4 specifies harvesting a gazetteer by walking
tiles around each city, then joining pins to it. Tiling the whole catalogue is
affordable (1,612 tiles of 2 km, ~67 min) — but it **cannot catch the errors
this exists for**, and the reason is structural rather than a tuning problem:

    a tile is drawn around the coordinate the entry ALREADY HAS.
    If that coordinate is wrong, the right feature is outside the tile.

Grace Farms' pin sat 6.1 km from Grace Farms. No tile around the wrong point
contains the right answer. Asking by NAME has no such blind spot: the answer is
wherever Wikidata says it is, and the distance from our stored point IS the
finding.

A tiled harvest remains the right shape for the OTHER jobs the spine was
designed for — autofilling a NEW pin's coordinate, and the AMBIGUOUS band
("something is near this point but it is not what the title says"). Neither is
this script's job. See `docs/place-spine-design.md`.

🔴 WHY WIKIDATA — the source is not a preference, it is what is reachable
-------------------------------------------------------------------------
Re-verified from this session, not quoted from a document:

    download.geofabrik.de   blocked by the egress proxy
    overpass-api.de         HTTP 000 — still blocked (as #913, #924 recorded)
    query.wikidata.org      HTTP 200  ✅

Wikidata is a smaller universe than OSM — see the coverage note below — but it
is the one that answers.

⚠️ COVERAGE IS THE HONEST LIMIT, AND "UNMATCHED" IS NEVER A VERDICT
--------------------------------------------------------------------
Of the six errors above, Wikidata knows four and has never heard of two
(`La Collina`, `Asakusa Underground Street`). Measured previously by creator:
architecture 78–83%, urbanism 54–59%, **food 14–25%** — and food is not a
rounding error in this catalogue (`@jacksdiningroom` alone is 256 pins).

So a missing answer means *Wikidata does not know this subject*. It does NOT
mean the coordinate is fine, and it must never be reported as if it did.

🔴 TWO GUARDS, BOTH PAID FOR BY A REAL FALSE POSITIVE
------------------------------------------------------
1. **Bound the answer by distance.** An unbounded label search for
   `La Collina` returns an item in Italy — **9,570 km** from the Japanese
   bakery of the same name — and it looks exactly like a confident hit. Every
   candidate beyond `--bound-km` (default 100) is discarded. 100 km is far
   wider than any error we have ever found (the worst was 6.1 km) and far
   narrower than a same-name collision on another continent.

2. **Ask in the entry's own script too.** Titles carry a bilingual tail
   (`Asakusa Underground Street | 浅草地下街`). Searching only the English half
   throws away the name the subject is actually catalogued under locally.

⚠️ THE LABEL THAT COMES BACK NEED NOT MATCH THE NAME ASKED FOR, AND THAT IS
CORRECT. `Casa de Vidro` resolves to an item whose English label is
`Glass House`, 6 m from our coordinate — matched through an alias. A strict
label-equality gate would have thrown away a right answer. The name gate is the
SEARCH; the distance is the finding.

WHAT THIS WRITES
----------------
`spine/lookups.json.gz` — one record per catalogue entry, keyed by entry id,
carrying the name that was asked and the candidates that came back. Committed,
so the analysis (`scripts/spine-match.py`) runs offline, in CI, for free, and
re-running this is a no-op for every entry whose title has not changed.

The cache is the resume state: interrupt this at any point and run it again.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import importlib.util
import json
import math
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402  (stamps every run; see scripts/runstamp.py)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")
CACHE = os.path.join(REPO, "spine", "lookups.json.gz")

WDQS = "https://query.wikidata.org/sparql"

# A descriptive User-Agent is REQUIRED by WDQS policy; an anonymous or
# library-default agent is throttled or refused.
UA = "AtlasPlaceSpine/1.0 (https://dozent.world; edward.yung@gmail.com)"

TIMEOUT_S = 55          # WDQS enforces 60; stay under it.
SLEEP_S = 1.0           # WDQS is a free shared service.
MAX_RETRY = 3
BOUND_KM = 100.0        # see guard 1 in the module docstring.
SEARCH_LIMIT = 10

# The distance at which an answer stops being reassuring and starts being worth
# a human's time. Measured on this catalogue's own known-good entries: correct
# ones land at 6, 7, 85 and 88 m, and the smallest real error we have on record
# read 242 m. `scripts/spine-match.py` owns the banding; this file uses the
# threshold only to decide whether a second, native-script opinion is worth a
# query. Keep the two in step.
REVIEW_M = 120.0

# Schema version of a cache record. Bump when the record shape changes so old
# records are re-fetched rather than silently read under the wrong assumptions.
RECORD_VERSION = 2


# --- the catalogue's own name logic, imported rather than re-implemented ----
#
# `check-place-candidates.py` carries name handling that has been corrected
# twice against real misses (the bilingual tail, the parenthetical, the
# symmetric city drop). A second copy here would drift from it silently, and
# the drift would look like a coverage problem rather than a bug.

def _load_candidates_module():
    path = os.path.join(HERE, "check-place-candidates.py")
    spec = importlib.util.spec_from_file_location("_place_candidates", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_cpc = _load_candidates_module()
display_stem = _cpc.display_stem
haversine = _cpc.haversine


def marker(entry):
    """The coordinate the map actually draws.

    ⚠️ The stop at `order == 0`, never the centroid — a walk's centroid is the
    mean of stops a kilometre apart and is not anywhere. Link pins carry one
    stop; some single tours number their only stop something other than 0, so
    fall back to the first stop rather than dropping the entry.
    """
    stops = entry.get("stops") or []
    for stop in stops:
        if stop.get("order") == 0:
            return (stop["latitude"], stop["longitude"])
    if stops:
        return (stops[0]["latitude"], stops[0]["longitude"])
    return None


NON_LATIN = re.compile(r"[^\x00-\x7F]")


def query_names(title):
    """The names to ask Wikidata for, in order.

    A bilingual title (`English | 日本語`) is two names for one subject and both
    are worth asking: the English half is what an English search index knows,
    the native half is what the subject is catalogued under locally. Returns at
    most two, deduped, with the parentheticals stripped.
    """
    raw = title or ""
    names = []
    for part in raw.split("|"):
        cleaned = re.sub(r"\(.*?\)", " ", part)
        cleaned = re.sub(r"\s+", " ", cleaned).strip(" -–—,")
        if cleaned and cleaned not in names:
            names.append(cleaned)
    if not names:
        return []
    head = names[0]
    tail = [n for n in names[1:] if NON_LATIN.search(n)]
    return ([head] + tail)[:2]


# An Atlas tour's title is often an ANGLE on a site rather than the site's name
# — "The South Facade of Grand Central", "After the Fire: Wren's City". Wikidata
# has never heard of the angle. `docs/places.md` Rule 2 says the same thing from
# the other end: editorial framing never creates a new place.
EDITORIAL_SPLITS = (
    (r"^.*?:\s+", ""),          # "After the Fire: Wren's City" -> "Wren's City"
    (r"^.*\bof\s+", ""),        # "The South Facade of Grand Central" -> "Grand Central"
    (r"\s+[—–]\s+.*$", ""),     # "Grace Farms — River Building" -> "Grace Farms"
    (r"^.*\bat\s+", ""),        # "Bar Luce at Fondazione Prada" -> "Fondazione Prada"
)


def fallback_names(title):
    """Shorter forms to try ONLY when the full title found nothing.

    ⚠️ Deliberately a fallback, never a first choice. "Bar Luce at Fondazione
    Prada" reduced to "Fondazione Prada" is the tenant-is-not-the-site case
    (`docs/places.md` Rule 4) — a useful last resort for locating roughly the
    right spot, and a wrong answer to lead with.
    """
    names = query_names(title)
    if not names:
        return []
    head = names[0]
    out = []
    for pattern, repl in EDITORIAL_SPLITS:
        reduced = re.sub(pattern, repl, head).strip(" -–—,:")
        if reduced and reduced != head and reduced not in out:
            out.append(reduced)
    return out


# A CJK ideograph does not name its own language. `浅草地下街` is Japanese and
# `文武廟` is Chinese, and nothing in their codepoints says so — both are pure
# Han. The entry's own country does say so, and the catalogue already carries
# it on every tour and pin.
HAN_LANGUAGE_BY_COUNTRY = {
    "japan": "ja",
    "south korea": "ko", "korea": "ko",
    "china": "zh", "taiwan": "zh", "hong kong": "zh", "macau": "zh", "macao": "zh",
    "singapore": "zh",
}


def search_language(name, country=None):
    """The language to ask EntitySearch in — it ranks by the language given, so
    searching a Japanese name as English buries the right item under
    transliterations.

    🔴 Kana, hangul, thai and arabic identify themselves. **Han does not.**
    `浅草地下街` (Japanese) and `文武廟` (Chinese) are both pure ideographs, so a
    codepoint-only rule silently asks in the wrong language for one of them.
    Fall back to the entry's country, which the catalogue already stores.
    """
    for lo, hi, lang in (
        (0x3040, 0x30FF, "ja"),     # hiragana + katakana — definitive
        (0xAC00, 0xD7AF, "ko"),     # hangul syllables
        (0x0E00, 0x0E7F, "th"),     # thai
        (0x0600, 0x06FF, "ar"),     # arabic
    ):
        if any(lo <= ord(ch) <= hi for ch in name):
            return lang
    if any(0x4E00 <= ord(ch) <= 0x9FFF for ch in name):
        return HAN_LANGUAGE_BY_COUNTRY.get((country or "").strip().lower(), "zh")
    return "en"


def sparql(query, *, timeout=TIMEOUT_S):
    """POST a query and return parsed JSON. Raises on failure — never returns {}.

    🔴 An empty result and a failed request must not be indistinguishable. A
    caller that cannot tell them apart caches "no candidates" for an entry whose
    request simply fell over, and that wrong answer is then permanent, because
    the cache is the resume state.
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
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return json.load(response)


def search_query(name, language, limit=SEARCH_LIMIT):
    """Items whose label or alias matches `name`, that carry a coordinate.

    `wikibase:mwapi` + `EntitySearch` is Wikidata's own search index, which
    matches aliases — the reason `Casa de Vidro` finds an item labelled
    `Glass House`. `wdt:P625` is an inner join on purpose: an item with no
    coordinate cannot answer the question being asked.
    """
    escaped = name.replace("\\", "\\\\").replace('"', '\\"')
    return f"""
SELECT ?item ?itemLabel ?coord ?sitelinks WHERE {{
  SERVICE wikibase:mwapi {{
    bd:serviceParam wikibase:endpoint "www.wikidata.org" .
    bd:serviceParam wikibase:api "EntitySearch" .
    bd:serviceParam mwapi:search "{escaped}" .
    bd:serviceParam mwapi:language "{language}" .
    bd:serviceParam mwapi:limit "{limit}" .
    ?item wikibase:apiOutputItem mwapi:item .
  }}
  ?item wdt:P625 ?coord .
  OPTIONAL {{ ?item wikibase:sitelinks ?sitelinks }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en,mul" }}
}}
"""


def parse_point(wkt):
    """`Point(lon lat)` -> (lat, lon). None on anything unexpected."""
    if not wkt or not wkt.startswith("Point(") or not wkt.endswith(")"):
        return None
    try:
        lon_s, lat_s = wkt[6:-1].split()
        return float(lat_s), float(lon_s)
    except ValueError:
        return None


def candidates_for(name, at, *, country=None, bound_km=BOUND_KM, log=print):
    """Search `name`, keep geolocated hits within `bound_km` of `at`.

    Raises if every retry fails — the caller must not cache a network failure
    as "nothing found".
    """
    language = search_language(name, country)
    query = search_query(name, language)
    payload = None
    last = None
    for attempt in range(1, MAX_RETRY + 1):
        try:
            payload = sparql(query)
            break
        except Exception as exc:                            # noqa: BLE001
            last = exc
            if attempt < MAX_RETRY:
                time.sleep(SLEEP_S * 2 * attempt)
    if payload is None:
        raise RuntimeError(f"{type(last).__name__}: {last}")

    return {
        "language": language,
        "candidates": candidates_from_bindings(
            payload["results"]["bindings"], at, bound_km),
    }


def candidates_from_bindings(bindings, at, bound_km):
    """Geolocated hits within `bound_km` of `at`, nearest first.

    🔴 Split out from `candidates_for` so the bound can be tested WITHOUT a
    network call. The first version of this selftest asserted only that
    `haversine(far) > bound`, which is arithmetic — it passed unchanged when
    the filter itself was deleted. A guard that cannot fail is the exact bug
    `runstamp.py` exists for.
    """
    out = []
    for binding in bindings:
        point = parse_point(binding.get("coord", {}).get("value", ""))
        if point is None:
            continue
        metres = haversine(at, point)
        if metres > bound_km * 1000.0:
            continue                                        # 🔴 the La Collina guard
        out.append({
            "qid": binding["item"]["value"].rsplit("/", 1)[-1],
            "label": binding.get("itemLabel", {}).get("value") or "",
            "lat": point[0],
            "lon": point[1],
            "distance_m": round(metres, 1),
            "sitelinks": int(binding.get("sitelinks", {}).get("value", 0) or 0),
        })
    out.sort(key=lambda c: c["distance_m"])
    return out


def entries(catalog):
    """Tours and link pins alike — the worst errors found so far were tours."""
    return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])


def ask_digest(title, at, bound_km):
    """What a cached answer depends on. Changing any of it re-asks.

    The coordinate is in here deliberately: the bound is measured from it, so a
    moved entry's cached candidate list is no longer the right list.
    """
    payload = json.dumps(
        [title or "", round(at[0], 6), round(at[1], 6), bound_km, RECORD_VERSION],
        ensure_ascii=False, sort_keys=True,
    )
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:16]


def load_cache(path):
    if not os.path.exists(path):
        return {}
    with gzip.open(path, "rt", encoding="utf-8") as fh:
        return json.load(fh)


def save_cache(path, cache):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    # mtime=0 so an unchanged cache is byte-identical between runs; otherwise
    # every run shows a diff and the artefact's history stops being readable.
    with gzip.GzipFile(tmp, "wb", compresslevel=9, mtime=0) as raw:
        raw.write(json.dumps(cache, ensure_ascii=False, sort_keys=True,
                             indent=1).encode("utf-8"))
    os.replace(tmp, path)


def selftest():
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

    check("query_names keeps a plain title",
          query_names("Domino Park") == ["Domino Park"])
    check("query_names splits a bilingual title",
          query_names("Asakusa Underground Street | 浅草地下街")
          == ["Asakusa Underground Street", "浅草地下街"])
    check("query_names strips a parenthetical",
          query_names("Wat Arun (Temple of Dawn)") == ["Wat Arun"])
    check("🔴 query_names drops a LATIN tail, which is not a native name",
          query_names("Casa de Vidro | Glass House") == ["Casa de Vidro"])
    check("query_names survives an empty title", query_names("") == [])

    check("fallback strips an editorial colon",
          "Wren's City" in fallback_names("After the Fire: Wren's City"))
    check("fallback strips 'the X of Y'",
          "Grand Central" in fallback_names("The South Facade of Grand Central"))
    check("fallback keeps the whole, not the part, across an em dash",
          "Grace Farms" in fallback_names("Grace Farms — River Building"))
    check("🔴 a plain venue name has NO fallback, so none is ever tried first",
          fallback_names("Domino Park") == [])
    check("fallback survives an empty title", fallback_names("") == [])

    check("search_language: kana is definitive",
          search_language("ラ コリーナ近江八幡") == "ja")
    check("search_language detects korean", search_language("경복궁") == "ko")
    check("search_language defaults to english", search_language("Domino Park") == "en")
    # 🔴 The Han case: identical scripts, different languages, decided by country.
    check("🔴 pure-kanji name in Japan asks in japanese",
          search_language("浅草地下街", "Japan") == "ja")
    check("🔴 the same script in Hong Kong asks in chinese",
          search_language("文武廟", "Hong Kong") == "zh")
    check("han with no country falls back to chinese",
          search_language("文武廟", None) == "zh")

    q = search_query("Domino Park", "en")
    check("query uses EntitySearch", "EntitySearch" in q)
    check("query requires a coordinate", "wdt:P625 ?coord" in q)
    check('🔴 query escapes an embedded quote',
          '\\"' in search_query('the "best" bar', "en"))

    # 🔴 The La Collina guard, exercised through the code that applies it.
    # Feeding synthetic bindings is what makes this able to fail: an earlier
    # version asserted `haversine(far) > bound`, which is arithmetic, and it
    # passed unchanged when the filter was deleted.
    def binding(qid, label, lat, lon):
        return {"item": {"value": f"http://www.wikidata.org/entity/{qid}"},
                "itemLabel": {"value": label},
                "coord": {"value": f"Point({lon} {lat})"}}

    at_la_collina = (35.14916, 136.09145)
    got = candidates_from_bindings([
        binding("Q18428290", "La Collina", 44.0, 11.0),      # Italy — 9,570 km
        binding("Q1", "La Collina Ōmi-Hachiman", 35.1492, 136.0915),
    ], at_la_collina, BOUND_KM)
    check("🔴 bound DROPS a same-name item on another continent",
          [c["qid"] for c in got] == ["Q1"])

    near = candidates_from_bindings(
        [binding("Q962291", "Geisel Library", 32.88114, -117.23758)],
        (32.84560, -117.27782), BOUND_KM)
    check("bound KEEPS a real 5.4 km error",
          len(near) == 1 and 5000 < near[0]["distance_m"] < 6000)

    # ⚠️ Three candidates, in an order where reversing is NOT the same as
    # sorting. With two, `out.reverse()` produced the expected answer by
    # coincidence and this check survived deleting the sort entirely.
    ordered = candidates_from_bindings([
        binding("Q_near", "near", 40.71411, -73.96827),
        binding("Q_far", "far", 40.80, -73.96),
        binding("Q_mid", "mid", 40.75, -73.96827),
    ], (40.71411, -73.96827), BOUND_KM)
    check("candidates come back nearest-first",
          [c["qid"] for c in ordered] == ["Q_near", "Q_mid", "Q_far"])
    check("a candidate with no coordinate is dropped",
          candidates_from_bindings(
              [{"item": {"value": ".../Q9"}, "coord": {"value": "MULTIPOINT(1 2)"}}],
              (0.0, 0.0), BOUND_KM) == [])

    d1 = ask_digest("A", (1.0, 2.0), 100.0)
    check("digest is stable", d1 == ask_digest("A", (1.0, 2.0), 100.0))
    check("digest moves when the title changes", d1 != ask_digest("B", (1.0, 2.0), 100.0))
    check("digest moves when the entry moves", d1 != ask_digest("A", (1.5, 2.0), 100.0))
    check("digest moves when the bound changes", d1 != ask_digest("A", (1.0, 2.0), 50.0))

    total = 32
    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — {total - len(fails)}/{total}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--cache", default=CACHE)
    ap.add_argument("--bound-km", type=float, default=BOUND_KM,
                    help="discard candidates further than this (the La Collina guard)")
    ap.add_argument("--limit", type=int, default=0,
                    help="ask at most N entries this run; 0 = all. The cache is "
                         "the resume state, so a slice is safe to repeat.")
    ap.add_argument("--only", default="",
                    help="substring filter on the title, for probing one subject")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()

        with open(a.catalog, encoding="utf-8") as fh:
            catalog = json.load(fh)
        cache = load_cache(a.cache)

        todo = []
        for entry in entries(catalog):
            at = marker(entry)
            if at is None:
                continue
            if a.only and a.only.lower() not in (entry.get("title") or "").lower():
                continue
            digest = ask_digest(entry.get("title"), at, a.bound_km)
            cached = cache.get(entry["id"])
            if cached and cached.get("digest") == digest:
                continue
            todo.append((entry, at, digest))

        print(f"{len(cache)} cached · {len(todo)} to ask"
              + (f" · limiting to {a.limit}" if a.limit else ""))
        if a.limit:
            todo = todo[:a.limit]
        if not todo:
            print("\nOK — cache is complete for this catalogue")
            return 0

        asked = failed = 0
        for index, (entry, at, digest) in enumerate(todo, 1):
            names = query_names(entry.get("title"))
            if not names:
                continue
            merged, langs, error = {}, [], None
            for position, name in enumerate(names):
                # ⚠️ The native-script name is a SECOND opinion, not a routine
                # one. Asking it for every bilingual title doubles a sweep that
                # already runs for hours. Ask it only when the first answer is
                # one we would act on being wrong about: nothing found, or a
                # hit far enough away to be reported as a problem.
                if position > 0:
                    best_so_far = min((c["distance_m"] for c in merged.values()),
                                      default=None)
                    if best_so_far is not None and best_so_far < REVIEW_M:
                        break
                try:
                    got = candidates_for(name, at,
                                         country=entry.get("country"),
                                         bound_km=a.bound_km)
                except Exception as exc:                    # noqa: BLE001
                    error = str(exc)
                    break
                langs.append(got["language"])
                for candidate in got["candidates"]:
                    prev = merged.get(candidate["qid"])
                    if prev is None or candidate["distance_m"] < prev["distance_m"]:
                        merged[candidate["qid"]] = candidate
                time.sleep(SLEEP_S)

            if not merged and error is None:
                # Nothing under the title as written. Try the editorial
                # reductions before giving up — a tour named for an angle on a
                # site is not a site Wikidata has never heard of, it is a site
                # asked for by the wrong name.
                for name in fallback_names(entry.get("title")):
                    try:
                        got = candidates_for(name, at,
                                             country=entry.get("country"),
                                             bound_km=a.bound_km)
                    except Exception as exc:                # noqa: BLE001
                        error = str(exc)
                        break
                    langs.append(got["language"])
                    for candidate in got["candidates"]:
                        candidate = dict(candidate, via=name)
                        prev = merged.get(candidate["qid"])
                        if prev is None or candidate["distance_m"] < prev["distance_m"]:
                            merged[candidate["qid"]] = candidate
                    time.sleep(SLEEP_S)
                    if merged:
                        break

            if error is not None:
                # 🔴 Never cache a network failure as "nothing found".
                failed += 1
                print(f"  {index}/{len(todo)} FAILED {entry.get('title','')[:40]}: {error}")
                continue

            ranked = sorted(merged.values(), key=lambda c: c["distance_m"])
            cache[entry["id"]] = {
                "digest": digest,
                "version": RECORD_VERSION,
                "title": entry.get("title"),
                "asked": names,
                "languages": langs,
                "at": [round(at[0], 6), round(at[1], 6)],
                "bound_km": a.bound_km,
                "candidates": ranked,
            }
            asked += 1
            if ranked:
                best = ranked[0]
                print(f"  {index}/{len(todo)} {entry.get('title','')[:38]:38} -> "
                      f"{best['label'][:26]:26} {best['distance_m']:8.0f} m")
            else:
                print(f"  {index}/{len(todo)} {entry.get('title','')[:38]:38} -> "
                      f"no candidate within {a.bound_km:.0f} km")
            if asked % 25 == 0:
                save_cache(a.cache, cache)

        save_cache(a.cache, cache)
        print(f"\nasked {asked} · failed {failed} · cache now {len(cache)} entries")
        print(f"wrote {a.cache}")
        if failed:
            # 🔴 A partial sweep must not read as a complete one.
            print("COULD NOT VERIFY — some lookups failed; re-run to finish them")
            return 2
        print("OK — every requested lookup answered")
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
