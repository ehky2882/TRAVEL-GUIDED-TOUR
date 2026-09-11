#!/usr/bin/env python3
"""Regenerate `docs/place-candidates-260911.md` — the live place-candidate menu.

WHY THIS EXISTS
---------------
`check-place-candidates.py` answers "what is coincident?". This turns that into
a list a person can pick from by number — and it has to be RE-RUN rather than
hand-patched. The 2026-09-11 sweep was written by hand, 45 of its rows became
places within hours, and #804/#805 then introduced a new one. A menu that is not
regenerated is a menu that lies.

🔴 TWO THINGS HERE ARE LOAD-BEARING, NOT STYLE

1. **Pipes in titles are escaped.** 24 entries in this catalogue carry a literal
   `|` in the title — the bilingual convention, "Museum SAN | 뮤지엄 산". Dropped
   into a markdown table that opens an extra column and **silently shifts every
   cell after it in that row**, rendering a plausible table with the wrong data
   in it. `esc()` is the fix; `--selftest` counts columns to prove it.

2. **§ 4 exists because the sweep cannot know a decision was made.** Il
   Presidente, the Cosmati Pavement, the Shrine of Edward the Confessor, the
   Channel Gardens and Madame Fu were each considered and declined by the owner.
   Without that section they return as fresh candidates on every run, and
   someone eventually "fixes" them.

Usage:
    python3 scripts/make-place-menu.py                 # writes DEFAULT_OUT
    python3 scripts/make-place-menu.py --selftest
"""

import argparse
import datetime
import importlib.util
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402  (stamps every run; see scripts/runstamp.py)

CATALOG = "TRAVEL GUIDED TOUR/Resources/Tours.json"
DEFAULT_OUT = "docs/place-candidates-260911.md"
PR_SWEEP = "https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/801"

# Groups the owner considered and DECLINED, keyed by the existing place they
# would have joined. Rendered as § 4 so they are never re-offered.
DECLINED = {
    "Duddell Street Steps and Gas Lamps",
    "Westminster Abbey",
    "Rockefeller Center",
}


def load_checker():
    """Import check-place-candidates.py, whose filename is not a module name."""
    here = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location(
        "cpc", os.path.join(here, "check-place-candidates.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def esc(text):
    """Escape a literal pipe so a bilingual title cannot open a table column."""
    return (text or "").replace("|", "\\|")


def group(cpc, doc):
    """EXACT + TIGHT pairs unioned into site groups; NEAR stays pairwise.

    ⚠️ Only hops of <=25 m are unioned. Chaining anything looser is what the
    40 m proximity rule died of in session 95 — it strung separate sites
    together transitively.
    """
    exact, tight, near = cpc.scan(doc)
    claimed = {tid: p["name"] for p in doc["places"] for tid in p["tourIds"]}

    parent = {}

    def find(x):
        parent.setdefault(x, x)
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    node = {}
    for _coord, members in exact:
        ids = [t["id"] for _, t in members]
        for kind, t in members:
            node[t["id"]] = (kind, t)
        for other in ids[1:]:
            union(ids[0], other)
    for _d, (k1, a), (k2, b) in tight:
        node[a["id"]] = (k1, a)
        node[b["id"]] = (k2, b)
        union(a["id"], b["id"])

    buckets = {}
    for tid in node:
        buckets.setdefault(find(tid), []).append(tid)

    groups = []
    for ids in buckets.values():
        members = sorted((node[i] for i in ids), key=lambda m: m[1]["title"])
        pts = [cpc.marker(t) for _, t in members]
        span = max((cpc.haversine(p, q)
                    for i, p in enumerate(pts) for q in pts[i + 1:]), default=0.0)
        existing = sorted({claimed[t["id"]] for _, t in members if t["id"] in claimed})
        groups.append({
            "span": span,
            "city": members[0][1].get("city"),
            "existing": existing,
            "members": [{"kind": k, "title": t["title"],
                         "claimed": t["id"] in claimed, "place": claimed.get(t["id"])}
                        for k, t in members],
        })
    groups.sort(key=lambda r: (bool(r["existing"]), r["span"], r["city"] or ""))

    pairs = [{"dist": d, "city": a.get("city"),
              "a": {"kind": k1, "title": a["title"], "place": claimed.get(a["id"])},
              "b": {"kind": k2, "title": b["title"], "place": claimed.get(b["id"])}}
             for d, (k1, a), (k2, b) in near]
    return groups, pairs


def entry(m):
    s = f"`[{m['kind']}]` {esc(m['title'])}"
    return s + (f" *(in {esc(m['place'])})*" if m["claimed"] else "")


def render(doc, groups, pairs, rev):
    held = [r for r in groups if set(r["existing"]) & DECLINED]
    open_groups = [r for r in groups if not set(r["existing"]) & DECLINED]
    zero = [r for r in open_groups if r["span"] == 0]
    rest = [r for r in open_groups if r["span"] > 0]
    n_places = len(doc["places"])
    n_members = sum(len(p["tourIds"]) for p in doc["places"])
    now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    o = []
    w = o.append
    w("# Place candidates — the live menu\n")
    w(f"**Regenerated {now} against `main` at `{rev}`.** Every number here is a reading of")
    w("`Tours.json` and goes stale the moment a pin batch merges. Regenerate it — do not patch it:\n")
    w("```bash")
    w("python3 scripts/make-place-menu.py")
    w("```\n")
    w("## Where this stands\n")
    w("A `Place` is a site that more than one entry describes: the site becomes the thing on the map")
    w("and the entries become its contents. The catalogue holds")
    w(f"**{n_places} places covering {n_members} entries**.\n")
    w(f"The 2026-09-11 sweep found 221 candidates and **45 became places** — 7 existing places gained")
    w("the 8 entries standing on them, 38 new places came from the 0 m rows, and both held groups")
    w(f"were resolved ([#801]({PR_SWEEP})). That took the sweep from **41 exact / 151 tight / 79 near**")
    w("to nearly nothing.\n")
    w("**Then `main` moved** — #804 and #805 changed pins and a new coincident group appeared. That is")
    w("the normal condition. What follows is what is open **right now**.\n")
    w("| | Finding | Act on it? |")
    w("|---|---|---|")
    w(f"| **§ 1** | **{len(zero)} on an identical coordinate** — the catalogue's own identity rule | Yes, highest confidence |")
    w(f"| **§ 2** | **{len(rest)} sites** with 2+ entries within 25 m | Owner picks |")
    w(f"| **§ 3** | {len(pairs)} same-subject pairs 25–500 m apart | Read one at a time |")
    w(f"| **§ 4** | {len(held)} groups **already declined** | Do not re-offer |")
    w("")
    w("## 🔴 What creating one costs — it is never just a list entry\n")
    w("A place needs its own **name, description, address and a chosen coordinate**. And because a")
    w("place's identity is **exact coordinate equality** (`Place.swift`, enforced by `validate-tours`")
    w(f"at 1e-9°), every member is **snapped onto that coordinate** — all {n_members} existing members sit")
    w("exactly on their place. Creating a place *moves things on the map*.\n")
    w("⚠️ **Check each move against the entry's own `triggerRadiusMeters` (30 m) first.** A move inside")
    w("that radius changes nothing about when a tour fires; a larger one silently relocates the")
    w("trigger, and nothing else in the pipeline would object.\n")
    w("## ⚠️ The false positives are real and permanent\n")
    w("1. **A dense block of separate venues.** Hong Kong's restaurant pins sit 10–20 m apart and are")
    w("   different restaurants. Same for Stockholm's bars and Sydney's.")
    w("2. **Coordinates rounded to four decimal places** (~11 m) can round two genuinely separate")
    w("   sites to within a few metres — Madrid's *El Retiro* lands 8 m from the *Puerta de Alcalá*.\n")
    w("Proximity is evidence, not proof. Nothing here auto-creates.\n")
    w("---\n")

    if zero:
        w(f"## § 1 — on an identical coordinate ({len(zero)})\n")
        w("The catalogue's documented identity rule: provably one site, no editorial judgement.\n")
        w("| # | City | Entries |")
        w("|---|---|---|")
        for i, r in enumerate(zero, 1):
            w(f"| **Z{i}** | {r['city']} | " + "<br>".join(entry(m) for m in r["members"]) + " |")
        w("")

    w(f"## § 2 — {len(rest)} sites with two or more entries within 25 m\n")
    widest = max((r["span"] for r in rest), default=0)
    w(f"Built only from hops of 25 m or less; the widest group is **{widest:.0f} m** end to end, so")
    w("none is a chain of separate sites strung together.\n")
    w("| # | City | Span | Entries |")
    w("|---|---|---|---|")
    for i, r in enumerate(rest, 1):
        w(f"| P{i} | {r['city']} | {r['span']:.0f} m | "
          + "<br>".join(entry(m) for m in r["members"]) + " |")
    w("")

    w(f"## § 3 — {len(pairs)} same-subject pairs 25–500 m apart\n")
    w("Related by name but not coincident. **Never auto-create these** — picking the one coordinate")
    w("is an editorial decision, and some are deliberately two subjects.\n")
    w("| # | City | Apart | Pair |")
    w("|---|---|---|---|")

    def lab(x):
        return f"`[{x['kind']}]` {esc(x['title'])}" + (f" *(in {esc(x['place'])})*" if x["place"] else "")

    for i, r in enumerate(pairs, 1):
        w(f"| N{i} | {r['city']} | {r['dist']:.0f} m | {lab(r['a'])}<br>{lab(r['b'])} |")
    w("")

    w(f"## § 4 — declined, standing ({len(held)} groups + 2 named cases)\n")
    w("🔴 **These are decided. The sweep still reports them because it cannot know a decision was")
    w("made — do not re-offer them as new candidates.**\n")
    w("| Held | The entry left out | Decided |")
    w("|---|---|---|")
    for r in held:
        out = "<br>".join(entry(m) for m in r["members"] if not m["claimed"])
        w(f"| {'/'.join(esc(e) for e in r['existing'])} | {out} | owner, 2026-09-11 |")
    w("| **Tai Kwun** | `[pin]` Madame Fu — a restaurant *inside* a heritage compound is not the "
      "compound. It sits 27.4 m out, just past the TIGHT radius, so the sweep does not report it "
      "| owner, 2026-09-11 |")
    w("| **Tibidabo** / **Tibidabo Amusement Park** | 48 m apart — a mountain and a funfair are two "
      "subjects | #541 |")
    w("")
    return "\n".join(o) + "\n"


def column_counts(markdown):
    """Unescaped pipes per table row — the check that the esc() guard works."""
    return [len(re.findall(r"(?<!\\)\|", line))
            for line in markdown.splitlines() if line.startswith("|")]


def selftest():
    fails, ran = [], []

    def check(name, got, want):
        ran.append(name)
        if got != want:
            fails.append(f"{name}: got {got!r}, want {want!r}")

    check("a plain title is untouched", esc("Grand Central"), "Grand Central")
    check("a bilingual title is escaped", esc("Museum SAN | 뮤지엄 산"), "Museum SAN \\| 뮤지엄 산")
    check("both pipes are escaped", esc("a|b|c"), "a\\|b\\|c")
    check("None is safe", esc(None), "")

    # 🔴 The bug this guard exists for: an unescaped pipe silently adds a column.
    row_bad = "| P1 | Wonju | 0 m | Museum SAN | 뮤지엄 산 |"
    row_ok = f"| P1 | Wonju | 0 m | {esc('Museum SAN | 뮤지엄 산')} |"
    check("an unescaped pipe adds a column", column_counts(row_bad), [6])
    check("...and escaping it does not", column_counts(row_ok), [5])

    # An entry already in a place is labelled, and its place name is escaped too.
    check("a claimed member is labelled",
          entry({"kind": "pin", "title": "X", "claimed": True, "place": "A | B"}),
          "`[pin]` X *(in A \\| B)*")
    check("an unclaimed member is not",
          entry({"kind": "pin", "title": "X", "claimed": False, "place": None}),
          "`[pin]` X")

    total = len(ran)
    if fails:
        print(f"SELFTEST FAILED — {len(fails)}/{total}")
        for f in fails:
            print("  ✗", f)
        return 1
    print(f"SELFTEST OK — {total}/{total}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--catalog", default=CATALOG)
    ap.add_argument("--menu-out", default=DEFAULT_OUT,
                    help=f"document to write (default {DEFAULT_OUT})")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()
    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        cpc = load_checker()
        with open(a.catalog, encoding="utf-8") as fh:
            doc = json.load(fh)
        rev = subprocess.run(["git", "rev-parse", "--short", "HEAD"],
                             capture_output=True, text=True).stdout.strip() or "unknown"
        groups, pairs = group(cpc, doc)
        markdown = render(doc, groups, pairs, rev)

        # 🔴 Never write a table this run cannot vouch for.
        counts = set(column_counts(markdown))
        if not counts <= {4, 5}:
            print(f"REFUSED to write: inconsistent table columns {sorted(counts)}")
            return 2

        with open(a.menu_out, "w", encoding="utf-8") as fh:
            fh.write(markdown)
        held = sum(1 for r in groups if set(r["existing"]) & DECLINED)
        print(f"wrote {a.menu_out}: {len(groups) - held} open groups, "
              f"{len(pairs)} near pairs, {held} declined")
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
