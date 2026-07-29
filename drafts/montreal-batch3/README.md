# Montreal — batch 3 (16 single-stop tours) — STAGED, awaiting narration MP3s 🇨🇦

Third Montreal batch — downtown, the mountain, the Plateau/Mile End belt, the markets, the
east end. All single-stop, geofenced (radius 30 m), free, under **Atlas Studio YUL**. Heroes +
galleries sourced/owner-supplied, cropped 1200×900 WebP, pushed to gh-pages, verified live.
Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Pick-map (# / tour / slug / coord / category / hero + gallery / credit)

| # | Tour | slug | coord (lat, lon) | category | hero + gallery | credit |
|---|------|------|------------------|----------|----------------|--------|
| 10 | Mary, Queen of the World Cathedral | `mary-queen-cathedral` | 45.4995, -73.5695 | `sacredSites` | `_hero`(owner exterior) · **interior gallery PENDING** (MI9/MI10/…) | owner ship-safe; interiors = Wikimedia CC (pending pick) |
| 11 | Place Ville Marie / RÉSO | `place-ville-marie` | 45.5017, -73.5686 | `architecture` | `_hero`(owner esplanade) · **gallery PENDING** (PV…) | owner ship-safe |
| 12 | Dorchester Square & Sun Life | `dorchester-sun-life` | 45.4997, -73.5710 | `history` | `_hero`(SL4) · `_2`(SL19 columns) · `_3`(SL14 square) | ship-safe |
| 14 | Quartier des Spectacles | `quartier-des-spectacles` | 45.5088, -73.5678 | `musicAndPerformance` | `_hero`(QS8 night plaza) · `_2`(QS3 crowds) | ship-safe |
| 15 | Chinatown | `montreal-chinatown` | 45.5075, -73.5605 | `culturalHeritage` | `_hero`(CT2 gate) · `_2`(CT6 gate) · `_3`(CT4 pavilion) | ship-safe |
| 16 | Mount Royal / Kondiaronk Belvedere | `mount-royal-belvedere` | 45.5044, -73.5875 | `natureAndParks` | `_hero`(MR3 sunset) · `_2`(MR1) · `_3`(MR16) · `_4`(MR15) | ship-safe |
| 17 | Saint Joseph's Oratory | `st-joseph-oratory` | 45.4923, -73.6176 | `sacredSites` | `_hero`(JO7 dome) · `_2`(JO8) · `_3`(JO9) | ship-safe |
| 21 | Plateau staircases | `plateau-staircases` | 45.5230, -73.5810 | `culturalHeritage` | `_hero`(owner Square-St-Louis Victorians) | ship-safe |
| 22 | Square Saint-Louis | `square-saint-louis` | 45.5165, -73.5665 | `literature` | `_hero`(SQL6 colourful houses) · **gallery PENDING** (SQL7/SQL14/SQL8) | ship-safe |
| 23 | The Main (Boulevard Saint-Laurent) | `the-main-saint-laurent` | 45.5155, -73.5720 | `culturalHeritage` | `_hero`(owner Schwartz's + boulevard) · **gallery optional** (TMW…) | owner ship-safe |
| 24 | Mile End | `mile-end` | 45.5230, -73.6010 | `foodAndDrink` | `_hero`(ME12 St-Viateur Bagel) · `_2`(ME6 Fairmount Bagel) | ship-safe |
| 25 | Jean-Talon Market | `jean-talon-market` | 45.5365, -73.6145 | `foodAndDrink` | `_hero`(JT11 market hall) · `_2`(JTW5 market street) | **_2 = CC BY-SA 4.0, see CREDITS.md** |
| 26 | The Village | `the-village` | 45.5205, -73.5595 | `culturalHeritage` | `_hero`(VG1 pink balls) · `_2`(VG2) · `_3`(VG6 Pride) | ship-safe |
| 27 | Botanical Garden & Biodome | `botanical-garden-biodome` | 45.5595, -73.5525 | `natureAndParks` | `_hero`(BG12 Chinese garden) · `_2`(BG2 tower) · `_3`(BG10 penguins) · `_4`(BG3) | ship-safe |
| 30 | Lachine Canal | `lachine-canal` | 45.4790, -73.5870 | `culturalHeritage` | `_hero`(LC2 canal) · `_2`(LC19 bike path) · `_3`(LC17) | ship-safe |
| 31 | Atwater Market | `atwater-market` | 45.4795, -73.5775 | `foodAndDrink` | `_hero`(AT37 Art Deco building) · `_2`(AT5 facade) | **_hero = CC BY-SA 2.0, see CREDITS.md** |

**Numbering:** owner's script numbers (gaps 13/18/19/20/28/29 were never uploaded). 16 tours.
**Pending galleries (hero-complete without them):** #10 Mary interior, #11 PVM, #22 Square Saint-Louis, #23 The Main.

## Sourcing notes
- **Owner-supplied heroes** (pasted, ship-safe): Mary Queen exterior, Place Ville Marie esplanade, Plateau (Square St-Louis Victorians), The Main (Schwartz's + boulevard).
- **Re-sourced for subject accuracy:** Mary (stock pulled Notre-Dame interiors → Wikimedia `Cathedral-Basilica of Mary, Queen of the World`); Jean-Talon + The Main (generic stock → Wikimedia `Jean-Talon Market` / `Exteriors of Schwartz's Deli`). Atwater filtered out the many Old-Port-clock-tower strays.
- Categories per column; `sacredSites` for the two churches, `foodAndDrink` for the three markets/bagels, `literature` for Square Saint-Louis (Nelligan/poets).

## Wire-in (when MP3s arrive) — same as batch 1
Ids `atlas-tour:yul:<slug>` / `atlas-stop:yul:<slug>` (uuid5); `transcriptText` verbatim from each `NN_*.txt` (drop `[beat]`); geofenced/radius 30; durations from MP3s; `heroImageURL` + `additionalImageURLs` per the pick-map; `swift scripts/validate-tours.swift`.

## The 4 Montreal multi-stop walks (staged separately)
`drafts/montreal-oldmontreal-walk` · `drafts/montreal-mountroyal-walk` · `drafts/montreal-plateaumileend-walk` · `drafts/montreal-downtown-walk` — each reuses these single-stop heroes (Mount Royal walk added 3 new images: trail entrance, climb, the Cross).
