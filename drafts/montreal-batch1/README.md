# Montreal — batches 1 + 2 (9 single-stop tours) — STAGED, awaiting narration MP3s

New maker at wire-in: **Atlas Studio YUL** 🇨🇦 (Montreal, airport code — matches YYZ/TYO/KYO pattern).
All 9 tours: single-stop, geofenced (radius 30 m), free. Scripts (`.txt` + `_TTS.txt`) staged in this folder
(`01`–`05` = batch 1 Old Montreal; `06`–`09` = batch 2). Heroes + galleries sourced, cropped 1200×900 WebP,
pushed to gh-pages, live-verified.

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Pick-map (# / tour / slug / hero+gallery / credit / coord / category)

| # | Tour | slug | hero + gallery (in order) | credit | coord | category |
|---|------|------|---------------------------|--------|-------|----------|
| 01 | Notre-Dame Basilica / Place d'Armes | `notre-dame-basilica` | `_hero`(ND6 facade) · `_2`(ND14 Maisonneuve monument) · `_3`(ND4 blue interior) · `_4`(ND8 interior) · `_5`(ND23 side) | stock, **none** | `45.50451, -73.55627` | `sacredSites` |
| 02 | Place Jacques-Cartier / City Hall | `place-jacques-cartier-city-hall` | `_hero`(JW6 Nelson's Column + square) · `_2`(JW3 column sunset) · `_3`(CW2 City Hall street) · `_4`(CW4 City Hall front/balcony) | **CC — see CREDITS.md** (JW3 CC0, no credit) | `45.50789, -73.55283` | `history` |
| 03 | Old Port | `old-port` | `_hero`(OP10 Ferris wheel golden hour) · `_2`(OP1 Clock Tower+bridge) · `_3`(OP5 Clock Tower winter) · `_4`(OP12 Grande Roue) · `_5`(OP15 Habitat 67) | stock, **none** | `45.50630, -73.54780` | `culturalHeritage` |
| 04 | Pointe-à-Callière | `pointe-a-calliere` | `_hero`(PE36 Éperon museum) · `_2`(PE35 Éperon side) · `_3`(PC47 buried Saint-Pierre river tunnel) · `_4`(PC50 excavated foundations) | **CC — see CREDITS.md** | `45.50201, -73.55418` | `history` |
| 05 | Bonsecours Market + chapel | `bonsecours-market-chapel` | `_hero`(MW8 market across water) · `_2`(MW6 silver dome) · `_3`(BC34 chapel tower night) · `_4`(BC35 chapel spire) | **CC — see CREDITS.md** (MW6 PD, no credit) | `45.50820, -73.55150` | `culturalHeritage` |
| 06 | Château Ramezay | `chateau-ramezay` | `_hero`(CX5 fieldstone facade) · `_2`(CX7 house + Governor's Garden) | **CC — see CREDITS.md** (both Jean Gagnon CC BY-SA 3.0) | `45.50852, -73.55381` | `history` |
| 07 | Habitat 67 | `habitat-67` | `_hero`(HB8 stacked modules) · `_2`(HB1) · `_3`(HB4) · `_4`(HB7) · `_5`(HB11) · `_6`(HB9) | stock (Unsplash), **none** | `45.49664, -73.54260` | `architecture` |
| 08 | McGill / Golden Square Mile | `mcgill-golden-square-mile` | `_hero`(RX9 Roddick Gates) · `_2`(RX6 Roddick Gates) · `_3`(AX6 Arts Building) | **CC — see CREDITS.md** (RX9/AX6 = CC0 no credit; RX6 CC BY-SA 3.0) | `45.50455, -73.57478` | `culturalHeritage` |
| 09 | Christ Church Cathedral | `christ-church-cathedral` | `_hero`(CC37 church + glass tower) · `_2`(CC40 spire/facade) | **CC — see CREDITS.md** (both CC BY-SA) | `45.50387, -73.56952` | `sacredSites` |

**Note (tour 02):** the first stock picks were the *London* Nelson's Column / wrong monuments — re-sourced the real Montreal column + City Hall from Wikimedia (owner-caught). **Tour 05:** the market shots were re-sourced from Wikimedia after the stock set was unreliable; owner chose the market to lead (MW8 hero) with the chapel in the gallery. **Batch 2 (06–09):** Château Ramezay + McGill Roddick Gates + Christ Church Cathedral were all re-sourced Wikimedia-only after stock returned wrong subjects (owner-flagged "these might all be wrong" / "Roddick Gates wrong"); Habitat 67 sourced clean from Unsplash. McGill hero = the CC0 Roddick Gates shot (RX9); AX6 = the Arts Building tower (interpreted from owner's "zx6" typo).

## Sensitivity
None of these nine are sensitive subjects. (Bonsecours is a working market + a sailors' chapel — dignified as sourced; Christ Church Cathedral is a working Anglican cathedral, dignified exteriors.)

## Wire-in checklist (do when audio arrives)
1. New maker **Atlas Studio YUL** 🇨🇦 (deterministic uuid5 id, same scheme as other makers).
2. Per tour: id `atlas-tour:yul:<slug>` / stop `atlas-stop:yul:<slug>` (uuid5, NAMESPACE_URL).
   - `transcriptText` = verbatim from each `NN_*.txt` (trim outer whitespace + the `[beat]` stage cue is spoken-pause only — keep or drop consistently; recommend dropping the literal `[beat]` line from transcriptText).
   - `triggerMode: geofenced`, `radiusMeters: 30`, coords above.
   - `heroImageURL` + `additionalImageURLs` per the pick-map.
   - `durationSeconds` read from each MP3 at wire-in.
   - Category per the pick-map.
   - Audio slug: name each MP3 to the tour `slug` (e.g. `notre-dame-basilica.mp3`) OR keep the `montreal_01_*` names and set `audioURL` accordingly — just keep the image slug (above) as the canonical prefix.
3. `swift scripts/validate-tours.swift` → fix errors → merge auto-publishes to gh-pages + Supabase.
4. Credits: 15 CC images logged in `drafts/CREDITS.md` (Montreal section — 10 batch 1 + 5 batch 2; three batch-2 picks are CC0/no-credit).

## These 5 form a natural walking route
Place d'Armes → Place Jacques-Cartier → Old Port → Pointe-à-Callière → Bonsecours — a future **Old Montreal multi-stop walk** (reuse these heroes, zero new sourcing), same pattern as the Amsterdam walks.
