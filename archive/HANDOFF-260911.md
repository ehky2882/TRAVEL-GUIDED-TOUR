# HANDOFF 2026-09-11 — the place sweep, and a rule that could not see what it was looking for

One piece of work: the owner asked for a sweep of place candidates, saying *"even 2 tours at a
location is a candidate."* The sweep found **221**. None of them is a new idea — every one was
already in the catalogue, sitting unrecognised.

## The finding behind the finding

`scripts/check-place-candidates.py` already existed and already ran. It matched two entries as
one site when **one title's meaningful words contained the other's**, within 500 m.

🔴 **That rule is precise, and it is structurally blind to the commonest shape in this
catalogue: one site that two entries call by two unrelated names.**

| One site | The two names | Apart |
|---|---|---|
| A firehouse on North Moore Street | *Hook & Ladder 8* · *The Ghostbusters Firehouse* | 4 m |
| Westminster Abbey | *Britain's Oldest Door* · *The Tomb of Elizabeth I* | 5 m |
| The Nabisco building | *Chelsea Market* · *👀 Oreos were first made in NYC!* | 8 m |
| Old St Patrick's | *The Catacombs of Old St. Patrick's* · *The Godfather Baptism Church* | 16 m |
| 33 Liberty Street | *The Federal Reserve Bank of New York* · *$500 Billion of Gold Under 33 Liberty Street* | 0 m |

Not one of those five pairs shares a single word. No string comparison reaches any of them.

**The lesson generalises past places, and it is in `docs/lessons.md`: when the thing you are
identifying is physical, match on the physical fact and use the text only to explain the match.**
The title was never the evidence here. The coordinate was. The title was doing the work because
it was the easier thing to compare.

## What shipped

A third tier, **TIGHT** — within 25 m, whatever the titles say.

| | Before | After |
|---|---|---|
| EXACT (identical coordinate) | 41 | 41 |
| TIGHT (≤25 m, any titles) | — | **151** |
| NEAR (same subject, 25–500 m) | 148 | 79 |

**82 of the 151 TIGHT pairs could not have reached the old NEAR tier under any title rule, and
55 share no word at all.** Otherwise behaviour-preserving: the old NEAR tier's 148 pairs come
back as 69 TIGHT + 79 NEAR, **exactly** — which is how the refactor was checked, rather than by
reading the diff.

The O(n²) pair loop (5.3M haversines over 3,269 markers) became a grid of radius-sized cells
scanned nine at a time. 0.4 s. ⚠️ **Deliberately NOT bucketed by `city`** — two markers 20 m
apart can carry different city strings (New York / Brooklyn) and a place spans that label. A
selftest case pins it, and another pins a pair straddling a cell boundary; both were
mutation-tested by breaking the implementation and confirming they fail.

## The sweep — `docs/place-candidates-260911.md`, numbered for picking

| | | |
|---|---|---|
| **A** | **10 existing places are missing a member already standing on them** | Additive, no new place, no judgement. Do these first |
| **B** | **132 sites** with 2+ entries and no place page | Owner picks |
| **C** | 79 same-subject pairs 25–500 m apart | Read one at a time |

§ A is the quiet one and probably the most valuable: Rockefeller Center's page does not include
*The Channel Gardens*, Westminster Abbey's does not include *The Cosmati Pavement* or *The
Shrine of Edward the Confessor*, and Griffith Observatory's does not include either pin about
Griffith J. Griffith himself. The page exists; the entry standing on it is simply absent.

🔴 **The two owner decisions STATUS.md § 5 already owed are items in this list** — the First
National Bank of Hollywood pair is **B15**, the St Vincent de Paul pair **B83**. They should be
answered as part of it, not one at a time.

## ⚠️ The false positives are named, not hidden

Proximity is evidence, not proof, and two classes of wrong answer are permanent:

1. **A dense block of separate venues.** Hong Kong's restaurant pins sit 10–20 m apart and are
   different restaurants (*Little Bao* / *Primo Posto*, 14 m). Same for Stockholm's *Bar Montan*
   / *Hosoi* and Sydney's *Pellegrino 2000* / *The Rover*.
2. **Coordinates rounded to four decimal places** — ~11 m — which can round two genuinely
   separate sites to within a few metres. This is what puts Madrid's *El Retiro* 8 m from the
   *Puerta de Alcalá* and Chicago's *Marina City* 17 m from the *Merchandise Mart*.

Nothing auto-creates. Exact coincidence still exits non-zero; everything looser is for a human.

## ⚠️ A duplicate bug that wasn't

19 of the § B groups hold two entries with an **identical title** — *Hollyhock House* twice,
*The Noguchi Museum* twice, *Fondation Maeght* twice — which reads exactly like a merge that ran
twice. **It was checked rather than assumed**, against `sourceURL` and `makerId`: every one is a
different creator covering the same building, which is the precise thing a place exists to hold.
The two sharing a maker are two separate posts with two different heroes.

Separately, **5 `sourceURL`s are shared by more than one pin** — one video pinned at each place
it visits (a Zumthor reel at LACMA, Therme Vals and the Bruder Klaus Chapel; an antique-markets
reel at five Italian markets). Also correct, also not a duplicate.

## § A applied — and the claim that it was free turned out to be wrong

The owner picked **all of § A except Il Presidente, Westminster Abbey and the Channel Gardens**.
Each of those three was the *only* missing member of its row, so A4, A8 and A9 drop out entirely
and stay open. Applied: **seven places, eight entries.**

🔴 **"Adding the id to `tourIds` is the whole change" was WRONG — it is in this handoff's own
§ A description above, and in the doc, and it is what the owner was told.** The validator caught
it. `Place.swift` makes a place's identity **exact coordinate equality**, and `validate-tours`
enforces it at **1e-9 degrees**. All 362 existing place members sit exactly on their place — 362
of 362, which is the schema rather than a coincidence. The eight ids alone produced exactly eight
errors, `place <name>: member not on the place coordinate`.

So joining a place also means **snapping the entry's stop coordinate, and its centroid** (or the
centroid falls outside the stop range), onto the place:

| Moved | Onto | By |
|---|---|---|
| *Where Julius Caesar Was Assassinated* | Largo di Torre Argentina | 20.9 m |
| *M+ Museum* | M+ Museum | 15.6 m |
| *Museum at Eldridge Street* | Eldridge Street Synagogue | 11.9 m |
| *Above the Bradbury Building's Atrium* | Bradbury Building | 8.9 m |
| *Who Funded Griffith Observatory* · *The Crimes of Griffith J. Griffith* | Griffith Observatory | 5.4 m |
| *Charging Bull: How It Got There* | The Charging Bull | 3.5 m |
| *Tribune Tower* | Tribune Tower | 0.6 m |

⚠️ **Every move is ASSERTED in the script to be inside the entry's own `triggerRadiusMeters`**
(30 m for all eight), so nothing changes about when any tour fires. A larger move would silently
redefine where a tour triggers and nothing else in the pipeline would object — which is exactly
the class of defect `check-coordinates.py` exists for. The assertion stays.

**How the failure surfaced is worth keeping.** `validate-tours-mirror.py` did not print eight
errors; it exited **2 — "selftest 32/32 faults caught; control DIRTY … SELFTEST FAILED, verdict
not trustworthy"** with no detail. The control is the real catalogue, and my edit had made it
dirty. Running the same validator against `git stash`'s clean base returned **0 errors**, which
is what localised it to the edit rather than to the tooling. *Read the counts, not the verdict.*

### Verified after

- Validator **0 errors / 0 warnings** across 1,552 tours + 1,717 pins + 142 places; control clean.
- **No entity created** — every count unchanged.
- The `Tours.json` diff is **exactly 8 entries × 4 coordinate fields + 8 ids**, categorised line
  by line rather than eyeballed.
- `backend/seed_from_toursjson.py` runs clean and all 8 ids reach the places SQL, so
  `publish-catalog.yml` carries this to Supabase on merge (conditional on `SUPABASE_DB_URL`,
  which cannot be checked from here — verify against the live RPC after merge).
- Sweep re-run: **41/151/79 → 40/132/79**; the seven groups fall silent **and the three held rows
  still report**.

## § B's 0 m rows applied — 38 places, and two held on purpose

The owner then asked for **the 0 m candidates in § B** — the EXACT tier, every member on an
identical coordinate, which is the catalogue's own identity rule. There were 40.

**38 are now places (142 → 180). 2 are held.**

**Names, addresses and copy were written, not guessed at.** The id scheme was reverse-engineered
from the live catalogue — `uuid5(NAMESPACE_URL, "atlas-place:{slug(city)}:{slug(name)}")`,
lowercase, which reproduces **140 of 142** existing ids (the two misses are older
`atlas-place:{slug(name)}` ids and, like the odd link-pin ids, are NOT re-minted) — and verified
by reproducing the three most recently added places exactly before minting anything. **All 40
addresses were reverse-geocoded from the exact coordinate** rather than recalled, via Photon
(40/40 FOUND, the three outcomes kept distinct per `docs/lessons.md` § 4), and every returned
locality was read back against the catalogue's `city`. ⚠️ **Ellis Island geocodes to Jersey City,
New Jersey and that is correct** — most of the island's made land is legally New Jersey.

🔴 **Eight groups were folded wider than 0 m, deliberately.** Each had a same-subject entry a few
metres off the exact coordinate, and building the place from the coincident pair alone would have
produced **a place called "The Pantheon" that excludes the Pantheon tour standing 5.8 m away.**
On the § A precedent they are snapped in (25.8 m down to 1.4 m), each move asserted inside that
entry's own 30 m radius.

### ⏸ The two held, and why holding was the answer

**Grand Central** and **Tai Kwun** each have a same-subject entry **87.9 m away — outside its own
30 m geofence**, so it cannot be snapped without moving where that tour actually fires. For Grand
Central it is worse: the far entries are the **existing `Grand Central Terminal` place**, so
creating this one would put a second place of the same name 88 m from the first. The choice is
**move the far entries onto one coordinate, accepting the 88 m shift in their trigger point, or
leave the site split in two** — editorial, not mechanical.

### Verified

- Validator **0 errors / 0 warnings**, 1,552 tours + 1,717 pins + **180 places**; control clean.
- Sweep **40 exact → 2**, and the 2 are exactly the held pair. TIGHT 132 → 117.
- `seed_from_toursjson.py` emits 180 places cleanly.
- Every new place has `heroImageURL: null` **by design** (the page falls back to its top tour's
  hero) and **every one has at least one member carrying a hero**, checked — so none renders blank.
- ⚠️ **The first attempt sorted `places` and rewrote 1,425 unchanged lines.** Reverted; the array
  is appended to instead. Final diff is **611 insertions / 32 deletions, and the 32 deletions are
  exactly the eight folded entries × four coordinate fields** — categorised, not eyeballed.

## What is NOT done

**§ B's non-0 m rows and § C (79 pairs) create nothing.** A place needs its own name, description,
address and a chosen coordinate — and, as above, every member then moves onto that coordinate —
so it stays an editorial decision, not a batch job. `heroImageURL` stays optional by design, so
none of them is blocked on sourcing an image.
