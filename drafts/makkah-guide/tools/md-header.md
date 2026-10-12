# Makkah — Atlas audio guide scripts

Thirty-eight single-stop tours, one per listing in the Architecture-Hunter-style Makkah city guide
(Stay · Dine · Drink · Shop · Visit · Observe), written to the **atlas-audio-tour** skill:
British conversational voice, position check in paragraph two, 2–4 featured items each with a gift
detail, an editorial pivot, one `[beat]`, and an explore-further close.

**Every script was written only after its sources were fetched and read** (listed under each tour).
Where a source contradicted the original guide, the source won — see *What changed from the guide* below.

## Files

| File | What it is |
|---|---|
| `scripts/NN_slug_clean.txt` | Authoring script. Keeps `[beat]` and normal spelling. |
| `scripts/NN_slug_tts-safe.txt` | For the TTS engine. Phonetic respellings (plain lowercase-style words, no caps, no hyphens), no brackets or markup, `[beat]` replaced by a paragraph break, every number and year spelled out in full. Titles respelled where the title itself trips TTS. |
| `MAKKAH-GUIDE.md` | This file: index, coordinates, every clean script, its respelling table and its sources. |
| `source/*.txt`, `tools/build.py` | Edit the source, re-run `python3 tools/build.py`; it rebuilds both txt sets and this file, and fails if a TTS-safe file still holds a digit, hyphen, bracket, non-ASCII letter, all-caps word or unrespelled apostrophe name. |

Every script carries a `[beat]`, so every tour has a TTS-safe version.

## Access note (applies to every tour)

The haram of Makkah, everything inside the Mecca Gate boundary, is open to **Muslims only**. Mina,
Muzdalifah and Arafat are closed to ordinary visitors during the Hajj, and the Mashaaer metro runs
only in the Hajj season. Several scripts say so where it matters; none of them invites a non-Muslim
listener to enter.

## What changed from the guide — read before wiring anything

Reading the primary sources overturned five of the original picks. They are **not** scripted:

| Guide pick | What the sources showed | Action |
|---|---|---|
| **Mama Jamila Cafe** (Drink) | Google listing marked **permanently closed**. | Dropped. |
| **Al Tekkeya Café** (Drink) | Not a heritage café. Hyatt's own page: a **grab-and-go market** inside the Jabal Omar Hyatt Regency selling sandwiches, pastries and Starbucks drinks. The guide's "Ottoman takiyya" framing had no source. | Dropped. |
| **Dates Market, Al-Kakiyah** (Shop) | The only substantive source (Times Indonesia, June 2026) describes the Kakiyah market as a three-storey **general wholesale market** (perfume, clothing, prayer mats, toys), not a date souq. No source describes the OSM "سوق التمور" node. | Dropped. Re-source before re-adding. |
| **Souq al-Aziziya** (Shop) | No source describes the market itself. One aggregator placed it "a 10-minute walk from the Grand Mosque"; it is about 5 km away. | Dropped. |
| **Masjid Namirah** (Observe, paired with Arafat) | Kept inside tour 37, but the guide's claim that its western part lies outside Arafat had no source and was cut. | Folded into 37. |

Corrections made inside scripts that keep their venue:

- **Abraj Al-Bait** — designed by Dar Al-Handasah (hotel complex) with SL Rasch (the clock); built by the Saudi Binladin Group. The guide credited Dar Al-Handasah alone; the scripts name no architect for the tower, and only Dar Al-Handasah for the Jamaraat Bridge, where Wikipedia states it.
- **Al Baik** — founded in **Jeddah** (1974); first Makkah branch 1990. Wanderlog's "originated in Mecca" is wrong.
- **Hira Cultural District** — district opened January 2023; the **Holy Qur'an Museum opened March 2025**, not 2023.
- **Makkah Library** — founding year is disputed (1950, 1953, 1954 across sources); the script says "around nineteen fifty".
- **Kamal Ismail's Thassos-marble and refused-fee stories** — sourced only to magazines and a LinkedIn post; left out.

## Thin sourcing — flagged, not hidden

These venues were scripted from the Google listing (via Wanderlog's mirror of it) plus review summaries,
because no first-party website exists. Each script states only what those sources state.

- **07 Arika Um Qasem** — 9 Google ratings; one blog line. Shortest script in the set.
- **11 nootropic**, **12 Asante**, **13 Cultivo** — independent cafés with Instagram/Google presence only. Asante's FineDine menu link did not render.
- **25 Tuwa Well** — visitors report it closed for renovation at times; the script says so.
- **38 Arak Park** — DiscoverMakkah and Google listing only; no opening date found.

## Coordinates

WGS-84, as listed in the guide. Source per row: **Google** = Google's own place pin (read via Wanderlog,
which stores the Google placeId); **OSM** = OpenStreetMap; **Wikipedia** = article coordinates.
**32 Jabal Thawr** uses the OSM summit, because Google's "Thowr Mountain" pin sits ~700 m away.
