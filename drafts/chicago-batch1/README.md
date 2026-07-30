# 🇺🇸 Chicago — batch 1 master pick-map

**Status: image staging COMPLETE for all 25 staged tours — awaiting narration MP3s.**
New maker **Atlas Studio ORD** 🇺🇸 — the 21st maker. Maker id (uuid5 of `atlas-maker:ord`): `f34cd76e-1e41-5c38-865d-d8eccd775cd3`.

Single source of truth for slug ↔ coordinate ↔ category ↔ hero/gallery. Scripts sit beside this file: `NN_<slug>.txt` is the narration that becomes `transcriptText`; `NN_<slug>_TTS.txt` is the voice-direction variant and is **not** the transcript.

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/` · **audio slug = the `slug` column** (`audio/<slug>.mp3`) · **84 images, coverage audited — every hero present, every gallery contiguous from `_2`.**

## Tours

| # | Tour | slug | script | category | coord | img | tags | credit |
|---|------|------|--------|----------|-------|-----|------|--------|
| 01 | Cloud Gate (The Bean) | `cloud-gate` | `01_cloud_gate` | `visualArt` | `41.88265, -87.62325` | 4 | Monument, Art, Contemporary, Iconic Landmark, Public Art, Free to Visit | — |
| 02 | The Chicago Riverwalk at DuSable Bridge | `dusable-bridge-riverwalk` | `02_dusable_bridge_riverwalk` | `history` | `41.88870, -87.62450` | 4 | Bridge, Engineering, History, Free to Visit | — |
| 03 | The Art Institute | `art-institute` | `03_art_institute` | `culturalHeritage` | `41.87965, -87.62375` | 3 | Museum, Art, Beaux-Arts, Iconic Landmark, Renzo Piano | — (`_3` owner) |
| 04 | Willis Tower | `willis-tower` | `04_willis_tower` | `architecture` | `41.87860, -87.63760` | 4 | Tower, Architecture, Modernist, Iconic Landmark | — |
| 05 | The Historic Water Tower | `historic-water-tower` | `05_historic_water_tower` | `history` | `41.89725, -87.62445` | 3 | Monument, History, Victorian, Free to Visit | **`_2`,`_3` CC** |
| 06 | The Wrigley Building & Tribune Tower | `wrigley-tribune` | `06_wrigley_tribune` | `architecture` | `41.88960, -87.62430` | 3 | Notable Building, Architecture, Gothic, Iconic Landmark | — |
| 07 | Buckingham Fountain | `buckingham-fountain` | `07_buckingham_fountain` | `culturalHeritage` | `41.87575, -87.61885` | 4 | Monument, Art, Beaux-Arts, Free to Visit, After Dark | — |
| 08 | Marina City | `marina-city` | `08_marina_city` | `architecture` | `41.88760, -87.63430` | 5 | Notable Building, Architecture, Modernist, Engineering | — |
| 09 | The Rookery | `the-rookery` | `09_the_rookery` | `architecture` | `41.87910, -87.63220` | 5 | Notable Building, Architecture, Frank Lloyd Wright, Hidden Gem | **`_2`–`_5` CC** (hero owner) |
| 10 | Jay Pritzker Pavilion | `pritzker-pavilion` | `10_pritzker_pavilion` | `musicAndPerformance` | `41.88250, -87.62060` | 2 | Venue, Performance, Contemporary, Frank Gehry, Free to Visit | — |
| 11 | Navy Pier | `navy-pier` | `11_navy_pier` | `culturalHeritage` | `41.89180, -87.60950` | 5 | Waterfront, Maritime, Free to Visit | — |
| 12 | The Michigan Avenue Streetwall | `michigan-avenue-streetwall` | `12_michigan_avenue_streetwall` | `architecture` | `41.88090, -87.62410` | 4 | District, Architecture, Free to Visit | — |
| 13 | The Chicago Cultural Center | `cultural-center` | `13_cultural_center` | `culturalHeritage` | `41.88395, -87.62475` | 3 | Library, History, Beaux-Arts, Free to Visit | — |
| 14 | Daley Plaza & the Picasso | `daley-plaza-picasso` | `14_daley_plaza_picasso` | `visualArt` | `41.88400, -87.63020` | 2 | Public Square, Art, Modernist, Public Art, Free to Visit | **both CC** ⚖️ |
| 15 | The Monadnock Building | `monadnock-building` | `15_monadnock_building` | `architecture` | `41.87830, -87.62960` | 2 | Notable Building, Architecture, Engineering | — (`_2` owner) |
| 16 | LaSalle Canyon & the Board of Trade | `lasalle-board-of-trade` | `16_lasalle_canyon_board_of_trade` | `architecture` | `41.87990, -87.63220` | 4 | Notable Building, Architecture, Art Deco, Commerce | — |
| 17 | Merchandise Mart | `merchandise-mart` | `17_merchandise_mart` | `architecture` | `41.88760, -87.63450` | 3 | Notable Building, Architecture, Art Deco, Commerce | — |
| 20 | North Avenue Beach | `north-avenue-beach` | `20_north_avenue_beach` | `natureAndParks` | `41.91180, -87.62650` | 2 | Waterfront, Engineering, Art Deco, Free to Visit | — (both owner) |
| 21 | Old Town & St Michael's | `old-town-st-michaels` | `21_old_town_st_michaels` | `history` | `41.91530, -87.64180` | 5 | Religious Building, History, Free to Visit | **`_2`–`_5` CC**; hero PD |
| 23 | Museum Campus | `museum-campus` | `23_museum_campus` | `culturalHeritage` | `41.86600, -87.60600` | 5 | Museum, History, Neoclassical, Viewpoint, Free to Visit | — |
| 24 | Chinatown & Ping Tom | `chinatown-ping-tom` | `24_chinatown_ping_tom` | `culturalHeritage` | `41.85200, -87.63200` | 2 | District, Immigration, Commerce, Free to Visit | **both CC** |
| 25 | Pilsen & 18th Street | `pilsen-18th-street` | `25_pilsen_18th_street` | `culturalHeritage` | `41.85750, -87.65530` | 2 | District, Immigration, Art, Free to Visit | — (both owner) |
| 28 | Robie House | `robie-house` | `28_robie_house` | `architecture` | `41.78010, -87.59600` | 3 | Notable Building, Architecture, Modernist, Frank Lloyd Wright | **all 3 CC** |
| 29 | Griffin Museum of Science and Industry | `museum-science-industry` | `29_msi_palace_fine_arts` | `culturalHeritage` | `41.79155, -87.58330` | 3 | Museum, History, Beaux-Arts, Iconic Landmark | — |
| 30 | Obama Presidential Center | `obama-center` | `30_obama_center_jackson_park` | `architecture` | `41.78630, -87.58900` | 2 | Notable Building, Architecture, Contemporary, History | — (both owner) |

## ⚠️ The script numbering is NOT contiguous

**25 tours, numbered 01–17, 20, 21, 23, 24, 25, 28, 29, 30. Numbers 18, 19, 22, 26 and 27 were never delivered.** Recorded so no wire-in session assumes a gap means a lost file.

This is the failure that hit Rome: the staging session was handed 01–24 while the scriptwriting sessions had produced through 31, and the mismatch only surfaced after launch. **If those five exist, they are a second batch; if they were never written, this list is complete.**

## ⚠️ transcriptText — two header formats, two beat spellings

Every script opens with a header block terminated by a `---` rule. **`transcriptText` starts after the rule.** There are two formats:

```
ATLAS — CHICAGO                          CHICAGO — STOP 20
Stop 04: Willis Tower …                  NORTH AVENUE BEACH
T1 Essentials | Clean version            Single-stop · T2 Popular · clean version

---                                      ---
```

Tours **01–17** use the first; **20–30** use the second. Script 21 carries an extra `[FIRE SPINE — FINAL ECHO]` editorial line inside its header. **Beat markers appear as both `[beat]` and `*[beat]*`** — strip both.

## ⚠️ Vantage — five tours geofence where the listener stands, not the landmark

| Tour | Script sends you to | Geofence coord (used) | Landmark | Gap |
|------|--------------------|----------------------|----------|-----|
| 04 Willis Tower | Wacker between Adams and Jackson, looking up | `41.87860, -87.63760` | `41.87880, -87.63590` | ~150 m |
| 08 Marina City | Wacker / Riverwalk, south bank, looking north | `41.88760, -87.63430` | `41.88815, -87.63430` | ~60 m |
| 16 Board of Trade | LaSalle between Monroe and Jackson, looking south | `41.87990, -87.63220` | `41.87785, -87.63225` | ~230 m |
| 17 Merchandise Mart | South bank between Wells and Franklin | `41.88760, -87.63450` | `41.88840, -87.63550` | ~120 m |
| 23 Museum Campus | The point beside the Adler | `41.86600, -87.60600` | three museums, spread | — |

At the catalog-standard **30 m** radius this matters. Geofencing the Board of Trade itself would fire the audio 230 m from where the narration assumes you are — and the narration's first line is *"look south down LaSalle and notice how little sky there is,"* which only works from up the street.

## ⚠️ Sensitivity — tour 02

Script 02 is pointedly critical of the **Fort Dearborn relief** on the DuSable Bridge's southwest tower, whose 1920s sculptors *"treated the removal of the Potawatomi from this land as an adventure story."* **That relief must not be used as an image.** The staged set is bridge, bascule leaves, corner tower houses and Riverwalk only. Same standard as Berlin's memorials and Amsterdam's Jewish Quarter.

## Credits — 16 obligations across 84 images

Full ledger: `drafts/CREDITS.md` (Chicago section). **17 rows, but `old-town-st-michaels_hero` is public domain and owes nothing**, so the real obligation is 16. Every attribution was resolved by **SHA-1 reverse-lookup** against the Commons `allimages` API — exact file identity, never dimension matching.

**⚖️ The Chicago Picasso (tour 14) is PUBLIC DOMAIN in the US** — *Letter Edged in Black Press, Inc. v. Public Building Commission of Chicago* (1970) held its design was published without a copyright notice under the 1909 Act. Photographs are therefore **not** encumbered derivative works and only the photographer is credited. This is a documented exception: the US has no freedom of panorama for artworks, so the general rule points the other way. **Verified, not assumed — do not re-derive it and conclude the images are unusable.**

**Pilsen's murals (tour 25) have no such exception.** They are in copyright, and photographs of them would be encumbered. Tour 25 is built entirely from **buildings**, which the US architectural exemption does cover. Keep it that way.

## Owner-supplied images — 8 across 6 tours

| Tour | File | Why sourcing failed |
|------|------|---------------------|
| 03 Art Institute | `_3` Modern Wing | stock has no Modern Wing at all |
| 09 Rookery | `hero` LaSalle front | Commons is almost entirely Wright's interior light court |
| 15 Monadnock | `_2` full block | stock returned unrelated Loop towers |
| 20 North Avenue Beach | `hero` + `_2` | the beach house and Chess Pavilion are in no accessible source |
| 25 Pilsen | `hero` + `_2` | `Thalia Hall (Chicago)` is entirely dark concert interiors, no exterior |
| 30 Obama Center | `hero` + `_2` | see the portrait-filter note below |

**The pattern is consistent and worth planning around:** when a script points at something specific and locally known — a named building's front door, a park pavilion, a six-week-old tower — stock and Commons both fail, and an owner photograph resolves it faster than more searching.

## Sourcing lessons — read before staging another city

**1. Search for the Commons category name; never guess it.** Five wasted fetches this batch:

| Guessed | Actual |
|---------|--------|
| `Modern Wing (Art Institute of Chicago)` | `Art Institute of Chicago modern wing` (lowercase) |
| `Monadnock Building` | `Monadnock Building, Chicago` — the bare name is **San Francisco's** |
| `Robie House` | `Robie House exterior` — the parent is thin |
| `Thalia Hall` | `Thalia Hall (Chicago)` |
| `Obama Presidential Center` | `Barack Obama Presidential Center` |

**2. Enumerate subcategories.** `Barack Obama Presidential Center` holds 8 files — logos and a website screenshot — which produced a wrong "no images exist" conclusion. It has **six subcategories**; `Construction of the Barack Obama Presidential Center` alone holds nine real photographs.

**3. 🔴 The fetcher drops PORTRAIT images.** `wiki_grab.run(..., landscape=True)` filters them out. For a 225-foot tower that discards nearly everything — six of ten usable Obama Center files were portrait, including the two best. **Any tour reported as having a thin pool deserves re-checking on this basis alone, tall subjects especially.**

**4. 🔴 `crop43` centre-crops portrait sources**, taking an equal band off top and bottom. On a tower that decapitates the building — it cut straight through the Obama Center's carved lettering panel. Wrong for architecture generally. **A top-biased crop is the right default for tall subjects**, and this has been applied silently to every portrait source this session (Berlin's Water Tower and Willis Tower are the likely casualties — check before those ship).

**5. Verify the pixels, never the result title.** Rejected this batch: Tribune Tower and the Field Museum under "Art Institute"; a drive-in called *Art's* and actual zoo lions; the John Hancock Center under "Willis Tower"; lighthouses and rooftop water tanks under "Water Tower"; Fallingwater and the Guggenheim under "Rookery", plus literal rookeries (egrets); **Mexico City's Palacio de Bellas Artes** six times under "Palace of Fine Arts Chicago"; the White House seven times under "Obama Presidential Center"; Brooklyn's Barclays Center under "Daley Plaza".

**6. A plausible wrong subject can pass the gate.** Tour 21 shipped a first pass where I had read a different Gothic church as St Michael's; the owner caught it. Check the *specific building*, not the building type.

## Known gap

**Tour 21's wooden cottages were never found.** The script's second half is about the small wooden houses built inside the two-and-a-half-year window before the 1874 ban. `_4` and `_5` are **brick Victorian rowhouses** — flagged to the owner and picked knowingly. Backfillable without touching audio.

## Wire-in checklist (when audio arrives)

1. Create maker **Atlas Studio ORD** 🇺🇸 (id above; 21st maker).
2. Add each tour `kind: single`, ids `atlas-tour:ord:<slug>` / `atlas-stop:ord:<slug>` (uuid5, `NAMESPACE_URL`).
   - One stop, `order: 0`, `triggerMode: geofenced`, `radiusMeters: 30` (catalog-wide city-launch default).
   - Stop `imageURL: null`; the tour carries `heroImageURL` + `additionalImageURLs`.
   - `city: "Chicago"`; `priceUSD: 0`; `introAudioURL: null`; `walkingDistanceMeters: null`.
   - `centroidLatitude`/`centroidLongitude` = the coord above (**the vantage, not the landmark** — see table).
   - `totalDurationSeconds` read from the delivered MP3 — do not estimate.
   - `transcriptText` per the header/beat rules above.
3. `swift scripts/validate-tours.swift` before pushing; merge auto-publishes to gh-pages + Supabase.
4. Surface `drafts/CREDITS.md` (Chicago section) — 16 obligations.
