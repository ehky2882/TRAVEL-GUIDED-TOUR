# Toronto — audio upload + wire-in progress 🇨🇦

Toronto is **fully image-staged** (38 singles `toronto-batch1..10` + 4 walks; maker **Atlas Studio YYZ**, not yet created). Audio is arriving in batches; this file tracks which tours have audio on gh-pages and the wire-in plan. Owner note: **single-stop tour audio and walk audio are SEPARATE files** — the walks get their own narration later.

## Wire-in plan (owner + Claude, 2026-07-02)
Audio is being staged to gh-pages as it arrives. **Wire the whole city into `Tours.json` in one pass once all/most audio is collected** (matches how Tokyo/HK launched complete) — create **Atlas Studio YYZ** once, then add the singles + walks. Wire-in per tour: `kind=single`, 1 geofenced stop (radius 40), free, `walkingDistanceMeters=null`, `heroImageURL`+`additionalImageURLs` from gh-pages, `audioURL=audio/<slug>.mp3`, `durationSeconds` from the table below, `caption`=first sentence, `transcriptText`=the non-TTS script, `city="Toronto"`. Then `swift scripts/validate-tours.swift`.

## Audio uploaded to gh-pages — SINGLE-STOP tours

### Batch A — 10 tours (pushed 2026-07-02, gh-pages `1b40529`)
| Tour | slug (`audio/<slug>.mp3`) | durationSeconds |
|------|---------------------------|-----------------|
| CN Tower | `cn-tower` | 139 |
| Rogers Centre | `rogers-centre` | 104 |
| Ripley's Aquarium of Canada | `ripleys-aquarium` | 98 |
| Harbourfront / Queens Quay | `harbourfront` | 113 |
| Toronto Islands | `toronto-islands` | 124 |
| Union Station | `union-station` | 123 |
| Financial District (TD Centre) | `financial-district` | 144 |
| Hockey Hall of Fame | `hockey-hall-of-fame` | 116 |
| St. Lawrence Market | `st-lawrence-market` | 131 |
| Gooderham Building (flatiron) | `gooderham-building` | 127 |

## STILL PENDING audio (28 singles + 4 walks)
- **Singles without audio (28):** Berczy Park, Distillery District, Nathan Phillips Square, Old City Hall, Osgoode Hall, Sankofa Square, Eaton Centre, Royal Ontario Museum, Art Gallery of Ontario, Queen's Park, U of T King's College Circle, Casa Loma, Spadina Museum, The Annex, Prince Edward Viaduct, Kensington Market, Chinatown (Spadina), Graffiti Alley, Queen Street West, Trinity Bellwoods, Yorkville, Aga Khan Museum, High Park, Fort York, The Beaches, Scarborough Bluffs, Bata Shoe Museum, Gardiner Museum.
- **Walks (4) — need their own separate stop audio + intro:** Old Town, Downtown Spine, Museum Mile, Immigrant West/Kensington. (Walk stops reuse single-stop *images/slugs* but have distinct narration.)

**Duration source:** read via `mutagen.mp3.MP3(...).info.length`, rounded to whole seconds. Owner's raw filenames are `<Subject>_converted_by_soundandgo.com_.mp3` — mapped to slugs per `drafts/toronto-batch*/README.md`.
