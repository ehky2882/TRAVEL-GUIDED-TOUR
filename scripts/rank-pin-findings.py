#!/usr/bin/env python3
"""Sort the vision check's CONTRADICTS into bands by how much they are worth.

WHY THIS EXISTS
---------------
`check-pin-subject.py` swept the whole catalogue on 2026-09-20 and returned
**323 CONTRADICTS**. Precision, measured on the first 33 the owner reviewed one
at a time, is **42%** — 14 real catalogue errors against 19 cases of the check
being wrong. So the raw list is not a work queue: two rows in three cost the
owner's attention for nothing, and reviewing 33 that way consumed most of a
session.

🔴 **A list sorted by the check's own enthusiasm is not a ranking.** That was
tried, and the owner's reply was that two of its three tiers were not questions
at all. What separates a real error from a wrong guess is not confidence — it is
GEOGRAPHIC DISTANCE between what the catalogue claims and what gate C named:

    cross-country  the picture is a place in a DIFFERENT COUNTRY
                   7 of the owner's 14 real errors looked exactly like this
                   (MSG Sphere -> Lucas Museum, LA; MOL Campus -> Eurovea
                   Tower, Slovakia; Bosco Verticale -> La Nouvel KLCC)
    cross-city     a different city in the same country
    same-area      everything else — the low-signal tail

⚠️ **A band is a reading order, not a verdict.** A cross-country hit can still
be the check being wrong: a replica reads as its original (the Leaning Tower of
Niles is half-scale Pisa and lands in `cross-country` on every run), and a
building by the same architect reads as its sibling. Open the post.

⚠️ Findings the owner has already ruled on are dropped, matched on the FOLDED
title — `owner-verdicts.json` is keyed by title, not by id, so an entry whose
title carries an accent or different case would otherwise come back.
🔴 That match is per-title, and three differently-titled Niles pins share one
ruling, so a ruling does not always reach every entry it settles.
"""
import argparse
import collections
import gzip
import json
import os
import re
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import runstamp  # noqa: E402

CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")
CACHE = os.path.join(REPO, "checks", "pin-subject.json.gz")
VERDICTS = os.path.join(REPO, "checks", "owner-verdicts.json")
BANDS = ("cross-country", "cross-city", "same-area")


def fold(s):
    """Accent- and case-insensitive key. Zurich and Zürich are one city.

    ⚠️ The combining-mark filter below is BELT-AND-BRACES, not the guard: the
    `[^a-z0-9 ]` regex already strips combining marks, so removing the filter
    changes nothing (verified over Zürich / São Paulo / Málaga / Ōsaka). The
    mutation harness lists that sabotage as EQUIVALENT for this reason.
    ⚠️ A letter that does not DECOMPOSE is deleted outright, so "Køge" folds to
    "kge". Harmless while both sides fold the same way; it would matter if a
    fold were ever compared against something folded another way.
    """
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9 ]", "", s.lower()).strip()


def gazetteer(entries):
    """city -> {countries} and the set of country names, from the catalogue.

    The catalogue is its own gazetteer here: every city we carry states its
    country, so a place named by gate C can be located without a network call.

    🔴 LIMITATION: a city the catalogue does not carry cannot be located, so a
    finding naming it falls to `same-area` however far away it really is. The
    bands therefore UNDERSTATE cross-country, and `same-area` is not a claim
    that a finding is nearby — only that nothing here could place it.
    """
    city_country = collections.defaultdict(set)
    countries = set()
    for e in entries:
        city, country = e.get("city"), e.get("country")
        if city and country:
            city_country[fold(city)].add(country)
            countries.add(fold(country))
    return city_country, countries


def band_of(said, entry_city, entry_country, city_country, countries):
    """Which band a finding falls in, and the token that put it there.

    `said` is gate C's answer, e.g. "Casa del Mare, Forte dei Marmi". It is
    split on commas and brackets because the place and its city arrive as one
    string and either half may be the one we recognise.
    """
    tokens = [fold(t) for t in re.split(r"[,()]", said or "") if fold(t)]
    for t in tokens:
        if t in countries and t != fold(entry_country):
            return "cross-country", t
        # A city we carry, whose country is not this entry's country.
        if t in city_country and fold(entry_country) not in {
            fold(c) for c in city_country[t]
        }:
            return "cross-country", f'{t} ({"/".join(sorted(city_country[t]))})'
    for t in tokens:
        if t in city_country and t != fold(entry_city):
            return "cross-city", t
    return "same-area", ""


def rank(cache, catalog, ruled_titles):
    entries = list(catalog.get("tours", [])) + list(catalog.get("linkPins", []))
    by_id = {e["id"].upper(): e for e in entries}
    makers = {m["id"]: m.get("displayName", m["id"]) for m in catalog.get("makers", [])}
    city_country, countries = gazetteer(entries)

    out = {b: [] for b in BANDS}
    skipped = 0
    for key, rec in cache.items():
        if rec.get("verdict") != "CONTRADICTS":
            continue
        title = rec.get("title") or ""
        if fold(title) in ruled_titles:
            skipped += 1
            continue
        e = by_id.get(key.upper()) or {}
        band, why = band_of(rec.get("identified_as"), e.get("city", ""),
                            e.get("country", ""), city_country, countries)
        out[band].append({
            "id": key, "title": title, "said": rec.get("identified_as"),
            "maker": makers.get(e.get("makerId"), "?"),
            "city": e.get("city", "?"), "country": e.get("country", "?"),
            "why": why, "kind": e.get("kind", "tour"),
        })
    for band in out.values():
        band.sort(key=lambda r: (r["maker"], r["city"], r["title"]))
    return out, skipped


def selftest():
    ran = failed = 0

    def check(label, ok):
        nonlocal ran, failed
        ran += 1
        if not ok:
            failed += 1
            print(f"  FAIL {label}")

    cc = {"paris": {"France"}, "london": {"United Kingdom"},
          "york": {"United Kingdom"}}
    countries = {"france", "united kingdom"}

    check("a different country bands cross-country",
          band_of("La Villette, Paris", "London", "United Kingdom",
                  cc, countries)[0] == "cross-country")
    check("a different city in the same country bands cross-city",
          band_of("Something, York", "London", "United Kingdom",
                  cc, countries)[0] == "cross-city")
    check("the entry's own city bands same-area",
          band_of("A pub, London", "London", "United Kingdom",
                  cc, countries)[0] == "same-area")
    check("an unrecognised place bands same-area",
          band_of("Nowhere At All", "London", "United Kingdom",
                  cc, countries)[0] == "same-area")
    # 🔴 The accent case is the one the fold exists for. This must be written so
    # that LOSING the fold CHANGES the band -- an earlier version asserted
    # "same-area" and passed even with accent-stripping removed, because an
    # unfoldable token matches nothing and falls to same-area anyway. That test
    # was decorative: the mutation harness caught it, the selftest never could.
    accent = {"zurich": {"Switzerland"}}
    # The ACCENT must sit on the token being looked up, not on the key: the
    # gazetteer key is already folded, so an unfolded token is what fails to
    # match. Writing it the other way round tests nothing.
    check("an accented answer still resolves to its unaccented city",
          band_of("a bank, Zürich", "Paris", "France",
                  accent, {"france"})[0] == "cross-country")
    check("and a city is never foreign to its own accented spelling",
          band_of("a bank, Zurich", "Zürich", "Switzerland",
                  accent, {"switzerland"})[0] == "same-area")

    # 🔴 A BARE COUNTRY NAME is the first branch of band_of and had NO test at
    # all -- three separate mutants disabling or breaking it went undetected.
    check("a bare country name bands cross-country",
          band_of("Montmartre, France", "London", "United Kingdom",
                  cc, countries)[0] == "cross-country")
    check("the entry's OWN country named does not band cross-country",
          band_of("a pub, United Kingdom", "London", "United Kingdom",
                  cc, countries)[0] == "same-area")

    # gazetteer() is what every band is computed against; a city carrying no
    # country must not enter it, or a None country compares against everything.
    g_cities, g_countries = gazetteer([
        {"city": "Lisbon", "country": "Portugal"},
        {"city": "Nowhere", "country": None},
    ])
    check("a city with a country enters the gazetteer", "lisbon" in g_cities)
    check("a city with NO country does not", "nowhere" not in g_cities)
    check("and no empty country name is admitted", "" not in g_countries)
    check("gate C saying nothing bands same-area",
          band_of(None, "London", "United Kingdom", cc, countries)[0] == "same-area")
    # 🔴 "somewhere in France" does NOT band: the split is on commas and
    # brackets, so the country name is buried inside one token and never
    # matches. Asserted deliberately — this is a known false negative, and a
    # test that claimed otherwise would be describing code that does not exist.
    check("a country buried mid-phrase is missed, by design",
          band_of("somewhere in France", "London", "United Kingdom",
                  cc, {"france"})[0] == "same-area")

    # Paris must be IN the catalogue, because the catalogue IS the gazetteer
    # (see `gazetteer`): a city we do not carry cannot be located, so gate C
    # naming it bands as same-area. That is a real false negative, not a bug
    # this test should paper over — see the limitation noted in `gazetteer`.
    cat = {"tours": [{"id": "A", "city": "London", "country": "United Kingdom",
                      "makerId": "m", "stops": []},
                     {"id": "B", "city": "Paris", "country": "France",
                      "makerId": "m", "stops": []}],
           "linkPins": [], "makers": [{"id": "m", "displayName": "M"}]}
    cache = {"A": {"verdict": "CONTRADICTS", "title": "St Paul's",
                   "identified_as": "Sacre Coeur, Paris"}}
    got, skipped = rank(cache, cat, set())
    check("a real finding lands in a band", len(got["cross-country"]) == 1)
    check("nothing is skipped when nothing is ruled", skipped == 0)
    got, skipped = rank(cache, cat, {fold("St Paul's")})
    check("an owner-ruled title is dropped", skipped == 1)
    check("and does not appear in any band",
          sum(len(v) for v in got.values()) == 0)
    # A CONFIRMS must never reach a band, or the queue fills with passes.
    got, _ = rank({"A": {"verdict": "CONFIRMS", "title": "x",
                         "identified_as": "y, Paris"}}, cat, set())
    check("a CONFIRMS is not ranked", sum(len(v) for v in got.values()) == 0)

    print(f"selftest {ran - failed}/{ran} passed")
    return 1 if failed else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--cache", default=CACHE)
    ap.add_argument("--verdicts", default=VERDICTS)
    ap.add_argument("--band", choices=BANDS, help="print only this band, in full")
    ap.add_argument("--json", metavar="PATH", help="write every band as JSON")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        # 🔴 A check that cannot run must not be able to return a pass.
        for path in (a.catalog, a.cache):
            if not os.path.exists(path):
                print(f"COULD NOT VERIFY — missing {path}")
                return 2
        with open(a.catalog, encoding="utf-8") as fh:
            catalog = json.load(fh)
        with gzip.open(a.cache, "rt", encoding="utf-8") as fh:
            cache = json.load(fh)
        ruled = set()
        if os.path.exists(a.verdicts):
            with open(a.verdicts, encoding="utf-8") as fh:
                ruled = {fold(k) for k in json.load(fh)}

        bands, skipped = rank(cache, catalog, ruled)
        total = sum(len(v) for v in bands.values())
        print(f"{total} unruled CONTRADICTS · {skipped} already ruled on\n")
        for name in BANDS:
            rows = bands[name]
            print(f"{name:>14}: {len(rows)}")
        if a.band:
            print()
            for i, r in enumerate(bands[a.band], 1):
                print(f"{i:3d}. {r['title']}")
                print(f"      {r['city']}, {r['country']} · {r['maker']} · {r['kind']}")
                print(f"      picture looks like: {r['said']}")
        if a.json:
            with open(a.json, "w", encoding="utf-8") as fh:
                json.dump(bands, fh, indent=1, ensure_ascii=False)
            print(f"\nwrote {a.json}")
        return 1 if total else 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
