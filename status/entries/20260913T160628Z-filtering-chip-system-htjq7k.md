# Filter chips shipped (#835) and reordered (#861, build 156)

_2026-09-13 16:06 UTC · branch `filtering-chip-system-htjq7k`_

**The filter row shipped, then reordered.**
[#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835) **MERGED** (squash `a3ec5d9`):
the flat eighteen-toggle tag row becomes **All · Format · Price · Dozents · Tags**, each chip
opening a panel, every panel multi-select, every option carrying a **contextual** count. Designed
in Claude Design against the owner's AllTrails reference before any code; spec of record
`docs/filter-chips-design.md`. Three rounds of device review on builds 145 → 146 → 148 → 150.
Then [#861](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/861) (build **156**, CI 2414
green) reorders it to **All · Tags · Dozents · Format · Price** on owner instruction —
richest-first — row and All panel together.

🔴 **Three things this cost, all now written down:**

1. **Price comes from the DATABASE, never from `Tours.json`.** The design nearly shipped with no
   Price chip because the file reads `priceTier: nil` for every tour — and always will, since
   `seed_from_toursjson.py` omits the column deliberately. The live DB has **66 paid tours**.
2. **On iOS 26 a PARTIAL-height sheet is DRAWN as a floating card**, inset from the sides and
   nested into the display's corners; a sheet attaches to the screen's edges only at the LARGE
   detent. "Sized to its content" and "spans edge to edge" cannot both be had. A `.fraction`
   detent is not a height knob on this OS.
3. **A sheet from the main window cannot cover the mini-player and tab bar** — they sit in a
   window at `.normal + 1` — and **hiding them is the wrong fix**, which this repo has now paid
   for twice (session 24 with `PlayerView`, session 160 here). The owner filmed the result: the
   module vanished **~130 ms before the sheet appeared**. The panel is presented from
   `BottomModuleRoot`, which meant moving `TourFilter` onto `AppSharedState`. In
   `docs/lessons.md` § 9.

⚠️ A web session's push does **not** reliably start CI on an open PR — `ci.yml` carries
`workflow_dispatch` for exactly this. Run 2329 sat green on an older commit while newer work was
unverified. Read the run list against the head being merged.

**Open, deliberately not built:** sort on the drawer header — the one item the design lists.
