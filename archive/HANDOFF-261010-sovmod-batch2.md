# HANDOFF 2026-10-10: SovMod batch 2 (53 tours) + Atlas Studio TAO (Qingdao)

**What shipped:** 53 more single-stop audio tours for **SovMod** 🗿 and one for a new studio, **Atlas Studio TAO** 🇨🇳 (Qingdao), the 42nd.
- **Maker:** TAO is platform `dozent`, handle `atlas.tao`. Its id is uuid5 `atlas-maker:tao` = `ed55028a-027b-5f5a-819e-f7bdaaca813a`. SovMod's maker is unchanged.
- **Ids:** tours use `atlas-tour:<sovmod|tao>:<slug>`, and stops use `atlas-stop:<sovmod|tao>:<slug>:1`. The slug is the source script's filename with hyphens.
- **Catalogue:** tours went from 1879 to 1933, makers from 645 to 646, cities from 939 to 961 and countries from 101 to 103. The new countries are **Armenia** (10 tours) and **Cuba** (3).

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner) with 54 folders in the SovMod format. The zip downloads straight into the container with `dl=1`. One folder name (Pash-Aparan) is too long for `unzip`, so extract with Python's `zipfile`.
- **Photos:** 149 in all, every one 1200×900, with no duplicates.
- **Audio:** 102–137 s each. Every file was transcript-matched against its own script (faster-whisper tiny.en, first 60 s, decoded with ffmpeg to an array). Scores ran 0.82–0.98.
- **Assembler rules** are the same as batch 1 and Auckland:
  - **Caption:** the first sentence of paragraph 2.
  - **Descriptions:** `longDescription` is the hook plus paragraph 3. `shortDescription` is cut at 145 characters.
  - **Geofence:** 60 m for history, monuments, parks and districts; 40 m for buildings.

**Triage and the contributor's rulings** (artifact "SovMod Batch 2 Triage", https://claude.ai/artifact/5EtCNmKWxBwca8MjDYKz5f):
- **"Monument to the Victims of the Genocide", Yerevan:** the title comes from the folder name, which matches Google Maps. The script and audio describe the Armenian–Arab gratitude monument (2009–12) at the same point. The slug keeps the script's name, `armenian-arab-friendship-monument`.
- **Eshba (Sukhumi) and The Pearl Divers (Pitsunda), both in Abkhazia:** the country is `Georgia`, following the Khankendi precedent of using OSM's label.
- **Pripyat Ferris Wheel:** pinned, even though the Exclusion Zone is closed. The Prypiat Entrance Stele is the precedent.
- **FOCSA, Havana:** pinned, even though it was built in 1954–56, before the revolution. The contributor did not answer this one explicitly; it went in on the triage recommendation to pin.
- **Qingdao Observatory:** this is German colonial, not socialist-era. The contributor asked for it under a **new Atlas studio for the city** rather than SovMod, hence TAO.

**Coordinates.** `check-coordinates.py --drop --city` was run per city, one city at a time.
- **No GROSS was real.** Salaspils and Zagrepčanka were flagged because the geocoder matched other things with the same name 3 km away (a Zagreb brownfield called Zagrepčanka). The supplied points are 28 m and 22 m from OSM's venues.
- **The UNVERIFIABLEs were checked by hand.** They sit 7–80 m from OSM's named features, or land on the right building.
- **Moved:** Qingdao. The folder point was 310 m off, so it now uses the script header's coordinate, which is 6 m from OSM's 胶澳皇家观象台旧址.
- **Iron Fountain:** the script header's coordinate is 2.9 km off, but the folder point (used) is 17 m from OSM.
- ⚠️ **Zvartnots Old Terminal 1 is unverified.** The supplied point is 600 m from the airport's reference point. OSM has no named node for the old round terminal, and Overpass is blocked from the container.
- **Musa Dagh** is on the hilltop at the edge of the village, consistent with the script. OSM has no node for the monument.

**Places:** `check-place-candidates` paired **Blok 23** with @urbanistar's "Block 23, New Belgrade" pin at 22 m (TIGHT). **Richard Sorge** is 163 m from @rasulal's "Richard Sorge Park" pin. Both are on Edward's board as `place-sovmod-batch2`. `join-places --max-move 100` found 0 joins.

**gh-pages:** one commit, `54caceb`, with 203 added files (54 audio, 149 images) and nothing modified or removed. It was built in a blobless shallow clone.

**Not done:**
- **Architect tags.** About 30 architects named in the scripts have no tag yet: Israelyan, Tarkhanyan, Svetlana Kana Radević, Richter / Centar 51, Marko Mušič, Raine Karp, Karel Filsak, Boris Čipan, Florian Yuriev, Stojan Maksimović, Mihailo Janković and others. This is a separate Job 5 follow-up. Cinema Moskva could take the existing Mikhail Vinogradov tag, and the Pyramid of Tirana the existing MVRDV tag; neither was applied, to keep this PR content-only.
