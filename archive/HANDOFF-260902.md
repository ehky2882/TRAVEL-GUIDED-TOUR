# HANDOFF — 2026-09-02 (session 135c, web/content)

**Cube House and Tribune Tower become places.** Branch `claude/tour-links-yg5yw2`, restarted clean off
merged `main` (`b2ffd16f`) after #703 landed. **Places 95 → 97**, and **`check-place-candidates.py`
reaches 0 EXACT and exits 0** — the clean state last held before #674. Content only: no Swift, no SQL,
no gh-pages push, no build.

Owner, given the last two coincident groups:

> make both places

---

## What was built

| Place | Members | Coordinate | Hero |
|---|---|---|---|
| **Cube House** (Toronto) | `Cube House` (`@toronto_papi_`) + `Inside the Cube House` (`@vonwong`) | `43.6546346, -79.3575624` | borrowed — the exterior |
| **Tribune Tower** (Chicago) | `Tribune Tower` (`@about_buildings`) + `The Artifacts in Tribune Tower` (`@kayleejochicago`) | `41.890584, -87.6232046` | borrowed — the full elevation |

Both **pure additions**: `makers`, `tours` and `linkPins` byte-identical, the 95 existing places
unchanged as a prefix, **both pairs already exactly coincident so nothing moved**. Diff **30 / 0**.

---

## ⚠️ The sweep went past the checker's pair, and on Tribune Tower it changed the answer

Each site was swept by **title full-text and by distance to 350 m** before anything was built (the
session-131 lesson).

- **Cube House is clean.** Two pins, coincident, and **nothing else within 350 m at all**.
- **Tribune Tower is not.** The Atlas tour **`The Wrigley Building & Tribune Tower` sits 142 m away**
  and is **correctly NOT a member** — the identity rule is exact coordinate equality and 142 m is not
  close. **That exclusion also disposes of the naming problem this pair has carried since #701**: that
  tour covers *two* subjects, so a place named for the tower would half-cover its own member. The rule
  settled it; no judgement was needed, and the flagged-and-not-built note can be closed.
- Correctly excluded at close range: **Apple Michigan Avenue 68 m**, the **DuSable Bridge Riverwalk
  101 m**, the **Magnificent Mile walk 222 m**.

## Coordinates

- **Cube House** reverse-geocodes **by name** to `Cube House, 1, Sumach Street, Moss Park, Toronto`,
  **way 184346300**, `building=house`. Its own pin caption reads `📍 1 Sumach St`, so coordinate and
  caption confirm each other independently.
- **Tribune Tower's reverse names nothing** — it lands on an `amenity=loading_dock` node, the
  documented nearest-addressed-node case, though the address it returns (**435 North Michigan Avenue**)
  is the building's own. The **forward** geocode returns **`Tribune Tower`, way 150407241, at 0.0 m**
  from the pin (`wikidata=Q2143136`, `architect=Howells & Hood`), so the pins sit on OSM's own building
  centroid. *Fetch the other direction; don't argue with the reverse.*

## 🔴 The Cube House is slated for demolition, and only checking caught it

The `@vonwong` caption mentions giving the building *"a second life as a public artwork made from its
reclaimed materials"* — a demolition notice in disguise. Verified: **Block Developments bought the
cubes with six neighbouring properties in late 2023 for $19.12M**, has said they cannot be safely
kept, and has filed to take them down; **Benjamin Von Wong** is working with the developer to rebuild
the reclaimed material as a public artwork.

**The description is written to stay true either way** — it states the permit and the reuse project
and asserts **no demolition date** and **no claim that the building still stands**.

⚠️ Its heritage status is **`listed`, not designated** — the Ontario distinction that records a
building without protecting it, which is exactly why this can proceed. Worth knowing before writing
"protected" about any Toronto building.

**The durable rule, one level up from Tung Po / Papaya King:** a reverse-geocode confirms a coordinate
sits on a building of that name. It cannot tell you the business left — and it cannot tell you the
building is coming down.

## ⚠️ Sources disagree on who designed the Cube House, so neither reading is asserted

**ACO Toronto** credits *Piet Blom as architect, Ben Kutner as designer*; **blogTO** credits *Kutner as
architect, inspired by Blom*. The copy says Kutner built them in 1996 with his partner **Jeff Brown**,
taking the form directly from Blom's cube houses in **Rotterdam and Helmond** — **true under both
readings** (the Grove at Grand Bay rule).

Uncontested and shipped: **1996 · three cubes · an affordable-housing idea for the leftover scraps of
land a city cannot otherwise build on · part of a planned community called UniTri that never happened.**

## ⚠️ Every Tribune Tower figure verified; one deliberately approximate

**463 ft to the roof across 36 floors, finished 1925, John Mead Howells and Raymond Hood**, from the
Tribune's **1922** seventy-fifth-anniversary competition, which drew **more than 260 entries**. The
crown is modelled on the **Butter Tower at Rouen**, and **Eliel Saarinen's second-place design was the
more influential building**. **Chicago Landmark 1 February 1989**; contributing building in the
**Michigan–Wacker Historic District**; the newspaper left in **June 2018** after ninety-three years and
the tower is now residences.

⚠️ **The embedded-fragment count ships as "roughly 150"** — the source cites *"all 149 rocks"* without
a definitive total in its own text, and the creator's caption says *"nearly 150"*. No precise figure is
asserted.

## ⚠️ Both heroes are borrowed, and that is structural

Every member of both places is a **link pin with an empty gallery**, and neither site has an Atlas tour
with photographs to lend (Tribune Tower's is 142 m away and not a member), so **no third photograph of
either site exists in the catalogue** — the Waterlooplein / Legion of Honor case the owner has closed.
**Do not go sourcing replacements.** The build asserts the hero **is** one of the members' rather than
an invention. Borrowed-hero count **re-derived: 26 of 97** (66 third photographs, 5 none).

**All four candidates were rendered and looked at, not chosen by filename.**

- **Cube House → `@toronto_papi_`'s exterior**: the tilted green cubes against blue sky, naming itself
  in frame (`Cube House / 1 Sumach St / Toronto`). ⚠️ The `@vonwong` alternative is **the creator
  sitting in a skylight with the interior barely readable** — flagged as weak in #698, confirmed here.
- **Tribune Tower → `@about_buildings`'s full elevation**: the whole Gothic tower with its buttressed
  crown and **`Chicago Tribune` legible at the base**. ⚠️ **The `@kayleejochicago` alternative is
  genuinely beautiful and was rejected on the establishing-shot criterion** — a close-up of the carved
  entrance screen with **`TRIBUNE TOWER 435` legible on both doors**, which is what independently
  confirms the address. **One line swaps it.**

## ⚠️ Each place shares a name with a member, unavoidably

`@about_buildings`' pin is titled exactly `Tribune Tower`; `@toronto_papi_`'s exactly `Cube House`.
Both buildings have exactly one name, so the alternative is inventing one — the same call as One Times
Square, The Tin Building and Eastern State Penitentiary. **Do not "fix" it.**

## Verification

- Place ids `uuid5(NAMESPACE_URL, "atlas-place:<city-slug>:<name-slug>")` — `a7c90ef2-…` (Cube House),
  `b64f5b2a-…` (Tribune Tower). **0 collisions.**
- Validator mirror — vocabulary parsed from **both** `Models/Tag.swift` and the Swift validator plus the
  enum domains, refusing to run on disagreement or an empty parse — **self-tested 47/47**, then
  **0 errors, 2 warnings** across 1,552 tours + 740 pins + 97 places, **both pre-existing**.
- ⚠️ **26 place-layer faults injected against the TWO new places specifically — 26/26 caught, control
  clean.** Per place: one member; empty name; either member nudged 55 m; the place's own latitude and
  longitude drifting off its members; a bad hero URL; an unknown tour id; a duplicate place id; a
  member claimed by two places; the hero repeated in its own gallery; an out-of-range latitude; and
  both members set to the same tour.
- 🎉 **`check-place-candidates.py` reaches 0 EXACT and exits 0**, against `main`'s **2 / 36**, with
  **NEAR unchanged at 36** — it falls by exactly the two groups resolved and gains nothing, so **no
  coincident group was manufactured**. ⚠️ Exit code read **directly, not through a pipe**.
- Structural sweep: **all members of all 97 places exactly on their place**, 0 tours claimed twice,
  0 duplicate place/tour/stop ids, **0 link pins inside `tours`**, 0 `images//`.
- `seed_from_toursjson.py` clean at **262 / 2,292 / 2,664 / 97**, carrying the places, so this reaches
  Supabase on merge with **no owner SQL**.
- `Tours.json` **byte-stable under a Python re-dump before editing** (the assembler asserts it and
  refuses otherwise); diff **30 insertions / 0 deletions**, `makers`/`tours`/`linkPins` asserted
  byte-identical and the 95 existing places asserted unchanged as a prefix. Both heroes live **200**.
- ⚠️ **Nothing compiled locally** (no Swift toolchain in a Linux web session) — **CI is the
  authoritative validator.**

## ✅ The place backlog is empty again

Every coincident group in the catalogue now has a place page. **A clean exit from
`check-place-candidates.py` is the expected state — treat any future EXACT group as a real finding.**

## Open

- Nothing owed from this session. The five weak heroes flagged in #689 remain a standing keep-or-pull
  question for the owner, unchanged.
