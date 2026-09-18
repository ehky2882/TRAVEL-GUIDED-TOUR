# One place-creation system, covering everything

**Status: SPEC. Nothing here is built except signal B, which shipped in #993.**

## Why this exists

#993 auto-created 23 places from a shared Wikidata id. Within the hour the owner
found two it could never have found: **Kossar's** and **Una Pizza Napoletana**,
both in New York, both sitting in `check-place-candidates.py`'s output already —
Kossar's at **exactly 0.0 m**.

🔴 **The feature that shipped covers landmarks, not venues**, and the tool that
covers venues was already in the repo and not wired to create anything. Measured
on `main` today, the tiers that exist but mint nothing:

| tier | groups waiting | covers |
|---|---:|---|
| **EXACT · PROVEN** | **13** | venues, restaurants, food — coincident **plus** independent proof |
| **NAME** | **14** | same name up to 1,500 m apart — Domino Park (201 m), Asakusa (662 m) |

That is **27 places available today** that #993's mechanism cannot see, against
the 23 it created. The gazetteer is the minority path.

## The three signals, and what each is for

**A · Coincident coordinate + independent proof** — `check-place-candidates.py`'s
EXACT · PROVEN. Two entries on one point, **plus** a second signal: an identical
display name, the same venue `@handle` in both captions (the creator's own handle
excluded — it proves nothing), or one entry's name appearing in the other's
caption prose. The owner licensed acting on it unasked: *"when it is super-clear
and doesnt need input, just go ahead and do it."*

⚠️ Safe because **every part-vs-whole case the owner has ever declined sits
between 6.9 m and 290 m apart — not one is coincident.**

**B · Shared gazetteer id** — built, #993. Wikidata resolves both entries to one
item and both sit within 120 m of it. Covers landmarks: 86% for Atlas Studio LDN,
**1–7% for food creators**.

**C · Same name within a radius** — the NAME tier. Catches what A misses when the
two coordinates differ and B misses when the gazetteer has never heard of the
subject. Set **equality** of subject words, not containment.

**They are complementary, not ranked by quality.** A covers what B cannot see and
B covers what A cannot: Grace Farms' pin sat 6.1 km from Grace Farms, so no
coordinate test could group it, while Kossar's is not in any gazetteer.

## 🔴 The gap that cost us Kossar's, and it is not coverage

The pin is titled **"Someone fact check my bialy claim 📍@kossars"**. That is a
caption, not a name. #993's lookup asked Wikidata for that literal string — it
could not have matched anything even if Kossar's were in the gazetteer.

**So the system needs a venue-name resolution step before any signal runs:**
prefer the `@handle` in the caption (`@kossars` → Kossar's), then the entry's own
title, then the editorial reductions. `check-place-candidates.py` already has the
handle extraction (`VENUE_HANDLE`, `_norm_handle`) — **reuse it, do not re-cut
it.** It already folds `@eat.namkeen`/`@eatnamkeen` and accepts prefixes.

## What the minter must do

One script, consuming all three signals, reusing what exists:

1. **Resolve a venue name per entry** — handle, then title, then reduction.
2. **Group** by signal A, then B, then C, taking the first that fires. Record
   which signal decided it; a place minted on a shared handle and one minted on a
   gazetteer id are different claims and the report should say which.
3. **Refuse** anything in `make-place-menu.py`'s `DECLINED`, `DECLINED_GROUPS` or
   `DECLINED_PAIRS`.
4. **Refuse** a group that would move any member more than `--max-move`.
5. **Escalate, never decide**, part-vs-whole. `docs/places.md` leaves it
   explicitly undecided and a gazetteer has no opinion on it.
6. **Skip extended sites** — a park, street, long bridge or district has no single
   honest point (`spine-match.py`'s `EXTENDED_TYPES`).
7. **Append, never sort** `places`. Sorting turned a 23-place addition into 4,048
   insertions across 1,570 coordinate lines in #993's first attempt.

## 🔴 The guard that matters most, and why

In #993 the declined check **failed on its first run** — Bar Luce at Fondazione
Prada, declined under Rule 4. The code was right; the *data* was missing. That
decision and **eight others existed only as prose in `docs/places.md`** and had
never been written into the machine-readable record, so every tool reading the
record believed nine owner decisions were still open. All nine are in it now.

**Auto-creation is only as safe as the declined record is complete.** Before
widening the signals, re-read `docs/places.md` against that record and close any
remaining gap. A signal that fires more often makes an incomplete record more
dangerous, not less.

## Build order

1. **Venue-name resolution**, reusing `VENUE_HANDLE`. Test it on Kossar's and Una
   Pizza — both must resolve to the venue, not the caption.
2. **Signal A minting.** 13 groups waiting; Kossar's and Una Pizza are in them.
   Highest value, lowest risk, owner already licensed it.
3. **Signal C minting**, with the same guards.
4. **Fold #993's signal B** into the same script so there is one minter, one
   report and one set of guards rather than three.
5. **CI**: report the remaining candidates per tier, never mint in CI.

## Verification, non-negotiable

- **Mutation-test every guard.** In #993 four guards could not fail, and a fifth
  test passed against a mutant because one guard *masked* another. All five read
  as ordinary green checks.
- **Ground truth**: Kossar's and Una Pizza must be proposed; Bar Luce must be
  refused; every previously declined pair must be refused.
- `validate-tours` after every apply — it is the only mechanical check that a
  member actually sits on its place.
- **Read the diff shape**: N places should mean N new `tourIds` blocks and at most
  2 coordinate lines per member. Anything larger means something was reordered.
