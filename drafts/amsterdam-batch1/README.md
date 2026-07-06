# Amsterdam — batch 1 (NEW CITY, image-staging IN PROGRESS) 🇳🇱

Started 2026-07-06. New city **Amsterdam**; maker **Atlas Studio AMS** (create at first wire-in).
Owner numbering scheme (gaps expected). Scripts saved here; **images NOT yet picked/pushed** — session
hit context limits mid-flight and handed off. Re-source these 4 next session (candidates were in `/tmp`, now gone).

## Scripts received (4) — all still need owner picks + gh-pages push
| # | Tour | slug (planned) | notes |
|---|------|----------------|-------|
| 01 | Dam Square & Royal Palace | `dam-square-royal-palace` | Royal Palace (ex town hall) + National Monument pillar. RICH stock. |
| 03 | De Wallen | `de-wallen` | **SENSITIVE:** source the medieval CANAL QUARTER + Oude Kerk tower + old gabled house-fronts ONLY. **Never feature red-light windows or workers** (script's absolute rule + app-appropriateness). Exclude any red-glow/window shots (e.g. the one night RLD canal shot). |
| 04 | Oude Kerk | `oude-kerk` | Gothic brick church, wooden-capped tower, huge wooden-vault interior ("upturned hull"), gravestone floor. **Stock pool polluted with OTHER Amsterdam churches** (Westerkerk, Nieuwe Kerk, Zuiderkerk, St Nicolaas) — VERIFY it's the Oude Kerk before using. |
| 08 | Begijnhof | `begijnhof` | Enclosed courtyard, green lawn, gabled houses, wooden house #34 (Het Houten Huys), hidden chapel. **Also a "don't photograph residents/windows" rule** — source courtyard architecture only. |

## Sourcing status (all re-fetchable via `drafts/pipeline/fetch*`)
- Fetched candidates for all 4 (Dam Square 43, De Wallen 54, Oude Kerk 47, Begijnhof 39) but **owner had not yet picked** when the session hit "request too large."
- Dam Square strong hero candidates seen: DS2 / DS21 (clean Royal Palace facade), DS9 (National Monument), DS18/DS20 (square wide). Mostly ship-safe stock.
- De Wallen: clean canal/gabled-house pool; best "old quarter" candidates DW22/DW25/DW26/DW30 (canal + Oude Kerk). Exclude DW23 (red-glow night).
- Oude Kerk + Begijnhof: NOT yet triaged for exact-subject correctness — verify pixels (church look-alikes; Begijnhof courtyard).

## ⚠️ Lesson for next session — MONTAGE SIZE
The "request too large" errors came from **oversized montage PNGs** (7-col, ~1600px) stacking in context.
**Fix:** build smaller montages (fewer cols / smaller thumbs, target < ~1200px wide) OR send fewer full-size
candidates per message. Owner prefers full-size individual images for picking anyway (not tiny grids) —
so lean on small batches of full-size labeled picks rather than one huge contact sheet.

## Next steps
1. Re-source the 4 tours (fetch scripts in `drafts/pipeline/`; keys pasted fresh by owner).
2. Verify De Wallen (no RLD windows), Oude Kerk (right church), Begijnhof (courtyard).
3. Present full-size picks with source/license tags → owner picks → crop 1200×900 WebP → gh-pages `images/` → this README.
4. Log any CC credits in `drafts/CREDITS.md` (add an Amsterdam section).
5. Owner will send more Amsterdam scripts (02, 05, 06, 07, … not yet sent).
