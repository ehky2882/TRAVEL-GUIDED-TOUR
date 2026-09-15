# More like this — tour-to-tour similarity, and the two inert date sorts

**Session 113 · branch `claude/open-source-ai-integration-pxuxdh` · code + content + backend**

Owner asked what the next big win was, and whether it was semantic search. The
answer given, and taken: semantic search is the right target but the wrong
*next step*, because "More like this" gets most of the discovery value with
none of the Core ML risk — **the phone runs no model at all.**

---

## What shipped

**`relatedTourIds` on every tour.** Up to 8 neighbour ids, generated offline
from the sentence embeddings proven in `scripts/build-embeddings.py`, shipped in
the catalogue exactly as `country` is, rendered as a **More Like This** section
on the tour detail page below Nearby Tours.

**`createdAt` is served at last**, closing four sort controls that have rendered
and done nothing on every real phone since #600/#601.

## The numbers

| | |
|---|---|
| Catalogue | 1,582 tours · 429 makers · 305 places · 2,318 link pins · 117 cities |
| Tours with a neighbour | **1,580 of 1,582** (the two without hide the section) |
| Tours with a full 8 | 1,547 |
| Links written | 12,508, of which **12% cross-city** |
| `Tours.json` diff | **15,668 insertions, 0 deletions** |
| Generation | ~3.5 min, 6,884 chunks, one matmul |

## Decisions, and the evidence behind them

- **Owner, 2026-09-15: same city first, then cross-city fill.** Measured, not a
  preference — cross-city matches are thematically right and geographically
  useless on their own (Casa Batlló's best cross-city neighbour is a Madrid
  park). Fisherman's Wharf is the shape: 6 San Francisco, then Marseille's Old
  Port and Tai O.
- **Owner: bundle the `createdAt` fix**, since it needs the same migration and
  the same single owner paste.

## 🔴 Things a future session will get wrong

- **`createdAt` IS SERVED FROM A NEW `authored_on` COLUMN, NOT FROM
  `created_at`.** The audit column is `timestamptz not null default now()` and
  holds SEED time. Serving it would light all four sorts up and order them by
  seed sequence — fixed-looking and wrong, which is worse than the visible
  nothing they do today. `authored_on` is `date` and **nullable on purpose**:
  36 tours genuinely have no authored date and must sort last rather than be
  handed a fabricated one. `created_at` is untouched.

- **THE TOUR KEYS NOW LIVE IN `get_catalog_core_base`.** `split_link_pins.sql`
  renamed `get_catalog_core` and wrapped it, so the live chain is
  `get_catalog()` → `get_catalog_core()` → `get_catalog_core_base()`.
  **`add_video_role.sql`'s finder predates the rename** and searches only
  `('get_catalog_core','get_catalog')` — copied verbatim it finds nothing and
  raises. `backend/add_related_tours.sql` adds the new name. It fails closed.

- **THE MIGRATION MUST BE APPLIED BEFORE THIS MERGES.**
  `seed_from_toursjson.py` now writes both new columns, and
  `publish-catalog.yml` runs it under `ON_ERROR_STOP=1` in one transaction — so
  on a database without them the whole seed aborts and **every content merge
  stops reaching Supabase.** It fails loudly, not silently, but it blocks all
  content. Applying early is free: until a re-seed both keys are null, which is
  what the app already sees.

- **Similarity is mean-to-mean, deliberately NOT `tour_scores`' blend.**
  `tour_scores` weights the best chunk at 0.6 because a *query* is narrow and
  should find the one paragraph about art deco lobbies. A whole tour is not
  narrow — best-chunk pairs two tours because they each spend one sentence on
  brickwork. If you are here to make the two agree, there is a comment saying
  don't.

- **Do not loop `tour_scores` over the catalogue.** Its `owners == index` mask
  is a full pass per call: ~10^10 operations. `reduceat` over the offsets array
  that already exists is one matmul.

- **The floor is 0.45 and it was calibrated, not chosen.** 0.50 was tried and
  rejected: it **evicts good same-city matches in thin cities** — Fisherman's
  Wharf loses "Pier 39 Sea Lions" (0.477) and is handed a Hong Kong fishing
  village (0.592) instead. The floor has to sit *under* the thin cities. What
  it does cut: Boulders Beach's 0.395-and-below tail (Battery Park, a
  restaurant, the Company's Garden — "other things in Cape Town").

- **THE DETAIL PAGE'S THREE TAIL SECTIONS NOW DERIVE ONCE.** They cascade —
  each excludes what the one before showed — so all three need the other two's
  results. As computed properties `nearbyTours` (an O(n log n) sort over 1,582
  tours) and `siblingTours` re-ran several times per body evaluation. **Fourth
  time this repo has paid for "derive once, use many"** after `filteredTours`
  (#605), `railList` and `savedTours`. `TailSections` exists to stop a fifth.

- **Ids resolve through `UUID(uuidString:)`, never as text.** 103 of the
  catalogue's ids are uppercase and the rest are not, and Postgres hands them
  back lowercased — a string comparison would drop exactly those, on a device
  only. Pinned by a test.

## ⚠️ Owed, and not done

- **The 36 undated tours could NOT be backfilled and were deliberately not
  invented.** 35 are Atlas Studio SFO — **the entire maker, so no sibling
  carries a date** — plus one London tour. The dates are not recoverable here:
  **this clone is SHALLOW and its history stops at 2026-08-17**, which is why a
  `git log -S` pickaxe returns that date for every id. Needs either
  `git fetch --unshallow` or the owner's own knowledge of when SFO launched.
  Until then those 36 sort last, which is exactly what `Tour.createdAt`'s
  optionality already promises. **Do not fabricate them — that is the
  `created_at = now()` mistake in a different costume.**

- **Nothing was compiled.** Linux web session, no Swift toolchain, so CI is the
  `test_sim` stand-in and the owner's device check is the visual confirmation.
  The validator likewise ran as a Python mirror, **self-tested against 9
  injected faults first (9/9 caught)**; CI's Swift validator is authoritative.

- **`check-catalog-contract.py` goes RED until the owner pastes the SQL.** The
  `createdAt` KNOWN_GAPS entry was removed because the key is now genuinely
  owed rather than permanently absent. That is correct, not a regression.

## Worth knowing, found in passing

- **`stops.transcriptText` was removed from the catalog RPC on 2026-09-10** to
  cut egress (1.105 MB of 2.945 MB gzipped). Harmless here — the embeddings are
  built from `Tours.json`, which still carries transcripts — but a future
  semantic-search step that expected the RPC to carry them would be wrong.

- **The two tours with no neighbours at all** are the Intrepid Sea, Air & Space
  Museum and Montserrat's boys' choir. Both genuinely idiosyncratic; the
  section hides, which is the designed outcome rather than a gap.

## Verification

- `--selftest` **15 new checks, all green**, model-free. The same-city test was
  rewritten after it passed for the wrong reason: its first fixture ranked the
  same-city match highest anyway, so it would have passed with the rule
  deleted. The cross-city candidate now scores **higher**.
- Python validator mirror: **9/9 injected faults caught, then 0 errors** over
  1,582 tours and 2,318 pins.
- `Tours.json` byte-stable under a re-dump before and after; diff **additive
  only**, and every added line is the key, a UUID or a bracket — 0 lines that
  are anything else.
- All 12,508 references resolve; **0 point at a link pin**.
- Seed script regenerates: 429 makers / 3,900 tours / 4,272 stops / 305 places,
  with `authored_on` populated and the coalesce mirrored on both sides of the
  upsert guard.
