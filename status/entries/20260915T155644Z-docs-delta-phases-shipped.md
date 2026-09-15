# Phase 2 MERGED: the delta path is complete, 43 rows in 19,496 B

_2026-09-15 15:56 UTC · branch `docs-delta-phases-shipped`_

🟢 **Phase 2 MERGED** — [#914](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/914) → `24903b8`.
The delta path is complete end to end: the RPC is live, and the client that merges its output is on
`main`.

**The device check that gated it, and why the second one counted.** The owner's *first* test —
3,901 held across five force-quit-and-relaunch cycles — proved less than it looked like. Head `rev`
never moved, so every launch was told nothing had changed and **skipped the download; the merge
never ran.** It took a deliberate `rev` bump, plus #917 landing 37 corrected Tokyo coordinates in
the same window, to produce a delta worth merging:

| | |
|---|---:|
| changed rows (3 tours + 40 link pins) | **43** |
| delta on the wire | **19,496 B** |
| full catalogue, which is what ships today | **2,427,222 B** |
| | **124× smaller** |
| nothing changed | **131 B** — ~19,000× smaller |

Owner relaunched and Settings → About read **3,901** — exactly what the database independently
says (2,318 `kind='link'` + 1,583 others, re-derived twice from `content-range` at 47 bytes).

🔴 **3,901 is the reading that matters, and specifically because of what it rules out.** The four
safety rules refuse a merge that **shrinks** the catalogue; **nothing refuses one that grows it.**
A duplicate-append would have read **3,944** and been cached silently, climbing on every content
change until someone noticed on the map. That is the one failure mode with no runtime guard behind
it, and it is now disproven on production rather than only in a unit test.

⚠️ **Nothing reaches a user until 1.1.3 ships.** Every build in the field still downloads the whole
catalogue, so today's egress bill is unchanged. Do not read this entry as the problem being solved.

⚠️ **Phase 3 — removals — is NOT built.** `removedIds` is always empty, so content *deleted* from
the catalogue still reaches phones only via a full download. It compounds the upsert-only deletion
gap: `seed_from_toursjson.py` never deletes, so a removal is always a two-part change.

⚠️ **A green test that could not have failed is not a result.** Recorded because this session
nearly reported the first device check as a pass.
