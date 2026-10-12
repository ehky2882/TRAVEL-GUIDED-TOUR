# Vienna batch 1 — architect's city guide, 35 single-stop scripts (staged 2026-10-12)

Scripts only: no audio, no images, not wired into `Tours.json`. Written from the Architecture
Hunter–style Vienna guide (Loos American Bar dropped at the owner's request), following the
atlas-audio-tour skill. Every venue's primary source (its own site, or the architect's or a reference
source where the site was thin or down) was read before writing; claims that could not be sourced were cut.

- `source/clean-*.txt` — the authored text, one `=== NN slug` block per tour. **Edit here.**
- `tools/build.py` — splits the source into `scripts/NN_slug_{clean,tts-safe}.{txt,md}` and builds
  the TTS-safe text (respellings table inside; no digits, hyphens, caps, brackets or `[beat]`).
  It refuses to write if any rule is broken. Re-run after any edit: `python3 tools/build.py`.

| # | Google Maps name | lat | lon | category |
|---|---|---|---|---|
| 01 | Hotel Altstadt Vienna | 48.204817 | 16.351339 | Stay |
| 02 | The Guesthouse Vienna | 48.205173 | 16.369009 | Stay |
| 03 | Grand Ferdinand | 48.202320 | 16.374967 | Stay |
| 04 | Hotel Daniel Vienna | 48.188862 | 16.383851 | Stay |
| 05 | Steirereck | 48.204460 | 16.381279 | Dine |
| 06 | Café Prückel | 48.207607 | 16.380417 | Dine |
| 07 | Zum Schwarzen Kameel | 48.209994 | 16.368316 | Dine |
| 08 | Gasthaus Pöschl | 48.206657 | 16.373858 | Dine |
| 09 | Mayer am Pfarrplatz | 48.255131 | 16.358982 | Dine |
| 10 | Kleines Café | 48.206583 | 16.374358 | Drink |
| 11 | Das LOFT (SO/ Vienna) | 48.212719 | 16.379790 | Drink |
| 12 | Café Sperl | 48.199838 | 16.361169 | Drink |
| 13 | Café Museum | 48.201437 | 16.367665 | Drink |
| 14 | Strandbar Herrmann | 48.211946 | 16.385805 | Drink |
| 15 | J. & L. Lobmeyr | 48.205196 | 16.370800 | Shop |
| 16 | Knize | 48.208438 | 16.369821 | Shop |
| 17 | Mühlbauer | 48.207233 | 16.370640 | Shop |
| 18 | AUGARTEN Wien | 48.207749 | 16.370522 | Shop |
| 19 | Österreichische Postsparkasse | 48.209977 | 16.380647 | Visit |
| 20 | Looshaus | 48.208468 | 16.366592 | Visit |
| 21 | Secession | 48.200497 | 16.365768 | Visit |
| 22 | Otto-Wagner-Pavillon Karlsplatz | 48.200275 | 16.370266 | Visit |
| 23 | Kirche am Steinhof | 48.210383 | 16.278411 | Visit |
| 24 | Haus Wittgenstein | 48.203448 | 16.394274 | Visit |
| 25 | Wotrubakirche | 48.147632 | 16.253453 | Visit |
| 26 | Karl-Marx-Hof | 48.250160 | 16.364539 | Visit |
| 27 | Werkbundsiedlung | 48.179905 | 16.269496 | Visit |
| 28 | Library & Learning Center | 48.213856 | 16.408884 | Visit |
| 29 | Prunksaal der Österreichischen Nationalbibliothek | 48.206167 | 16.366690 | Visit |
| 30 | Hofmobiliendepot · Möbel Museum Wien | 48.198706 | 16.347049 | Visit |
| 31 | Haas-Haus | 48.208364 | 16.371555 | Observe |
| 32 | Flakturm Augarten | 48.225826 | 16.373287 | Observe |
| 33 | Yppenplatz | 48.213564 | 16.335837 | Observe |
| 34 | Friedhofskirche zum Heiligen Karl Borromäus | 48.150619 | 16.438094 | Observe |
| 35 | Kahlenberg | 48.276341 | 16.333068 | Observe |

Coordinates: OpenStreetMap (Nominatim) by name or address, 2026-10-12. Run
`scripts/check-coordinates.py` before any wire-in (CLAUDE.md rule 8b).

**Facts flagged for the owner before recording:** Steirereck's PPAG extension dates from 2014 (not 2005);
Hotel Daniel's caravan is a 1952 American caravan, brand unconfirmed, so the script does not say
"Airstream"; Postsparkasse hall and Haus Wittgenstein access hours could not be confirmed, so both
scripts say to check ahead; the Gasthaus Pöschl / Hermann Czech link rests on a single Falter report.
