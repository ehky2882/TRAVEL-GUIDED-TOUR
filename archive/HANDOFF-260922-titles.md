# Handoff 2026-09-22 — "are we really done with existing content?" (no), and 269 pins get their names back

**Session:** SCALE PINNED TOURS (web). Branch `claude/scale-pinned-tours-automation-dba3lx`.

## Why this happened

The owner asked whether existing content was really done. It was not: "done" had covered the
place tools only. A full re-run of every content audit on `main` gave the honest backlog, and
reading it surfaced a gap missing from the list entirely: **355 entries titled with a creator's
caption** (`"Here's another @michelinguide spot you have to try! This…"`). A caption title cannot
be geocoded, matched against a gazetteer, or asked of a picture, so every coordinate check was
blind on those pins.

## What changed (one PR)

| | |
|---|---|
| **269 pin titles** recovered from the caption itself | 4 parallel readers, each told to name only what the caption names: prose, `📍`, `Shop:`, or an unambiguous venue @handle. No names from an address, a coordinate or a vague description. Each proposal carries the verbatim evidence. **Caption titles 355 → 89**; the rest name nothing and were left alone |
| **The recovered names were checked against the places the pins already belonged to** | Every renamed pin that sat in a place got a name matching that place (e.g. Kossar's, Soothr, Centre Pompidou, Stedelijk). That caught 3 spellings: *Oedo* Antique Market (the caption misspelled it), *Mark's Off Madison*, and the place **Papa Da Mour → Papa d'Amour** |
| **331 stop titles synced** | A link pin's single stop carries its own `title`. The rename left all 269 stops on the old caption, and **62 older mismatches** were already sitting there: pins corrected in earlier sessions whose stops still said *Crown Sydney*, *Vittoriano*, *MSG Sphere*, *Bosco Verticale* and *Grace Farms*, which are the wrong names those fixes removed. 5 deliberate differences kept (Glasshouse Theatre ×2, the Crooked House, Lincoln Heights Jail, Westminster) |
| **8 place descriptions** | Intempo, National Stadium Beijing, Fraunces Tavern, Casa de Serralves, The Marquis, Ye Olde Cheshire Cheese, The Warrington, Concrete Matter. The Marquis and Concrete Matter were confirmed on OSM (Chandos Place; Gasthuismolensteeg) before being written |
| **9 coordinates corrected** (8 venues) | From the REVIEW band, where OSM **and** Wikidata agreed with each other against us: The Spiral 248 m, Bathtub Gin 240 m, Hundertwasserhaus 229 m, Chicago Board of Trade 180 m, American Radiator Building 171 m, Markiezenhof 154 m, **The Warrington (place + 2 pins) 153 m**, Hotel Jalta 151 m. Each target is an OSM feature of the right kind carrying the venue's name, and most of the old points were 4-decimal hand-typed approximations |
| **3 spine verdicts** | Futaba soba and St. Anselm (DC) are name-collisions; Jack Shainman Gallery's Tribeca space vs Wikidata's Chelsea point. All three NOT MOVED |
| **Spine cache refreshed** | 279 lookups re-asked (270 renames + 9 moves). Without this CI reports STALE and exits 2 |

**Measured effect:** spine CONFIRMS 1,861 → **1,923**; UNMATCHED 2,974 → **2,906**; DISAGREES 0 → 1
(Petit Palais, left open for the owner on purpose, below).

## The trap worth remembering

Nominatim's first hit for "The Warrington, Warrington Crescent" was a **building named The
Warrington**, near the Alan Turing plaque at no. 2. Moving the pin there would have looked
verified. Searching the pub's **address**, 93 Warrington Crescent, found `amenity/pub
"Warrington"` **150 m in the other direction**, where Wikidata also puts it. Rule 8d in practice:
check the feature's *type*, not just its name. → `docs/lessons.md`.

## Audits that came back clean (nothing to change)

- **City outliers, 79:** all are sights that really are far out (airports, Lantau, Cape Point,
  Chicago's South Side). Two Bronx entries checked by hand: the Grand Central stones are in Van
  Cortlandt Park, and the old PS 15 is the rural schoolhouse on Dyre Avenue.
- **Same-name, 5:** already triaged in `check-same-name.py`'s docstring (a stream, two chains), plus
  two caption-title groups, now gone.
- **Places without a hero, 265:** by design, since a place page falls back to its top member's
  photo (`docs/lessons.md` § 3). Not a gap. I listed it as one earlier; that was wrong.

## Still open — for the owner

1. **Place candidates (rule 8c), all created by the renames:**
   - Notre-Dame de Paris: a pin and the Atlas tour, 106 m apart
   - Niku X: two pins, 173 m apart (one may be off; Nominatim was rate-limited)
   - Yorkshire Sculpture Park: two pins, 194 m apart (the Turrell skyspace vs the park; part-vs-whole)
   - Krispy Pizza: two pins, 64 m apart
2. **Petit Palais:** the museum pin `0F278313` is in the owner's place *Pont Alexandre III & Petit
   Palais*, whose point is on the bridge, 259 m from the palace, and another *Petit Palais* pin
   sits on the building outside any place. Left unruled so it stays visible.
3. **REVIEW band, 175:** most are big sites. Atlas-tour rows (Capitol Records 97 m, Dolby 113 m,
   Hurt 95 m, Muscle Beach, Gaysorn) were **not moved**, because an Atlas stop is a geofence
   trigger and may be a deliberate viewpoint. The Court of Final Appeal row is OSM and Wikidata
   being stale: the court moved to the old Supreme Court building on Statue Square in 2015, which
   is where the pin is. 40 rows hit Nominatim 429s and are unchecked.
4. **UNMATCHED, 2,906:** unverifiable by the spine. The remaining route is looking each venue up
   by name (rule 8d), city by city.

## Part 2 (2026-09-23): the owner's rulings on the open questions

*"make all four places"* and *"petit palais - make a place at the building"*, and the
@lucymcorban pin in the Pont Alexandre III place *"should instead be in the petit palais place"*.

| Place | Point | Source | Moves |
|---|---|---|---|
| Notre-Dame de Paris | the Atlas tour's own stop, on the parvis | the tour (not moved, since it is the geofence trigger) | the pin, 106 m |
| Krispy Pizza (Brooklyn) | 7112 13th Avenue | OSM `amenity/restaurant`, on which one pin already sat | the other pin, 64 m. ⚠️ One pin's city was changed New York → Brooklyn and **reverted**: 63 New York pins name it in `relatedTourIds`, and a pin takes same-city suggestions only, so the validator failed. Change a city only together with a related-tours rebuild |
| Niku X | Wilshire Grand Center, 900 Wilshire Blvd, 2nd floor | the venue's listed address (Apple Maps point) | 39 m and 136 m |
| Yorkshire Sculpture Park | the main visitor entrance | OSM `tourism/attraction` | 354 m and 248 m. ⚠️ The Turrell pin was on the Deer Shelter Skyspace itself, so the place point trades that precision for one honest point for the park |
| **Petit Palais** | the museum | OSM `tourism/museum` | @lucymcorban's pin 283 m (off the bridge), @suzyandaustin's 54 m |

**`Pont Alexandre III & Petit Palais` is dissolved**, because moving the pin out left only the Atlas
tour, and one entry is not a place. The Atlas tour itself is untouched. The Supabase seed prunes
dissolved places since the Westerkerk leak (`docs/lessons.md`), so no SQL is owed; confirm with
the 47-byte place count after the publish.

Places **431 → 435**. Spine DISAGREES **0 unexamined** again; no unplaced same-name pairs are left.
