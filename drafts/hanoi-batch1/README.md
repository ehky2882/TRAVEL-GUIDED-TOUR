# Hanoi batch 1 — 28 single-stop scripts (from Architecture Hunter's Hanoi city guide)

Source list: <https://architecturehunter.com/guide/hanoi-vietnam-city-guide/> (28 entries, all kept, one tour each).
Voice: Atlas British (atlas-audio-tour skill). Every venue was researched from primary or first-hand
sources before writing; each script's header names its sources.

| Folder | What |
|---|---|
| `clean/*.txt` | Clean script, with header (vantage + sources) and `[beat]` authoring markers |
| `clean/md/*.md` | Same, as Markdown |
| `tts/*_TTS.txt` | TTS-safe: phonetic respellings (lowercase, no hyphens), no `[beat]`, no brackets, numbers in words, title respelled, header removed |
| `tts/md/*.md` | Same, as Markdown |
| `IMAGE-LINKS.md` | Every image candidate's source page, plus where to look for venues with no public-domain photos |

## Coordinates (from Architecture Hunter's own map pins unless noted)

| # | Slug | Lat | Lon | Note |
|---|---|---|---|---|
| 01 | gia | 21.027329 | 105.835910 | |
| 02 | tung-dining | 21.026900 | 105.850015 | |
| 03 | ngo-trung-yen | 21.033375 | 105.852656 | |
| 04 | long-waits-jazz | 21.032513 | 105.845655 | |
| 05 | workshop14 | 21.058153 | 105.832437 | |
| 06 | memoire-15 | 21.036590 | 105.849623 | Guide spells it "Memoir 15"; the café is **Mémoire 15** |
| 07 | duy-tri | 21.051497 | 105.838798 | Guide's address (8 Chân Cầm) is wrong; pin + press place it on **Yên Phụ** (43 or 46) |
| 08 | loading-t | 21.030522 | 105.848501 | Guide's address (15 Ngô Quyền) is wrong; real address **8 Chân Cầm** |
| 09 | metropole-hanoi | 21.025413 | 105.856375 | Guide's address (6 Ngõ 5 Từ Hoa) is wrong; real address **15 Ngô Quyền** |
| 10 | jw-marriott-hanoi | 21.006956 | 105.783168 | |
| 11 | silk-path-boutique-hanoi | 21.025574 | 105.852421 | |
| 12 | jackfruit-village | 21.058897 | 105.528113 | ~45 km west of the city |
| 13 | 54-traditions | 21.041701 | 105.844855 | |
| 14 | art-vietnam-gallery | 21.000688 | 105.863753 | By appointment only (private house) |
| 15 | manzi-art-space | 21.041389 | 105.845556 | |
| 16 | hanoi-old-quarter | 21.0359 | 105.8517 | Re-anchored at Bạch Mã Temple, 76 Hàng Buồm (guide pins the district) — **verify** |
| 17 | hanoi-french-quarter | 21.0243 | 105.8576 | Re-anchored at the Opera House (guide pins the district) — **verify** |
| 18 | ba-dinh-square | 21.036897 | 105.834667 | |
| 19 | imperial-citadel-thang-long | 21.035223 | 105.840259 | |
| 20 | vietnam-military-history-museum | 21.008513 | 105.755774 | New 2024 site |
| 21 | long-bien-bridge | 21.041784 | 105.854503 | |
| 22 | ho-chi-minh-museum | 21.035641 | 105.832663 | |
| 23 | ngoc-son-temple | 21.030688 | 105.852386 | |
| 24 | heritage-house-87-ma-may | 21.034419 | 105.853528 | |
| 25 | concrete-flakes | 21.017766 | 105.852507 | An office (OpenAsia HQ extension), not a house as the guide says |
| 26 | bat-trang-house | 20.977073 | 105.912553 | Private home |
| 27 | bat-trang-museum | 20.974738 | 105.912975 | |
| 28 | vietnam-museum-of-ethnology | 21.040342 | 105.798735 | |

Run `python3 scripts/check-coordinates.py` before wiring: none of these coordinates has been checked against a second source.

## Images uploaded (owner picks, 2026-10-12)

35 WebPs at 1200×900 on gh-pages, for 11 tours: 09, 16–23, 27, 28. `image-manifest.json` has each file's URL, licence, photographer and source page.
Tours with no picks yet: 01–08, 10–15, 24–26.
⚠️ `metropole-hanoi_2.webp` (pick 09-3) may not be the Metropole: the building has a tower the Heritage Wing doesn't. Confirm before wiring.
