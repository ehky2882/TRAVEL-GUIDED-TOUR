# Kuala Lumpur — an architect's guide (42 single-stop scripts) — DRAFT, not wired

These are 42 audio-tour scripts in the Atlas British voice (`atlas-audio-tour` skill). They follow the Kuala Lumpur
guide written in the style of Architecture Hunter (Stay / Dine / Drink / Shop / Visit / Observe).
Each location is its own single-stop tour. There is no audio, no images and no catalog entry yet.

## Files

| Path | What |
|---|---|
| `scripts/NN_slug_clean.txt` / `.md` | The authoring script. `[beat]` marks the pause and years are digits |
| `scripts/NN_slug_tts-safe.txt` / `.md` | The text to paste into the TTS tool. It uses phonetic respellings (titles too), has no caps, hyphens, brackets or markup, replaces `[beat]` with a paragraph break, and spells years and dates in full |
| `ALL_SCRIPTS_clean.md` · `ALL_SCRIPTS_tts-safe.txt` | All 42 in one file, for reading straight through |
| `coordinates.tsv` | num · slug · lat · lon · category · Google Maps name. Coordinates are WGS-84 from OpenStreetMap (Photon) |
| `tools/scripts_part1-4.py` | The source of every script. **Edit these, not the generated files** |
| `tools/build.py` | Regenerates all of the above, then lints every TTS-safe file. It exits 1 on any digit, hyphen, bracket, all-caps word or beat marker |

```bash
python3 drafts/kualalumpur-architect-guide/tools/build.py
```

## Changes from the guide as first published

- **Merchant's Lane has been DROPPED.** It closed permanently around 1 January 2026, according to SAYS (2 Jan 2026) and Seth Lui. Its building is still mentioned in the PS150 script, which occupies the ground floor of the same shophouse.
- **Menara Maybank is now Menara Tun Perak.** It was renamed on 28 July 2026, and Merdeka 118 is now Menara Merdeka Maybank (Malay Mail, The Star, 28 Jul 2026).
- **Masjid Negara's roof** is a sixteen-pointed star, not an eighteen-pointed one.
- **Yut Kee:** I found no source saying the marble tables moved with the shop, so the script doesn't claim it.
- **Sultan Abdul Samad Building:** its restoration was completed in February 2026, and it now has galleries and cafés.
- **PS150 coordinate:** this is the 150 Jalan Petaling building pin. **Heli Lounge Bar** uses the Menara KH tower pin. **KL Forest Eco Park** and **KLCC Park** use the centres of their areas.

## Facts kept deliberately soft (sources conflict)

- **Dewakan:** it moved to Naza Tower in 2019 or 2020, so the script says "a few years later".
- **Pahit:** sources give between 60 and 150 gins, so the script says "dozens".
- **Tabung Haji:** completion is given as 1984 or 1986, so the script says "mid-eighties".
- **VCR:** the story that warders lived there is the café's own account, and the script says so.
- **Zhongshan:** the tenant mix changes, so tenants are named as they were "when it opened".

## Primary sources read before writing (one or more per venue)

Venue sites and press releases were used where they could be fetched. Several of them (Malay Mail, Tatler, Hospitality
Design) blocked fetching, and for those the facts come from search excerpts quoting them.

- **The Majestic:** Wikipedia "Hotel Majestic (Kuala Lumpur)". **Hotel Stripes:** YTL Community press release
  (ytlcommunity.com news 974). **The RuMa:** Options/The Edge interview with Andy Hall. **KLoé:** Wallpaper*, plus excerpts
  from Zafigo/First Classe.
- **Dewakan:** Wikipedia "Dewakan", plus Tatler and Malay Mail excerpts. **Yut Kee:** FMT (16 Sep 2020) and Vulcan Post.
  **Sek Yuen:** FMT (14 Aug 2020), plus uniness.gallery excerpts. **Bijan:** Malay Mail (Jan 2015), Tatler and The Star excerpts.
  **Nasi Lemak Tanglin:** HungryOnion and Kosmo.
- **PS150:** FMT (20 Sep 2019), Time Out, CNN and Tatler. **Merchant's Lane closure:** SAYS (2 Jan 2026). **VCR:** Time Out and
  StoreHub. **LOKL:** EatDrinkKL, Happy Go KL and BFM. **Ho Kow:** Time Out and Kosmo. **Pahit:** Time Out, SilverKris and Tatler.
  **Bar Trigona:** Four Seasons press releases (2022–2025) and Malay Mail (Apr 2025). **Heli Lounge:** Traveling with Rob,
  and Yelp 2026 status.
- **Zhongshan:** Vulcan Post (Nov 2020), plus The Edge and Malay Mail excerpts. **REXKL:** Malay Mail (Apr 2019), Atlas
  Obscura and Cinema Treasures excerpts. **APW:** The Edge "Streetscapes", plus Vulcan Post (Royal Press). **Pasar Seni:**
  Wikipedia "Central Market, Kuala Lumpur" and "T. Y. Lee". **Royal Selangor:** Wikipedia "Royal Selangor", plus Malaysia
  Airlines Going Places.
- **Architecture and heritage (Wikipedia unless noted):** National Mosque of Malaysia · National Museum (Malaysia) · Islamic
  Arts Museum Malaysia · Rumah Penghulu Abu Seman (FMT 2021, Malaysia Traveller) · Kuala Lumpur railway station · Sultan
  Abdul Samad Building · Jamek Mosque · Sin Sze Si Ya Temple · Kwai Chai Hong (EdgeProp, NST 2019) · Thean Hou Temple ·
  ILHAM Gallery (ilhamgallery.com/about, Time Out) · Tugu Negara · National Library of Malaysia · Tabung Haji Tower
  (Lonely Planet, Berita Harian) · Menara Maybank / Tun Perak Tower · Dayabumi Complex · Malaysian Houses of Parliament
  · Stadium Merdeka · Bukit Nanas · Saloma Link (EdgeProp, Wikipedia) · KLCC Park · Petronas Towers.

## Before this goes to audio

- Listen to each TTS-safe script once. The respelling table is in `tools/build.py` (`RESPELL`), so a mispronounced name is a
  one-line fix there, followed by a rebuild.
- Hours, menus and tenants change. Re-check the business stops (DINE, DRINK and the hotels) shortly before recording.
