# HANDOFF — 2026-09-22 · Two place candidates, and the guard that wasn't one

**Branch:** `claude/scale-pinned-tours-automation-dba3lx` · **PR:** [#1059](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1059)

The owner asked for two place candidates to be created. One of them already
existed, and what was wrong with it was a different thing entirely.

---

## 1 · Walden 7 was already a place. The defect was an orphan beside it.

`Walden 7` (Sant Just Desvern) has been a place since #1022, with three members.
A **fourth** entry titled `Walden 7`, by TikTok `@ninosbuildings`, sat on the
*identical* coordinate and was not a member of it.

🔴 **Nothing was looking for that.** Every tier of `check-place-candidates.py`
hunts for sites with **no** place page, so the instant a place exists that site
reads as finished. This is the hole `join-places.py` was built for after the
owner found the Washington Monument with an entry 7.0 m outside it — and the
hole reopens with every new batch, because a new pin lands beside an existing
place, not beside another orphan.

**The lesson for a batch:** after merging pins, running
`check-place-candidates.py` is not sufficient. Run `join-places.py` too. They
answer different questions — *should a place exist?* and *is this place
complete?* — and only the first is in Rule 8c.

Joined; 4 members, **0.0 m moved**.

## 2 · Four Freedoms Park — created, and the coordinate was the whole job

| | |
|---|---|
| `Four Freedoms Park` | Atlas Studio NYC |
| `The FDR Monument on Roosevelt Island` | TikTok `@urbanistariel` |

14.6 m apart, nothing else within 400 m. Two names for one thing —
`docs/places.md` Rule 1, which has never been declined.

**A place is a COORDINATE**, so minting one moves every member onto a single
point, and that point has to be honest for all of them. Neither title resolves
in Wikidata, so the spine could offer nothing at all. Three independent sources
did:

- **OSM way `108315458`** files the site as **`FDR Four Freedoms State Park`** —
  a *third* name for the same thing, which is itself corroboration of Rule 1.
- **Both pins fall inside its polygon.** So does the Wikipedia infobox point,
  **131 m away**.
- The park is a **229 m wedge**, so 131 m is *inside the subject*.

🔴 **Distance could not have decided this and would have decided it wrongly.**
A 131 m gap to Wikipedia's coordinate reads as a serious error on any threshold
this repo uses; the polygon says all three points are in the park. This is the
`docs/lessons.md` rule about verifying by locality rather than by distance,
arriving in a new form: **the locality can be the subject's own footprint.**

Chose the polygon's centroid, which *is* the Atlas pin. Atlas moves 0.0 m, the
pin 14.6 m — both inside the 25 m bound.

## 3 · 🔴 The caption tier's clean record was the owner's, not the tool's

`join-places.py` proposed a **third** join:

```
18.2m  Dead Rabbit  ->  Fraunces Tavern (New York)
```

Different bars, different addresses. It matched because the Dead Rabbit's own
description says *"in the historic Fraunces Tavern **district**"* — a
**locator**. `docs/places.md` Rule 3: co-location is not identity. A join writes
the id into `tourIds` **and drags the entry onto the place's coordinate**, so
applying it merges two real venues and moves one of them.

Instrumenting the caption tier against the live catalogue is the finding worth
keeping:

| | |
|---|---|
| rows the tier matched | **7** |
| correct | **1** |
| refused by `declined_pairs()` | **4** — Channel Gardens/Rockefeller Center, Cosmati Pavement and Shrine of Edward the Confessor/Westminster Abbey, Blue Ribbon Garden/Walt Disney Concert Hall |
| refused by nothing | **1** — Dead Rabbit |

Every one of those four is a **part-vs-whole**, which `docs/places.md` leaves
explicitly to the owner, and every one was stopped by a record of rulings **the
owner had already made one at a time**.

🔴 **So the tier's apparent precision was not a property of the tier.** It was
the owner's judgement replayed. A refusal list cannot refuse a case nobody has
judged, and the first such case went straight through. **Measure a tier on the
rows its declined list does NOT cover — those are the only ones it is deciding.**

**The guard now in place.** `title_introduces_another_name()`: strip the place's
own name out of the entry's title, and if a name is left over, the entry is
about something else.

| title | place | left over | |
|---|---|---|---|
| `Stonewall Inn` | The Stonewall Inn | — | join |
| `@centrepompidou is the coolest museum ever` | Centre Pompidou | filler only | join |
| `Dead Rabbit` | Fraunces Tavern | **Dead** | refuse |
| `The Cosmati Pavement` | Westminster Abbey | **Cosmati** | refuse |
| `Bar Luce at Fondazione Prada` | Fondazione Prada | **Luce** | refuse |
| `Municipal Library of Viana do Castelo` | Viana do Castelo | **Municipal** | refuse |

The last two are failures the file's own docstrings already record; they are now
refused structurally rather than from memory. It keeps the case the tier was
built for — a pin titled with its caption, which has no other name to give.

⚠️ A non-Latin word folds to nothing, so it counts as a name and refuses. That
costs the bilingual titles, and refusing sends the pair to the owner, which is
the safe direction.

⚠️ **Editing the predicate broke three existing mutants' anchors.** All fifteen
`mutate-*.py` count a non-matching anchor as `missed`, so the run went red and
named them — re-anchored in the same commit. **A fixture that cannot run must
fail, never pass**, and this harness already does that.

## 4 · The five pub disagreements — all name collisions, our pins exact

The spine audit carried 5 unexamined DISAGREES, every one a `@historicpubcrawls`
pin. Verified against OSM **by locality**:

| entry | OSM says | gap from our pin | Wikidata's item |
|---|---|---|---|
| The Sun Inn | 7 Church Road, Barnes (Richmond upon Thames) | **0 m** | 29 km away |
| The Roebuck | 130 Richmond Hill, Petersham | **0 m** | 15 km away |
| The Marquis | 51–52 Chandos Place, Covent Garden | **0 m** | 2.3 km away |
| Hedigan's (The Brian Boru) | Prospect Road, Dublin | **0 m** | 3.7 km away |

**Every one of our coordinates is exact**, and in each case Wikidata resolved a
*different pub of the same name*. Pub names are the most collision-prone names
in these islands: Wikidata holds **three** separate items called `The Roebuck`,
and OSM shows a **fourth** Roebuck 4.6 km from ours **in the same London
borough**.

This is now the second sweep in which the top spine findings were sampled by
hand and **none was a catalogue error**. The tool works; the true-error rate is
simply low. `The Marquis` covers two entries sharing one pin, so 4 verdicts
settle 5 findings.

`spine-match.py` exits **0**: DISAGREES **0 unexamined** (82 ruled), **STALE 0**.

## 5 · A fourth "true of the wrong population", caught before it shipped

Reading the skip report I grepped for `missed += 1` on the SKIP *lines* and
concluded **13 of 15 mutation harnesses did not fail on a skip** — a CI-wide
hole. The increment is on the **next** line. Every harness was already correct.
The lesson draft said the opposite until re-checked with an `awk` reading both
lines.

🔴 Three times earlier this session a measurement was true of something other
than what it was reported about (the +12% egress that was +0.8%; "535 → 943
captions" that was 913 → 945; `move<=0 m` that was up to 19.5 m). This was the
fourth. The tell is always the same: **a number that makes a whole population
look broken deserves one confirming probe before it is written down.**

---

## State at handoff

| | |
|---|---|
| places | **417** |
| `join-places.py` | selftest **41/41**, mutants **21/21**, 0 SKIP |
| `check-place-candidates.py` | 51/51; EXACT tier clean |
| `validate-tours-mirror.py` | exit 0, 37/37 control faults caught |
| `spine-match.py` | exit 0 — DISAGREES 0 unexamined, STALE 0, CONFIRMS 1,860 |

## For the owner — two place candidates, not created

`check-place-candidates.py` NAME tier, both London, both from the recent
pub-crawl batches. Rule 8c says these go to the owner:

- `Brunswick Centre` (pin) + `The Brunswick Centre` (pin) — **69 m**
- `Smithfield Market` (pin) + `Smithfield Market` (tour) — **92 m**

Both look like straightforward Rule 1 pairs, but the call is the owner's.

## Still owner-side, carried forward

- Four `@welldonestuff` reel links — **the source URLs are recorded nowhere** and
  cannot be recovered from this side.
- Press **Release this version** for 1.1.3.
- List-description clamp check (`status/owner/list-description-clamp-check.md`).
- Stortorget part-vs-whole.
- 🔴 **#1019 must NOT be merged.**
