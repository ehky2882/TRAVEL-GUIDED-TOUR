# Montreal — batch 1 (Old Montreal · 5 single-stop tours) — STAGED, awaiting narration MP3s

First Montreal batch. New maker at wire-in: **Atlas Studio YUL** 🇨🇦 (Montreal, airport code — matches YYZ/TYO/KYO pattern).
All 5 tours: single-stop, geofenced (radius 30 m), free. Scripts (`.txt` + `_TTS.txt`) staged in this folder.
Heroes + galleries sourced, cropped 1200×900 WebP, pushed to gh-pages, live-verified.

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Pick-map (# / tour / slug / hero+gallery / credit / coord / category)

| # | Tour | slug | hero + gallery (in order) | credit | coord | category |
|---|------|------|---------------------------|--------|-------|----------|
| 01 | Notre-Dame Basilica / Place d'Armes | `notre-dame-basilica` | `_hero`(ND6 facade) · `_2`(ND14 Maisonneuve monument) · `_3`(ND4 blue interior) · `_4`(ND8 interior) · `_5`(ND23 side) | stock, **none** | `45.50451, -73.55627` | `sacredSites` |
| 02 | Place Jacques-Cartier / City Hall | `place-jacques-cartier-city-hall` | `_hero`(JW6 Nelson's Column + square) · `_2`(JW3 column sunset) · `_3`(CW2 City Hall street) · `_4`(CW4 City Hall front/balcony) | **CC — see CREDITS.md** (JW3 CC0, no credit) | `45.50789, -73.55283` | `history` |
| 03 | Old Port | `old-port` | `_hero`(OP10 Ferris wheel golden hour) · `_2`(OP1 Clock Tower+bridge) · `_3`(OP5 Clock Tower winter) · `_4`(OP12 Grande Roue) · `_5`(OP15 Habitat 67) | stock, **none** | `45.50630, -73.54780` | `culturalHeritage` |
| 04 | Pointe-à-Callière | `pointe-a-calliere` | `_hero`(PE36 Éperon museum) · `_2`(PE35 Éperon side) · `_3`(PC47 buried Saint-Pierre river tunnel) · `_4`(PC50 excavated foundations) | **CC — see CREDITS.md** | `45.50201, -73.55418` | `history` |
| 05 | Bonsecours Market + chapel | `bonsecours-market-chapel` | `_hero`(MW8 market across water) · `_2`(MW6 silver dome) · `_3`(BC34 chapel tower night) · `_4`(BC35 chapel spire) | **CC — see CREDITS.md** (MW6 PD, no credit) | `45.50820, -73.55150` | `culturalHeritage` |

**Note (tour 02):** the first stock picks were the *London* Nelson's Column / wrong monuments — re-sourced the real Montreal column + City Hall from Wikimedia (owner-caught). **Tour 05:** the market shots were re-sourced from Wikimedia after the stock set was unreliable; owner chose the market to lead (MW8 hero) with the chapel in the gallery.

## Sensitivity
None of these five are sensitive subjects. (Bonsecours is a working market + a sailors' chapel — dignified as sourced.)

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
4. Credits: 10 CC images already logged in `drafts/CREDITS.md` (Montreal section).

## These 5 form a natural walking route
Place d'Armes → Place Jacques-Cartier → Old Port → Pointe-à-Callière → Bonsecours — a future **Old Montreal multi-stop walk** (reuse these heroes, zero new sourcing), same pattern as the Amsterdam walks.
