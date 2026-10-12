# Mumbai batch 1: scripts staged, images in the picker

**30 single-stop tours · British register (`atlas-audio-tour` skill) · staged 2026-10-12 · scripts only, no audio yet**

Source list: [architecturehunter.com/guide/mumbai-india](https://architecturehunter.com/guide/mumbai-india/). It has 29 entries. Entry 10, "The Bombay Gymkhana Club Bar and the Willingdon Club Bar", is two sites 5 km apart, so it became **two tours (10 and 11)**. The guide's "35 years old" for Kanchanjunga is stale (completed 1983) and was not repeated.

## Files

| Path | What |
|---|---|
| `scripts/mumbai_NN_<slug>.txt` | Clean script. The metadata header sits above the first `---`; narration follows it. Keeps `[beat]` as an authoring marker |
| `scripts/mumbai_NN_<slug>_TTS.txt` | TTS-safe: phonetic respellings (lowercase, no hyphens), titles respelled too, no brackets, `[beat]` → paragraph break, every number in words |
| `scripts/mumbai_NN_<slug>.md` | The clean script as Markdown, one file per tour, with word count |
| `source.md` | The single source the scripts are built from. **Edit this, then rebuild:** `python3 drafts/mumbai-batch1/tools/build_scripts.py drafts/mumbai-batch1/source.md drafts/mumbai-batch1/scripts`. It exits 1 if a TTS body still holds a digit, hyphen or bracket |
| `coordinates.tsv` | One point per tour, with confidence notes. **Four are approximate or missing, see below** |
| `image-candidates.json` | Picker code → source page, licence, photographer, and (Unsplash) the `download_location` to ping when a photo is used |
| `mumbai-image-links.md` | Per-tour links for finding more photos, including the 7 tours with no candidate |

## Images: picker published, owner picks owed

[Mumbai Image Picks](https://claude.ai/artifact/D1f6mYjnq59JcSVLR3v8VX): **110 candidates across 23 tours.** Every one is public domain, Unsplash or Pexels; none needs a credit.

- 🔴 **The Gemini gates did NOT run.** The value supplied as the Gemini key (`gen-lang-client-…`) is a Google Cloud *project id*, and the API rejected it (`API_KEY_INVALID`). Both gates were done by eye instead, on labelled contact sheets of all ~460 candidates. Gate A rejected black-and-white, prints, etchings and paintings. Gate B rejected look-alikes. Re-run the two Gemini gates with a real key (`AQ.…`) if you want the mechanical check too.
- **Look-alikes caught:** India Gate (Delhi) for the Gateway; CST station and the BMC building for CSMVS; Mysore Palace, Museu Paulista and a Chișinău hall for Bhau Daji Lad; a Bermuda shipyard for the Yacht Club; a different Madras Café abroad. **Pexels' own captions** put several "Mumbai market" shots in Jaipur and Bengaluru, and the "Bombay Canteen" interiors were other restaurants (one in Bengaluru). All were rejected.
- **Tags in the licence line** mark photos that are *not* the exact venue: `the dish, not this venue`, `nearby, not this venue`, `the view, not the bar`. The food and drink venues have no public-domain or stock photos of themselves, so their rows hold only those.
- **No candidate at all:** 02 Bombay Canteen, 12 Bastian, 17 Colaba Causeway, 19 Linking Road, 20 Phoenix Mills, 22 Khotachiwadi, 27 Kanchanjunga. Use `mumbai-image-links.md`, or owner photos.
- **Wikimedia Commons was rate-limited** for this session's egress (HTTP 429 "robot policy" on both the API and `upload.wikimedia.org`), so Commons was reached only through Openverse's index. A later session should retry Commons directly, especially for Kanchanjunga, Khotachiwadi, the Gymkhana and the Yacht Club.

## Coordinates: four need a human
From OpenStreetMap by name (Nominatim), each with its OSM object in `coordinates.tsv`. Not yet run through `check-coordinates.py`.
- 🔴 **18 Kala Ghoda: do NOT take Nominatim's first hit.** It is the *original* statue now at Byculla (node 10108039535), 5.6 km from the junction. The junction is node 2630028159.
- **Approximate:** 02 (compound, not Process House), 04 (street, not Americano), 19 (a Khar segment of Linking Road), 24 (hand-placed opposite the Deco row).
- **Not geocoded:** 22 Khotachiwadi, 27 Kanchanjunga. Search the name first (CLAUDE.md rule 8d).
- 07 Eau Bar and 14 The Oberoi share one point on purpose.

## Place candidates, for Edward
These were spotted while staging. They have not been joined or created.
- **01 ELCO Pani Puri**: an existing creator pin covers the same stall ("📍 Elco Pani Puri, Bandra").
- **13 Taj Mahal Palace**: an existing creator pin covers the Taj hotel.

## Judgment calls flagged for the owner
- **Ownership and advertising.** Several stops are commercial venues (bars, restaurants, hotels) taken straight from the guide. The scripts describe them; none is paid placement.
- **Club bars (10, 11)** are members-only. The scripts say so plainly and give the listener something to do outside.
- **2008 attacks** are mentioned briefly and soberly at 07, 13, 14 and 17.
- **Contested or soft facts are hedged in the scripts:** Trishna's founding ("by most accounts, since the nineteen sixties"), the Taj's "first in India" claims, the Shor Bazaar etymology, the Queen Victoria violin story (told as folklore), eggs Kejriwal ("is said to be"), Leopold's first trade.

## Primary sources read before writing
Official or venue pages where they exist. Otherwise the most direct published account.
- 01 InsideIIM, ELCO founder profile (2016)
- 02 thebombaycanteen.com · ELLE Decor India (2023 revamp) · Asia's 50 Best Bars listing
- 03 Homegrown · TableJourney (two dates: 1965, and "about 50 years")
- 04 Tatler Asia restaurant page · Fodor's
- 05 InsideIIM interview with the owners · Asian Age (75th anniversary)
- 06 The Quint · Free Press Journal · yappe listing (hours)
- 07 Oberoi Hotels: Eau Bar page
- 08 Outlook Luxe · 50 Best discovery listing (the Four Seasons page returned 403)
- 09 En Primeur Club · TableJourney
- 10 Wikipedia: Bombay Gymkhana
- 11 Wikipedia: Willingdon Sports Club
- 12 Harper's Bazaar India (Nov 2023) · LBB
- 13 Wikipedia · Rotary Club of Bombay · The Week (the Taj site returned 403)
- 14 oberoihotels.com · Wikipedia: Trident Nariman Point
- 15 Wikipedia: Royal Bombay Yacht Club
- 16 Forbes Travel Guide · Hospibuz
- 17 Wikipedia: Colaba Causeway, Leopold Cafe · Outlook
- 18 Wikipedia: Kala Ghoda
- 19 Wikipedia: Linking Road
- 20 Wikipedia: High Street Phoenix · company history
- 21 Live History India · Curly Tales (name lore)
- 22 The Decor Journal India · Avid Learning
- 23 Wikipedia: Gateway of India
- 24 Wikipedia: Marine Drive
- 25 Wikipedia: Pali Village
- 26 Wikipedia: CSMVS
- 27 Charles Correa Foundation · ArchDaily · Archeyes
- 28 Wikipedia: Bandra–Worli Sea Link, Castella de Aguada, Coastal Road
- 29 Wikipedia: Dr. Bhau Daji Lad Museum
- 30 Wikipedia: Chowpatty · Coastal Road tunnel reports

## Before wire-in
1. Owner picks in the picker; crop to 1200×900 WebP as `<slug>_hero.webp`, `_2`, …; ping each picked Unsplash photo's `dl`.
2. Coordinate pass: `check-coordinates.py`, plus a fix for the four flagged points above.
3. Record audio from the `_TTS.txt` files.
4. Add the row to `drafts/AUDIO-PENDING-SURVEY.md` on `origin/main`, which the CLAUDE.md rule asks for once a batch is staged. **Not done in this session.**
