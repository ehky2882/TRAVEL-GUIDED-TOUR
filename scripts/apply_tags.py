#!/usr/bin/env python3
"""
apply_tags.py — Phase 1 of the tag migration (see docs/tag-migration-plan.md).

Writes the controlled, faceted tag vocabulary onto every tour's `tags` field in
Resources/Tours.json, REPLACING the old free-form tags with the normalized flat
list produced by scripts/seed_tags.py. It does NOT touch `primaryCategory` — the
old category rides along untouched so nothing user-facing changes (that's the
whole point of Phase 1: additive + reversible).

Tag shape (owner decision D4): a flat `[String]` — every facet's tags merged into
one sorted list. The app derives each tag's facet from a bundled vocabulary map.

SAFE BY DEFAULT: runs a dry-run and writes nothing unless you pass --write.

    python3 scripts/apply_tags.py            # dry-run: report only, no file change
    python3 scripts/apply_tags.py --write    # actually rewrite Resources/Tours.json

After --write, ALWAYS run:  swift scripts/validate-tours.swift

NOTE: This is the gated Phase-1 step. Only run --write with owner go-ahead — it
changes live, Supabase-backed content (the CI auto-seed pushes Tours.json → the
DB on merge to main). Ships as a content change; keep primaryCategory until the
app flips to tags (Phase 2).
"""
import json, sys, os, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from seed_tags import seed, VOCAB, TJ  # single source of truth for the vocabulary


def flat_tags(tour):
    """The normalized flat tag list for one tour: every facet merged, sorted,
    deduped. Place type + Theme are guaranteed non-empty by seed()."""
    s = seed(tour)
    tags = []
    for facet in VOCAB:            # stable facet order, then sorted within
        tags += sorted(s[facet])
    # de-dupe defensively while preserving order
    seen, out = set(), []
    for t in tags:
        if t not in seen:
            seen.add(t); out.append(t)
    return out, s


def main():
    write = "--write" in sys.argv
    d = json.load(open(TJ))
    T = d["tours"]

    changed = 0
    empty_place = empty_theme = 0
    tag_hist = collections.Counter()
    before_unique = set()
    for t in T:
        before_unique.update(t.get("tags") or [])
        tags, s = flat_tags(t)
        if not s["Place type"]:
            empty_place += 1
        if not s["Theme"]:
            empty_theme += 1
        for tag in tags:
            tag_hist[tag] += 1
        if (t.get("tags") or []) != tags:
            changed += 1
        if write:
            t["tags"] = tags

    print(f"tours:                {len(T)}")
    print(f"tours whose tags change: {changed}")
    print(f"unique tags before:   {len(before_unique)}  (free-form)")
    print(f"unique tags after:    {len(tag_hist)}  (controlled vocabulary)")
    print(f"avg tags/tour:        {sum(tag_hist.values())/len(T):.1f}")
    print(f"missing Place type:   {empty_place}   (must be 0)")
    print(f"missing Theme:        {empty_theme}   (must be 0)")

    if empty_place or empty_theme:
        print("\nERROR: some tours miss a required facet — fix seed_tags.py before writing.")
        sys.exit(1)

    if write:
        json.dump(d, open(TJ, "w"), ensure_ascii=False, indent=2)
        print(f"\nWROTE {TJ}")
        print("NEXT: swift scripts/validate-tours.swift   (then commit as a content change)")
    else:
        print("\nDRY RUN — nothing written. Re-run with --write to apply (owner go-ahead required).")


if __name__ == "__main__":
    main()
