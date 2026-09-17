#!/usr/bin/env python3
"""Fetch what KIND of thing each matched Wikidata item is, and how big.

WHY THIS EXISTS
---------------
The first full audit produced **145 DISAGREES**, and reading them showed the
list was dominated by one class that is not an error at all:

    Grand Concourse (a four-mile boulevard)      4,486 m
    Hollywood Walk of Fame (fifteen blocks)      1,664 m
    Khao Yai National Park (2,168 km²)          10,394 m
    Takase River · Meteora · Mile End · Prora

**A site with no single point has no single coordinate.** Ours sits at the
entrance, or the famous view, or the stop the tour begins at; the gazetteer's
sits at a centroid. They differ by hundreds or thousands of metres and neither
is wrong — `docs/places.md` records the same blind spot from the other side:
*"A forty-acre site cannot be found by a metre-scale sweep."*

Telling that class apart needs one fact the lookup does not collect: **what the
matched item IS.** A park, a river, a street, a district and a mountain range
are areas; a building, a museum, a bridge and a restaurant are points.

WHY THIS IS A SEPARATE SCRIPT AND NOT A RE-SWEEP
-------------------------------------------------
`spine-lookup.py` asked 4,566 questions over about an hour. Adding two columns
to its query would mean asking all of them again. This asks only about the
items that were actually matched — a few thousand QIDs, ~300 to a query, in
well under a minute — and writes them alongside the cache. **The expensive
artefact stays untouched.**

⚠️ The types are a REPORTING aid, never a verdict. An entry whose match is a
park is still reported; it is reported in a section headed by what it is, so a
person reads "this is a park, of course the centroid differs" instead of
"4,486 m — something is broken".
"""

from __future__ import annotations

import argparse
import gzip
import importlib.util
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402  (stamps every run; see scripts/runstamp.py)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CACHE = os.path.join(REPO, "spine", "lookups.json.gz")
FEATURES = os.path.join(REPO, "spine", "features.json.gz")

CHUNK = 300             # QIDs per query
SLEEP_S = 1.0


def _load(name):
    path = os.path.join(HERE, name)
    spec = importlib.util.spec_from_file_location("_" + name.replace("-", "_")[:-3], path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_sl = _load("spine-lookup.py")
sparql_with_retry = _sl.sparql_with_retry
chunked = _sl.chunked
save_cache = _sl.save_cache


def types_query(qids):
    """`instance of` and `area` for a list of items, in one query."""
    values = " ".join(f"wd:{q}" for q in qids)
    return f"""
SELECT ?item ?type ?area WHERE {{
  VALUES ?item {{ {values} }}
  OPTIONAL {{ ?item wdt:P31 ?type }}
  OPTIONAL {{ ?item wdt:P2046 ?area }}
}}
"""


def qids_in_cache(cache):
    """Every QID that could be a best candidate for some entry.

    Deliberately all of them, not only today's winners: the banding may change
    (it already has, three times), and re-deriving from a wider set is free
    while re-asking is not.
    """
    seen = set()
    for record in cache.values():
        for candidate in record.get("candidates") or []:
            seen.add(candidate["qid"])
    return sorted(seen)


def fetch(qids, *, log=print):
    """Returns `({qid: {"types": [...], "area_m2": float|None}}, n_failed)`."""
    out, failed = {}, 0
    batches = list(chunked(qids, CHUNK))
    for index, batch in enumerate(batches, 1):
        try:
            payload = sparql_with_retry(types_query(batch))
        except Exception as exc:                            # noqa: BLE001
            # 🔴 A failed batch must not read as "these items have no type".
            failed += len(batch)
            log(f"  batch {index}/{len(batches)} FAILED: {type(exc).__name__}: {exc}")
            time.sleep(SLEEP_S)
            continue
        for binding in payload["results"]["bindings"]:
            qid = binding["item"]["value"].rsplit("/", 1)[-1]
            row = out.setdefault(qid, {"types": [], "area_m2": None})
            type_uri = binding.get("type", {}).get("value")
            if type_uri:
                type_qid = type_uri.rsplit("/", 1)[-1]
                if type_qid not in row["types"]:
                    row["types"].append(type_qid)
            area = binding.get("area", {}).get("value")
            if area:
                try:
                    row["area_m2"] = max(row["area_m2"] or 0.0, float(area))
                except ValueError:
                    pass
        log(f"  batch {index}/{len(batches)} · {len(out)} items so far")
        time.sleep(SLEEP_S)
    return out, failed


def selftest():
    fails = []

    def check(name, ok):
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    q = types_query(["Q1", "Q2"])
    check("query asks for instance-of", "wdt:P31" in q)
    check("query asks for area", "wdt:P2046" in q)
    check("query lists every qid", "wd:Q1" in q and "wd:Q2" in q)
    check("both properties are OPTIONAL, so a typeless item still returns",
          q.count("OPTIONAL") == 2)

    cache = {"a": {"candidates": [{"qid": "Q5"}, {"qid": "Q6"}]},
             "b": {"candidates": [{"qid": "Q6"}]},
             "c": {"candidates": []},
             "d": {}}
    check("qids_in_cache dedupes across entries", qids_in_cache(cache) == ["Q5", "Q6"])
    check("qids_in_cache survives an entry with no candidates key",
          "d" not in qids_in_cache(cache))

    total = 6
    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — {total - len(fails)}/{total}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--cache", default=CACHE)
    ap.add_argument("--features", default=FEATURES)
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        if not os.path.exists(a.cache):
            print(f"COULD NOT VERIFY — no cache at {a.cache}")
            return 2
        with gzip.open(a.cache, "rt", encoding="utf-8") as fh:
            cache = json.load(fh)
        qids = qids_in_cache(cache)
        print(f"{len(qids)} distinct matched items to classify")
        features, failed = fetch(qids)
        save_cache(a.features, features)
        print(f"\nclassified {len(features)} · failed {failed}")
        print(f"wrote {a.features}")
        if failed:
            print("COULD NOT VERIFY — some batches failed; re-run to finish them")
            return 2
        print("OK — every matched item classified")
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
