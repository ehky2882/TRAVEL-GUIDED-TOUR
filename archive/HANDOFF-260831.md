# HANDOFF — 2026-08-31 (session 126, web/PM — content)

**Branch:** `claude/place-cards-audit-px3z3o`, cut clean off `origin/main` at `a997860a`.
**Scope:** an audit of un-placed place candidates, then four of them built. Content only —
no Swift, no SQL, no build, no gh-pages push. **No PR opened** (this session's harness forbids
opening one unasked).

**Counts:** places **49 → 53** — this branch adds 4; `main` gained the Chelsea Hotel underneath it mid-session (#669). Tours **1,552**, link pins **283**, makers **206** — all unchanged,
byte-for-byte (verified by diffing the parsed `tours` and `makers` arrays against `origin/main`).

---

## 1. The audit

`python3 scripts/check-place-candidates.py` → **4 EXACT / 12 NEAR** on the pre-edit catalogue.
Its selftest passes 24/24.

**⚠️ The checker cannot see everything, and this audit found a case it structurally misses.**
Its NEAR tier matches on *title containment* — one title's meaningful words must contain the
other's — so **Grand Central** never appeared: `{south, facade, grand, central}` and
`{grand, central, terminal}` are neither a subset of the other. CLAUDE.md already records the
same blind spot for Washington Square Arch/Park and St Pancras. A wider sweep was therefore run
by hand: **every marker pair within 40 m, plus every pair within 200 m sharing a distinctive
(non-generic) word — 86 pairs**, each read.

### Built (tier 1) — four sites, four free third photographs

| Site | Gap | Members |
|---|---|---|
| Casa Milà — La Pedrera (Barcelona) | 11 m | tour + `@nikola.matus` pin |
| Operaparken (Copenhagen) | 28 m | tour + `@karyna.y` pin |
| Wave Hill (Bronx) | 63 m | tour + `@wavehill` pin |
| Grand Central Terminal (New York) | 88 m | *The South Facade of Grand Central* + `@lizabanks11` pin |

**The Chelsea Hotel was the fifth and was left to the session already handling it.** It merged as
[#669](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/669) mid-session, so this branch was
rebuilt on top of it **the documented way: take `main`'s catalogue and re-run the idempotent
assembler, never hand-resolve a JSON conflict.** Every check below was re-run afterwards.

### Flagged, not built

- **Chichén Itzá** — three pins, no Atlas tour: Temple of Kukulkán and a `@bassforge.us` pin
  coincident, **The Great Ball Court 224 m off** (which the checker also misses). A place would
  have to **borrow a member's hero** — all three are pins with empty galleries — the
  Waterlooplein / Legion of Honor case.
- **Rosewood Mayakoba** — two coincident pins, identical title, one from the hotel's own account.
  Meets the identity rule; borrowed hero; low value.
- **Tribune Tower** (142 m) and **Petit Palais** (276 m) — in both, the Atlas tour covers *two*
  subjects (*The Wrigley Building & Tribune Tower*, *Pont Alexandre III & Petit Palais*), so a
  place named for the pin only half-covers its own member. A naming decision, not a data question.
- **Casa Lleó Morera / Dreta de l'Eixample** (0 m) — the documented Barcelona deferral.

### 🔴 The walk+single pattern, and what settles it

**24 of the 48 existing places are a walk paired with a single tour**, so this is the dominant
place shape, not an edge case. **47 of 72 walks belong to no place**, and 15 start within 60 m of
a single tour. Reading each walk's **stop 0 title** settles almost all of them:

- Genuinely the same site, **2**: *Dreta de l'Eixample* (stop 0 **is** Casa Lleó Morera, 0 m) and
  *The Monumental Rosary of Montserrat* (stop 0 **is** Monestir de Montserrat, 31 m).
- **Not candidates:** *The Loop — Where the Skyscraper Was Born* sits 24 m from the Rookery but its
  stop 0 is **LaSalle & Adams**, the Home Insurance site — a different subject. The other twelve
  have generic `"… — Introduction"` stop 0s naming no landmark, so the walk is not *about* the
  neighbour it happens to begin beside.

Both live ones need the walk's stop 0 moved onto the single's coordinate (places require exact
equality); both those stop 0s are `manual`, so no geofence would be disturbed.

### Already decided — do not re-raise

Little Island (owner: *"NOT little island for now"*), Tibidabo vs Tibidabo Amusement Park (#541),
LACMA vs the Academy Museum at 22 m (the documented false merge that killed the 40 m rule), and
Casa Batlló / Amatller / Lleó Morera as three separate buildings.

Close-but-distinct, checked and rejected: Westminster Abbey/Hall, Duomo/Piazza del Duomo,
Stonewall Inn/National Monument, Christ Church/Old Spitalfields, Al Fahidi Fort/Neighbourhood,
Marina City/Merchandise Mart, Castro Theatre/Harvey Milk, Graça Funicular/Miradouro, and both
San Francisco Chinatown pairs (a district, not a site).

**No stack-cap risk:** the only coincident groups of 3+ are AMNH (6) and Yankee Stadium (6), both
already places, so each collapses to a single map pin. `TourSetMap.maxStacked` is 3.

---

## 2. How the four were built

- **The pin moved, never the tour — all four times.** Verified rather than asserted: the parsed
  `tours` array is byte-identical to `origin/main`, so **0 tour coordinates, trigger modes or
  radii changed**. Each pin's `stops[0].latitude/longitude` **and** its `centroidLatitude/
  Longitude` were set to the tour's coordinate — four fields per pin, sixteen lines in total.
- **⚠️ Grand Central is the one judgement, and it follows the Petersen precedent.** The **pin** had
  the better address — it sat on OSM's own `Grand Central Terminal` node at 89 East 42nd Street —
  while the **tour** sits 88 m south on the 42nd Street pavement. That is not an error: the tour's
  own `longDescription` says *"standing at 42nd Street and Park Avenue, looking up at the south
  face"*, so it is a **deliberate vantage**, exactly like Petersen's Fairfax frontage and Grace
  Cathedral's Great Stairs. The place is anchored on the tour and **the address names the
  building**. ⚠️ Note the tour is `manual`, so the usual "moving a geofenced tour changes where
  audio fires" argument did not apply here — the vantage did.
- **Operaparken and Casa Milà are the CalAcademy rounding case**: the pins sat on OSM's own nodes
  (`Operaparken`; `Casa Milà`), 28 m and 11 m from tours stored at lower precision. Both tours are
  **geofenced**, so the tour anchors and the more precise node buys nothing.
- **🔴 Every place hero is a THIRD photograph, and each was opened and looked at.** The fault found
  across 13 of the first 24 places was one picture printed three times; here it is avoided by
  construction, and the build script asserts the hero equals neither member's. All four are
  promoted from the member tour's own gallery — **already uploaded, already verified, nothing
  sourced** — and all four live URLs return 200.
  - **Casa Milà** → `la-pedrera-casa-mila_3.webp`, the rooftop chimney warriors at sunset. The
    tour hero is the street elevation and the pin hero is a close crop with burned-in text, so
    this is the establishing shot neither member carries.
  - **Operaparken** → `operaparken_3.webp`, the oblique aerial of the whole island park. The tour
    hero is a tight top-down of the greenhouse alone.
  - **Wave Hill** → `Wave_Hill_2.webp`, the pergola and lawn. ⚠️ **The only option** — that tour's
    gallery holds exactly one image.
  - **Grand Central** → `GRAND.CENTRAL.SOUTH.FACADE_2.webp`, the whole south front in daylight.
    ⚠️ **It carries a Christmas wreath on the centre window** — seasonal, not wrong, and chosen
    over the alternative (`…_hero.webp`) because that one is a close-up of the sculpture group,
    and an establishing shot beats a close-up (the session-95 rejection criterion). One-line swap
    if the owner disagrees.
- **Ids are `uuid5(NAMESPACE_URL, "atlas-place:<city-slug>:<name-slug>")`.** ⚠️ **The slug does NOT
  fold accents** — it lowercases and replaces every non-`[a-z0-9]` run with a hyphen, so
  `Hackesche Höfe` → `hackesche-h-fe`. Reverse-verified: that rule reproduces **46 of the 48**
  existing ids, the two misses being the documented uppercase legacy ids (Green-Wood Cemetery,
  Oedo Antique Market). An accent-folding slug reproduces only 44 and would have minted the wrong
  id for `Casa Milà — La Pedrera`.
- **Addresses are editorial, corroborated by geocoding, never taken from it.** OSM files La Pedrera
  under **Carrer de Provença 261-265** (exactly as CLAUDE.md records) while the building's own
  published address is **Passeig de Gràcia 92**, which is what ships — the coordinate is where you
  stand, the address is what you are looking at. **Operaparken has no street number in OSM**, so
  it ships `Dokøen, Holmen, Copenhagen` rather than an invented one. Wave Hill's forward geocode
  returns `Wave Hill, 4900` (its reverse lands on neighbouring Sycamore Avenue — the documented
  Nominatim behaviour). Grand Central's forward geocode names **89 East 42nd Street** exactly.
- **Names.** `Grand Central Terminal` over the tour's *The South Facade of…* (the LA Union Station
  precedent — the place is the site, not one view of it). `Casa Milà — La Pedrera` carries both
  names, as both members do.

---

## 3. Verification

- **Validator: 0 errors, 2 warnings across 1,552 tours + 283 pins + 52 places** — and **both are
  pre-existing**, proved by running the same mirror against `origin/main`'s catalogue, which
  reports the identical pair (VIA 57 West's transcript gap; Bedrock Caverns' deliberate null
  `walkingDistanceMeters`). ⚠️ **No Swift toolchain in a Linux web session**, so this is a Python
  mirror of `scripts/validate-tours.swift` that parses the vocabulary from **both**
  `Models/Tag.swift` **and** the Swift validator and refuses to run if they disagree or either
  parse is empty (they agree at **385 tags across 5 facets**). **Self-tested against 14 injected
  fault classes, 14/14 caught**, including all seven place-layer checks.
  ⚠️ **One selftest "miss" was the test's own bug**, not the validator's — a lambda whose `or`
  short-circuited so the fault was never injected. Fixed, then 14/14.
- **`check-place-candidates.py`: 3 EXACT / 9 NEAR**, against `origin/main`'s 3 / 12. **NEAR fell by
  exactly the three pairs resolved** (Casa Milà, Operaparken, Wave Hill; Grand Central was never
  in NEAR because of the title rule above), and **EXACT is unchanged** — the four groups this
  session made coincident are each silenced by their new place, so **no new EXACT group was
  manufactured.** The three that remain are the Barcelona deferral, Chichén Itzá
  and Rosewood Mayakoba — Chelsea is gone, resolved by #669.
- **Structural, over the edited catalogue:** 0 duplicate place ids, 0 places with fewer than 2
  members, 0 tours claimed by two places, 0 members off their place's exact coordinate, 0 place
  heroes equal to a member's hero, 0 place heroes shared between places, 0 unknown tag, 0 link pin
  inside `tours`.
- **`backend/seed_from_toursjson.py` regenerates cleanly** — 206 makers / 1,835 tours / 2,207 stops
  / **53 places** — which exercises its own `validate_places`.
- **Tours.json byte-stable under a Python re-dump before editing**; diff **76 insertions /
  16 deletions**, which is exactly 4 places × 15 lines plus the 16 pin coordinate lines.
- **CI has not run: no PR is open**, so the authoritative Swift validator has not seen this.

## 4. Also noticed, not acted on

- **The `Casa Milà — La Pedrera` pin's `heroImageURL` contained a double slash** (`images//casa-mila-…`),
  from the batch that merged in #668. **It resolved — both spellings return 200** — so it was untidy
  rather than broken, and was left alone as another session's content. **#669 has since cleaned it and
  six others**, and that fix is preserved here because the merge took `main`'s file and re-ran the
  assembler over it.
