# Warsaw batch 1: Architecture Hunter-style city guide, as Atlas audio tours

**37 single-stop tours · British conversational register (atlas-audio-tour skill) · scripts only, no audio yet · drafted 2026-10-12**

These are the 37 venues from the Warsaw city guide (Stay, Dine, Drink, Shop, Visit, Observe), each written as its own tour.

**Every tour has three files in `scripts/`:**
- `.md` is the clean script, with the Google Maps name, the coordinates, the vantage point, and the sources read before writing.
- `.txt` is the clean script as plain text. `[beat]` stays in as an authoring marker.
- `_TTS.txt` is the TTS-safe version. Proper nouns, including the titles, are spelled phonetically in lowercase. It has no hyphens, no brackets, no markup and no digits, and years are spelled out. Each `[beat]` is replaced by a paragraph break.

**Rebuild:** run `python3 tools/build.py` after editing `source/*.txt`, then `python3 tools/make_readme.py`. The build fails if a TTS file still contains a digit, a bracket, a hyphen, an all-caps word, or a non-ASCII letter (a Polish name nobody has respelled).

**Research:** `RESEARCH-NOTES.md` records what each venue's sources said, before a word was written.

## Index

| # | Category | Tour title | Google Maps name | Coordinates (WGS-84) | Files |
|---|---|---|---|---|---|
@@ROWS@@

Coordinates are OpenStreetMap objects that carry each venue's own name, found by name with Nominatim and Photon on 2026-10-12. The ones that need care:
- **Za Żelazną Bramą** is a neighbourhood centroid.
- **Katowicka** is a street point.
- **Plac Konstytucji** is a road segment on the square.
- **Bulwar Flotylli Wiślanej** is one section of the boulevards.

`check-coordinates.py` has not been run on these points.

## 🔴 Corrections to the original city-guide listing (found during research)

| Venue | The guide said | The sources say |
|---|---|---|
| Pawilon Cepelii | sells folk craft | Restored and reopened in **December 2024 as an Empik bookshop**. Cepelia is gone; its neon cockerel remains. |
| Rozbrat 20 | natural-wine bar and bistro | **Fine dining**, chef Bartosz Szymczak, first Michelin star in 2024, with a serious Italian organic wine list |
| Muzeum Sztuki Nowoczesnej | opened 2023 | Opened to the public on **25 October 2024** |
| Fotoplastikon | a viewer from about 1905 | At this address **since 1946**, when it was already about fifty years old |
| Za Żelazną Bramą | prefabricated slab blocks | **Cast in place in monolithic concrete**, not large-panel prefab |
| Pawilony Nowy Świat | (implied 1950s–60s) | Built from **1972** as craftsmen's workshops; bars only from the late 1990s |
| Neon Muzeum | (Soho Factory) | Moved to the **4th floor of the Palace of Culture** on 1 August 2025 |

## Owed before recording
1. **Native pronunciation pass** on the TTS respellings below, especially Krakowskie Przedmieście, Marszałkowska, Kościół Wniebowstąpienia Pańskiego and Za Żelazną Bramą.
2. **Perishable claims to re-check on the day.** These are opening hours ("dinner only, Tuesday to Saturday" for 05 and 14), Rozbrat 20's Michelin star, the Pawilony lease, and the state of Bazar Różyckiego.
3. **Unverified, so deliberately left out of the scripts:** the opening years of Charlotte, Plan B and Kulturalna.

## Pronunciation (TTS respellings used)

| Written | Spoken |
|---|---|
@@PRON@@

## Images (picked 2026-10-18)

The owner picked these in the [Warsaw Image Picks](https://claude.ai/artifact/QGGnecrEVZRKg6mGgk4N7J) page. They are 24 photos for 9 tours, all from Unsplash or Pexels. Neither licence requires a credit line.

Each file was cropped from a full-size (2400 px) original to 1200 × 900 WebP, and none had to be enlarged. They are staged in `images/`, **not yet on gh-pages**. Upload them only when the tours are wired into `Tours.json`, then run `check-image-duplicates.py --maker <CODE>`. The filenames use the tour slugs from the index above, and none clashes with an existing gh-pages file (checked 2026-10-18).

⚠️ **The Gemini gates were NOT run.** The key supplied was a Cloud project name, not an API key. Every photo was identified by eye instead, and checked against its source caption. That review rejected look-alikes from Bucharest, Bratislava, Mysuru, Jabłonna and Poissy.

**28 tours still have no image.** Wikimedia Commons, and Openverse (which fetches from it), returned 429 to every request from the cloud session. A session with Commons access, or owner or venue photos, is needed for those tours.

| Tour | File | Role | Licence | Photographer | Source |
|---|---|---|---|---|---|
| 02 hotel-bristol | `hotel-bristol_hero.webp` | hero | Unsplash | flickch | <https://unsplash.com/photos/elegant-illuminated-building-at-night-with-street-and-parked-cars-h1xPyeW9Nqs> |
| 18 hala-mirowska | `hala-mirowska_hero.webp` | hero | Pexels | MART  PRODUCTION | <https://www.pexels.com/photo/brown-building-with-arched-windows-7316948/> |
| 20 palac-kultury-i-nauki | `palac-kultury-i-nauki_hero.webp` | hero | Unsplash | Valentyn Chernetskyi | <https://unsplash.com/photos/high-rise-building-beside-park-D7fPbwGQMHY> |
| 20 palac-kultury-i-nauki | `palac-kultury-i-nauki_2.webp` | gallery 1 | Pexels | Julia Filirovska | <https://www.pexels.com/photo/the-facade-of-the-palace-of-culture-and-science-8259171/> |
| 20 palac-kultury-i-nauki | `palac-kultury-i-nauki_3.webp` | gallery 2 | Unsplash | JEREMY MALECKI | <https://unsplash.com/photos/gray-concrete-building-under-white-clouds-during-daytime-sF7ClFY47yM> |
| 20 palac-kultury-i-nauki | `palac-kultury-i-nauki_4.webp` | gallery 3 | Unsplash | Paweł Malinowski | <https://unsplash.com/photos/a-view-of-a-large-city-with-tall-buildings-UwfHpAg_A6w> |
| 20 palac-kultury-i-nauki | `palac-kultury-i-nauki_5.webp` | gallery 4 | Pexels | Memory Lane | <https://www.pexels.com/photo/night-view-of-palace-of-culture-and-science-in-warsaw-35119863/> |
| 22 muzeum-sztuki-nowoczesnej | `muzeum-sztuki-nowoczesnej_hero.webp` | hero | Unsplash | Mathis Mauprivez | <https://unsplash.com/photos/an-aerial-view-of-a-building-in-a-city-S1W2Bf81qoE> |
| 25 buw | `buw_hero.webp` | hero | Pexels | Bogdan Krupin | <https://www.pexels.com/photo/flowerbeds-at-warsaw-university-library-garden-12028385/> |
| 25 buw | `buw_2.webp` | gallery 1 | Pexels | Anastasiia Lopushynska | <https://www.pexels.com/photo/warsaw-university-library-building-with-plants-growing-on-walls-12022296/> |
| 25 buw | `buw_3.webp` | gallery 2 | Pexels | Thomas Renaud | <https://www.pexels.com/photo/green-rooftop-walkway-in-warsaw-botanical-garden-35792463/> |
| 25 buw | `buw_4.webp` | gallery 3 | Pexels | vilnis Izotovs | <https://www.pexels.com/photo/drone-shot-of-house-roofs-and-green-grass-6054755/> |
| 26 sad-najwyzszy | `sad-najwyzszy_hero.webp` | hero | Unsplash | Nikolai Kolosov | <https://unsplash.com/photos/modern-building-with-a-large-stone-sculpture-outside-m11GGxMpsXs> |
| 26 sad-najwyzszy | `sad-najwyzszy_2.webp` | gallery 1 | Pexels | MART  PRODUCTION | <https://www.pexels.com/photo/a-historical-monument-in-front-of-a-building-7316991/> |
| 32 rynek-starego-miasta | `rynek-starego-miasta_hero.webp` | hero | Unsplash | Maksym Harbar | <https://unsplash.com/photos/people-walking-near-multicolored-building-okn8ZIjPMxI> |
| 32 rynek-starego-miasta | `rynek-starego-miasta_2.webp` | gallery 1 | Unsplash | Federico Mata | <https://unsplash.com/photos/the-mermaid-of-warsaw-statue-stands-in-the-city-center-LJ4pJtkMTzU> |
| 32 rynek-starego-miasta | `rynek-starego-miasta_3.webp` | gallery 2 | Unsplash | Sam | <https://unsplash.com/photos/a-group-of-people-walking-down-a-street-next-to-tall-buildings-WvNvTf5fb-k> |
| 32 rynek-starego-miasta | `rynek-starego-miasta_4.webp` | gallery 3 | Pexels | Egor Komarov | <https://www.pexels.com/photo/old-town-in-warsaw-17741460/> |
| 32 rynek-starego-miasta | `rynek-starego-miasta_5.webp` | gallery 4 | Pexels | Lesław Dzik | <https://www.pexels.com/photo/old-town-market-square-during-daytime-7115502/> |
| 36 bulwary-wislane | `bulwary-wislane_hero.webp` | hero | Pexels | Wojciech Wyszkowski | <https://www.pexels.com/photo/aerial-view-of-swietokrzyski-bridge-warsaw-poland-38487655/> |
| 36 bulwary-wislane | `bulwary-wislane_2.webp` | gallery 1 | Pexels | Radek Przybyłek | <https://www.pexels.com/photo/panoramic-view-of-warsaw-s-urban-skyline-31479746/> |
| 36 bulwary-wislane | `bulwary-wislane_3.webp` | gallery 2 | Pexels | Oleksiy Yeshtokyn,🌻🇺🇦🌻 | <https://www.pexels.com/photo/warsaw-s-national-stadium-and-vistula-river-view-38094410/> |
| 37 zlota-44 | `zlota-44_hero.webp` | hero | Pexels | urtimud.89 | <https://www.pexels.com/photo/aerial-view-warsaw-downtown-poland-18261856/> |
| 37 zlota-44 | `zlota-44_2.webp` | gallery 1 | Pexels | Wojciech Wyszkowski | <https://www.pexels.com/photo/modern-aerial-view-of-warsaw-s-skyline-38487664/> |
