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

# 🔴 Declined groups that join NO existing place, so `DECLINED` above cannot
# reach them. Keyed by the frozen set of member titles — identity here is the
# membership, not a place name that does not exist. Each was put to the owner
# with the under-10 m batch on 2026-09-11 and turned down for the stated reason.
DECLINED_GROUPS = {
    frozenset({"Gamla stan 1859", "Kouthoofd Familie Winkel"}):
        "one shopfront, two unrelated subjects",
    frozenset({"Britain's Oldest Door", "The Tomb of Elizabeth I"}):
        "both are Westminster Abbey, already a place 17 m away — this would duplicate it",
    frozenset({"Cafè de l'Arquitecte", "Hotel Casa Sagnier"}):
        "one building, but is the site the hotel or the building that holds both?",
    frozenset({"El Retiro: The Garden Handed to Everyone", "Puerta de Alcalá"}):
        "two distinct monuments that only round together — BOTH coordinates are 4 dp (~11 m)",
    frozenset({"Handcrafter, D2 Place", "Hoopla, D2 Place"}):
        "two shops inside D2 Place; the site is the mall, which neither entry is named for",

    # Put to the owner with the under-25 m batch, 2026-09-11, and declined.
    # 🔴 Keyed by TITLE, never by the P-label they were shown under: creating a
    # batch renumbers every remaining open group, so a label read back after the
    # fact names a different site. That mistake was made once here and caught.
    frozenset({"Natural Spices Shop", "New Patoy"}):
        "dense block — two separate Hong Kong shops",
    frozenset({"Arc de Triomphe", "The Tomb of the Unknown Soldier"}):
        "owner: keep separate",
    frozenset({"Little Bao", "Primo Posto"}):
        "dense block — two different Hong Kong restaurants",
    frozenset({"Casa Amatller", "Casa Batlló"}):
        "two separate houses side by side on the Illa de la Discòrdia — the point of that block",
    frozenset({"The Fletcher-Sinclair House", "The Venetian Room at Albertine"}):
        "owner: keep separate — two adjacent mansions",
    frozenset({"Bếp Mẹ Ỉn", "STIR - Modern Classic Cocktail"}):
        "dense block — two separate Ho Chi Minh City venues",
    frozenset({"Haidilao Hot Pot, Carnarvon Road", "Matsukiyo"}):
        "dense block — a hotpot restaurant and a drugstore",
    frozenset({"Fringe Club | 藝穗會", "Ho Lan Zheng"}):
        "dense block — two separate Hong Kong venues",
    frozenset({"ArkDes — Swedish Centre for Architecture and Design", "Moderna Museet"}):
        "owner: keep separate — they share a building on Skeppsholmen but are two institutions",
    frozenset({"Lazy Suzy", "Peng Leng Zheng"}):
        "dense block — two separate Hong Kong venues",
    frozenset({"Blue Bottle Studio Seoul | 블루보틀 삼청 한옥", "Kukje Gallery K3 | 국제갤러리 K3"}):
        "dense block — a coffee studio and a gallery",
    frozenset({"Diego Iluminado", "Fundación Proa"}):
        "owner: keep separate",
    frozenset({"Bar Montan", "Hosoi"}):
        "dense block — two separate Stockholm bars",
    frozenset({"Baan Plern Jitt | บ้านเพลินจิตต์ ณ คลองบางหลวง",
               "Khlong Bang Luang Floating Market | ตลาดชุมชนคลองบางหลวง"}):
        "owner: keep separate",
    frozenset({"Social Goods", "Stone Slab Street | 石板街"}):
        "dense block — a shop on the street it stands in",
    frozenset({"Palacio Barolo", "Salón 1923"}):
        "owner: keep separate",
    frozenset({"Heartwarming", "Yu Chau Street"}):
        "dense block — a shop on the street it stands in",
    frozenset({"The Loop — Where the Skyscraper Was Born", "The Rookery"}):
        "owner: keep separate — a building and a walk that passes it",
    frozenset({"Pellegrino 2000", "The Rover"}):
        "dense block — two separate Sydney venues",

    # The last four coincident groups, decided 2026-09-11.
    frozenset({"The Dark Secret of Wall Street", "The Red Room at One Wall Street"}):
        "owner: the Dark Secret joined the Wall Street place; the Red Room stays separate — it is One Wall Street, a different building",
    frozenset({"Academy Museum of Motion Pictures", "Jeff Koons' Split-Rocker Edition", "LACMA"}):
        "owner: all different — pins improved instead; LACMA and the Academy Museum were both 4 dp and are now 175 m apart",
    frozenset({"Dieci", "Kau Kee | 九記牛腩", "O'rm"}):
        "owner: all separate — dense block, a noodle shop and two neighbours",
}

# 🔴 Declined NEAR pairs (§ 3). A separate table from DECLINED_GROUPS because a
# near pair is never unioned into a site group — it has no `existing` place and
# no group row — so neither mechanism above can reach it. Without this, a pair
# the owner has already ruled on comes back as a fresh candidate on every run:
# Tibidabo was declined in #541 and was still being offered months later.
# Keyed by the frozen set of the two titles, never by the N-label: the labels
# are positions in a sorted list and renumber whenever a batch lands.
DECLINED_PAIRS = {
    frozenset({"Tibidabo", "Tibidabo Amusement Park"}):
        "a mountain and a funfair are two subjects (#541)",
    frozenset({"The Red Room at One Wall Street", "Wall Street"}):
        "owner: keep the Red Room separate — One Wall Street is a different building",
    frozenset({"The Red Room at One Wall Street", "The Wall of Wall Street"}):
        "owner: keep the Red Room separate — One Wall Street is a different building",
    frozenset({"LACMA", "LACMA's David Geffen Galleries"}):
        "owner: all different — the pins were repaired instead",
}


def pair_declined(r):
    """Why this near pair is held, or None if it is still open."""
    return DECLINED_PAIRS.get(frozenset({r["a"]["title"], r["b"]["title"]}))



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


def declined_reason(row):
    """Why this group is held, or None if it is still open."""
    if set(row["existing"]) & DECLINED:
        return "owner, 2026-09-11"
    return DECLINED_GROUPS.get(frozenset(m["title"] for m in row["members"]))


def render(doc, groups, all_pairs, rev):
    pairs = [r for r in all_pairs if not pair_declined(r)]
    held_pairs = [r for r in all_pairs if pair_declined(r)]
    held = [r for r in groups if declined_reason(r)]
    open_groups = [r for r in groups if not declined_reason(r)]
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
    w(f"| **§ 4** | {len(held) + len(held_pairs)} groups **already declined** | Do not re-offer |")  # ⚠️ must match § 4's own heading — count both tables
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

    def lab(x):
        return f"`[{x['kind']}]` {esc(x['title'])}" + (f" *(in {esc(x['place'])})*" if x["place"] else "")

    w(f"## § 3 — {len(pairs)} same-subject pairs 25–500 m apart\n")
    w("Related by name but not coincident. **Never auto-create these** — picking the one coordinate")
    w("is an editorial decision, and some are deliberately two subjects.\n")
    w("| # | City | Apart | Pair |")
    w("|---|---|---|---|")

    for i, r in enumerate(pairs, 1):
        w(f"| N{i} | {r['city']} | {r['dist']:.0f} m | {lab(r['a'])}<br>{lab(r['b'])} |")
    w("")

    w(f"## § 4 — declined, standing ({len(held) + len(held_pairs)} groups + 1 named case)\n")
    w("🔴 **These are decided. The sweep still reports them because it cannot know a decision was")
    w("made — do not re-offer them as new candidates.**\n")
    w("| Held | The entry left out | Decided |")
    w("|---|---|---|")
    for r in held:
        reason = declined_reason(r)
        if r["existing"]:
            what = "<br>".join(entry(m) for m in r["members"] if not m["claimed"])
            w(f"| {'/'.join(esc(e) for e in r['existing'])} | {what} | {reason} |")
        else:
            what = "<br>".join(entry(m) for m in r["members"])
            w(f"| *(no place)* | {what} — {esc(reason)} | owner, 2026-09-11 |")
    w("| **Tai Kwun** | `[pin]` Madame Fu — a restaurant *inside* a heritage compound is not the "
      "compound. It sits 27.4 m out, just past the TIGHT radius, so the sweep does not report it "
      "| owner, 2026-09-11 |")
    for r in held_pairs:
        w(f"| *(no place)* | {lab(r['a'])}<br>{lab(r['b'])} — {esc(pair_declined(r))} "
          f"({r['dist']:.0f} m apart) | owner |")
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

    # 🔴 § 3's own declined table. Without it a pair the owner ruled on months
    # ago is re-offered on every run — which is exactly what Tibidabo did.
    def pair(a, b):
        return {"a": {"title": a}, "b": {"title": b}}
    check("a declined near pair is held",
          bool(pair_declined(pair("Tibidabo", "Tibidabo Amusement Park"))), True)
    check("order does not matter",
          bool(pair_declined(pair("Tibidabo Amusement Park", "Tibidabo"))), True)
    check("an open near pair is not held",
          pair_declined(pair("The Oculus", "The Oculus")), None)
    check("one shared title is not enough",
          pair_declined(pair("Tibidabo", "Sagrada Família")), None)

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

    # 🔴 A declined group that joins no existing place must still be held —
    # DECLINED is keyed on place names these groups do not have.
    madrid = {"existing": [], "members": [
        {"title": "El Retiro: The Garden Handed to Everyone", "kind": "tour",
         "claimed": False, "place": None},
        {"title": "Puerta de Alcalá", "kind": "tour", "claimed": False, "place": None}]}
    check("a place-less declined group is held", bool(declined_reason(madrid)), True)
    check("an open group is not held",
          declined_reason({"existing": [], "members": [
              {"title": "Something", "kind": "pin", "claimed": False, "place": None}]}), None)
    check("a declined group attached to a place is still held",
          declined_reason({"existing": ["Westminster Abbey"], "members": []}), "owner, 2026-09-11")

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
        # ⚠️ Count with declined_reason(), not DECLINED — the latter only knows
        # the groups attached to an existing place, so it under-reports holds
        # and over-reports what is open.
        held = sum(1 for r in groups if declined_reason(r))
        print(f"wrote {a.menu_out}: {len(groups) - held} open groups, "
              f"{sum(1 for r in pairs if not pair_declined(r))} near pairs open "
              f"({sum(1 for r in pairs if pair_declined(r))} declined), {held} groups declined")
        return 0
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
