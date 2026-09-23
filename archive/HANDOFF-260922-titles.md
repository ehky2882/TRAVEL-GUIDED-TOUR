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

## Part 3 (overnight 2026-09-23): an OSM name sweep of the pins no gazetteer knew

The owner went to bed and asked for meaningful overnight work. The target was the 2,906 entries the
spine (Wikidata) cannot match. **2,175** of them are link pins with a title that could name a
venue, and each was looked up **by name on OpenStreetMap**.

| | |
|---|---|
| **CONFIRM** (a same-name OSM feature of a POI type within 60 m) | **557**. These are now independently checked for the first time |
| no usable OSM match | 1,557 (editorial titles like *"The House of Death on West 10th Street"*, and venues OSM lacks) |
| **moved** | **8**: Southwark Tavern 1,378 m (pinned near Waterloo; the caption says Borough), Café De Klos 1,305 m, Ernst Fuchs Museum 1,140 m (Otto Wagner villa, Hüttelbergstraße), Whiskers Smokehouse 370 m, The Twist (Kistefos) 263 m, Gordon Nicolson Kiltmakers 224 m (the caption's own address), Bust of Sylvette 202 m, The Anchor (Charlestown) 110 m |
| left alone, recorded for a human | 61: chains with several same-name branches, loose names, place members, and >1 km gaps where the caption names **our** branch (Little Bao *in Central*, Henry's Burger *in Jiyugaoka*, Horatio's *new space in Soho*) |

**The move rule:** the OSM name is exactly the title's (or the Latin half of a bilingual name
matches), the feature is of a POI type, it is the only same-name hit, the pin is not in a place,
and the gap is 100 m–1 km. Anything over 1 km was read by hand first. Loose containment matching was
tried and **rejected for moves**: it paired *Saint Mary's Cathedral* with *Old* Saint Mary's (a
different church) and *The Chelsea Hotel* with *The GEM Hotel Chelsea*. It is kept only for
confirming a pin already within 60 m.

**The REVIEW band, again:** 218 unruled rows were re-asked on Photon. Where **OSM and Wikidata
agree with each other within 75 m and both disagree with us**, 3 link pins moved: Café Goldegg
124 m, Auditorium Oscar Niemeyer (Ravello) 230 m, Brasília Palace Hotel 143 m. **12 Atlas tours met
the same test and were NOT moved**, because an Atlas stop is a geofence trigger and may be a
chosen viewpoint. They are for the owner: Estádio do Dragão 185 m, Jardins do Palácio de Cristal
177 m, Nubank Parque 179 m, Castelo de São Jorge 163 m, Jardim da Estrela 149 m, Chichu Art
Museum 241 m (OSM's point is the ticket office), Palais-Royal 156 m, Dolby Theatre 113 m, Gaysorn
Amarin 150 m, Candler Building 141 m, and AMNH (a place member).

**The record:** `checks/osm-name-sweep-260923.json`, with every CONFIRM (the pin's point and OSM's)
and the 61 left-alone rows. No check reads it; it exists so the sweep is not redone blind.

⚠️ **Nominatim banned the session after ~800 queries** (HTTP 429 on everything, even at one
request per 2 s). The sweep moved to **Photon** (`photon.komoot.io`, the same OSM data, no key),
which served the remaining ~1,500 at 1.5 s spacing without a single refusal.

## Part 4 (2026-09-23 morning): the owner's rulings on the overnight questions

**"MOVE THE ATLAS TOURS … as the catalog evolved I think [a deliberate spot to stand] would be
increasingly difficult to manage for a large catalog."** This is a durable rule change, now in
CLAUDE.md rule 8c and `docs/lessons.md`: **an Atlas stop sits on its subject, like a pin.**

- **9 moved** onto an OSM feature of the right type that Wikidata agrees with (within 75 m): Estádio
  do Dragão 185 m, Nubank Parque 179 m, Jardins do Palácio de Cristal 177 m, Castelo de São Jorge
  163 m, Palais-Royal 156 m, Gaysorn Amarin 150 m, Jardim da Estrela 149 m, Candler Building
  141 m, Dolby Theatre 113 m. The Hollywood Boulevard walk's *Dolby Theatre* stop shared the old
  point and moved with it.
- **Chichu Art Museum was NOT moved, and the evidence overturned the premise.** OSM's
  `tourism=museum` outline for 地中美術館 is **17 m from our stop**. The OSM point that "agreed
  with Wikidata" was the **ticket centre** at the foot of the hill, so Wikidata is the one pointing
  at the wrong building. Recorded as a spine verdict (`wikidata-elsewhere`).
- **American Museum of Natural History was NOT moved.** Its point is on the Central Park West
  frontage, and it is also stop 0 of the *Four Facades* walk, whose subject is that facade.
  Moving it to the centroid of a four-block building would pull the walk's first facade into the
  middle of the block. It stays as a walk-stop exception to the new rule.

**"RENAME THE 10":** Porchester Spa, Wilton's Music Hall, Michelin House, Le Beaujolais, Edith
Macefield's House, James Gordon Bennett Monument, William H. Seward Monument, Unité d'Habitation,
Mont Sainte-Odile and Café Konditorei Fürst, each with its stop title set the same.

**For the owner, from another session's #1075 (@preetigills, 55 Paris pins):** three same-name
pairs, each within 21 m. Le Relais de Venise (two pins, 0 m), Café de la Paix (two pins, 20 m), and
Musée Carnavalet (the Atlas tour and a pin, 21 m).

## Part 5: the #1075 place pairs

Edward: *"make all three places. WHY WEREN'T THESE FLAGGED AT THE TIME OF UPLOAD (PRESUMABLY MY
BROTHER UPLOADED)"*. **They were flagged.** #1075 (opened and merged by @arthuryung-gif) ran
`check-place-candidates`, which found all three, and its session asked the contributor, who said
"keep separate". It was recorded as the owner's ruling. Fixed by routing: `.claude/skills/atlas-upload/SKILL.md`
step 6 now requires `status.py --add-owner` for every place question in a contributor's session,
plus a "For Edward" section in the PR body. Places made: **Le Relais de Venise** (both pins
already on OSM's restaurant, 271 Bd Pereire), **Café de la Paix** (OSM restaurant, one pin moved
20 m), **Musée Carnavalet** (OSM museum, the Atlas tour moved 21 m under the new stops-on-subject
rule). Places **435 → 438**.

## Part 6: 1.1.3 released

Edward: *"1.1.3 IS NOW RELEASED - UPDATE THE DOCS"* (2026-09-23). Build 176, phased release over 7
days, so the public `itunes.apple.com/lookup` still read **1.1.2** that afternoon. Updated:
CLAUDE.md § Current state and § Egress (delta fetching is now live for updated phones; egress falls
with adoption; a catalogue-wide rewrite now costs each updated phone more than a full fetch),
`docs/scaling-to-100k-design.md`, ROADMAP, and the owner item `release-1-1-3-when-approved` is
cleared. **Still owed:** `MARKETING_VERSION` 1.1.3 → 1.1.4, opened as its own PR because
`project.pbxproj` waits for the owner's OK.

## Part 7: every Atlas stop checked against OSM under the new rule

Edward: *"START 2 NEXT"*, then *"merge 1078"* (MARKETING_VERSION is now **1.1.4**, #1078).

All **1,954** Atlas tour stops were looked up by name on Photon (OSM). **503 confirmed** within 50 m.
**52 moved** (50–130 m each) where OSM and Wikidata agree with each other (within 75 m) and both
disagree with our stop: Brooklyn Museum 129 m, Ny Carlsberg Glyptotek 109 m, Jay Pritzker Pavilion,
Designmuseum Danmark, Buckingham Palace 99 m, Fondazione Prada, Capitol Records, La Brea Tar Pits,
Sydney Opera House, Musée Rodin, Radio City and more. **5 walk stops** sitting on the same old
point under the same name moved with them (Capitol Records on the Hollywood walk, plus stops in Old
Montreal, the Scheunenviertel, Chicago's Lakefront and the Dreta de l'Eixample).

**Deliberately NOT moved:** large parks and districts (Retiro, Luxembourg, Champ de Mars, Porto's
botanic garden, De Wallen), where an OSM point is just the middle of an area; chains with several
same-name branches; place members; the Four Facades walk; and two big gaps that were a different
branch (Piccolina Gelateria) or an extended waterfront (the Dhow Wharfage). Record:
`checks/osm-atlas-stops-260923.json`. Spine DISAGREES stays 0; cache refreshed.

## Part 8: 28 near-miss rows ruled with OSM evidence

Of the spine's REVIEW band (100 m–1 km from Wikidata), **27 rows had OSM's same-name point of
interest within 31 m of our pin**, which settles them: the pin is on the subject and Wikidata's
point is elsewhere, often a different entity (*The Blackfriar* pub vs *Blackfriars Settlement*,
*Rudolph Hall* vs a campus point). Recorded as `wikidata-elsewhere` verdicts, each stamped at the
pin's current point. *First National Bank of Hollywood*'s old verdict was stamped at its
pre-place point and no longer applied, so it was re-stamped. *Ancient Messene* was **not** ruled:
OSM's match was a café of that name, not the archaeological site. REVIEW unexamined **163 → 137**.
The remainder are large sites (parks, zoos, a racecourse, campuses, castles).
