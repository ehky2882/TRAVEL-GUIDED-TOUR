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

---

# Part 2 — the owner's two candidates, and the check that was crashing

Owner: *"brunswick centre - make a place. smithfield market - make a place"*.
Both created ([#1060](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1060)); **419 places**, NAME tier now empty.

## 6 · The footprint method worked for one and NOT the other

Part 1 settled Four Freedoms Park with an OSM polygon. Reaching for the same
tool twice gave one good answer and one trap:

| | OSM polygon of that name | usable? |
|---|---|---|
| **Smithfield Market** | way `145477213`, **166 × 217 m** — the market complex | ✅ yes |
| **The Brunswick Centre** | way `291651300`, **11 × 20 m** — one retail unit | 🔴 **no** |

🔴 **A named polygon is not necessarily the named thing.** The Brunswick Centre
is a ~220 m megastructure; OSM's feature carrying its name is a shop inside it.
Using that centroid would have been *exactly* as confident, and wrong. The
published coordinate was no help either — 3 dp, ~100 m.

**What settled Brunswick instead** was locality, per rule 8d: both pins
reverse-geocode *inside* `Brunswick Centre, King's Cross, Camden` — one onto the
Saturday food market in the raised concourse, one onto a shop unit. So both are
on the complex, and the midpoint of two verified members is defensible. **Then
the midpoint itself was checked** and resolves to a unit inside the centre.
34.5 m each.

**Smithfield was the opposite shape:** the Atlas pin reverse-geocodes to
**Barley Mow Passage**, an alley *outside* the hall, while the pin is on the
market. So the move is a **correction**, not a compromise — 91.4 m and 0.4 m,
inside `make-places.py`'s 120 m bound (`TIGHT_M` 25 m is `join-places.py`'s
bound and does not apply to minting).

## 7 · 🔴 `check-place-candidates.py` was crashing, and the crash read as a pass

Its documented contract, which CI implements:

```
0 = nothing found, 1 = candidates found (both fine), >=2 = the check failed
```

**An uncaught Python exception exits 1.** `report()` referenced an undefined
`catalog` in its `if exact:` branch — my own refactor in #1058 — so it raised
`NameError` on any catalogue with a coincident group, *after* printing the NAME
section. Every run since printed one heading, died, and was read as *candidates
found, fine*.

The EXACT tier is the one **Rule 8c exists for**, written after the owner found
duplicate pins on the map twice. It was unreported with **three groups in it**:

| | |
|---|---|
| `Žižkov Television Tower` + `Zizkov Television Tower` | Prague — **identical** coordinate |
| `Seashore Library` + `Chapel of Music` | Beidaihe |
| `Long Ma She` + `Soft Square` | Shenzhen |

🔴 **I reported "EXACT tier is clean" to the owner twice from those runs.** It
was never clean; the check never reached it. **A tier that prints nothing is not
a tier that found nothing** — the report was missing three of its four headings
and still read as a pass. Count the sections you expected against the sections
you got.

**Both halves fixed.** The `NameError`, and `main()` now catches, prints the
traceback and returns **2** — a script whose success codes include 1 must not
let an exception produce a 1, or its error path *is* its happy path.

**Why 51 green selftests said nothing.** `report()` *was* exercised — on a
fixture whose two entries sit at **different** coordinates, so `if exact:` never
ran. The only broken branch was the only branch no fixture entered.
🔴 **Coverage of a function is not coverage of its branches.** The new fixture
differs in exactly one respect: the two entries share a coordinate.

Proven by re-introducing each defect:

| mutant | selftest | real run |
|---|---|---|
| the original `NameError` | **red** | **exit 2** |
| crash → `return 1` again | — | **exit 1** (CI calls this fine) |

The second is what makes the exit-code change load-bearing rather than cosmetic.

⚠️ **And a smaller trap on the way out:** the first attempt to prove the fixture
could fail used `sed -i '473s/…/'` — a line number captured *before* the
fixtures were added. It patched a different line, the selftest passed, and the
run printed `exit=0 (want non-zero)` as though the fixture were dead. **A
mutation applied by line number may not have been applied at all.** Anchor on
content and assert the anchor matched exactly once.

## 8 · The CI watcher announced ALL CHECKS COMPLETE with one still queued

Unrelated to the catalogue, and the same shape. A watcher stopped when every
check run it could see had `status == "completed"` — and `Run unit tests` was
still **queued**. The run had not been *created* yet, so `all(...)` was true over
the six that existed. It would have merged on six of seven, and a merge does not
re-run the missing job.

🔴 **A completion test is only as good as its denominator, and on CI the
denominator arrives late.** Fixed by requiring the complete set to hold across
**two consecutive polls** — not by hardcoding an expected count, which goes stale
the next time the workflow gains a job.

## State at Part 2 handoff

| | |
|---|---|
| places | **419** |
| `check-place-candidates.py` | **56/56**, both new defects proven catchable |
| NAME tier | **empty** |
| EXACT tier | **3 groups, for the owner** (above) |
| `validate-tours-mirror.py` | exit 0, control clean |
| `spine-match.py` | exit 0 — DISAGREES 0 unexamined, STALE 0 |

**For the owner:** the three EXACT groups. `Žižkov`/`Zizkov` is two spellings of
one tower on one point and looks like a plain Rule 1 pair; the other two are
co-location calls. None created.
