# Handoff — 2026-09-10 (session 153, part 2)

**The Supabase egress emergency, and the catalogue payload cut that answers it.**
Continues `HANDOFF-260909-4.md` (the version check, PR #776 — still open, owner OK pending).

Two PRs: **[#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776)** (code, owner OK
pending, TestFlight build 142 uploaded) and **[#795](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/795)**
(SQL + tooling + docs — **the SQL has been applied and verified live**).

---

## What happened

A **second** Supabase notice arrived: **11.82 GB against a 5 GB allowance**, grace period cut from
4 October to **13 September**. The owner sent the usage dashboard, then a screen recording of the
per-day breakdown.

**The breakdown settles the cause completely, and killed two plausible theories:**

| | |
|---|---|
| **PostgREST** | **100.0% — every single day** |
| Auth | 28–64 KB/day |
| Storage | **977 bytes**/day |
| Edge Functions | does not appear at all |

- ⚠️ **238,583 Edge Function invocations looked alarming and produce essentially zero egress.**
  I raised them as suspicious in chat; that was a false alarm and I said so.
- ⚠️ **It is not the users. MAU is 17.**

Daily figures — the honest scoreboard for every fix here (allowance ≈ **167 MB/day**):

| 8 Sep | 9 Sep (#770 lands) | 10 Sep |
|---|---|---|
| **1,963 MB** | **493 MB** | **241 MB** |

---

## What shipped

**`stops.transcriptText` is off the wire.** 1,924 stops, 3,768,989 characters of narration script,
**displayed by no consumer screen at all** — grep-verified across the app, not assumed: the only
readers are `Models/Stop.swift` (the declaration), `MakerTourService`, `TourWizardRules` and
`CreateTourWizardView`, all maker-side, and `MakerTourService` queries the `stops` table directly
rather than the RPC. The column is untouched.

**Measured on the live wire, before and after:**

| | |
|---|---|
| before | 3,698,842 bytes |
| after | **2,163,115 bytes** |
| **saving** | **41.5%, every fetch, forever** |

It reaches phones **already in the field with no App Store release**, because
`Stop.transcriptText` is `String?` — an absent key decodes as nil on every build ever shipped.

⚠️ **`longDescription` was considered and deliberately KEPT.** Its "18%" in older notes was a
**raw** figure; gzipped — which is what is billed — it is **8.2%**, and unlike the transcripts it
*is* used (`TourDetailView` renders it, `SearchView` searches it).

---

## 🔴 The incident inside the fix — read this one

**The first version of the migration reverted the link-pin split.**

It rebuilt `get_catalog_core()` by copying the body out of `backend/restore_catalog_keys.sql` and
deleting one line. That body was superseded: `split_link_pins.sql` had renamed the builder aside to
`get_catalog_core_base()` and made `get_catalog_core()` the **wrapper** that lifts link pins into
their own `linkPins` key.

So the paste took the live catalogue from `tours 1553 / linkPins 1712` to
**`tours 3253 / linkPins 0`** — which fails the **whole** catalog decode on every build predating
`TourKind.link`, silently, because the loader reads a throw as a failed fetch and keeps its last
good copy. Live for roughly six minutes.

**Caught by counting the live payload immediately after the paste.** "Success. No rows returned."
said nothing.

**The rule it taught — now in `docs/lessons.md`:**
> **Transform what the live chain returns; never retype it.** Committed SQL records what was true
> when it was written, not what is live underneath it now. A wrapper cannot lose a key it never
> mentions.

The repaired migration does exactly that: it calls `get_catalog_core_base()` and applies
`- 'transcriptText'` to each stop on the way past, preserving stop order explicitly
(`with ordinality` + `order by` — that order is the walking route).

**Three durable guards came out of it:**

1. **The migration verifies its own shape.** It ends in a `do $$` block that raises if `linkPins`
   is empty, if a pin is still inside `tours`, if `places` is empty, or if any transcript survived.
2. **The audit was looking one layer too high.** `check-catalog-keys.py` inspected only
   `create or replace function public.get_catalog()`; the destructive statement was against
   `get_catalog_core()`, so the bad file **passed the audit that exists for exactly this**. It now
   audits both layers on the same rule — a body that CALLS the layer beneath it is a wrapper and is
   fine; a body that RETYPES it is a loaded gun.
3. **`restore_catalog_keys.sql` now carries the `NO LONGER SAFE TO RE-RUN` banner** it had always
   warranted, plus the stronger warning that it is not safe to **copy from** either — the mistake
   actually made.

Also added: **`FORBIDDEN_STOP`** in `check-catalog-keys.py`, which fails if `transcriptText` ever
returns to the payload. The damage runs that way — a key that comes back costs money on every fetch
by every phone forever, and nothing else would notice.

---

## Verified live after the owner's paste

- `check-catalog-keys.py` → **exit 0**, fresh RUN stamp, `1553 tours, 404 makers, 141 places`
- `check-catalog-contract.py` → **exit 0**, `PASS — every key the app decodes is being served`
  (one pre-existing known gap: `tours[].createdAt`)
- Direct count: tours **1553** / linkPins **1712** / places **141** / makers **404**;
  **0** strays, **0** transcripts, **0** tours with stops out of order, `longDescription` still served
- Wire bytes **2,163,115** (from 3,698,842)

---

## What is owed

| | |
|---|---|
| 🔴 **Upgrade to Supabase Pro before 13 Sep** | The 11.82 GB is already spent and cannot be un-spent. This fix governs the NEXT cycle. Advised repeatedly; owner's call |
| **Owner OK + device check on [#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776)** | The version check. CI green, TestFlight **build 142** uploaded with notes |
| **Merge [#795](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/795)** | SQL/tooling/docs — auto-merge class once CI is green. **The SQL is already applied live** |
| Watch the daily egress bars | 11 Sep is the first full day carrying both the 9 Sep fixes and this cut. Expect well under 167 MB |

**Not built:** when anything changes, the app still downloads all 1,552 tours. Delta or
city-scoped fetching is the remaining step.
