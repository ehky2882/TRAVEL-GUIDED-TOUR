# Brasília batch 1: Atlas Studio BSB (31 singles), wired 2026-11-11

Source: contributor drop (Dropbox). 31 `output <Name> <lat>, <lon>` folders with scripts numbered 01–32 (there is no 03).
Each folder holds `NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt`, one MP3 (94–124 s, 3,472 s in all) and 2–6 photos
at 1200×900 WebP (124 delivered, 124 shipped, no byte duplicates). Non-ASCII letters in folder and file names arrive as
`#Uxxxx` escapes, so the assembler matches folders by **script number**.

`scripts/` holds both texts as delivered. `coordinates.tsv` lists slug · lat · lon · radius · category · city, as wired.
`coordinate-audit.txt` is the `check-coordinates.py --drop` run (on a copy with the escapes decoded — on the raw names
17 of 31 venues could not be geocoded at all).

`tools/wire_brasilia.py` is the assembler (`python3 -I wire_brasilia.py <unzipped drop> <stage dir>`), adapted from
`drafts/kuala-lumpur-batch1/tools/wire_kuala_lumpur.py`. Run it once only: it refuses colliding tour ids. Slugs carry a
**`bsb-` prefix**: audio at `audio/bsb-<slug>.mp3`, images at `images/bsb-<slug>_hero.webp`, `_2.webp`, … in the drop's order.

- **Maker:** Atlas Studio BSB 🇧🇷, platform `dozent`, handle `atlas.bsb`, uuid5 `atlas-maker:bsb`
  = `08918da7-8218-561a-b8ef-0b37907d4b87`.
- **Ids:** `atlas-tour:bsb:bsb-<slug>`, stops `atlas-stop:bsb:bsb-<slug>:1`.

## Coordinates
`check-coordinates.py --drop`: **3 GROSS, all cleared by hand** — Beirute (6.4 km) and Ernesto (8.4 km) because the
geocoder matched each venue's newer Asa Norte branch; the supplied points sit on the 109 Sul and CLS 115 Bloco C strips
the scripts name. Fundação Athos Bulcão (2.4 km) because the geocoder has its old CLS 404 address; the point is on the
W3 Sul at 510, the shop's current address (Correio Braziliense, 2025). 1 UNVERIFIABLE (Daniel Briand, 104 Norte Bloco A,
read by hand).

🔴 **BIAS: 20/24 north, median +17.0 m, p = 0.0015 — the upstream northward offset is STILL PRESENT** (absent in the
Kuala Lumpur drop a day earlier). Not corrected: small against these geofences.

**Moved onto the subject (owner OK, 2026-11-11), to the venue's own OpenStreetMap object:**
Hospital SARAH Lago Norte 146 m · Teatro Nacional 103 m · Conic 99 m.
Also proposed, but **left as supplied because already on the subject**: Congresso Nacional (the "153 m" was to the
reflecting pool, the point is inside the Congress polygon, 14 m from its centre) and Ponte JK (the "147 m" was to the
bridge's mid-point; the point is on the deck, 8 m off its centre line).

## Wiring
- **City:** `Brasília` for all 31 (Catetinho is 18 km south, in the Federal District). Country `Brazil`.
- **Geofence:** 20–30 m for cafés, bars, the foundation shop and the two sites under the Square of the Three Powers;
  40–60 m for buildings, churches and hotels; 80 m for the ICC (700 m long), SARAH, SQS 308 and Ponte JK. No overlaps;
  Casa de Chá and Espaço Lúcio Costa (49 m apart) were cut to 20 m each so they don't.
- **Bilingual titles:** `English | Portuguese` on the 20 of 31 where the names differ; venues and names used as-is keep one.
- **Text:** `longDescription` = hook + paragraph 3, `shortDescription` cut at 145 characters, `[beat]` stripped, one
  spelling fixed in the transcript ("Brasílians" → "Brasilians", Igrejinha; the audio is unchanged).
  Captions written by hand from each script's orientation paragraph.

## Architect tags (Job 5): 7 new names, one line in each list
João Filgueiras Lima (Lelé — SARAH, ICC) · Ruy Ohtake (Royal Tulip) · Alexandre Chan (Ponte JK) · BLOCO Arquitetos
(Mané Mercado) · Carlos Alberto Naves (Santuário Dom Bosco) · Sérgio Rocha, Marcelo Campelo (SQS 308 blocks; owner OK).
Existing tags used: Oscar Niemeyer (16 tours), Lúcio Costa (Torre de TV, Rodoviária), Roberto Burle Marx (Itamaraty, SQS 308).
**Not** tagged: Athos Bulcão, Marianne Peretti, Alfredo Ceschiatti, Bruno Giorgi, Tomie Ohtake (artists — Public Art/Art
instead) · Joaquim Cardozo, José Carlos Sussekind (engineers) · Lúcio Costa on the Conic and SQS 308 (he zoned them, did
not design the buildings) · Burle Marx on the Teatro (a foyer garden, not the subject).

## Places — for Edward, nothing created or joined
See `status/owner/place-brasilia.md`: Itamaraty 28 m, Cathedral 30 m, Brasília Palace Hotel 71 m, Congress 153 m,
ICC 164 m, each against a @ninosbuildings pin. `join-places.py --max-move 100` raised nothing involving the 31.

## Content notes (audio already recorded)
Lines that will date: Fundação Athos Bulcão "talk of a permanent home keeps coming and going" (a 2025 law grants it land
on the Eixo Monumental); Teatro Nacional "the rest has been coming back slowly"; Casa de Chá "reopened June 2024".
