# Brasília batch 1: 32 single-stop audio scripts (drafted 2026-11-08)

Written from the Architecture Hunter–style Brasília guide drafted in the same session, in the Atlas British
voice (`atlas-audio-tour` skill) and the house format of `drafts/fukuoka-batch1/` (clean text keeps `[beat]` and
digit years; TTS-safe spells numbers out and drops the beat). **No audio, no images, nothing wired** — these are
scripts only. Every venue's primary sources were fetched and read before it was written; they are listed in
each tour's `.md`.

`scripts/` holds, per tour: `NN_<slug>_clean.txt`, `NN_<slug>_tts-safe.txt`, and `NN_<slug>.md` (metadata,
sources, both texts). `coordinates.tsv` lists slug · lat · lon · category · Google Maps name.
`tools/build.py` regenerates all three from `tools/scripts_*.py`: `python3 -I tools/build.py`. Edit the clean
text there, never the generated files. The respelling table lives in `build.py`.

| # | Category | Google Maps name | Coordinate (WGS-84) | Words |
|---|---|---|---|---|
| 01 | Stay | Brasília Palace Hotel | `-15.788682, -47.830524` | 355 |
| 02 | Stay | Royal Tulip Brasília Alvorada | `-15.787059, -47.829462` | 308 |
| 03 | Stay | Hotel Nacional | `-15.79566, -47.886801` | 334 |
| 04 | Dine | Mangai | `-15.817433, -47.83694` | 320 |
| 05 | Dine | Daniel Briand Pâtissier & Chocolatier | `-15.777001, -47.882712` | 328 |
| 06 | Dine | Mané Mercado - Complexo Gastronômico | `-15.783218, -47.902032` | 286 |
| 07 | Drink | Beirute | `-15.819818, -47.907474` | 308 |
| 08 | Drink | Ernesto Cafés Especiais | `-15.830702, -47.924234` | 316 |
| 09 | Drink | Clube do Choro de Brasília | `-15.789312, -47.899141` | 322 |
| 10 | Drink | Casa de Chá | `-15.800775, -47.86081` | 337 |
| 11 | Shop | Feira da Torre de TV | `-15.790332, -47.894696` | 318 |
| 12 | Shop | Fundação Athos Bulcão | `-15.8178, -47.9135` ⚠️ | 326 |
| 13 | Visit | Catedral Metropolitana Nossa Senhora Aparecida | `-15.798344, -47.875546` | 327 |
| 14 | Visit | Palácio Itamaraty | `-15.800668, -47.867292` | 325 |
| 15 | Visit | Congresso Nacional | `-15.799524, -47.864095` | 327 |
| 16 | Visit | Santuário Dom Bosco | `-15.800573, -47.894771` | 326 |
| 17 | Visit | Igrejinha Nossa Senhora de Fátima | `-15.814, -47.903761` | 334 |
| 18 | Visit | Memorial JK | `-15.784169, -47.913393` | 311 |
| 19 | Visit | Museu Nacional Honestino Guimarães | `-15.797392, -47.878162` | 311 |
| 20 | Visit | Teatro Nacional Cláudio Santoro | `-15.791896, -47.880328` | 348 |
| 21 | Visit | Instituto Central de Ciências | `-15.763149, -47.86958` | 316 |
| 22 | Visit | Hospital SARAH - Lago Norte | `-15.752709, -47.82932` | 298 |
| 23 | Visit | Centro Cultural Banco do Brasil | `-15.813655, -47.838286` | 329 |
| 24 | Visit | Catetinho | `-15.947636, -47.988451` | 303 |
| 25 | Observe | SQS 308 | `-15.814722, -47.905319` | 329 |
| 26 | Observe | Torre de TV | `-15.790711, -47.892972` | 316 |
| 27 | Observe | Rodoviária do Plano Piloto | `-15.793846, -47.883366` | 328 |
| 28 | Observe | Centro Comercial Boulevard (CONIC) | `-15.795721, -47.884681` | 331 |
| 29 | Observe | Ermida Dom Bosco | `-15.798337, -47.809503` | 325 |
| 30 | Observe | Ponte Juscelino Kubitschek | `-15.823784, -47.829451` | 306 |
| 31 | Observe | Pontão do Lago Sul | `-15.825531, -47.871534` | 279 |
| 32 | Observe | Espaço Cultural Lúcio Costa - Maquete de Brasília | `-15.801094, -47.861677` | 330 |

## What the primary sources changed (vs. the first-pass guide list)

- **Feitiço Mineiro — dropped.** Closed for good in early 2021 after 31 years (Correio Braziliense, 21 Jan 2021).
- **Pinella — dropped.** Announced its closure in June 2026 after 15 years (Correio Braziliense).
- **Hotel Nacional — no longer a stay.** Emptied by court order and closed in June 2020; restoration works were
  announced for late 2025. The script is written as a look-from-the-pavement stop.
- **Beirute — moved to the original.** The 1966 bar is at CLS 109 Sul; the 107 Norte branch (the first-pass pin)
  only opened in 2017.
- **Ernesto — moved to the original.** Opened July 2011 at CLS 115 Sul; 107 Norte is a branch.
- **Fundação Athos Bulcão — moved.** The shop left CLS 404 Sul (where OpenStreetMap still has it) for CRS 510
  Bloco B Loja 51, W3 Sul. ⚠️ **Its coordinate is APPROXIMATE (±150 m)**: no map source places the new unit.
  Check the pin by hand before wiring.
- **Santuário Dom Bosco** — architect is Carlos Alberto Naves; the blue glass is by Hubert Van Doorne. Only the
  chandelier is Murano glass.
- **Congresso** — the upturned bowl is the Chamber of Deputies, the dome the Senate (pt.wikipedia's infobox has
  them the other way round; the Câmara's own pages agree with the script).
- **Teatro Nacional** — closed in 2014 and partly reopened in December 2024 (Martins Pena hall first); the script
  says to check which halls are open.
- **Catetinho** — Dilermando Reis was a guitarist (*violonista*), not a violinist.

## Lines that will date

Hotel Nacional's restoration (announced late 2025); Teatro Nacional's phased reopening; Casa de Chá "more than
forty five thousand people in its first hundred days" (2024); Ernesto "not yet fifteen years old"; the Feira
craftsman "in 2022 … thirty five years"; Fundação Athos Bulcão's address; Sarah Lago Norte visiting.

## Before wiring

Coordinates come from OpenStreetMap (Nominatim / Photon), building-level matches. Run
`python3 scripts/check-coordinates.py` on the drop as usual (§ Automation rule 8b), and
`check-place-candidates.py` + `join-places.py --max-move 100` after merge: several of these subjects
(Catedral, Congresso, Itamaraty, Torre de TV, Ponte JK, Memorial JK) are very likely already pinned by creators.
