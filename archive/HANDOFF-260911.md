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

## What is NOT done

**No place was created.** A place needs its own name, description, address and a chosen
coordinate — picking that coordinate is a decision, not an average — so § B is a menu, not a
to-do list. The owner picks and they get written. `heroImageURL` stays optional by design, so
none of them is blocked on sourcing an image.
