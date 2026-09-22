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

---

# Part 3 — Žižkov, and the two pairs that could NOT be separated

Owner: *"zizkov - make a place. seashore and library - can we space the
coordinates apart properly? same for long ma she and soft square"*
([#1061](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1061)). **420 places.**

## 9 · Žižkov — the strongest evidence a place has had here

`Žižkov Television Tower` (`@insightcities`) + `Zizkov Television Tower`
(`@pasttworld`), already coincident. Three independent confirmations:

* OSM names that **exact point** `Žižkov Television Tower, Mahlerovy sady, Praha 3`
* **Both** entries resolve to the same Wikidata item **`Q1413217`**, 28 sitelinks, 32 m away
* The two titles are the same name with and without diacritics

Nothing moved. ⚠️ Note the pair never reached the NAME tier — `fold()` strips
diacritics, so `Žižkov`/`Zizkov` *would* have matched there, but an **identical
coordinate puts a pair in EXACT instead**, and EXACT is the tier that had been
crashing (§ 7). The accent-folding worked; the tier that would have shown it did
not.

## 10 · 🔴 The two pairs were NOT separated, deliberately

The owner's reading was right — each pair is two different buildings:

| pair | what they are |
|---|---|
| `Seashore Library` + `Chapel of Music` | Vector Architects, **2015** and **2023**, both in the Aranya community, Changli County |
| `Long Ma She` 龙马社 + `Soft Square` | different buildings by different architects (Soft Square is ZXD), both in Changshou Village |

So the shared coordinate is a geocoding artefact. **But the LOCALITY is right and
only the precision is wrong** — the Beidaihe point reverse-geocodes to
`阿那亚三期` (Aranya Phase 3) and the Shenzhen one to Jiangling Road, Maluan
Sub-district, Pingshan District. **These are not misplaced pins**, which is a
different defect from the ones this session spent the day fixing.

**No per-building coordinate is reachable from here.** Routes tried, per rule 8d
— *a blocked scrape is not an absent fact*, so the point is that these were
genuinely exhausted before asking:

| route | result |
|---|---|
| Nominatim, English **and** Chinese (`三联海边图书馆`, `龙马社 长寿村`) | no results — OSM has no coverage of these |
| Wikidata entity search | HTTP **429**, so retried by another service |
| Wikidata SPARQL bounding box over the whole Aranya area | **4 items, none of them these buildings** |
| Web search ×2, explicitly for coordinates | architecture press only |
| ArchDaily project page | location field reads just *"Qinhuangdao Shi, China"* |
| Overpass | blocked by the egress proxy |

🔴 **Inventing a separation would have been worse than leaving them coincident.**
It would look precise and put a geofence where nobody stood, and rule 8d's own
record is three pins moved on a weak distance signal that came out **11 m right,
220 m wrong and 100 m wrong**. The whole session had been about checks that
report confidently on things they never evaluated; fabricating two coordinates
would have been the same failure by hand.

Recorded as `status/owner/china-pin-coordinates.md` with the routes tried and the
one-minute unblock, rather than guessed.

⚠️ **The trap waiting for whoever picks this up** is in `docs/lessons.md` now:
Baidu and Amap publish **GCJ-02 / BD-09**, offset from WGS-84 by **100–700 m**
inside China — *larger than the gap being created*. Google/Apple satellite is
WGS-84 and safe.

## State at Part 3 handoff

| | |
|---|---|
| places | **420** |
| `check-place-candidates.py` | NAME none · **EXACT 2** — the two open pairs, correctly reported |
| `validate-tours-mirror.py` | exit 0, control clean |
| `spine-match.py` | exit 0 — DISAGREES 0 unexamined, STALE 0 |

**Owner-side, carried forward:** the four coordinates above · 1.1.3 *Release this
version* · the four `@welldonestuff` reel links · the list-description clamp
check · Stortorget part-vs-whole

---

# Part 4 — the owner sent four Amap links, and the board went clean

Part 3 ended by saying no per-building coordinate was reachable and asking the
owner for them. The owner sent **Amap share links**, which resolve server-side —
`curl -L` and read the `p=` parameter out of the redirect `Location` header:

```
p = B0KG4BL0O2, 22.662834926503454, 114.36971426010129, Longmashe, Changshoucun No.40
```

The address field alone is worth the link: it confirmed the village the pin's
description named.

## 11 · Every one needed GCJ-02 → WGS-84, and the cost of skipping differed each time

`scripts/gcj02.py` (new, 8/8 selftests). The inverse has no closed form, so it is
solved by iteration; the round trip holds to **1.4e-14°**.

| pin | raw Amap | converted | what pasting the raw number would have done |
|---|---|---|---|
| Long Ma She | 975 m from the old pin | **414 m** | left it **further** from the building than the wrong shared pin |
| Seashore Library | 551 m | **4 m** | 🔴 **moved a pin that was already CORRECT, by 551 m** |
| Chapel of Music | 1,684 m | 1,510 m | a 174 m error on top of a real 1.5 km fix |

⚠️ **The two selftests that matter are not the round trip.** One asserts the
offset is **real** (482–589 m across six Chinese cities) — *a transform that
quietly did nothing would pass a round trip perfectly*. The other asserts the
transform is the **identity outside China**, because applying it to a coordinate
already in WGS-84 corrupts a correct pin by the same ~500 m and nothing
downstream could tell.

## 12 · 🔴 The Beidaihe pair was one wrong pin, not two

Both pins sat on `39.6561544, 119.3169543`, which reads unmistakably as a
shared village-centroid artefact — the same shape as Changshou Village.

It was nothing of the kind. The library's Amap point converts to **4 m** from
it. So that coordinate **was the Seashore Library's correct position**, and the
defect was that **`Chapel of Music` had been given it** — the chapel was
**1,510 m** out.

🔴 **The shape of a defect is not its cause.** "Two pins share a point" has at
least two causes that look identical from the catalogue, and the fixes are
opposite: one moves both, the other moves one.

⚠️ **The near-miss in the middle.** Once the library was known correct, applying
its 4 m refinement alone was tempting. It would have dropped the pair out of
`EXACT · ASK` — visible, addressed to the owner — into the 81-row `TIGHT` list,
where it would not have been seen again. **A 4 m improvement is not worth hiding
a 1.5 km fault.** Both were set together.

⚠️ **And the locality check went mute.** It settled Long Ma She decisively
(converted → `长守 Changshou`, matching Amap's own address; raw → `三河 Sanhe`, a
different village). For the chapel, OSM returned bare `Changli County` for
**both** points and could not discriminate. What carried that conversion instead
was the library case — the same converter landing within 4 m of an
independently-sourced coordinate already in the catalogue, which is an external
check at that exact location. **Say when a check has nothing to say, rather than
counting it as support.**

## State at the end of the session

| | |
|---|---|
| places | **421** |
| `check-place-candidates.py` | **exit 0** — `NAME — none` · `EXACT — none. Every coincident group is already a place.` **First clean board.** |
| `validate-tours-mirror.py` | exit 0, control clean |
| `spine-match.py` | exit 0 — DISAGREES 0 unexamined, STALE 0 |
| `status/owner/china-pin-coordinates.md` | **cleared** (`git rm`) — all four resolved |

**Owner-side, carried forward:** 1.1.3 *Release this version* · the four
`@welldonestuff` reel links · the list-description clamp check · Stortorget
part-vs-whole


---

## Correction — "#1019 must NOT be merged" was never an owner instruction

Parts 1–4 above carried that line forward as though the owner had said it. The
owner did not recall saying it, and the PR shows why the line existed at all:
**#1019 and #1015 contradicted each other.** #1019 added pins to an owner item
telling the owner to reseed Supabase; #1015, opened the same day, proved every
pin was already live. A session concluded that merging #1019 would re-assert a
disproved task — a sound inference — and it was then repeated as the owner's
instruction, which it was not.

Triaged 2026-09-22 and all three closed, each with a comment:

| PR | outcome |
|---|---|
| #1019 | **closed** — it edits a file already deleted from `main`, so merging would resurrect a false task; the live DB holds **3,657** link pins against **3,657** in the catalogue, so no reseed is owed |
| #1020 | **closed** — a board entry for #1012's merge, two days late |
| #1015 | **closed** — its four removals were already done; `status/builds/172.md`, the 1.1.3 App Store candidate record and a real gap on `main`, **salvaged byte-identical** into #1063 |

🔴 **The lesson is the one this whole session kept meeting:** a conclusion
someone reached gets repeated until it reads as a fact someone stated. Record
*why* a PR is being held, not just that it is — "held because it contradicts
#1015" can be re-checked; "must NOT be merged" cannot.
