#!/usr/bin/env python3
"""Recover the captions a 140-character cut destroyed.

🔴 WHY. Until 2026-09-21 `make-link-pin.py` stored `caption[:140]` and threw
the rest away. **2,374 captions sit at exactly 140 characters**, nearly all
ending mid-word — and because creators put their address LAST, the cut landed
on the most useful line in the text. *Modern Coffee House* shipped **22.9 km
wrong**, on Staten Island, because the postcode that separates two East
Broadways was in the tail we deleted.

The posts still exist. This re-reads them.

🔴 THE PREFIX GUARD IS THE WHOLE SAFETY PROPERTY
------------------------------------------------
A refetched caption is accepted **only if the stored 140 characters are a
prefix of it**. That is what distinguishes *"the same caption, now complete"*
from *"some other text"* — a re-used URL, an edited post, a platform serving a
different item, or a fetch that silently returned the wrong thing. Anything
that fails the test is recorded as MISMATCH and **never written**.

⚠️ The comparison must be made on NORMALISED text. The pipeline stores
`" ".join(text.split())` (line 588 of `make-link-pin.py`), so a stored caption
has its newlines collapsed to single spaces while a freshly fetched one still
carries them. Comparing raw text fails on every Instagram post with a line
break — which is most of them — and would reject the whole platform.

⚠️ RESUMABLE, AND RUN IN THE FOREGROUND. The cache is written after every
batch, because a background process does not outlive an idle session here: the
first spine sweep died at 316 of 4,566 five minutes after its turn ended.
"""
import argparse
import gzip
import importlib.util
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CATALOG = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")
CACHE = os.path.join(REPO, "checks", "caption-refetch.json.gz")
sys.path.insert(0, HERE)
import runstamp  # noqa: E402

CUT = 140  # the length the old pipeline truncated to


def _pipeline():
    spec = importlib.util.spec_from_file_location("_mlp", os.path.join(HERE, "make-link-pin.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def normalise(text):
    """Exactly what make-link-pin.py:588 stores, so the two are comparable."""
    return " ".join((text or "").split())


def entries(catalog):
    return list(catalog.get("tours") or []) + list(catalog.get("linkPins") or [])


def truncated(catalog, cut=CUT):
    """Entries whose caption sits exactly on the cut and that name a source."""
    out = []
    for e in entries(catalog):
        stops = e.get("stops") or []
        if not stops:
            continue
        cap = stops[0].get("caption") or ""
        url = e.get("sourceURL") or ""
        if len(cap) == cut and url:
            out.append((e, cap, url))
    return out


def accept(stored, fetched):
    """🔴 The guard. Normalised, longer, and the stored text must be a PREFIX.

    Returns (ok, reason). A caption that is merely different is NOT a recovery;
    it is evidence that the URL no longer points at what it used to.
    """
    got = normalise(fetched)
    if not got:
        return False, "empty"
    if not got.startswith(normalise(stored)):
        return False, "mismatch"
    if len(got) <= len(stored):
        return False, "no-longer"
    return True, "ok"


def load_cache(path=CACHE):
    if not os.path.exists(path):
        return {}
    with gzip.open(path, "rt", encoding="utf-8") as fh:
        return json.load(fh)


def save_cache(data, path=CACHE):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with gzip.open(path, "wt", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, sort_keys=True)


def unexcused(catalog, cache, cut=CUT):
    """Captions sitting on the cut that the cache does NOT excuse.

    🔴 WHY THIS EXISTS. `make-link-pin.py` stopped truncating on 2026-09-21,
    and on 2026-09-22 **87 fresh captions arrived at exactly 140 characters
    anyway** — #1054 was built from a branch cut before the fix, so the batch
    carried the old code with it. **A pipeline fix does not reach work already
    in flight**, and nothing noticed until a count was re-derived by hand.

    A caption may sit at the cut for an honest reason — the post is deleted, or
    the text really is that long — and those are recorded in the cache. Anything
    else is a NEW truncation, which means some checkout is still cutting.

    ⚠️ Scope: `truncated()` requires a source URL, so a caption sitting on the
    cut with no URL is invisible here — there is nothing to re-read it from.
    Eleven such entries exist, and the printed count says "sit at 140" rather
    than claiming to cover every caption in the catalogue.
    """
    out = []
    for e, cap, url in truncated(catalog, cut):
        rec = cache.get(e["id"])
        if rec is None or rec.get("status") == "ok":
            out.append(e)
    return out


def selftest():
    fails = []

    def check(name, ok):
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    stored = "Stopped by the shop and had the best sandwich of my life, truly"
    check("a longer caption carrying the stored text is accepted",
          accept(stored, stored + " 📍 105 E Broadway")[0])
    check("🔴 text that does NOT start with the stored caption is refused",
          accept(stored, "A completely different post about something else entirely")[1] == "mismatch")
    check("a caption that is not longer is refused",
          accept(stored, stored)[1] == "no-longer")
    check("an empty fetch is refused, not treated as a deletion",
          accept(stored, "")[1] == "empty")
    check("🔴 a NEWLINE in the fetched text does not defeat the prefix test — "
          "the pipeline stores whitespace collapsed",
          accept("Poché - Studio Gang | episode 2 of 3 Completed in May 2023",
                 "Poché - Studio Gang | episode 2 of 3\n\nCompleted in May 2023, and more")[0])
    # 🔴 The STORED side must be normalised too, not just the fetched side.
    # Mutation testing found this: a fixture whose stored text was already
    # clean could not tell `startswith(normalise(stored))` from
    # `startswith(stored)`. A stored caption with stray whitespace can exist —
    # hand-edited, or written before the pipeline normalised — and would then
    # be refused forever.
    check("🔴 a STORED caption carrying stray whitespace still matches",
          accept("a  b\nc", "a b c and then some more text")[0])
    # 🔴 PREFIX, not "appears somewhere". If the stored text turns up in the
    # middle, the post was edited ahead of it and this is no longer the same
    # caption continued — which is precisely what the guard exists to refuse.
    check("🔴 the stored text appearing MID-WAY is refused, not accepted",
          accept("the best sandwich",
                 "EDIT: reposting! the best sandwich you will ever eat")[1] == "mismatch")
    check("normalise collapses runs and strips", normalise("  a \n\n b\t c ") == "a b c")
    check("normalise of None is empty, not a crash", normalise(None) == "")

    cat = {"tours": [], "linkPins": [
        {"id": "a", "sourceURL": "https://x/1", "stops": [{"caption": "x" * CUT}]},
        {"id": "b", "sourceURL": "https://x/2", "stops": [{"caption": "short"}]},
        {"id": "c", "sourceURL": "", "stops": [{"caption": "y" * CUT}]},
        {"id": "d", "sourceURL": "https://x/4", "stops": []},
    ]}
    ids = [e["id"] for e, _, _ in truncated(cat)]
    check("only entries AT the cut with a source URL are selected", ids == ["a"])
    check("an entry with no stops is skipped, not crashed on", "d" not in ids)
    check("🔴 a tour is eligible too, not only a link pin",
          [e["id"] for e, _, _ in truncated(
              {"tours": [{"id": "t", "sourceURL": "https://x/9",
                          "stops": [{"caption": "z" * CUT}]}], "linkPins": []})] == ["t"])
    check("the cut length is a parameter, not baked in",
          truncated({"tours": [], "linkPins": [
              {"id": "e", "sourceURL": "https://x/5", "stops": [{"caption": "ab"}]}]},
              cut=2) != [])

    cat2 = {"tours": [], "linkPins": [
        {"id": "new", "sourceURL": "https://x/1", "stops": [{"caption": "x" * CUT}]},
        {"id": "dead", "sourceURL": "https://x/2", "stops": [{"caption": "y" * CUT}]},
    ]}
    cache2 = {"dead": {"status": "failed"}}
    check("🔴 a caption at the cut with NO cache record is a new truncation",
          [e["id"] for e in unexcused(cat2, cache2)] == ["new"])
    check("a caption the cache records as unrecoverable is excused",
          "dead" not in [e["id"] for e in unexcused(cat2, cache2)])
    check("🔴 a caption the cache says was RECOVERED but is still at the cut is "
          "NOT excused — it means something re-truncated it",
          sorted(e["id"] for e in unexcused(cat2, {"dead": {"status": "ok"},
                                                   "new": {"status": "ok"}})) == ["dead", "new"])

    total = 16
    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — {total - len(fails)}/{total}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--cache", default=CACHE)
    ap.add_argument("--limit", type=int, default=200,
                    help="how many to FETCH this run; the rest stay for the next")
    ap.add_argument("--sleep", type=float, default=0.6)
    ap.add_argument("--apply", action="store_true",
                    help="write recovered captions into the catalogue and stop")
    ap.add_argument("--check", action="store_true",
                    help="report captions newly sitting on the cut and exit 1 "
                         "(offline; no fetching)")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        with open(a.catalog, encoding="utf-8") as fh:
            catalog = json.load(fh)
        rows = truncated(catalog)
        cache = load_cache(a.cache)

        if a.check:
            bad = unexcused(catalog, cache)
            excused = len(rows) - len(bad)
            everything = sum(1 for e in entries(catalog)
                             for st in (e.get("stops") or [])[:1]
                             if len(st.get("caption") or "") == CUT)
            print(f"{everything} captions sit at exactly {CUT} characters · "
                  f"{everything - len(rows)} have no source URL and cannot be re-read · "
                  f"{excused} excused by the cache · {len(bad)} NOT excused")
            for e in bad[:20]:
                print(f"   {(e.get('sourceAuthor') or '?')[:22]:24} "
                      f"{(e.get('title') or '')[:44]}")
            if bad:
                print(f"\n🔴 {len(bad)} caption(s) newly cut at {CUT}. Something is still "
                      f"truncating —\n   a branch cut before make-link-pin.py stopped, most "
                      f"likely. Rebase it, then:\n   python3 scripts/refetch-captions.py "
                      f"--limit 200 && python3 scripts/refetch-captions.py --apply")
            return 1 if bad else 0

        if a.apply:
            raw = open(a.catalog, encoding="utf-8").read()
            assert json.dumps(catalog, indent=2, ensure_ascii=False) + "\n" == raw, \
                "REFUSED — Tours.json is not byte-stable"
            written = skipped = 0
            for e, cap, _ in rows:
                rec = cache.get(e["id"])
                if not rec or rec.get("status") != "ok":
                    skipped += 1
                    continue
                e["stops"][0]["caption"] = rec["caption"]
                written += 1
            assert written + skipped == len(rows), (written, skipped, len(rows))
            print(f"population: {written} recovered + {skipped} not recovered == {len(rows)}")
            open(a.catalog, "w", encoding="utf-8").write(
                json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
            return 0

        todo = [r for r in rows if r[0]["id"] not in cache]
        print(f"{len(rows)} truncated · {len(rows) - len(todo)} cached · "
              f"{len(todo)} to fetch · asking {min(a.limit, len(todo))}\n")
        mod = _pipeline()
        counts = {"ok": 0, "mismatch": 0, "no-longer": 0, "empty": 0, "failed": 0}
        for i, (e, cap, url) in enumerate(todo[:a.limit]):
            try:
                meta = mod.oembed(url)
                fetched = meta.get("title") or ""
                ok, why = accept(cap, fetched)
            except SystemExit:
                ok, why, fetched = False, "failed", ""
            except Exception:
                ok, why, fetched = False, "failed", ""
            counts[why] = counts.get(why, 0) + 1
            cache[e["id"]] = {"status": "ok" if ok else why, "url": url,
                              "caption": normalise(fetched) if ok else None,
                              "was": len(cap), "now": len(normalise(fetched))}
            if (i + 1) % 25 == 0:
                save_cache(cache, a.cache)
                print(f"  {i + 1}/{min(a.limit, len(todo))} · " +
                      " ".join(f"{k}={v}" for k, v in counts.items() if v))
            time.sleep(a.sleep)
        save_cache(cache, a.cache)
        done = sum(1 for r in rows if r[0]["id"] in cache)
        print(f"\nasked {min(a.limit, len(todo))} · " +
              " ".join(f"{k}={v}" for k, v in counts.items() if v))
        print(f"cache now covers {done}/{len(rows)}")
        # 🔴 A run that could not reach the network at all must not read as a pass.
        if counts["failed"] and counts["failed"] == sum(counts.values()):
            print("\n🔴 COULD NOT VERIFY — every fetch failed. Not a clean result.")
            return 2
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
