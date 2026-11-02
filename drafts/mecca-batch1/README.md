# Mecca batch 1 — Atlas Studio MAK (29 singles) — wired 2026-11-02

Source: contributor drop (Dropbox, arthur.yung), 29 `<Name> <lat>, <lon>` folders with scripts numbered 01–37. Numbers
04–07, 09, 20, 35 and 36 were dropped upstream (contributor confirmed). Each folder holds `NN_<slug>_clean.txt` +
`NN_<slug>_tts-safe.txt`, one MP3 (75–123 s) and 1–5 photos at 1200×900 WebP (80 in all, no byte duplicates). Arabic
and curly-quote folder names arrived mangled by the zip (`#U0627…`, `Bay#U2019ah`); the assembler matches on a
folder-name prefix.

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.

`tools/wire_mecca.py` is the assembler (`python3 -I wire_mecca.py <unzipped drop> <stage dir>`), adapted from
`drafts/valencia-batch1/tools/wire_valencia.py`. Run it once: it refuses colliding tour ids. Slugs carry a **`mak-`
prefix**: audio at `audio/mak-<slug>.mp3`, images at `images/mak-<slug>_hero.webp`, `_2.webp`, … in the drop's order.

- **Maker:** Atlas Studio MAK, platform `dozent`, handle `atlas.mak`, uuid5 `atlas-maker:mak`. The code is MAK (for
  Makkah), the contributor's choice: Mecca has no airport code of its own.
- **Ids:** `atlas-tour:mak:mak-<slug>`, stops `atlas-stop:mak:mak-<slug>:1`.

## Coordinates
Every coordinate comes from its folder name; none was moved. `check-coordinates.py --drop` found **no directional bias
(7/22 north, median −0.1 m, p = 0.13)**. Its one GROSS is a false alarm: the Kaaba point sits on the Black Stone, and
the geocoder had matched the *Sheraton Jabal Al Kaaba* hotel 777 m away. Of the 13 UNVERIFIABLE results:
- **Bay'ah Mosque** matches OSM's مسجد البيعة exactly.
- **Al Romansiah** reverse-geocodes to Al Mursalat, Mina, as the script says. The branch is not in OSM, but several hotel
  listings on Al Masjid Al Haram Road in Al Mursalat put an Al Romansiah 1–7 minutes' walk away.
- **Mount Arafat**: the supplied point is on Jabal al-Rahmah. The geocoder's match was the wider Arafat plain, 8 km off.
- The rest are cafés and sites that OSM does not name; each sits in the district its script describes.

## Wiring
- **City:** `Mecca` for all 29, including Mina, Arafat and the Mecca Gate, which are all inside the city's limits
  (the Valencia rule). Mecca and Saudi Arabia already had a creator pin, so cities and countries did not move.
- **Geofence:** 20 m for Raffles, the Clock Tower Museum and Abdul Samad Al Qurashi, and 30 m for the Fairmont, the
  shopping centre and Cafe Moment, because the Clock Towers cluster is dense. 40–50 m for venues and mosques; 60 m for
  the Kaaba, Safa and Marwa, and Hira Cave; 80 m for the Haram, the cemetery, the Hira district, the station and the
  Mecca Gate; 100 m for the Jamarat, Arafat and Thawr. No two of the 29 circles overlap.
- **Bilingual `English | العربية`** on 24. Brand-name venues keep one name: Raffles, Conrad, the Fairmont and Cafe
  Moment. The Arabic for Al Romansiah, Asante, Cultivo and Nootropic comes from the folder names.
- **Spelling:** Jamaraat → Jamarat, Safaa and Marwah (Saee) → Safa and Marwa, Mt Arafat → Mount Arafat,
  Al Kaaba → The Kaaba.
- **Place-type tags:** Park for the mountains and the cave (as on Sugarloaf and Mount Royal), Monument for the cemetery
  and Tuwa Well (as on Oakland and Copp's Hill).
- **Text:** `longDescription` = hook + paragraph 3, as in Valencia; `shortDescription` cut at 145 characters; `[beat]`
  stripped from the transcript. Captions written by hand from each script's orientation paragraph.

## Architect tags (Job 5): 3 new names, one line in each list
Mohamed Kamal Ismail (Saudi expansions of Masjid al-Haram) · Dar Al-Handasah (Jamarat Bridge) · Samir Elabd (Mecca Gate).
Existing tags used: Mimar Sinan (Masjid al-Haram's Ottoman arcades), Norman Foster (Haramain station).
**Not** tagged: Dia Aziz Dia (the Mecca Gate's designer; the script names Elabd as its architect), Buro Happold
(engineers), Saudi Binladin Group (builder), and Foster and Partners on the Conrad (they worked on the Jabal Omar masterplan,
not the hotel).

## Places
None created or joined. `join-places --max-move 100` found nothing. `check-place-candidates` added two NEAR pairs, which
are on Edward's board (`status/owner/mecca-launch.md`):
- **Abraj Al-Bait Shopping Center** (tour) and the **Abraj Al Bait** pin, 49 m: the podium against the whole complex.
- **Makkah Clock Tower** (the museum) and the **Fairmont** tour, 145 m: one tower, two angles.
