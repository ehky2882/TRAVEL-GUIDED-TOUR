# Tag migration — Phase 1 kickoff brief

**Status:** ready to run, awaiting owner go-ahead (2026-07-02). This is the
turnkey handoff for the FIRST implementation step of the tag migration. Read
`docs/tag-taxonomy-v2.md` (the vocabulary) and `docs/tag-migration-plan.md` (the
full plan + locked decisions) first. Owner decisions are locked; only **D7**
(curated vs popularity home rails) is open, and it isn't needed until Phase 2.

---

## What Phase 1 is (plain)

Quietly write the new controlled tags onto all 509 tours, **alongside** the
existing category. Nothing changes for users — the app still reads
`primaryCategory` and shows today's rails/chips. It's **additive and
reversible**: we're only replacing the messy free-form `tags` field (2,183
unique, mostly used once) with a clean 85-tag controlled vocabulary. The UI flip
(Phase 2) and dropping the old category (Phase 3) come later, in their own
sessions.

**Why do it first:** it de-risks everything after. The content goes live and
gets a real soak in the catalog + Supabase before any code depends on it.

---

## The tooling is built and dry-run-verified

`scripts/apply_tags.py` reads `Resources/Tours.json`, computes each tour's flat
tag list via `scripts/seed_tags.py` (the shared vocabulary), and rewrites the
`tags` field. `primaryCategory` is left untouched. Safe by default — it reports
and writes nothing unless you pass `--write`.

Dry-run result (2026-07-02):

```
tours:                509
tours whose tags change: 509
unique tags before:   2183  (free-form)
unique tags after:    85    (controlled vocabulary)
avg tags/tour:        6.5
missing Place type:   0     (must be 0)
missing Theme:        0     (must be 0)
```

### What a real tour looks like after (samples)

| Tour | New flat tags |
|---|---|
| **Dior Azabudai Hills** (Tokyo) | `Shop & Flagship`, `Tower & Skyscraper`, `Architecture & Design`, `Fashion & Retail`, `Designed by a Master`, `Kengo Kuma` |
| **Borough Market** (London) | `Market & Arcade`, `Food & Drink`, `History`, `Money & Trade`, `Victorian` |
| **Golden Gate Bridge** (SF) | `Bridge`, `Architecture & Design`, `Art`, `Engineering & Innovation`, `Art Deco` |

The new Tokyo/HK/SF tags (`Shop & Flagship`, `Fashion & Retail`, `Kengo Kuma`,
`I. M. Pei`…) all fire correctly. **But the auto-pass is a first draft** — the
same run tags Empire State with a stray `Food & Drink`, and Bank of China with
`Norman Foster` (a comparative mention, not the architect — it's I. M. Pei).
That's exactly what the city-by-city spot-check (D10) is for; see
`docs/tag-migration-review.md`, flagged tours sorted to the top of each city.

---

## Run order (the actual Phase 1 steps)

1. **(Optional but recommended) Spot-check first.** Skim
   `docs/tag-migration-review.md` city by city, fix obvious misses in
   `scripts/seed_tags.py`'s heuristics (or plan to correct `Tours.json` after).
   ~3–5 hours; the 85 ⚠️-flagged place-type tours are at the top of each city.
2. **Apply (gated — needs owner go-ahead):**
   ```
   python3 scripts/apply_tags.py --write
   swift scripts/validate-tours.swift
   ```
   *(Validator still passes today — `tags` is already `[String]`; it doesn't yet
   enforce the vocabulary. Vocabulary enforcement is a Phase-2 validator change.)*
3. **Ship as a content change.** Commit `Resources/Tours.json` on a branch → PR →
   CI green → squash-merge (content PRs auto-merge per policy). The
   `publish-catalog` workflow pushes it to gh-pages **and** auto-seeds Supabase
   — so the normalized tags reach the live DB within ~1 min. No app build.
4. **Verify live** (as with any content merge): poll the `get_catalog` RPC +
   gh-pages mirror until both serve the new tags.

**Reversibility:** it only rewrites one field. To undo, revert the content
commit and re-merge (the auto-seed upserts the old tags back). No schema or app
change is involved in Phase 1.

---

## Copy-paste kickoff prompt for the fresh implementation session

> Start Phase 1 of the tag migration (M-rethink-categories). The plan is
> approved — see `docs/tag-migration-plan.md` (decisions locked), the vocabulary
> in `docs/tag-taxonomy-v2.md`, and this brief `docs/tag-phase1-kickoff.md`. Do
> the city-by-city spot-check against `docs/tag-migration-review.md` first,
> correcting `scripts/seed_tags.py` where the auto-pass is wrong, then run
> `python3 scripts/apply_tags.py --write` + `swift scripts/validate-tours.swift`,
> and ship `Resources/Tours.json` as a content PR. Keep `primaryCategory`
> untouched — this is the additive, reversible step; the UI flip is Phase 2. Show
> me the before/after tag summary before you commit.

---

## After Phase 1 — what's next (not now)

- **Phase 2 (app + design session):** flip rails + a multi-select chip row to
  read tags; add `Tag`/vocabulary to the app + validators; derive a lightweight
  primary tag (D5). **Decide D7 here** (curated vs popularity rails). ~3–5 days.
- **Phase 3 (cleanup session):** drop `primaryCategory` from the model, the enum,
  the RPC JSON, the DB column. ~1 day.

Full change list + effort in `docs/tag-migration-plan.md` §2–3.
