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
— but the Channel Gardens cut against it. **There is no settled rule here. Put
these to the owner individually and do not infer one.**

---

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
