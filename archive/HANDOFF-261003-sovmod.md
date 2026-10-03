# HANDOFF 2026-10-03: SovMod launches (72 original audio tours)

**What shipped:** a new creator, **SovMod** 🗿. It is not an Atlas studio and not a pinned creator. Its 72 single-stop audio tours cover socialist-era architecture and monuments in 21 countries.
- **Maker:** platform `dozent`, handle `sovmod`. The maker id is uuid5 `atlas-maker:sovmod` (NAMESPACE_URL).
- **Ids:** tours use `atlas-tour:sovmod:<slug>`; stops use `atlas-stop:sovmod:<slug>:1`.
- **Name:** the contributor (arthur.yung) first proposed "Socialist Modernism", then renamed it to SovMod, because Socialist Modernism is the name of BACU's existing heritage project.
- **Catalogue:** tours went 1752 → 1824, cities 876 → 919, and countries 93 → 101. The eight new countries are Belarus, Bulgaria, Georgia, Kosovo, Moldova, Montenegro, North Macedonia and Ukraine.

**Source:** a Dropbox drop with one folder per site, named `output <Name> <lat>, <lon>` under country folders. Each folder holds an MP3, a `_clean.txt` script, a `_tts-safe.txt` script and 1–7 webp photos at 1200×900.
- **Photos:** 169 in all. The contributor says they are royalty-free or public domain.
- **Audio:** 128k mono MP3s, 100–150 s each. Every file was transcript-matched to its own script with faster-whisper tiny.en.
- ⚠️ **A first-30-seconds match can come back empty.** Four files scored 0.02 against their own script. Re-transcribing 45–60 s showed all four were correct.

**Assembler** (scratchpad, `wire_sovmod.py`) follows the Boston/Miami rules:
- **Transcript:** the clean script without its header line or `[beat]` markers. Four scripts have no header (Jasenovac, Vukovar, Petrova Gora, Moslavina), so their first line is the hook.
- **Caption:** the first sentence of paragraph 2, which is the standpoint in every script.
- **Descriptions:** `shortDescription` is the transcript cut to 145 characters. `longDescription` is the hook paragraph plus paragraph 3.
- **Geofence:** 60 m for history/memorial sites and 40 m for buildings.
- **Titles, categories and tags** come from the triage (artifact "Socialist Modernism Triage"). Henselmann is the only architect tag used.

**Coordinates.** `check-coordinates.py --drop` was run per country, plus a slow reverse-geocode of all 72 points. Nominatim throttled when two runs overlapped; run them one at a time.
- **Eight were wrong by 280 m to 1.8 km** and were moved to their OpenStreetMap venue:

  | Site | Was off by |
  |---|---|
  | Ugala | 400 m |
  | Avas TV Tower | 400 m |
  | Chorsu | 710 m (now the marketplace centroid) |
  | Costinești | 460 m |
  | Makedonium | 660 m |
  | Tuzla bank | 570 m |
  | Georgia–Russia Friendship Monument | 280 m |
  | Dom-Korabl | 1.8 km |

  Most of the bad ones were degree-minute-second conversions (`…3333`, `…8889`). The bias was not uniform north.
- **Spine:** Dudik was ruled `wikidata-elsewhere`: Wikidata's point is rounded, and OpenStreetMap's park is 35 m from ours. The REVIEW rows are a wrong Wikidata match (Eastern City Gate → a cemetery) and three large sites at 125–163 m.

**Kept at the contributor's request:**
- **Prypiat Entrance Stele.** The Exclusion Zone has been closed to visitors since 2022.
- **We Are Our Mountains**, at the supplied point, with city `Khankendi`, country `Azerbaijan` (OpenStreetMap's labels).

**For Edward:** Kosmaj (22 m), Avala (34 m) and Genex (93 m) sit on existing creator pins. The contributor prefers separate entries. This is on the board as `status/owner/place-sovmod-belgrade-trio.md`.

**Not done:**
- **Architect tags.** Bogdan Bogdanović appears four times, plus Stoilov, Miletsky, Džamonja and Živković. Job 5 can add them.
- **Hotel Cosmos audio** says "on this walk".
- **Cafenea Guguță.** A 2018 court ruling allowed its demolition, so its current state is unverified.
