# Amsterdam — batch 1 (NEW CITY) — images STAGED ✅

Started 2026-07-06. New city **Amsterdam**; new maker **Atlas Studio AMS** (create at first wire-in).
Owner numbering scheme (gaps expected). **All 4 scripts sourced + owner-picked + cropped + pushed to
gh-pages** on 2026-07-06. Awaiting narration audio → wire into `Tours.json` at that point.

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Tours (4) — image staging COMPLETE
| # | Tour | slug | hero + gallery (in order) | credit? |
|---|------|------|---------------------------|---------|
| 01 | Dam Square & Royal Palace | `dam-square-royal-palace` | `_hero`(DS7 palace+square) · `_2`(DS29) · `_3`(DS22 aerial) · `_4`(DS2 monument) · `_5`(DS19 palace facade) | ship-safe stock, none |
| 03 | De Wallen | `de-wallen` | `_hero`(DW3 gabled fronts) · `_2`(DW33) · `_3`(DW34) · `_4`(DW4 sunset) · `_5`(DW1) · `_6`(DW44 autumn) | ship-safe stock, none |
| 04 | Oude Kerk | `oude-kerk` | `_hero`(OK29 exterior+tower) · `_2`(OK28 exterior) · `_3`(OKW2 interior — wooden vault + gravestone floor) | **CC — see CREDITS.md** |
| 08 | Begijnhof | `begijnhof` | `_hero`(BGW9 courtyard+statue) · `_2`(BGW2 weeping tree) · `_3`(BGW8 lawn+houses) · `_4`(BGW10 house detail) | **CC — see CREDITS.md** |

All webp are 1200×900 q82. Committed to gh-pages in `d58e94d`.

## Sensitivity rules HONORED
- **De Wallen:** every candidate frame screened; only the daytime/dusk **canal quarter + gabled
  house-fronts + church towers** were used. **No red-light windows/workers** — the one red-glow
  night shot (DW23) was excluded. App-appropriate.
- **Begijnhof:** courtyard architecture only, no residents/windows.

## Sourcing notes (for the record)
- **Dam Square + De Wallen:** rich ship-safe stock (Unsplash/Pexels/Pixabay). No credit obligation.
- **Oude Kerk:** stock pool badly polluted (Delft's Oude Kerk, an alpine town, unrelated roads) →
  switched to **Wikimedia-verified** images from the correct subcategories
  (`Interior of Oude Kerk (Amsterdam)`, `Exterior views of the Oude Kerk (Amsterdam)`). CC-licensed.
- **Begijnhof:** stock polluted with Belgian beguinages (Bruges/Leuven) + canal houses →
  Wikimedia `Category:Begijnhof, Amsterdam` (note the comma, not parens). CC-licensed.
- **NOT captured:** a clean verified shot of Het Houten Huys (#34, black wooden front) or the hidden
  chapel — offered to the owner; can add later if wanted.

## Wire-in checklist (do when audio arrives)
1. Create maker **Atlas Studio AMS** 🇳🇱 (deterministic uuid5, scheme `atlas-maker:ams`).
2. Add 4 tour entries to `Resources/Tours.json` (single-stop, geofenced, radius 30m, free).
   - Deterministic ids: `atlas-tour:ams:<slug>` / `atlas-stop:ams:<slug>` (uuid5, NAMESPACE_URL).
   - `transcriptText` = verbatim clean narration from each `.txt` here (trim outer whitespace).
   - `heroImageURL` + `additionalImageURLs` per the pick map above.
   - **Coords (approximate — verify against final audio/pin):**
     - Dam Square & Royal Palace: `52.37310, 4.89135`
     - De Wallen: `52.37360, 4.89750`
     - Oude Kerk: `52.37440, 4.89810`
     - Begijnhof: `52.36900, 4.88990`
   - **Category suggestions (owner's call):** Dam Square → `history`; De Wallen → `culturalHeritage`;
     Oude Kerk → `sacredSites`; Begijnhof → `hiddenGems`.
3. `swift scripts/validate-tours.swift` → fix any errors.
4. Surface the Oude Kerk + Begijnhof credits at ship time (per `drafts/CREDITS.md`).

## Still to come (owner)
- Amsterdam scripts **02, 05, 06, 07, …** not yet received — source in the next pass.
- Narration MP3s for these 4 (nothing goes live until audio + maker exist).
