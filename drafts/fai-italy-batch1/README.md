# Italy audio scripts — batch 1 (86 single-stop tours)

Written 2026-11-21 (77 tours) and 2026-11-24 (nine more, 78-86). One tour per place. `tours.csv` is the master list: number, slug, title, city, region and coordinates for all 86.

**No script mentions FAI** (owner, 2026-11-24: the tours are not made for FAI and must not read as promotion). `tools/defai.py` rewrote the 52 sentences that did, and `tools/build.py` output was re-checked: no `FAI` in any clean or TTS-safe file. The **sources and fact-check notes** in each `.md` still cite FAI's website where it was the source, because those notes exist for fact-checking, not for recording.

## What's in each tour

- `scripts/NN_slug.md` — clean script, TTS-safe script, respellings table, **sources read**, and **fact-check notes** (conflicts between sources, single-source facts, unsourced flourishes to soften).
- `scripts/NN_slug_clean.txt` — the clean script, with one `[beat]` authoring marker.
- `scripts/NN_slug_tts-safe.txt` — phonetic respelling (lowercase, no hyphens), no brackets or markup, `[beat]` removed (paragraph break instead), every number and year spelled out, title respelled where it would trip TTS.

Every script follows the `atlas-audio-tour` skill: British conversational voice, hook → position → 2–4 featured items with gift details → pivot → one beat → a specific explore-further close. No script says the narrator is an architect.

## Rules applied

- Primary sources were fetched and read before each script (official sites first, Wikipedia second). Sources are listed per tour.
- Where sources disagree, the script uses the safer wording and the note records the conflict.
- Facts I could not source were removed, not guessed. A few remaining narrator's opinions or general-knowledge glosses are flagged in the notes.
- `tools/build.py` regenerates every output from `src/*.json` and **fails** if a clean script contains a digit, or a TTS-safe script contains brackets, digits, hyphens or ALL-CAPS words.

## Before recording

- Opening hours and access were **not** written into scripts except where a closure matters (Giganti della Sila closed until further notice; Saline Conti Vecchi historic rooms closed; Teatro Massimo Bellini works in 2026; Castel Savoia, Villa Pisani, Buonconsiglio and others single-sourced because official sites were down). Check each tour's notes.
- Several tours are single-sourced (Wikipedia only) because the official site failed: Castel Savoia, Buonconsiglio, Villa Pisani, Ponte Vecchio Bassano, Rotonda a Mare, Troia, Teatro Margherita, Castello Tramontano, San Giovanni degli Eremiti, Sant'Apollinare in Classe, Palazzo di Teodorico, Tellaro.

## Changes on 2026-11-24

- **FAI removed from every script** (see above).
- **Nine new tours:** 78 Palazzo Mondadori, 79 Ville Jacques Couëlle, 80 Castello di Sammezzano, 81 Antica Edicola dei Giornali (Mantua; the owner's 'Antica Edicola Liberty' — the sources call it neo-Gothic), 82 Piazza del Duomo Trento, 83 Doge's Palace, 84 Buco del Piombo, 85 Villa Necchi Campiglio, 86 Idrovora di Sassu.
- **Four places the owner listed were already tours**, so they were not written twice; their coordinates were updated to the owner's: 05 Villa Taranto (now the entrance on Via Vittorio Veneto), 11 Villa Fogazzaro Roi, 20 Traghetto di Leonardo, 51 Torre e Casa Campatelli.
- **Idrovora di Sassu coordinate NOT the owner's.** The supplied 39.93087, 8.56061 reverse-geocodes to Cabras, about 12 km north; `tours.csv` uses the OpenStreetMap node 'Idrovora Sassu' on the SP 49 at Arborea (39.82326, 8.57722), which matches every source. Confirm with the owner.
- `shortlist.csv` is the original research list and is no longer updated; use `tours.csv`.

## Index

| # | Tour | City | Region | Words | Files |
|---|---|---|---|---|---|
| 01 | Castello della Manta | Manta | Piemonte | 395 | `01_castello-della-manta` |
| 02 | Castello e Parco di Masino | Caravino | Piemonte | 347 | `02_castello-e-parco-di-masino` |
| 03 | Collezione Enrico a Villa Flecchia | Magnano | Piemonte | 323 | `03_collezione-enrico-villa-flecchia` |
| 04 | Sacra di San Michele | Sant'Ambrogio di Torino | Piemonte | 363 | `04_sacra-di-san-michele` |
| 05 | Giardini Botanici di Villa Taranto | Verbania | Piemonte | 338 | `05_villa-taranto` |
| 06 | Castel Savoia | Gressoney-Saint-Jean | Valle d'Aosta | 367 | `06_castel-savoia` |
| 07 | Villa Della Porta Bozzolo | Casalzuigno | Lombardia | 346 | `07_villa-della-porta-bozzolo` |
| 08 | Villa e Collezione Panza | Varese | Lombardia | 349 | `08_villa-e-collezione-panza` |
| 09 | Casa Macchi | Morazzone | Lombardia | 301 | `09_casa-macchi` |
| 10 | Monastero di Torba | Gornate Olona | Lombardia | 346 | `10_monastero-di-torba` |
| 11 | Villa Fogazzaro Roi | Valsolda | Lombardia | 335 | `11_villa-fogazzaro-roi` |
| 12 | Villa del Balbianello | Tremezzina | Lombardia | 350 | `12_villa-del-balbianello` |
| 13 | La Velarca | Tremezzina | Lombardia | 332 | `13_la-velarca` |
| 14 | Palazzo Moroni | Bergamo | Lombardia | 339 | `14_palazzo-moroni` |
| 15 | Castel Grumello | Montagna in Valtellina | Lombardia | 318 | `15_castel-grumello` |
| 16 | Villa Carlotta | Tremezzina | Lombardia | 329 | `16_villa-carlotta` |
| 17 | Ponte San Michele | Paderno d'Adda | Lombardia | 330 | `17_ponte-san-michele` |
| 18 | Villa Reale di Monza | Monza | Lombardia | 312 | `18_villa-reale-di-monza` |
| 19 | Ippodromo San Siro and Leonardo's Horse | Milano | Lombardia | 324 | `19_san-siro-leonardos-horse` |
| 20 | Traghetto di Leonardo | Imbersago | Lombardia | 320 | `20_traghetto-di-leonardo` |
| 21 | Rocca di Lonato and Casa del Podestà | Lonato del Garda | Lombardia | 327 | `21_rocca-di-lonato` |
| 22 | Aula del Simonino | Trento | Trentino-Alto Adige | 342 | `22_aula-del-simonino` |
| 23 | Castello di Avio | Avio | Trentino-Alto Adige | 315 | `23_castello-di-avio` |
| 24 | Castello del Buonconsiglio | Trento | Trentino-Alto Adige | 307 | `24_castello-del-buonconsiglio` |
| 25 | MUSE, Museo delle Scienze | Trento | Trentino-Alto Adige | 323 | `25_muse-trento` |
| 26 | Mart, Rovereto | Rovereto | Trentino-Alto Adige | 275 | `26_mart-rovereto` |
| 27 | Ponte del Diavolo, Cividale del Friuli | Cividale del Friuli | Friuli-Venezia Giulia | 317 | `27_ponte-del-diavolo-cividale` |
| 28 | Basilica di Aquileia | Aquileia | Friuli-Venezia Giulia | 313 | `28_basilica-di-aquileia` |
| 29 | Mausoleo di Teodorico | Ravenna | Emilia-Romagna | 322 | `29_mausoleo-di-teodorico` |
| 30 | Sant'Apollinare in Classe | Ravenna | Emilia-Romagna | 351 | `30_sant-apollinare-in-classe` |
| 31 | Palazzo di Teodorico, Ravenna | Ravenna | Emilia-Romagna | 297 | `31_palazzo-di-teodorico` |
| 32 | Villa dei Vescovi | Torreglia | Veneto | 368 | `32_villa-dei-vescovi` |
| 33 | Santuario Madonna della Corona | Ferrara di Monte Baldo | Veneto | 361 | `33_madonna-della-corona` |
| 34 | Palazzo della Ragione, Padua | Padova | Veneto | 356 | `34_palazzo-della-ragione` |
| 35 | San Giorgio Maggiore | Venezia | Veneto | 313 | `35_san-giorgio-maggiore` |
| 36 | Caffè Pedrocchi, Padua | Padova | Veneto | 337 | `36_caffe-pedrocchi` |
| 37 | Casa del Petrarca, Arquà Petrarca | Arquà Petrarca | Veneto | 320 | `37_casa-del-petrarca` |
| 38 | Giardini della Biennale | Venezia | Veneto | 333 | `38_giardini-della-biennale` |
| 39 | Villa Pisani, Stra | Stra | Veneto | 331 | `39_villa-pisani` |
| 40 | Ca' Giustinian, Venice | Venezia | Veneto | 309 | `40_ca-giustinian` |
| 41 | Ca' Pesaro, Venice | Venezia | Veneto | 306 | `41_ca-pesaro` |
| 42 | Monte Fontana Secca | Quero Vas / Seren del Grappa | Veneto | 362 | `42_monte-fontana-secca` |
| 43 | Ponte Vecchio, Bassano del Grappa | Bassano del Grappa | Veneto | 369 | `43_ponte-vecchio-bassano` |
| 44 | Casa e Collezione Laura | Ospedaletti | Liguria | 300 | `44_casa-e-collezione-laura` |
| 45 | Antica Barberia Giacalone, Genoa | Genova | Liguria | 287 | `45_antica-barberia-giacalone` |
| 46 | Abbazia di San Fruttuoso | Camogli | Liguria | 305 | `46_abbazia-di-san-fruttuoso` |
| 47 | Casa Carbone, Lavagna | Lavagna | Liguria | 319 | `47_casa-carbone` |
| 48 | Villa Rezzola, Lerici | Lerici | Liguria | 326 | `48_villa-rezzola` |
| 49 | Tellaro | Lerici | Liguria | 313 | `49_tellaro` |
| 50 | Teatrino di Vetriano | Pescaglia | Toscana | 322 | `50_teatrino-di-vetriano` |
| 51 | Torre e Casa Campatelli, San Gimignano | San Gimignano | Toscana | 313 | `51_torre-e-casa-campatelli` |
| 52 | Abbazia di San Galgano | Chiusdino | Toscana | 345 | `52_abbazia-di-san-galgano` |
| 53 | Villa Gamberaia, Settignano | Firenze | Toscana | 362 | `53_villa-gamberaia` |
| 54 | Bosco di San Francesco, Assisi | Assisi | Umbria | 319 | `54_bosco-di-san-francesco` |
| 55 | Ponte delle Torri, Spoleto | Spoleto | Umbria | 328 | `55_ponte-delle-torri` |
| 56 | Orto sul Colle dell'Infinito, Recanati | Recanati | Marche | 290 | `56_orto-sul-colle-dell-infinito` |
| 57 | Rotonda a Mare, Senigallia | Senigallia | Marche | 326 | `57_rotonda-a-mare` |
| 58 | Villa Gregoriana, Tivoli | Tivoli | Lazio | 347 | `58_villa-gregoriana` |
| 59 | Parco degli Acquedotti, Rome | Roma | Lazio | 328 | `59_parco-degli-acquedotti` |
| 60 | Baia di Ieranto | Massa Lubrense | Campania | 298 | `60_baia-di-ieranto` |
| 61 | Duomo di Salerno | Salerno | Campania | 327 | `61_duomo-di-salerno` |
| 62 | Abbazia di Santa Maria di Cerrate | Lecce | Puglia | 327 | `62_abbazia-di-cerrate` |
| 63 | Cattedrale di Troia | Troia | Puglia | 337 | `63_cattedrale-di-troia` |
| 64 | Teatro Margherita, Bari | Bari | Puglia | 333 | `64_teatro-margherita-bari` |
| 65 | Teatro Petruzzelli, Bari | Bari | Puglia | 305 | `65_teatro-petruzzelli` |
| 66 | Fontana Greca, Gallipoli | Gallipoli | Puglia | 352 | `66_fontana-greca-gallipoli` |
| 67 | Casa Noha, Matera | Matera | Basilicata | 312 | `67_casa-noha` |
| 68 | Castello Tramontano, Matera | Matera | Basilicata | 332 | `68_castello-tramontano` |
| 69 | I Giganti della Sila | Spezzano della Sila | Calabria | 342 | `69_giganti-della-sila` |
| 70 | Giardino della Kolymbethra, Agrigento | Agrigento | Sicilia | 328 | `70_giardino-della-kolymbethra` |
| 71 | Giardino Pantesco Donnafugata, Pantelleria | Pantelleria | Sicilia | 321 | `71_giardino-pantesco-donnafugata` |
| 72 | Tempio di Segesta | Calatafimi-Segesta | Sicilia | 333 | `72_tempio-di-segesta` |
| 73 | Fontana Pretoria, Palermo | Palermo | Sicilia | 356 | `73_fontana-pretoria` |
| 74 | San Giovanni degli Eremiti, Palermo | Palermo | Sicilia | 327 | `74_san-giovanni-degli-eremiti` |
| 75 | Teatro Massimo Bellini, Catania | Catania | Sicilia | 327 | `75_teatro-massimo-bellini` |
| 76 | Batteria Militare Talmone, Palau | Palau | Sardegna | 298 | `76_batteria-militare-talmone` |
| 77 | Saline Conti Vecchi, Assemini | Assemini | Sardegna | 306 | `77_saline-conti-vecchi` |
| 78 | Palazzo Mondadori, Segrate | Segrate | Lombardia | 352 | `78_palazzo-mondadori` |
| 79 | Ville Jacques Couëlle, Monti Mannu | Arzachena | Sardegna | 371 | `79_ville-jacques-couelle` |
| 80 | Castello di Sammezzano | Reggello | Toscana | 342 | `80_castello-di-sammezzano` |
| 81 | Antica Edicola dei Giornali, Mantua | Mantova | Lombardia | 354 | `81_antica-edicola-mantova` |
| 82 | Piazza del Duomo, Trento | Trento | Trentino-Alto Adige | 365 | `82_piazza-del-duomo-trento` |
| 83 | Doge's Palace, Venice | Venezia | Veneto | 383 | `83_palazzo-ducale-venezia` |
| 84 | Buco del Piombo, Erba | Erba | Lombardia | 353 | `84_buco-del-piombo` |
| 85 | Villa Necchi Campiglio, Milan | Milano | Lombardia | 371 | `85_villa-necchi-campiglio` |
| 86 | Idrovora di Sassu, Arborea | Arborea | Sardegna | 356 | `86_idrovora-di-sassu` |

Zips in `zips/`: one per region, with a folder per city inside, each holding the three files per tour.
