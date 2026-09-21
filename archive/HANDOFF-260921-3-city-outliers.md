# Handoff — 2026-09-21 (3) · The check that asks nothing

Continues `HANDOFF-260921-2-stale-cache.md`. That session ended with the coordinate
audit honest again and two new checks wired into CI. This one answers the question
those checks could not: **what about the entries no gazetteer has ever heard of?**

---

## The gap

`spine-match.py` is a lookup. It asks Wikidata where a name is and compares. That
makes it silent on **2,901 entries Wikidata does not know** — a bucket its own
footer is careful to call *unexamined, not clean*.

And a large part of that bucket is not a coverage problem that more lookups would
fix. Sweeping `@pasttworld` / `@urbanistariel` / `@hereinnyc` the day before,
**83% had no OSM result either**, and reading them explains why:

> *The Million Dollar Corner* · *Breakfast at Tiffany's Townhouse* ·
> *A Greek Goddess on Fifth Avenue*

Those are **story titles**. No gazetteer will ever match them, however many
sources are added.

## What the catalogue can answer on its own

It knows where its own cities are. An entry claiming to be in London that sits
**58 km from every other London entry** is answerable from the file alone.

That is not hypothetical — it is how **"Great Court, British Museum"** was caught:

| | |
|---|---|
| our coordinate | `51.8550012, 0.5176106` |
| reverse-geocodes to | *Horizon Boulevard, Horizon 120, **Great Notley**, Braintree, Essex* |
| a business park, out by | **58 km** |
| moved to | `51.519312, -0.126705` — OSM `type=museum`, Great Russell Street |

🔴 **Note the tell: *GREAT Court* → *GREAT Notley*.** A geocoder had matched the
wrong word and returned a confident answer in the wrong county. **Neither
gazetteer check could ever have found it** — the entry was `UNMATCHED`, so
`spine-match.py` had nothing to say, and `check-same-name.py` needs a second
entry of the same name, which does not exist.

## The second find, and what it exposed underneath

**"Modern Coffee House", New York — 22.9 km out, on Staten Island.**

The creator's own caption ends with the address: **📍 105 E BROADWAY, NY, NY 10002**.
Geocoding that string returns **three** results, and the **third is our exact
stored point**:

| | |
|---|---|
| 1 | `40.7135951, -73.9930832` — 105 East Broadway, Two Bridges, **Manhattan**, 10002 |
| 2 | `40.7136888, -73.9930960` — OSM `cafe` node **named Modern Coffee House**, same address |
| 3 | `40.5697726, -74.1296932` — a semidetached house, 105 East Broadway, **Staten Island**, 10306 |

**Staten Island has an East Broadway too**, and the thing that separates them is
the postcode. Moved to result 2 — the named venue itself.

### 🔴 And the postcode was in our data, and we had cut it off

Our stored copy of that caption stops mid-word, 140 characters in, **immediately
before the 📍**. The address that settles the pin was thrown away at ingest.

That is not one pin. Measured across the catalogue:

| | |
|---|---|
| captions | 5,463 |
| **exactly 140 characters** | **2,375 — 43%** |
| of those, ending mid-sentence | **2,320** |
| carrying a 📍 at all | 535 |

`scripts/make-link-pin.py:621` is `caption[:140]`. **Creators put the address
LAST**, so a hard cut at 140 preferentially destroys the single most valuable
line in the caption — and 535 is therefore a floor, not a count.

🔴 **This is not a tooling fix to make quietly.** The caption is what a user
reads on the pin, so changing it is a product decision. It goes to the owner
with a recommendation, not into this PR.

## `scripts/check-city-outliers.py`

Distance from the **median** of the city's **other** entries, scaled by that
city's **own** median spread. Three things are load-bearing, each chosen against
a specific failure and each pinned by a mutant that must go red:

| | why |
|---|---|
| the **MEDIAN** | a mean centre is dragged toward the very entry being hunted — and with two bad entries in one place, it hides **both** |
| the **SELF EXCLUSION** | an entry must not vote on its own centre |
| the **PER-CITY SCALE** | a flat threshold flags a sprawling city wholesale, and burying one finding in eighty is the same as not finding it |

**selftest 21/21 · mutants 17/17 caught, 2 proven equivalent.**

The two equivalents are worth recording rather than hiding: the `min_others` rule
is written **twice** (`len(members) <= min_others` outside the loop,
`len(others) < min_others` inside it), and since `others` is `members` minus one
those are the *same predicate*. Neither copy can be broken alone. Removing
**both** is a real mutant and is tested as one.

### 🔴 It is a question, never a verdict

Of **76 flagged out of 4,174 scored**, the large majority are correct: Cape Point
is 48 km from Cape Town, Kansai Airport 37 km from Osaka, the whole of Lantau
23–31 km from Hong Kong, Heathrow, the Củ Chi tunnels. The tool cannot tell a
famous far-out sight from an error and does not pretend to. **Read the subject,
not the number.**

### The hold-out is measured, not assumed

A city whose *other* entries sit on one exact point has no scale of its own, so
it is held out. That guard was **measured against the live catalogue rather than
argued**: it withholds **exactly two rows of 4,174**, and both are noise. Denver
holds five entries, **three of them the same building** (Populus), so its median
spread is 0 and two ordinary motels 3.3 and 5.8 km away would read as outliers.

Measuring it mattered — the instinct after this week was that a guard which
withholds an answer is the defect. Here it is not, and two minutes of arithmetic
is what separates those two cases.

### `--homonyms`

One city **name** holding two places, reported separately rather than called an
outlier:

| | span | |
|---|---|---|
| **San Juan** | 20,167 km | Philippines 1 · Puerto Rico 7 |
| **Jericho** | 10,351 km | United States 1 · West Bank 1 |

**Not errors** — `country` disambiguates them and the data is correct. But they
count as **one city**, and anything grouping by city name alone merges them, so
measuring a centre across both would make every member of the smaller one an
outlier. They are held out of the scoring.

---

## State

| | |
|---|---|
| `validate-tours-mirror.py` | **0 errors**, 530 warnings · `control clean` · selftest 37/37 + 12/12 |
| `check-city-outliers.py` | 21/21 · mutants 17/17 (+2 proven equivalent) |
| coordinates moved | **2** — Great Court, British Museum (58 km) · Modern Coffee House (22.9 km) |
| verdicts on file | 191 |

## Still open for the owner

- 🔴 **43% of captions are cut at 140 characters, and the cut lands on the address.** `make-link-pin.py:621` is `caption[:140]`. It has already shipped one wrong coordinate. Options, cheapest first: **(a)** keep the stored caption as is but preserve the 📍 line when the cut would remove it; **(b)** store the full caption and truncate in the UI, where it can be expanded; **(c)** leave it. **This changes what a user reads, so it is the owner's call.**

- **`Stortorget, Gamla Stan`** — part-vs-whole. It shares the place `Gamla stan`
  with a walk about the *whole* old town; a place is a coordinate, so both sit on
  the Royal Palace courtyard, 226 m from the square. Reverted, recorded, undecided.
- **Two place candidates** — Walden 7 now has four entries on one point;
  Four Freedoms Park sits 14.5 m from the FDR Monument pin.
- **Press *Release this version*** when Apple approves 1.1.3.
- **[#1019](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1019) should NOT be merged** — it resurrects a cleared owner item.

## Next

The two entries the audit still cannot settle are *Chiesa di Nostra Signora del
Cadore* (708 m) and *Ginza Kojyu* (282 m); neither point names the subject, so
neither is answerable by lookup or by city cluster. They need the creator's own
caption or the owner.
