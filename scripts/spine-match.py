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
import re
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

FEATURES = os.path.join(REPO, "spine", "features.json.gz")

# 🔴 A SITE WITH NO SINGLE POINT HAS NO SINGLE COORDINATE, so a distance to its
# centroid is not evidence of anything. Ours sits at the entrance, or the famous
# view, or the stop the tour begins at; the gazetteer's sits in the middle.
#
# These are the `instance of` values that actually dominated the first full
# audit's 145 DISAGREES — **read off the data, not guessed** — with their
# Wikidata labels confirmed rather than assumed:
#
#   Q123705 neighborhood · Q22698 park · Q22746 urban park · Q167346 botanical
#   garden · Q1759852 sculpture garden · Q8502 mountain · Q54050 hill ·
#   Q79007 street · Q83620 thoroughfare · Q34442 road · Q95080679 national park
#   of Thailand · Q644371 international airport · Q94993988 commercial traffic
#   aerodrome · Q1576693 gondola lift · Q142031 funicular · Q40080 beach ·
#   Q23442 island · Q12280 bridge · Q537127 road bridge · Q158218 truss bridge
#
# ⚠️ Bridges and lifts are here because they are LINEAR, not because they are
# large: the Vasco da Gama Bridge is 12 km end to end, so its midpoint is
# kilometres from any viewpoint a tour would send someone to.
#
# ⚠️ Buildings, museums, hotels, houses, monuments and churches are deliberately
# ABSENT. Those have an honest single point, so a disagreement about one is a
# finding.
EXTENDED_TYPES = {
    "Q123705", "Q22698", "Q22746", "Q167346", "Q1759852",
    "Q8502", "Q54050", "Q23442", "Q40080",
    "Q79007", "Q83620", "Q34442",
    "Q95080679", "Q46169", "Q1377575",
    "Q644371", "Q94993988", "Q1248784",
    "Q1576693", "Q142031",
    "Q12280", "Q537127", "Q158218",
    "Q4022", "Q12284", "Q39614", "Q174782",
}


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


def _load_lookup_module():
    """`ask_digest` from the fetcher, so both halves agree on what a cached
    answer depends on. Re-implementing it here would let the two drift, and a
    drifted staleness check is worse than none: it would cry stale forever."""
    path = os.path.join(HERE, "spine-lookup.py")
    spec = importlib.util.spec_from_file_location("_spine_lookup", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


ask_digest = _load_lookup_module().ask_digest


def is_stale(entry, at, record):
    """Was this cached answer computed against the entry we hold TODAY?

    🔴 Without this the tool reports a distance measured from a point the
    catalogue no longer holds, and it does so with no warning at all. That cuts
    BOTH ways, and the second way is the dangerous one:

      * a coordinate we already CORRECTED keeps being reported as broken
        (Belgrade Tower read 2,329 m out for hours after it was moved onto
        Wikidata's own point, which is a 0 m agreement);
      * a coordinate someone moves to the WRONG place keeps reporting its OLD
        distance, so the one check that exists to police such a move is blind
        to it, and CI stays green.

    The bound comes from the RECORD, not from this run: the bound is the
    fetcher's business, and the two things a reporter can see change are the
    title and the marker.
    """
    return ask_digest(entry.get("title"), at,
                      record.get("bound_km", 100.0)) != record.get("digest")


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

    🔴 THE ENTRY'S CITY WORDS ARE DROPPED FROM BOTH SIDES FIRST, and without
    that this reintroduces a bug the project has already paid for once.
    `Municipal Library of Viana do Castelo` contains `Viana do Castelo` — so
    plain containment promotes a match against **the town itself**, 464 m away,
    into a finding about the library. It is the same shape as `Akihabara`
    matching `Gyukatsu Ichi Ni San, Akihabara`, which is why
    `check-place-candidates.same_name` uses equality rather than containment.

    Dropping the city leaves `{municipal, library}` against `{}` — empty, so
    rejected — while `Geisel Library, UC San Diego` against `Geisel Library`
    still leaves `{geisel, library}` inside `{geisel, library, uc, san, diego}`
    and is still accepted. The distinctive word is what has to survive.

    ⚠️ Dropping the city is not enough on its own, because the containing thing
    is not always the `city` field. `Gyukatsu Ichi Ni San, Akihabara` sits in a
    city recorded as `Tokyo`, so `Akihabara` survives the drop and is still a
    subset. The second rule below is what rejects it: an English title names its
    subject FIRST and its locator LAST, so a candidate that is a subset of our
    title must contain our title's HEAD word to be about the same thing.
    `Geisel Library` carries `geisel`; `Akihabara` does not carry `gyukatsu`.
    """
    city = entry.get("city")
    ours = subject_words(display_stem(entry.get("title")), city)
    theirs = subject_words(display_stem(candidate.get("label")), city)
    if not ours or not theirs:
        return False
    if ours <= theirs:
        return True                     # they name our subject and then some
    if theirs <= ours:
        head = head_word(entry.get("title"), city, ours)
        return head is not None and head in theirs
    return False


def head_word(title, city, meaningful):
    """The first meaningful word of a title — the subject, not the locator."""
    normalised = re.sub(r"[^a-z0-9 ]", " ", display_stem(title or "").lower())
    for word in normalised.split():
        if word in meaningful:
            return word
    return None


def is_extended(qid, features):
    """Is the matched item a site with no single honest point?

    ⚠️ Reporting aid, never a verdict: such an entry is still listed, under a
    heading that says what it is, so a reader sees "a four-mile boulevard, of
    course the centroid differs" rather than "4,486 m, something is broken".
    An absent features file simply means nothing is reclassified.
    """
    row = (features or {}).get(qid) or {}
    return any(t in EXTENDED_TYPES for t in row.get("types") or [])


def band(distance_m, *, related=True, extended=False):
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
    if distance_m <= CONFIRM_M:
        return "CONFIRMS"
    if extended:
        # An area or a line, not a point. Reported, but never as a finding.
        return "EXTENDED"
    if distance_m >= DISAGREE_M:
        return "DISAGREES" if related else "REVIEW"
    return "REVIEW"


VERDICTS = os.path.join(REPO, "checks", "spine-verdicts.json")

# A verdict is stamped with the coordinate it was reached against, to 7 dp. A
# move smaller than this is rounding, not an edit.
VERDICT_EPS = 5e-7


def verdict_applies(entry, at, record):
    """Does this recorded verdict still describe the entry in front of us?

    🔴 Only while the entry has not moved. A verdict is a judgement about ONE
    coordinate: `wikidata-elsewhere` says *our* point is right and theirs is
    not, and the moment ours changes nobody has judged the new one. Carrying the
    verdict across the move would suppress the finding permanently — silence
    that looks exactly like agreement, on the one defect CLAUDE.md calls
    invisible to every other check.

    This is the same rule the lookup cache needed, for the same reason and after
    the same failure: an answer is only valid for the point it was measured
    from, and every READER of the answer has to enforce that, not just whoever
    wrote it.

    A record with no `at` is not trusted. It cannot be — there is nothing to
    compare, so "unstamped" and "unmoved" would be indistinguishable.
    """
    if not record:
        return False
    was = record.get("at")
    if not was or len(was) != 2:
        return False
    return (abs(was[0] - at[0]) <= VERDICT_EPS
            and abs(was[1] - at[1]) <= VERDICT_EPS)


def load_verdicts(path=VERDICTS):
    """Missing file is not an error — the audit simply rules nothing out."""
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def classify(catalog, cache, features=None, verdicts=None):
    """One record per entry: its band, its best candidate, and why."""
    out = []
    for entry in entries(catalog):
        at = entry_marker(entry)
        if at is None:
            continue
        record = cache.get(entry["id"])
        if record is None:
            out.append({"entry": entry, "band": "NOT-ASKED", "best": None,
                        "named": False, "verdict": None})
            continue
        if is_stale(entry, at, record):
            # 🔴 Not banded, and deliberately given no distance. A number
            # measured from a coordinate this entry no longer sits on is not a
            # weaker answer than none — it is a confident wrong one.
            out.append({"entry": entry, "band": "STALE", "best": None,
                        "named": False, "verdict": None})
            continue
        best = best_candidate(entry, record.get("candidates") or [])
        related = bool(best) and label_related(entry, best)
        extended = bool(best) and is_extended(best["qid"], features)
        ruling = (verdicts or {}).get(entry.get("title") or "")
        out.append({
            "entry": entry,
            "band": band(best["distance_m"] if best else None,
                         related=related, extended=extended),
            "best": best,
            "named": bool(best) and label_matches(entry, best),
            # 🔴 The verdict rides ALONGSIDE the band, never replacing it. A
            # ruled entry that later stops confirming — a fix reverted by a bad
            # merge — must still be visible as a finding, and it would not be if
            # the ruling overwrote the band.
            "verdict": (ruling.get("verdict")
                        if verdict_applies(entry, at, ruling) else None),
        })
    return out


def covered_rows(rows):
    """The rows this method actually answered for — the coverage denominator.

    🔴 STALE belongs out here with NOT-ASKED. Coverage is the claim "Wikidata
    knows this subject", and a row cached against an entry we no longer hold
    supports that claim no better than one never asked about at all. Counting it
    would quietly inflate the one figure that decides where the address-parsing
    path is needed instead.
    """
    return [r for r in rows if r["band"] not in ("NOT-ASKED", "STALE")]


def exit_code(counts):
    """0 clean · 1 findings to read · 2 the check could not answer.

    🔴 2 is not a worse 1. It means entries exist that this run CANNOT speak
    for, and it must win over both of the others: a run that reports
    "no entry disagrees" while holding rows it never evaluated is the exact
    shape CLAUDE.md calls a check that cannot run returning a pass.
    """
    if counts.get("STALE"):
        return 2
    if counts.get("NOT-ASKED"):
        return 2
    if counts.get("DISAGREES"):
        return 1
    return 0


def maker_names(catalog):
    return {m["id"]: m.get("displayName") or m["id"]
            for m in (catalog.get("makers") or [])}


def report(rows, catalog, *, limit=40):
    by_band = collections.Counter(r["band"] for r in rows)
    total = len(rows)
    makers = maker_names(catalog)

    print(f"audited {total} catalogue entries against Wikidata\n")

    stale = [r for r in rows if r["band"] == "STALE"]
    if stale:
        print(f"⚠️  STALE — moved or renamed since the cache was built, so this "
              f"run CANNOT speak for them: {len(stale)}")
        for row in stale[:limit]:
            entry = row["entry"]
            print(f"  {'':11} {(entry.get('title') or '')[:40]:40} "
                  f"{(entry.get('city') or '')[:16]:16}")
        if len(stale) > limit:
            print(f"  … and {len(stale) - limit} more (raise --limit to see them)")
        print("  Re-run: python3 scripts/spine-lookup.py   "
              "(digest-gated — it re-asks only these)\n")

    for name in ("DISAGREES", "REVIEW", "EXTENDED"):
        hits = sorted((r for r in rows if r["band"] == name and r["best"]),
                      key=lambda r: -r["best"]["distance_m"])
        headline = {
            "DISAGREES": "🔴 DISAGREES — our coordinate is not where the subject is",
            "REVIEW": "REVIEW — near, but further out than a correct entry usually sits",
            "EXTENDED": ("EXTENDED SITE — a park, street, bridge, island or district. "
                         "NOT a finding: no single point is honest for these"),
        }[name]
        # ⚠️ Only the two FINDING bands. EXTENDED is not a finding — it is a
        # heading that explains a distance — so subtracting its ruled rows
        # would print a count smaller than the band, explaining nothing.
        ruled = [r for r in hits if r["verdict"]] if name != "EXTENDED" else []
        hits = [r for r in hits if r not in ruled]
        if ruled:
            tally = ", ".join(f"{n} {v}" for v, n in
                              collections.Counter(r["verdict"] for r in ruled).most_common())
            print(f"{headline}: {len(hits)} unexamined "
                  f"({len(ruled)} already ruled — {tally})")
        else:
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
          f"EXTENDED: {by_band['EXTENDED']}   "
          f"UNMATCHED: {by_band['UNMATCHED']}   "
          f"STALE: {by_band['STALE']}   "
          f"NOT-ASKED: {by_band['NOT-ASKED']}")

    # Coverage by creator is the routing evidence: it says where this method
    # works and where the catalogue needs the address-parsing path instead.
    asked = covered_rows(rows)
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
    print("⚠️  EXTENDED SITE entries are separated out, not fixed: a park, a")
    print("    street, a long bridge or a district has no single honest point, so")
    print("    the distance to a centroid means nothing. They are listed so you")
    print("    can see them, never because they are wrong.")
    print("⚠️  Nothing here is auto-fixed. A distance is evidence, not a verdict:")
    print("    three pins moved on a distance alone came out 11 m right, 220 m")
    print("    wrong and 100 m wrong. Every line goes to the owner individually.")

    by_band["RULED"] = sum(1 for r in rows if r["verdict"])
    # 🔴 What exit 1 must mean is "there is something here nobody has looked
    # at". Counting a ruled row would keep the check shouting about 44 findings
    # that were each read and settled, and a check that always shouts is one
    # nobody reads.
    by_band["DISAGREES"] = sum(1 for r in rows
                               if r["band"] == "DISAGREES" and not r["verdict"])
    if by_band["RULED"]:
        print(f"\nRULED: {by_band['RULED']} entries carry a recorded verdict that "
              f"still applies — checks/spine-verdicts.json")
        print("⚠️  A verdict is stamped with the coordinate it was reached against "
              "and\n    STOPS APPLYING the moment that coordinate moves: nobody has "
              "judged\n    the new point, and silence would look exactly like "
              "agreement.")
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
    # 🔴 The extended-site band. A park's centroid is not evidence.
    check("🔴 an EXTENDED site is never a finding, however far",
          band(4486.0, related=True, extended=True) == "EXTENDED")
    check("...but a close extended site still CONFIRMS",
          band(50.0, related=True, extended=True) == "CONFIRMS")
    check("a POINT-type match at the same distance IS a finding",
          band(4486.0, related=True, extended=False) == "DISAGREES")
    feats = {"Q1": {"types": ["Q22698"]}, "Q2": {"types": ["Q41176"]}, "Q3": {}}
    check("is_extended: a park is extended", is_extended("Q1", feats))
    check("🔴 is_extended: a BUILDING is not", not is_extended("Q2", feats))
    check("is_extended: an untyped item is not", not is_extended("Q3", feats))
    check("is_extended: no features file means nothing is reclassified",
          not is_extended("Q1", None))
    check("a related distant match IS a finding", band(900.0, related=True) == "DISAGREES")

    santa = {"title": "Church of Santa Maria", "city": "Porto"}
    check("🔴 label_related REJECTS the Santa Maria collision",
          not label_related(santa, {"label": "Igreja de Santa Maria (Celorico de Basto)"}))
    geisel = {"title": "Geisel Library, UC San Diego", "city": "La Jolla"}
    check("🔴 label_related ACCEPTS Geisel, which equality would have demoted",
          label_related(geisel, {"label": "Geisel Library"})
          and not label_matches(geisel, {"label": "Geisel Library"}))
    # 🔴 The containment trap, live-caught: the TOWN is not the library in it.
    viana = {"title": "Municipal Library of Viana do Castelo",
             "city": "Viana do Castelo"}
    check("🔴 label_related REJECTS the containing town",
          not label_related(viana, {"label": "Viana do Castelo"}))
    check("...while still accepting the library itself",
          label_related(viana, {"label": "Municipal Library of Viana do Castelo"}))
    # The same shape one level down: a venue inside a named district.
    akiba = {"title": "Gyukatsu Ichi Ni San, Akihabara", "city": "Tokyo"}
    check("🔴 label_related REJECTS the containing district",
          not label_related(akiba, {"label": "Akihabara"}))
    check("...and the head-word rule keeps a trailing qualifier working",
          label_related({"title": "Times Square — The View from the Red Steps",
                         "city": "New York"}, {"label": "Times Square"}))
    check("head_word is the first MEANINGFUL word, not the first word",
          head_word("The Brooklyn Museum", "Brooklyn", {"museum"}) == "museum")
    # 🔴 The city drop, tested where the head-word rule does NOT already cover
    # it: a title that LEADS with its city. Without the drop the head word is
    # the city itself, so the borough matches the botanic garden inside it.
    bbg = {"title": "Brooklyn Botanic Garden", "city": "Brooklyn"}
    check("🔴 a title leading with its city does not match the city",
          not label_related(bbg, {"label": "Brooklyn"}))
    check("...and still matches its own name",
          label_related(bbg, {"label": "Brooklyn Botanic Garden"}))
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

    # 🔴 The staleness guard. Belgrade Tower read 2,329 m out for hours AFTER it
    # had been moved onto Wikidata's own point, because the cache still held the
    # distance from where it used to sit. The same blindness hides a bad move.
    def _cached(title, at, *, distance_m=10.0, label=None, bound_km=100.0):
        return {"digest": ask_digest(title, at, bound_km), "bound_km": bound_km,
                "at": list(at), "candidates": [
                    {"label": label or title, "qid": "Q1", "sitelinks": 5,
                     "lat": at[0], "lon": at[1], "distance_m": distance_m}]}

    def _entry(title, at):
        return {"id": "s", "title": title, "city": "C", "kind": "single",
                "stops": [{"order": 0, "latitude": at[0], "longitude": at[1]}]}

    here, moved = (10.0, 20.0), (10.02, 20.0)
    one = {"tours": [_entry("Tower", here)], "linkPins": []}
    check("a cache built against today's entry is used, not refused",
          [r["band"] for r in classify(one, {"s": _cached("Tower", here)})]
          == ["CONFIRMS"])
    check("🔴 an entry MOVED since the cache was built is STALE, not CONFIRMS",
          [r["band"] for r in classify(one, {"s": _cached("Tower", moved)})]
          == ["STALE"])
    check("🔴 an entry RENAMED since the cache was built is STALE",
          [r["band"] for r in classify(one, {"s": _cached("Other", here)})]
          == ["STALE"])
    stale_row = classify(one, {"s": _cached("Tower", moved, distance_m=9000.0)})[0]
    check("🔴 a STALE row carries NO distance — a stale number is a confident "
          "wrong answer, not a weak one", stale_row["best"] is None)
    check("🔴 a STALE row does not count as covered by this method",
          "STALE" not in {r["band"] for r in classify(one, {"s": _cached("Tower", here)})})
    # The bound is the fetcher's business: reading it from the record is what
    # keeps this guard reporting only what a reporter can actually see change.
    check("the record's own bound is used, so a differing bound is not 'stale'",
          [r["band"] for r in classify(one, {"s": _cached("Tower", here, bound_km=7.0)})]
          == ["CONFIRMS"])
    check("a real move is detected below the rounding the digest applies",
          is_stale(_entry("Tower", (10.0, 20.0)), (10.0, 20.0),
                   _cached("Tower", (10.00001, 20.0))))

    # 🔴 classify() must WIRE band()'s arguments, not merely have them. The
    # thresholds were tested directly above and passed while the call site could
    # still have hard-coded either flag.
    unrelated = {"s": _cached("Tower", here, distance_m=900.0, label="Somewhere Else")}
    check("🔴 classify passes `related` through: an unrelated distant label is "
          "offered for reading, never asserted",
          [r["band"] for r in classify(one, unrelated)] == ["REVIEW"])
    park = {"s": _cached("Tower", here, distance_m=4486.0)}
    check("🔴 classify passes `extended` through: a known extended site is not "
          "a finding", [r["band"] for r in classify(one, park, {"Q1": {"types": ["Q22698"]}})]
          == ["EXTENDED"])
    check("classify without the features file still reports that site",
          [r["band"] for r in classify(one, park)] == ["DISAGREES"])

    # 🔴 The exit-code contract. 2 must beat both of the others: a run that
    # prints "no entry disagrees" while holding rows it never evaluated is a
    # check that could not run returning a pass.
    check("exit 0 when nothing disagrees", exit_code({}) == 0)
    check("exit 1 on findings", exit_code({"DISAGREES": 3}) == 1)
    check("exit 2 when entries were never asked about",
          exit_code({"NOT-ASKED": 1}) == 2)
    check("🔴 exit 2 when entries are STALE, even with no findings",
          exit_code({"STALE": 1}) == 2)
    check("🔴 STALE outranks findings — it is not a milder 1",
          exit_code({"STALE": 1, "DISAGREES": 9}) == 2)

    # 🔴 A verdict is a judgement about ONE coordinate. Carrying it across a
    # move would suppress a finding on a point nobody has judged — silence that
    # looks exactly like agreement. Same rule as the lookup cache, same reason.
    ruled = {"Tower": {"verdict": "wikidata-elsewhere", "at": list(here)}}
    rows = classify(one, {"s": _cached("Tower", here, distance_m=900.0)}, None, ruled)
    check("a verdict stamped on today's coordinate applies",
          rows[0]["verdict"] == "wikidata-elsewhere")
    check("🔴 the BAND is unchanged by a verdict — a ruled entry that stops "
          "confirming must still read as a finding", rows[0]["band"] == "DISAGREES")
    moved_cat = {"tours": [_entry("Tower", moved)], "linkPins": []}
    check("🔴 a verdict does NOT survive the entry moving",
          classify(moved_cat, {"s": _cached("Tower", moved, distance_m=900.0)},
                   None, ruled)[0]["verdict"] is None)
    # 🔴 Every other fixture here moves due NORTH, which leaves a longitude-only
    # comparison passing. Mutation testing found this; a realistic fixture would
    # not have, because a real move changes both.
    east = (here[0], here[1] + 0.02)
    east_cat = {"tours": [_entry("Tower", east)], "linkPins": []}
    check("🔴 a verdict does not survive a move due EAST either",
          classify(east_cat, {"s": _cached("Tower", east, distance_m=900.0)},
                   None, ruled)[0]["verdict"] is None)
    check("🔴 an UNSTAMPED verdict is not trusted — nothing to compare, so "
          "'unstamped' and 'unmoved' would be indistinguishable",
          not verdict_applies(_entry("Tower", here), here, {"verdict": "x"}))
    check("a malformed stamp is not trusted",
          not verdict_applies(_entry("Tower", here), here,
                              {"verdict": "x", "at": [1.0]}))
    check("no verdict on file is not a verdict",
          not verdict_applies(_entry("Tower", here), here, None))
    check("rounding at the 7th decimal is not a move",
          verdict_applies(_entry("Tower", here), (here[0] + 1e-7, here[1]),
                          {"verdict": "x", "at": list(here)}))
    check("🔴 a verdict on a DIFFERENT title does not apply",
          classify(one, {"s": _cached("Tower", here, distance_m=900.0)}, None,
                   {"Other": {"verdict": "x", "at": list(here)}})[0]["verdict"] is None)
    check("no verdict file at all leaves every finding standing",
          classify(one, {"s": _cached("Tower", here, distance_m=900.0)})[0]["verdict"]
          is None)
    check("load_verdicts tolerates a missing file",
          load_verdicts(os.path.join(HERE, "no-such-verdicts.json")) == {})

    # 🔴 EVERY row must carry EVERY key. The early-return branches once omitted
    # "verdict", so any consumer iterating all rows hit a KeyError — which is
    # exactly what --show-ruled did the moment it was written.
    shapes = {frozenset(r) for r in classify(
        {"tours": [_entry("Tower", here), _entry("Gone", (1.0, 2.0))], "linkPins": []},
        {"s": _cached("Tower", here)}, None, {})}
    check("🔴 every classify() row has the same keys, banded or not",
          len(shapes) == 1)
    check("and 'verdict' is one of them", all("verdict" in sh for sh in shapes))

    check("🔴 coverage excludes STALE, which would otherwise inflate it",
          [r["band"] for r in covered_rows(
              [{"band": "CONFIRMS"}, {"band": "STALE"}, {"band": "NOT-ASKED"}])]
          == ["CONFIRMS"])

    total = 81
    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — {total - len(fails)}/{total}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--cache", default=CACHE)
    ap.add_argument("--features", default=FEATURES,
                    help="item types from spine-features.py; optional — without "
                         "it nothing is reclassified as an extended site")
    ap.add_argument("--show-ruled", action="store_true",
                    help="LIST the findings a verdict is suppressing, instead of "
                         "only counting them. 🔴 A verdict can be WRONG, and "
                         "suppression makes a wrong one permanent — this is how "
                         "you audit them.")
    ap.add_argument("--verdicts", default=VERDICTS,
                    help="recorded rulings; a finding already settled is "
                         "counted separately, never silently dropped")
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

        features = {}
        if os.path.exists(a.features):
            with gzip.open(a.features, "rt", encoding="utf-8") as fh:
                features = json.load(fh)
        else:
            print(f"⚠️  no {a.features} — parks, streets and bridges will be "
                  f"reported as findings. Run scripts/spine-features.py.")
        rows = classify(catalog, cache, features, load_verdicts(a.verdicts))
        if a.show_ruled:
            # 🔴 Suppression is only safe if it can be inspected. On 2026-09-21
            # two entries carrying `wikidata-elsewhere` ("ours is right") turned
            # out to be 1,316 m and 966 m WRONG — and the suppression shipped
            # that morning was hiding them from every future run.
            ruled = [r for r in rows if r["verdict"] and r["best"]]
            print(f"{len(ruled)} finding(s) a verdict is suppressing — "
                  f"a verdict can be wrong, so read them:\n")
            for row in sorted(ruled, key=lambda r: -r["best"]["distance_m"]):
                entry = row["entry"]
                print(f"  {row['best']['distance_m']:8.0f} m  {row['verdict']:18} "
                      f"{(entry.get('title') or '')[:38]:38} "
                      f"{(entry.get('city') or '')[:16]}")
            return 0
        counts = report(rows, catalog, limit=a.limit)

        code = exit_code(counts)
        if counts["STALE"]:
            print(f"\nCOULD NOT VERIFY — {counts['STALE']} entries moved or were "
                  f"renamed after the cache was built; run scripts/spine-lookup.py")
        elif counts["NOT-ASKED"]:
            print(f"\nCOULD NOT VERIFY — {counts['NOT-ASKED']} entries are not in "
                  f"the cache; run scripts/spine-lookup.py to finish the sweep")
        elif counts["DISAGREES"]:
            print(f"\n{counts['DISAGREES']} entr"
                  f"{'y' if counts['DISAGREES'] == 1 else 'ies'} to put to the owner")
        elif counts["RULED"]:
            print(f"\nOK — every disagreement on file has been ruled on "
                  f"({counts['RULED']} verdicts)")
        else:
            print("\nOK — no entry disagrees with Wikidata by 250 m or more")
        return code
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
