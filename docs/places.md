# What qualifies as a place page

A **place** is a site that more than one catalogue entry describes: the site
becomes the thing on the map, and the entries become its contents.

These rules were settled by the owner across ~60 decisions on 2026-09-11
(`archive/HANDOFF-260911-3.md`). Read this before offering place candidates.

---

## 🔴 Rule 0 — TWO entries qualify. Do not wait for a third.

**Owner, 2026-09-11: *"2 tours at a location already qualifies for a place page.
Don't wait for 3 to ask me."*** Said twice: it also opened the sweep, as *"even
2 tours at a location is a candidate."*

Nothing in the tooling ever disagreed — `check-place-candidates.py` groups at
`len(members) >= 2`, and `validate-tours` **errors** on a place with fewer than
two. **73% of all places have exactly two members**, so two is not a marginal
case, it is the normal one.

⚠️ **The failure mode is presentational, not mechanical.** Candidates get ranked
by member count in conversation — *"four entries, the strongest on the page"* —
and two-entry pairs get softened into *"judgement calls"*. That reads as holding
out for a third. **A pair is a full candidate. Put it up plainly.**

---

## Rule 1 — Two names for one thing is always a place

`Man Mo Temple` / `Man Mo Temple | 文武廟`. `Kubuswoningen` / `The Cube Houses of
Rotterdam`. `Lloyd's Building` / `Lloyd's of London`. `Port Authority Bus
Terminal` / `The Port Authority Bus Terminal`.

**Never once declined.** If two entries name the same thing, they are one place.

## Rule 2 — An angle on a site is not a different site

`The 20,000 Skeletons Under Washington Square Park` → Washington Square Park.
`Abbey Road: The Conspiracy Theories` → Abbey Road. `Building Marina City` →
Marina City. `How the Leaning Tower of Niles Was Built` → the tower.

Editorial framing — a story, a question, a construction history — never creates
a new place.

## 🔴 Rule 3 — Co-location is not identity

Adjacent things stay separate **even when they touch**:

- `Casa Amatller` / `Casa Batlló` — owner: *"two separate houses side by side on
  the Illa de la Discòrdia — the point of that block"*
- `ArkDes` / `Moderna Museet` — **the same building**, two institutions
- `Lloyd's of London` / `The Leadenhall Building`, `LACMA` / `Academy Museum`,
  `The Red Room at One Wall Street` / `Wall Street`

Proximity is what the sweep measures; it is **not** what makes a place. This is
the rule a distance-only tier can never express, which is why the tight tier
produces real false positives.

## Rule 4 — A tenant is not the site

`Madame Fu` inside Tai Kwun — owner: *"a restaurant inside a heritage compound is
not the compound."* Also `Il Presidente`, `Bar Luce at Fondazione Prada`,
`Bakehouse at Victoria Peak`.

A business that occupies a site is not the site.

## ⚠️ Rule 5 — A place is a COORDINATE, so one point must be honest for everyone

Creating a place **moves every member onto a single point**. A candidate only
qualifies if one point is truthful for all of them.

- **The Barbican** — forty acres, so *neither* member sat on an OSM feature.
  That is not a defect; it is information about the **site**. Anchored on the
  estate polygon.
- **Gamla stan** — anchored on its walk, because `marker()` is the stop at
  order 0 and moving a walk relocates **where it begins**.
- **Westminster Abbey's** sub-features — declined because a second place 17 m
  away would have **duplicated** the existing one.

**If you cannot name the single point, it is not a place — it is an area with
entries in it.**

---

## ⚠️ Genuinely undecided: part vs. whole

`The Glass Hall at Tokyo International Forum` became a place with the Forum.
`Big Ben` / `Houses of Parliament`, `Bar Luce` / `Fondazione Prada` and
`The Channel Gardens` / Rockefeller Center did not.

A plausible line is *"the part that IS the draw"* versus *"a nameable component"*
— but the Channel Gardens cut against it.

### ⚠️ 2026-09-14: four decided one way — but still a JUDGEMENT CALL

🔴 **The owner was explicit that this is NOT a settled rule.** Asked to choose on
four such pairs at once they said *"DO ALL OF #2 ALSO"*, and then, immediately
after: **"I THINK THE PART AND WHOLE IS A JUDGEMENT CALL. I WOULD LEAVE THE 3
FROM MY BATCH."** So four went one way and three identical-looking cases were
deliberately left alone in the same breath. **Do not infer a rule from the four.
Keep putting these to the owner individually.**

The three left alone, for the record: Keith Haring's Carmine Street Mural vs the
Tony Dapolito Recreation Center; The Blue Ribbon Garden vs Walt Disney Concert
Hall; Hoyt–Schermerhorn Streets Station vs a pin about the street's name.

What the four that *were* made have in common — a component with no independent
identity, inside a site whose name everybody already knows — may be the shape of
it, but the owner has not said so and the three above are not obviously different:

| Place | The "part" that joined it |
|---|---|
| **One Vanderbilt** | Summit One Vanderbilt — the observation deck inside the tower |
| **Canterbury Cathedral** | The Shrine of Thomas Becket |
| **Kulturpalast Dresden** | its mural, *Der Weg der roten Fahne* |
| **Strahov Library** | the Philosophical Hall, its fresco, the Forbidden Books, the Theological Hall |

**When one IS made, name it for the whole, not the component** — `One
Vanderbilt`, not `Summit`. That part is consistent across all four.

🔴 **This does NOT overturn Rules 3 and 4, which remain the harder constraint.**
A part is *inside* the whole; the rules below are about things merely *beside*
each other:

- **Rule 3 (co-location is not identity)** still stands. `MOCA Grand Avenue`
  was declined against the Blue Ribbon Garden 20 m away — a different
  institution is not a component.
- **Rule 4 (a tenant is not the site)** still stands, and it decided the fifth
  Strahov entry: the **Strahov Monastery Brewery** shares the library's exact
  coordinate and was **left out**. A brewery is not a component of a library.
  Had the place been named *Strahov Monastery* the answer might differ — which
  is why the **name you choose decides the membership**, and is worth choosing
  before minting.

⚠️ The earlier precedents this section lists (`Big Ben` / `Houses of
Parliament`, `Bar Luce` / `Fondazione Prada`, `The Channel Gardens`) were
declined earlier and were not revisited. Given the owner's "judgement call"
framing they are **not** in conflict with the four above — they are simply other
judgements. Leave them.

---

### 2026-09-15: Westminster Abbey — the owner's REASON, which is new

Two pins, **The Coronation Chair** and **The Tomb of Elizabeth I**, are deliberately **NOT** members
of the Westminster Abbey place. In the owner's words:

> *"i kept [them] outside of the 'place page' because they were specific to things inside the
> church and i didnt want it to be comingled with things dealing with the more general building"*

🔴 **This is the first time the reason has been stated, and it is not the same as the 2026-09-14
judgement calls above.** Those were about whether a component is "the draw". This one is about
**what a place page is FOR**: a page whose members are all about the building itself reads
differently from one that mixes the building with its furniture. Comingling is the cost the owner
is avoiding, not similarity.

⚠️ **The consequence for coordinates, which is the part that bites.** Wikidata has items for both
(`Q1751063`, `Q113709229`) and **neither carries a coordinate** — both say only *"located in:
Westminster Abbey"*. So the only precise point available is the Abbey's own. **Putting them there
would undo the decision in the only place a user can see it:** they would sit on the identical map
dot as the Abbey and start surfacing as EXACT candidates in `check-place-candidates.py`.
Mechanically separate, visibly comingled.

**So both pins keep their current, deliberately imprecise coordinates** (`51.49943,-0.128` and
`51.49908,-0.127`), which already sit inside the Abbey footprint. **Imprecise-and-distinct beats
precise-and-merged here.** Do not "fix" them.

⚠️ Note that the pattern IS supported where the data exists — **Poets' Corner has its own Wikidata
coordinate**, separate from the Abbey. If either of these two ever gains one, a precise interior
point is the right answer and still requires no place membership.

### 2026-09-15: East Side Gallery — a site with no single honest point

`Two Sides of the Berlin Wall` stays at `52.505, 13.4394`, and the place stays with it.

The owner supplied the Google Maps address, **Mühlenstraße, 10243 Berlin** — which is a *street*,
because the Gallery is a 1.3 km wall beside it and has no building number. Geocoding it returns
**three results spread ~800 m apart** (`52.5029,13.4460` · `52.5073,13.4364` · `52.5062,13.4385`),
and the pin already sits among them, nearer mid-Gallery than any one of them. Wikidata's own point
(`52.5031,13.4447`) is a fourth candidate at the eastern end, 420 m away and no better justified.

**The subject is the whole wall** — the video contrasts the painted east face with the plain west
one — so a mid-Gallery point is the honest answer. Rule 5 says a place is a coordinate and one
point must be honest for everyone; here that point is deliberately the middle, not an endpoint.

## 🔴 Before deciding anything: check the coordinate

`Lloyd's of London` / `The Leadenhall Building` sat 7 m apart and looked like a
textbook two-buildings-across-a-street false positive. It was recommended for
decline. **It was a broken coordinate** — the Lloyd's tour was parked on the
Leadenhall Building, 93 m from Lloyd's.

⚠️ **A wrong coordinate and a genuine neighbour are indistinguishable from the
titles and the distance.** Declining one buries the bug where nothing will look
again. **Check which member OSM agrees with, then decide.**

That check found **nine wrong coordinates** in a single day. The signature is a
**4-decimal coordinate on a tour**: pins are geocoded per link at import, while
tours carry coordinates typed once and never verified. In the 26–49 m band,
**fifteen of seventeen groups had the pin right and the tour wrong.**
