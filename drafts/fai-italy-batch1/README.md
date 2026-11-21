# FAI Italy audio scripts — batch 1 (77 single-stop tours)

Written 2026-11-21 from the 77-place FAI shortlist (`shortlist.csv`, with coordinates). One tour per place.

## What's in each tour

- `scripts/NN_slug.md` — clean script, TTS-safe script, respellings table, **sources read**, and **fact-check notes** (conflicts between sources, single-source facts, unsourced flourishes to soften).
- `scripts/NN_slug_clean.txt` — the clean script, with one `[beat]` authoring marker.
- `scripts/NN_slug_tts-safe.txt` — phonetic respelling (lowercase, no hyphens), no brackets or markup, `[beat]` removed (paragraph break instead), every number and year spelled out, title respelled where it would trip TTS.

Every script follows the `atlas-audio-tour` skill: British conversational voice, hook → position → 2–4 featured items with gift details → pivot → one beat → a specific explore-further close. No script says the narrator is an architect.

## Rules applied

- Primary sources were fetched and read before each script (official sites and FAI pages first, Wikipedia second). Sources are listed per tour.
- Where sources disagree, the script uses the safer wording and the note records the conflict.
- Facts I could not source were removed, not guessed. A few remaining narrator's opinions or general-knowledge glosses are flagged in the notes.
- `tools/build.py` regenerates every output from `src/*.json` and **fails** if a clean script contains a digit, or a TTS-safe script contains brackets, digits, hyphens or ALL-CAPS words.

## Before recording

- Opening hours and access were **not** written into scripts except where a closure matters (Giganti della Sila closed until further notice; Saline Conti Vecchi historic rooms closed; Teatro Massimo Bellini works in 2026; Castel Savoia, Villa Pisani, Buonconsiglio and others single-sourced because official sites were down). Check each tour's notes.
- Several tours are single-sourced (Wikipedia only) because the official site failed: Castel Savoia, Buonconsiglio, Villa Pisani, Ponte Vecchio Bassano, Rotonda a Mare, Troia, Teatro Margherita, Castello Tramontano, San Giovanni degli Eremiti, Sant'Apollinare in Classe, Palazzo di Teodorico, Tellaro.

## Index

| # | Tour | Region | Words | Notes | Files |
|---|---|---|---|---|---|
| 01 | Castello della Manta | Piemonte | 386 | 5 | `01_castello-della-manta` |
| 02 | Castello e Parco di Masino | Piemonte | 348 | 5 | `02_castello-e-parco-di-masino` |
| 03 | Collezione Enrico a Villa Flecchia | Piemonte | 317 | 3 | `03_collezione-enrico-villa-flecchia` |
| 04 | Sacra di San Michele | Piemonte | 363 | 6 | `04_sacra-di-san-michele` |
| 05 | Giardini Botanici di Villa Taranto | Piemonte | 338 | 5 | `05_villa-taranto` |
| 06 | Castel Savoia | Valle d'Aosta | 367 | 4 | `06_castel-savoia` |
| 07 | Villa Della Porta Bozzolo | Lombardia | 339 | 5 | `07_villa-della-porta-bozzolo` |
| 08 | Villa e Collezione Panza | Lombardia | 344 | 6 | `08_villa-e-collezione-panza` |
| 09 | Casa Macchi | Lombardia | 295 | 3 | `09_casa-macchi` |
| 10 | Monastero di Torba | Lombardia | 342 | 6 | `10_monastero-di-torba` |
| 11 | Villa Fogazzaro Roi | Lombardia | 337 | 5 | `11_villa-fogazzaro-roi` |
| 12 | Villa del Balbianello | Lombardia | 344 | 5 | `12_villa-del-balbianello` |
| 13 | La Velarca | Lombardia | 323 | 4 | `13_la-velarca` |
| 14 | Palazzo Moroni | Lombardia | 335 | 4 | `14_palazzo-moroni` |
| 15 | Castel Grumello | Lombardia | 317 | 4 | `15_castel-grumello` |
| 16 | Villa Carlotta | Lombardia | 329 | 4 | `16_villa-carlotta` |
| 17 | Ponte San Michele | Lombardia | 330 | 5 | `17_ponte-san-michele` |
| 18 | Villa Reale di Monza | Lombardia | 312 | 4 | `18_villa-reale-di-monza` |
| 19 | Ippodromo San Siro and Leonardo's Horse | Lombardia | 324 | 3 | `19_san-siro-leonardos-horse` |
| 20 | Traghetto di Leonardo | Lombardia | 320 | 6 | `20_traghetto-di-leonardo` |
| 21 | Rocca di Lonato and Casa del Podestà | Lombardia | 327 | 6 | `21_rocca-di-lonato` |
| 22 | Aula del Simonino | Trentino-Alto Adige | 340 | 6 | `22_aula-del-simonino` |
| 23 | Castello di Avio | Trentino-Alto Adige | 317 | 5 | `23_castello-di-avio` |
| 24 | Castello del Buonconsiglio | Trentino-Alto Adige | 307 | 3 | `24_castello-del-buonconsiglio` |
| 25 | MUSE, Museo delle Scienze | Trentino-Alto Adige | 323 | 5 | `25_muse-trento` |
| 26 | Mart, Rovereto | Trentino-Alto Adige | 275 | 4 | `26_mart-rovereto` |
| 27 | Ponte del Diavolo, Cividale del Friuli | Friuli-Venezia Giulia | 317 | 4 | `27_ponte-del-diavolo-cividale` |
| 28 | Basilica di Aquileia | Friuli-Venezia Giulia | 313 | 4 | `28_basilica-di-aquileia` |
| 29 | Mausoleo di Teodorico | Emilia-Romagna | 322 | 5 | `29_mausoleo-di-teodorico` |
| 30 | Sant'Apollinare in Classe | Emilia-Romagna | 351 | 5 | `30_sant-apollinare-in-classe` |
| 31 | Palazzo di Teodorico, Ravenna | Emilia-Romagna | 297 | 6 | `31_palazzo-di-teodorico` |
| 32 | Villa dei Vescovi | Veneto | 361 | 5 | `32_villa-dei-vescovi` |
| 33 | Santuario Madonna della Corona | Veneto | 361 | 5 | `33_madonna-della-corona` |
| 34 | Palazzo della Ragione, Padua | Veneto | 356 | 6 | `34_palazzo-della-ragione` |
| 35 | San Giorgio Maggiore | Veneto | 313 | 4 | `35_san-giorgio-maggiore` |
| 36 | Caffè Pedrocchi, Padua | Veneto | 337 | 6 | `36_caffe-pedrocchi` |
| 37 | Casa del Petrarca, Arquà Petrarca | Veneto | 320 | 3 | `37_casa-del-petrarca` |
| 38 | Giardini della Biennale | Veneto | 333 | 4 | `38_giardini-della-biennale` |
| 39 | Villa Pisani, Stra | Veneto | 331 | 6 | `39_villa-pisani` |
| 40 | Ca' Giustinian, Venice | Veneto | 309 | 7 | `40_ca-giustinian` |
| 41 | Ca' Pesaro, Venice | Veneto | 306 | 4 | `41_ca-pesaro` |
| 42 | Monte Fontana Secca | Veneto | 362 | 5 | `42_monte-fontana-secca` |
| 43 | Ponte Vecchio, Bassano del Grappa | Veneto | 369 | 5 | `43_ponte-vecchio-bassano` |
| 44 | Casa e Collezione Laura | Liguria | 296 | 4 | `44_casa-e-collezione-laura` |
| 45 | Antica Barberia Giacalone, Genoa | Liguria | 295 | 5 | `45_antica-barberia-giacalone` |
| 46 | Abbazia di San Fruttuoso | Liguria | 300 | 3 | `46_abbazia-di-san-fruttuoso` |
| 47 | Casa Carbone, Lavagna | Liguria | 312 | 4 | `47_casa-carbone` |
| 48 | Villa Rezzola, Lerici | Liguria | 320 | 5 | `48_villa-rezzola` |
| 49 | Tellaro | Liguria | 313 | 3 | `49_tellaro` |
| 50 | Teatrino di Vetriano | Toscana | 322 | 6 | `50_teatrino-di-vetriano` |
| 51 | Torre e Casa Campatelli, San Gimignano | Toscana | 308 | 5 | `51_torre-e-casa-campatelli` |
| 52 | Abbazia di San Galgano | Toscana | 345 | 6 | `52_abbazia-di-san-galgano` |
| 53 | Villa Gamberaia, Settignano | Toscana | 362 | 3 | `53_villa-gamberaia` |
| 54 | Bosco di San Francesco, Assisi | Umbria | 318 | 5 | `54_bosco-di-san-francesco` |
| 55 | Ponte delle Torri, Spoleto | Umbria | 328 | 5 | `55_ponte-delle-torri` |
| 56 | Orto sul Colle dell'Infinito, Recanati | Marche | 298 | 6 | `56_orto-sul-colle-dell-infinito` |
| 57 | Rotonda a Mare, Senigallia | Marche | 326 | 5 | `57_rotonda-a-mare` |
| 58 | Villa Gregoriana, Tivoli | Lazio | 348 | 7 | `58_villa-gregoriana` |
| 59 | Parco degli Acquedotti, Rome | Lazio | 328 | 6 | `59_parco-degli-acquedotti` |
| 60 | Baia di Ieranto | Campania | 300 | 6 | `60_baia-di-ieranto` |
| 61 | Duomo di Salerno | Campania | 327 | 5 | `61_duomo-di-salerno` |
| 62 | Abbazia di Santa Maria di Cerrate | Puglia | 326 | 6 | `62_abbazia-di-cerrate` |
| 63 | Cattedrale di Troia | Puglia | 337 | 8 | `63_cattedrale-di-troia` |
| 64 | Teatro Margherita, Bari | Puglia | 333 | 7 | `64_teatro-margherita-bari` |
| 65 | Teatro Petruzzelli, Bari | Puglia | 305 | 6 | `65_teatro-petruzzelli` |
| 66 | Fontana Greca, Gallipoli | Puglia | 345 | 4 | `66_fontana-greca-gallipoli` |
| 67 | Casa Noha, Matera | Basilicata | 313 | 4 | `67_casa-noha` |
| 68 | Castello Tramontano, Matera | Basilicata | 332 | 6 | `68_castello-tramontano` |
| 69 | I Giganti della Sila | Calabria | 348 | 5 | `69_giganti-della-sila` |
| 70 | Giardino della Kolymbethra, Agrigento | Sicilia | 325 | 5 | `70_giardino-della-kolymbethra` |
| 71 | Giardino Pantesco Donnafugata, Pantelleria | Sicilia | 315 | 7 | `71_giardino-pantesco-donnafugata` |
| 72 | Tempio di Segesta | Sicilia | 333 | 6 | `72_tempio-di-segesta` |
| 73 | Fontana Pretoria, Palermo | Sicilia | 356 | 6 | `73_fontana-pretoria` |
| 74 | San Giovanni degli Eremiti, Palermo | Sicilia | 327 | 7 | `74_san-giovanni-degli-eremiti` |
| 75 | Teatro Massimo Bellini, Catania | Sicilia | 327 | 7 | `75_teatro-massimo-bellini` |
| 76 | Batteria Militare Talmone, Palau | Sardegna | 302 | 6 | `76_batteria-militare-talmone` |
| 77 | Saline Conti Vecchi, Assemini | Sardegna | 309 | 7 | `77_saline-conti-vecchi` |
