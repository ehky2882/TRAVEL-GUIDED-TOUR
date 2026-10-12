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
