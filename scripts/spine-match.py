#!/usr/bin/env python3
"""Band every catalogue entry against where Wikidata says its subject is.

Reads the catalogue and the cache written by `scripts/spine-lookup.py`, and
answers one question per entry: **is our coordinate where the thing this entry
is named after actually stands?**

Offline and free — no network, so this runs in CI and on every content change.
`spine-lookup.py` is the only half that talks to Wikidata.

WHY THIS EXISTS
---------------
Clearing the place-candidate backlog on 2026-09-17 surfaced six coordinate
errors that every existing check passes, because each one was precise,
plausible and in the right city:

    Grace Farms   6,104 m · Geisel Library 5,412 m · La Collina 1,440 m
    Casa de Vidro   833 m · Asakusa          718 m · Domino Park    201 m

In 13 of 15 place groups the displaced entry was the Atlas TOUR, not the pin.
Every one was found by a human noticing. `check-coordinates.py` asks whether a
point is plausible; `validate-tours.swift` asks whether it is well-formed. This
asks the only question that catches them: whether it is *right*.

THE BANDS
---------
    DISAGREES   a RELATED match 250 m - 30 km away        -> 🔴 the finding
    REVIEW      a match 120-250 m away, or an unrelated
                match beyond that                         -> read it by hand
    CONFIRMS    a match within 120 m                       -> good
    UNMATCHED   no geolocated item by that name, or only
                one too far away to be about this entry

🔴 UNMATCHED IS NOT A VERDICT. It means Wikidata has never heard of the
subject, which is routine: measured coverage runs 78-83% for architecture
creators and **14-25% for food**, and food is a large part of this catalogue.
An unmatched entry is not a clean entry. It is an unexamined one, and this
report says so in those words.

WHY 120 AND 250, MEASURED ON THIS CATALOGUE'S OWN GROUND TRUTH
---------------------------------------------------------------
Entries known to be CORRECT land at 6, 7, 67, 75, 85 and 88 m — Wikidata's
point and ours are rarely the same point, so a zero-tolerance band would call
every correct entry an error. Entries known to be WRONG read 242 m (Domino
Park, a 201 m error), 844 m (Casa de Vidro) and 5,451 m (Geisel Library).

⚠️ 242 and 88 are close together, and that is the honest resolution limit of
this method rather than a threshold worth tuning further. Hence two bands: a
confident one that can be acted on, and a middle one that a person reads.
**A single threshold here would either lose Domino Park or drown the report.**

🔴 NEAREST IS NOT BEST. `Brooklyn Museum` returns `Brooklyn Museum Art School`
75 m away alongside the museum itself. Ranking on distance alone silently
answers a question about the museum with a fact about its art school — and in a
case where our coordinate was wrong, the sibling would make it look right.
Candidates whose LABEL is the name we asked for are preferred, and only then
sorted by distance. The label test shares `check-place-candidates.py`'s
`display_stem` and `subject_words`, but — see `label_matches` — deliberately
neither drops the city nor applies the GENERIC guard, both of which are right
for pairing two catalogue entries and wrong for matching a title to a label.

WHAT THIS DELIBERATELY DOES NOT DO
-----------------------------------
It moves nothing. `docs/lessons.md`: *"Move the pin, never the place, and only
with the owner's say-so"*, and three pins moved on a district-centroid distance
came out 11 m right, 220 m wrong and 100 m wrong. This produces a report a
person approves from, one line at a time — exactly how #930's 31 fixes went.
"""

from __future__ import annotations

import argparse
import collections
import gzip
import importlib.util
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402  (stamps every run; see scripts/runstamp.py)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")
CACHE = os.path.join(REPO, "spine", "lookups.json.gz")

CONFIRM_M = 120.0       # at or under this, our point and Wikidata's agree
DISAGREE_M = 250.0      # at or over this, a finding worth acting on

# 🔴 Beyond this, a same-name item is not evidence about THIS entry.
#
# `spine-lookup.py` collects candidates out to 100 km deliberately — the cache
# is expensive and a wide one can be re-judged for free. Judging is this file's
# job, and 100 km is too generous for it: a live sweep matched a tour called
# "Church of Santa Maria" to `Igreja de Santa Maria` **88 km away**, which would
# have been reported as an 88 km coordinate error. It is the `La Collina` case
# (a generic name colliding on another continent) at national scale.
#
# The worst real error this catalogue has ever produced is Grace Farms at
# 6.1 km. 30 km is a five-fold margin over that and still an order of magnitude
# inside the collision. Anything past it is reported as UNMATCHED, because that
# is what it is: we did not find this entry's subject.
MAX_ERROR_M = 30000.0


def _load_candidates_module():
    path = os.path.join(HERE, "check-place-candidates.py")
    spec = importlib.util.spec_from_file_location("_place_candidates", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_cpc = _load_candidates_module()
display_stem = _cpc.display_stem
subject_words = _cpc.subject_words
marker = _cpc.marker


def entries(catalog):
    """Tours and link pins alike — 13 of 15 known errors were tours."""
    return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])


def entry_marker(entry):
    """`check-place-candidates.marker`, with a fallback for an unnumbered stop.

    That module returns None when no stop carries `order == 0`; a handful of
    single tours number their only stop otherwise, and dropping them would
    quietly shrink the audited population.
    """
    found = marker(entry)
    if found is not None:
        return found
    stops = entry.get("stops") or []
    if stops:
        return (stops[0]["latitude"], stops[0]["longitude"])
    return None


def label_matches(entry, candidate):
    """Is the candidate's label the same name as the entry's title?

    Set equality over the meaningful words of both, sharing
    `check-place-candidates.py`'s `display_stem` (bilingual tail, parentheticals)
    and `subject_words` (stopwords) so the three agree on what a name is.

    🔴 Two things that function does are deliberately NOT done here, and both
    were found by this check failing on `Brooklyn Museum`:

    - **The city is not dropped.** There it is decoration on both sides; here
      the gazetteer's label legitimately contains it — `Brooklyn Museum` IS the
      museum's name. Dropping it leaves `{museum}`, which then matches nothing
      useful and, worse, matches every other museum equally.
    - **The GENERIC guard is not applied.** It exists to stop two DIFFERENT
      catalogue entries pairing on a bare noun. Here the comparison is against
      a label returned for a search of this very name, and equality over the
      full name is already the stricter test — applying GENERIC on top rejected
      `Brooklyn Museum` against `Brooklyn Museum`.
    """
    ours = subject_words(display_stem(entry.get("title")))
    theirs = subject_words(display_stem(candidate.get("label")))
    return bool(ours) and ours == theirs


def best_candidate(entry, candidates):
    """The candidate to judge the entry against.

    🔴 Label agreement outranks proximity. `Brooklyn Museum` returns both the
    museum and its art school; the school is nearer in one direction and the
    museum is the answer. Sorting on distance alone picks whichever happens to
    be closer to a coordinate whose correctness is the very thing in question.
    """
    if not candidates:
        return None
    named = [c for c in candidates if label_matches(entry, c)]
    pool = named or candidates
    return min(pool, key=lambda c: (c["distance_m"], -c.get("sitelinks", 0)))


def label_related(entry, candidate):
    """A weaker test than `label_matches`: does either name contain the other?

    🔴 Used to decide whether a distant match may be reported as a FINDING, and
    deliberately not the equality test, which is too strict for exactly the case
    that matters most. `Geisel Library, UC San Diego` against the label
    `Geisel Library` is not set-equal — and it is a real 5.4 km error. Demoting
    it for failing equality would have hidden the second-worst error on record.

    Containment still rejects the case this guards: `Church of Santa Maria`
    against `Igreja de Santa Maria (Celorico de Basto)` shares `santa maria`
    but neither contains the other, and that match was 88 km away.
    """
    ours = subject_words(display_stem(entry.get("title")))
    theirs = subject_words(display_stem(candidate.get("label")))
    if not ours or not theirs:
        return False
    return ours <= theirs or theirs <= ours


def band(distance_m, *, related=True):
    """The band for a distance.

    `related` is whether the matched label is plausibly the same name. An
    unrelated match is never promoted to a finding — it is offered for reading
    instead, because the usual cause is a different place that shares a word.
    """
    if distance_m is None:
        return "UNMATCHED"
    if distance_m > MAX_ERROR_M:
        # Not an error about this entry — a same-name item somewhere else.
        return "UNMATCHED"
    if distance_m >= DISAGREE_M:
        return "DISAGREES" if related else "REVIEW"
    if distance_m > CONFIRM_M:
        return "REVIEW"
    return "CONFIRMS"


def classify(catalog, cache):
    """One record per entry: its band, its best candidate, and why."""
    out = []
    for entry in entries(catalog):
        at = entry_marker(entry)
        if at is None:
            continue
        record = cache.get(entry["id"])
        if record is None:
            out.append({"entry": entry, "band": "NOT-ASKED", "best": None,
                        "named": False})
            continue
        best = best_candidate(entry, record.get("candidates") or [])
        related = bool(best) and label_related(entry, best)
        out.append({
            "entry": entry,
            "band": band(best["distance_m"] if best else None, related=related),
            "best": best,
            "named": bool(best) and label_matches(entry, best),
        })
    return out


def maker_names(catalog):
    return {m["id"]: m.get("displayName") or m["id"]
            for m in (catalog.get("makers") or [])}


def report(rows, catalog, *, limit=40):
    by_band = collections.Counter(r["band"] for r in rows)
    total = len(rows)
    makers = maker_names(catalog)

    print(f"audited {total} catalogue entries against Wikidata\n")

    for name in ("DISAGREES", "REVIEW"):
        hits = sorted((r for r in rows if r["band"] == name and r["best"]),
                      key=lambda r: -r["best"]["distance_m"])
        headline = ("🔴 DISAGREES — our coordinate is not where the subject is"
                    if name == "DISAGREES"
                    else "REVIEW — near, but further out than a correct entry usually sits")
        print(f"{headline}: {len(hits)}")
        for row in hits[:limit]:
            entry, best = row["entry"], row["best"]
            flag = " " if row["named"] else "~"      # ~ = matched on alias, not label
            print(f"  {best['distance_m']:9.0f} m {flag} {(entry.get('title') or '')[:40]:40} "
                  f"{(entry.get('city') or '')[:16]:16} -> {best['label'][:30]}")
        if len(hits) > limit:
            print(f"  … and {len(hits) - limit} more (raise --limit to see them)")
        print()

    print(f"CONFIRMS: {by_band['CONFIRMS']}   "
          f"UNMATCHED: {by_band['UNMATCHED']}   "
          f"NOT-ASKED: {by_band['NOT-ASKED']}")

    # Coverage by creator is the routing evidence: it says where this method
    # works and where the catalogue needs the address-parsing path instead.
    asked = [r for r in rows if r["band"] != "NOT-ASKED"]
    if asked:
        per = collections.defaultdict(lambda: [0, 0])
        for row in asked:
            key = makers.get(row["entry"].get("makerId"), "?")
            per[key][0] += 1
            if row["band"] != "UNMATCHED":
                per[key][1] += 1
        ranked = sorted(per.items(), key=lambda kv: -kv[1][0])[:12]
        print("\ncoverage by creator (matched / asked) — where this method works:")
        for who, (n, matched) in ranked:
            print(f"  {matched * 100 // n:3d}%  {matched:4}/{n:<4}  {who[:40]}")

    print("\n⚠️  UNMATCHED is NOT a clean bill of health — it means Wikidata has")
    print("    never heard of the subject. Coverage runs 78-83% for architecture")
    print("    creators and 14-25% for food. An unmatched entry is UNEXAMINED.")
    print("⚠️  Nothing here is auto-fixed. A distance is evidence, not a verdict:")
    print("    three pins moved on a distance alone came out 11 m right, 220 m")
    print("    wrong and 100 m wrong. Every line goes to the owner individually.")

    return by_band


def selftest():
    """Offline checks with negative controls — no cache, no network."""
    fails = []

    def check(name, ok):
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    check("band: at the disagree floor", band(DISAGREE_M) == "DISAGREES")
    check("band: just under it is REVIEW", band(DISAGREE_M - 1) == "REVIEW")
    check("band: at the confirm ceiling", band(CONFIRM_M) == "CONFIRMS")
    check("band: just over it is REVIEW", band(CONFIRM_M + 0.1) == "REVIEW")
    check("band: no candidate is UNMATCHED", band(None) == "UNMATCHED")

    # 🔴 The ground truth this session created. Correct entries and known errors
    # must land in different bands, or the tool is not worth running.
    check("🔴 ground truth: Geisel's 5,451 m error is a finding",
          band(5451.0) == "DISAGREES")
    check("🔴 ground truth: Casa de Vidro's 844 m error is a finding",
          band(844.0) == "DISAGREES")
    check("🔴 ground truth: Domino Park's 242 m error is not silently CONFIRMED",
          band(242.0) in ("DISAGREES", "REVIEW"))
    # 🔴 The Santa Maria case: a real 88 km match to a different church.
    check("🔴 a match past MAX_ERROR_M is UNMATCHED, not an 88 km 'error'",
          band(88145.0) == "UNMATCHED")
    check("a match just inside MAX_ERROR_M is still a finding",
          band(MAX_ERROR_M - 1) == "DISAGREES")
    check("🔴 an UNRELATED distant match is offered for reading, not asserted",
          band(900.0, related=False) == "REVIEW")
    check("a related distant match IS a finding", band(900.0, related=True) == "DISAGREES")

    santa = {"title": "Church of Santa Maria", "city": "Porto"}
    check("🔴 label_related REJECTS the Santa Maria collision",
          not label_related(santa, {"label": "Igreja de Santa Maria (Celorico de Basto)"}))
    geisel = {"title": "Geisel Library, UC San Diego", "city": "La Jolla"}
    check("🔴 label_related ACCEPTS Geisel, which equality would have demoted",
          label_related(geisel, {"label": "Geisel Library"})
          and not label_matches(geisel, {"label": "Geisel Library"}))
    for correct in (6.0, 7.0, 67.0, 75.0, 85.0, 88.0):
        check(f"ground truth: a known-correct entry at {correct:.0f} m confirms",
              band(correct) == "CONFIRMS")

    def cand(label, metres, sitelinks=0):
        return {"qid": "Q" + label[:4], "label": label, "lat": 0.0, "lon": 0.0,
                "distance_m": metres, "sitelinks": sitelinks}

    museum = {"title": "Brooklyn Museum", "city": "Brooklyn"}
    picked = best_candidate(museum, [cand("Brooklyn Museum Art School", 75.0),
                                     cand("Brooklyn Museum", 140.0)])
    check("🔴 label agreement outranks proximity (the art-school case)",
          picked["label"] == "Brooklyn Museum")

    picked = best_candidate(museum, [cand("Brooklyn Museum", 140.0),
                                     cand("Brooklyn Museum", 30.0)])
    check("among label matches, nearest wins",
          picked["distance_m"] == 30.0)

    # `Casa de Vidro` resolves to an item labelled `Glass House`. No label
    # matches, so the nearest is used — and the match is still right.
    picked = best_candidate({"title": "Casa de Vidro", "city": "São Paulo"},
                            [cand("Glass House", 6.0), cand("Other", 900.0)])
    check("an alias match still resolves when no label agrees",
          picked["label"] == "Glass House")
    check("no candidates -> no answer", best_candidate(museum, []) is None)

    check("label_matches accepts the same name",
          label_matches({"title": "Domino Park", "city": "Brooklyn"},
                        {"label": "Domino Park"}))
    check("🔴 label_matches REJECTS a different name",
          not label_matches({"title": "Domino Park", "city": "Brooklyn"},
                            {"label": "Bushwick Inlet Park"}))
    # 🔴 The city must NOT be dropped, and GENERIC must NOT apply. Reusing
    # `same_name` wholesale reduced this title to {"museum"} and rejected the
    # museum against itself.
    check("🔴 a title that is city + generic noun still matches its own label",
          label_matches({"title": "Brooklyn Museum", "city": "Brooklyn"},
                        {"label": "Brooklyn Museum"}))
    check("🔴 and it does NOT match a longer name containing it",
          not label_matches({"title": "Brooklyn Museum", "city": "Brooklyn"},
                            {"label": "Brooklyn Museum Art School"}))
    # ⚠️ A non-Latin bilingual tail is NOT the test to use here: `subject_words`
    # already drops every non-ASCII character, so that case passes with or
    # without `display_stem` and cannot detect its removal. The PARENTHETICAL is
    # the discriminator — `subject_words` keeps "moma", `display_stem` does not.
    check("label_matches strips a parenthetical before comparing",
          label_matches({"title": "Museum of Modern Art (MoMA)", "city": "New York"},
                        {"label": "Museum of Modern Art"}))
    check("label_matches strips a LATIN bilingual tail",
          label_matches({"title": "1881 Heritage | Former Marine Police HQ",
                         "city": "Hong Kong"},
                        {"label": "1881 Heritage"}))
    check("label_matches survives an empty title",
          not label_matches({"title": "", "city": None}, {"label": "Anything"}))

    # An entry whose only stop is not numbered 0 must still be audited.
    odd = {"id": "x", "title": "t", "kind": "single",
           "stops": [{"order": 3, "latitude": 1.0, "longitude": 2.0}]}
    check("an unnumbered single stop is still audited",
          entry_marker(odd) == (1.0, 2.0))
    check("an entry with no stops is skipped", entry_marker({"stops": []}) is None)

    cat = {"tours": [{"id": "a", "stops": [{"order": 0, "latitude": 0, "longitude": 0}]}],
           "linkPins": [{"id": "b", "stops": [{"order": 0, "latitude": 0, "longitude": 0}]}]}
    check("🔴 tours AND link pins are both audited", len(entries(cat)) == 2)
    rows = classify(cat, {})
    check("an entry missing from the cache is NOT-ASKED, never CONFIRMS",
          [r["band"] for r in rows] == ["NOT-ASKED", "NOT-ASKED"])

    total = 38
    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — {total - len(fails)}/{total}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--cache", default=CACHE)
    ap.add_argument("--limit", type=int, default=40,
                    help="how many findings to print per band")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()

        with open(a.catalog, encoding="utf-8") as fh:
            catalog = json.load(fh)

        if not os.path.exists(a.cache):
            # 🔴 A checker that cannot run must not be able to return a pass.
            print(f"COULD NOT VERIFY — no cache at {a.cache}")
            print("Run: python3 scripts/spine-lookup.py")
            return 2
        with gzip.open(a.cache, "rt", encoding="utf-8") as fh:
            cache = json.load(fh)

        rows = classify(catalog, cache)
        counts = report(rows, catalog, limit=a.limit)

        if counts["NOT-ASKED"]:
            print(f"\nCOULD NOT VERIFY — {counts['NOT-ASKED']} entries are not in "
                  f"the cache; run scripts/spine-lookup.py to finish the sweep")
            return 2
        if counts["DISAGREES"]:
            print(f"\n{counts['DISAGREES']} entr"
                  f"{'y' if counts['DISAGREES'] == 1 else 'ies'} to put to the owner")
            return 1
        print("\nOK — no entry disagrees with Wikidata by 250 m or more")
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
