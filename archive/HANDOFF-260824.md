# HANDOFF — 2026-08-24 (session 106, local Mac, Stockholm)

**Owner: "i have new tours to upload - stockholm. with images, scripts and audio"**, then, unprompted and
important: *"one thing for stockholm unique to it - some names dont use capital letters in their swedish
names, bc of their grammar rules, not a mistake."* Branch `claude/stockholm-tours-upload`,
[PR #575](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/575). Content only — no Swift, no SQL.

## What shipped

**Atlas Studio STO** (`f2a33936-ad47-5787-a9ea-526c7daf475f` = uuid5 `atlas-maker:sto`, 🇸🇪):
**42 single-stop tours + 3 walks, 55 MP3s** (7,392 s ≈ 2h03m, third-largest drop to date), 162 images.
**Catalog 1467 → 1512 tours / 32 → 33 makers / 1829 → 1884 stops.**

The twelfth consecutive complete drop and the second needing **zero processing**: Dropbox `/scl/fo/`,
136 MB, downloaded first try with `dl=1`; all 162 images already 1200×900, all 55 MP3s already
44.1 kHz, 55 clean/TTS script pairs 1:1, nothing spare, nothing missing, zero byte-duplicates.

## 🔴 Swedish capitalisation is grammar, not a typo

Swedish capitalises only the **first word** of a proper-noun phrase. **`Gamla stan`,
`Stockholms stadsbibliotek`, `Kungliga slottet`, `Solna centrum`, `Tekniska högskolan`, `Kina slott`
are correct as delivered and must never be title-cased.**

**⚠️ The supplied script headers themselves carry the error** — they read `Solna Centrum`,
`Tekniska Högskolan` and `Gamla Stan 1859` while the **folder names have them right**. Titles here take
the folder casing. An institution that genuinely styles itself with a capital (`Moderna Museet`) keeps
it: follow the delivered source rather than applying a rule blindly in either direction.
Saved as memory `project-swedish-lowercase-names`.

## 🔴 Three coordinates wrong, all displaced due north

| tour | supplied point sat on | error | corrected to |
|---|---|---:|---|
| Carl Eldhs Ateljémuseum | Kräftriket, not Bellevueparken | **471 m N** | `59.3528674, 18.0516224` |
| Hammarbybacken | Sickla Kanalgata, across the water | **359 m N** | `59.3013028, 18.1096399` |
| Nationalmuseum | Nybrokajen, 200 m from the building | **180 m N** | `59.3284983, 18.0781214` |

At the 30 m geofence none of these would ever have fired. Each correction **reverse-geocodes onto the
venue itself** ("Carl Eldhs Ateljémuseum", "Hammarbybacken Skidhyra", "Södra Blasieholmshamnen").

## ✅ The upstream bias is gone — and that is the headline

`scripts/check-coordinates.py` reports **16/29 north, median +3.3 m, p = 0.71** — statistically
identical to the dead-centred NYC/London baseline, against Barcelona and Milan's **+10.3 m at
p = 5.6e-06**. **This is the first drop since the fault was diagnosed to come back clean.**

**⚠️ But all three gross errors are still northward, so upstream is HALF-fixed.** That is exactly what
the zoom theory predicts: a constant screen-pixel offset becomes a larger ground distance the further
out you zoom, so it survives for subjects you have to zoom out to find (471 m, 359 m, 180 m all sit in
the zoom ~14–15 band). **Report it as half-fixed, not fixed.**

## ⚠️ Five flags were false alarms, and two are worth keeping

- **Kaffekoppen** → **Stortorget 20**; the tool matched a same-name café 8.3 km away in Bromma. The
  hero's own street plate reads `Stortorget 20-18`.
- **Stockholm Stadshotell** → the point sits on a building OSM names **"Konung Oscar 1s Minne"**, and
  the script is about a widows' home funded as a rebuke to King Oscar I. **The hero's pediment reads
  `KONUNG OSCAR I:S MINNE`** — coordinate, script and photograph all confirming each other.
- **Observatorium** is Gunilla Bandolin's 2003 artwork on a pier, not the old scientific observatory
  the geocoder matched 4.7 km away; the script says so in its first line.

**A distance alone still proves nothing.** Reverse-geocoding the supplied point at zoom 18 is what
settles it.

## 🔴 Two heroes ship as delivered — owner decision, flagged for the partner

Owner, after seeing both: *"ship those as they are in the dropbox link. flag it for me so i can ask my
partner."* **Do not silently "fix" these.**

- **Ministry of Enterprise — the photograph is a different building.** It is the **Centralposthuset**,
  the old Royal Post Office, `KONGL. POST` carved into the stonework. The script says the ministry sits
  in *"an office building on Herkulesgatan… behind nothing more dramatic than a discreet sign"* and
  closes on *"the building itself gives nothing away."* The coordinate correctly resolves to
  **Herkulesgatan 22**. Coordinate and script agree; the photograph disagrees with both. Thyssen class.
- **Akalla — probably right, contradicts its narration.** A grand ochre escalator hall against a script
  saying *"no grand entrance hall, no famous vault, just raw rock and pictures of ordinary people"*,
  with a paragraph on Birgit Ståhl-Nyberg's ceramic scenes, none in frame.

**Neither stop shipped a second image**, so there is no in-folder alternative to promote.

## The hero audit

**All 56 opened and read against their scripts; 54 correct.** Many confirmed by **signage in frame**:
Saluhall, Rönnells, Kouthoofd (+ `Stora Nygatan 19`), Den Gyldene Freden (+ `Österlånggatan 47-51`),
Science Fiction Bokhandeln (+ `48`), Frantzén (+ `26`), Moderna Museet, ArkDes, Nationalmuseum,
Nordiska, Dramaten, Radisson, Svenskt Tenn, Hosoi, Savant, Tripletta.

**The look-alike density here is unusually high** and every cluster was checked deliberately:

- **Six cave metro stations**, each showing its own signature — Rådhuset's buried classical column
  base, Solna centrum's red sky over an unbroken spruce line, T-Centralen's blue vines (with blue-line
  destinations on the boards), Stadion's rainbow, Tekniska högskolan's hanging dodecahedron.
- **ArkDes vs Moderna Museet**, which share the Skeppsholmen complex — a classic Thyssen setup; both
  carry their own name on the building in frame.
- **Storkyrkan vs Sankt Jacobs kyrka**, and the **two Södermalm clifftops** (Skinnarviksberget's bare
  granite vs Mariaberget's grass and red fence).

## ⚠️ `walkingDistanceMeters` is deliberately null on Bedrock Caverns

That is the one validator warning this batch ships. **It is a metro itinerary, not a walk** — Akalla is
15 km from the centre — so any distance the app could print would be wrong. **A warning is better than
a fabricated number. Do not "fix" it by inventing one.**

## ⚠️ The Stockholm architect gap is large

**Only `Rafael Moneo` is in the vocabulary**, used by name on Moderna Museet. Absent, all shipping the
generic `Designed by a Master`: **Gunnar Asplund** (Skogskyrkogården, a UNESCO site, *and* Stockholms
stadsbibliotek), **Sigurd Lewerentz**, **Ragnar Östberg** (Stadshuset, Carl Eldhs studio), **Ivar
Tengbom** (Konserthuset, Sundbyberg Water Tower), **Isak Gustaf Clason** (Nordiska museet, Östermalms
Saluhall), **Ferdinand Boberg**, **Friedrich August Stüler**, **Fredrik Lilljekvist**, **Aron
Johansson**, **Fredrik Blom**, **Carl Fredrik Adelcrantz**, **Nicodemus Tessin the Younger**.

A `Models/Tag.swift` **code** change — and `validate-tours.swift` keeps its own copy, so **both must be
edited** or you get a wall of validator errors. Deliberately kept out of a content PR.
**Asplund is the strongest name the vocabulary is still missing.**

⚠️ Moneo also *extended* the ArkDes drill hall, but that tour is about Fredrik Blom's 1851–53 building,
so ArkDes carries `Designed by a Master` — the conservative reading of the Sullivan rule. One-line
change if the owner prefers otherwise.

## Verification

- **`swift scripts/validate-tours.swift` → 0 errors** across all 1,512 tours (Mac session, so the
  authoritative validator rather than a Python mirror). Two warnings: the deliberate
  `walkingDistanceMeters`, and a **pre-existing** VIA 57 West transcript gap — **confirmed present on
  `main` with this branch stashed**, which is the check worth repeating before blaming your own batch.
- uuid5 reverse-verified against **25 live makers** plus a Milan tour, stop, walk and walk-stop before
  minting STO. **0 duplicate tour ids, 0 duplicate stop ids** across 1,512/1,884/33.
- **0 slug collisions** against the live catalog and all 7,141 gh-pages paths, plus a slug-prefix sweep
  for banked content.
- Assets-first via **pure plumbing** (blobless fetch → temp `GIT_INDEX_FILE` → `hash-object -w` →
  `write-tree --missing-ok` → `commit-tree`): 0 of 217 target paths pre-existed, tree diff **exactly
  217 additions, 0 deletions, nothing outside `audio/` and `images/`** (gh-pages `4a31a56a`).
  The push refspec was guarded on a non-empty variable and the message passed via `-F`, per the
  session-97 branch-deletion incident.
- **162 uploaded = 162 referenced, 0 orphaned.**
- `Tours.json` byte-stable under a Python re-dump before editing; diff **2,184 insertions / 0 deletions**.

## Notes

- **4 tours ship outside Stockholm municipality** with their own `city`, per the Montserrat/Opera
  convention: Drottningholm → **Ekerö**, Artipelag → **Gustavsberg**, Yasuragi → **Nacka**, Sundbyberg
  Water Tower → **Sundbyberg**.
- **Sensitivity.** The Stockholm Bloodbath runs through both Stortorget and Kaffekoppen. **No mortality
  figure appears in any title, caption or description** — Kaffekoppen's caption is deliberately taken
  from **paragraph 2** for exactly this reason. Same convention for the Vasa's loss of life.
- **5 tours ship hero-only** (Skinnarviksberget, Mariaberget, Ministry of Enterprise, Rönnells
  Antikvariat, Sundbyberg Water Tower) — backfillable without touching audio.
- All images owner-supplied, so **no CREDITS rows**.
- **Bar Montan and Hosoi are ~40 m apart** in Slakthusområdet — two genuinely distinct venues at
  building scale, which `MapClustering.needsDisambiguation`'s backstop handles. Not a data fault.
- ⚠️ **The gh-pages Pages deploy is slow** — the site is ~4 GB and the build ran well past 20 minutes
  while still reporting `building`. That is the documented lag, not a failure; verify by hashing the
  live bytes against the uploaded blob SHAs rather than trusting the push or a 404.
