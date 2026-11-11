# Venice batch 1: architect's city guide, 29 single-stop scripts (drafted 2026-11-11)

**Status: scripts only. No audio, no images, nothing wired.** This is a set of scripts for a curated Venice guide in the style of the
Architecture Hunter city guides: Stay · Dine · Drink · Shop · Visit · Observe. Each venue is its own single-stop tour.

- `src/scripts.md` is the only file to edit. Every script lives there.
- `tools/build_venice.py` generates the rest (`python3 -I tools/build_venice.py drafts/venice-batch1`).
- `scripts/NN_<slug>_clean.{md,txt}` is the authoring text, with `[beat]` kept as a marker.
- `scripts/NN_<slug>_tts-safe.{md,txt}` is the text to read to the voice. Names are respelled phonetically, in
  lowercase with no hyphens. `[beat]` becomes a paragraph break. Years are spelled out. There are no brackets or
  markup. Titles are respelled too.
- `coordinates.tsv` lists, for each tour: number · slug · section · Google Maps name · lat · lon · word count.
- `SOURCES.md` lists what was read for each venue before it was written.

Every script is written in the British voice set by the `atlas-audio-tour` skill. Each runs 270–370 words, about
two minutes, has one engineered beat and ends with an "explore further" pointer.

## Coordinates
Every point was checked against OpenStreetMap through Photon. A point was kept only when the result's name and its
Venice address matched the venue. **One point is approximate:** 16 Tessitura Luigi Bevilacqua uses the centroid of
Campo San Zan Degolà. The workshop is on that campo, at Santa Croce 1320, but it has no OSM node of its own.

⚠️ **One venue changed from the published list.** The list gave "Bevilacqua" at Campo Santa Maria del Giglio, a
velvet shop. The sources tie the eighteenth-century looms, and the whole story, to the weaving house in Santa Croce.
The Giglio shop appears to belong to a separate branch of the family, so the tour was moved to the weaving house, and
the Giglio shop is mentioned in its closing.

Run `python3 scripts/check-coordinates.py --drop` before anything is wired.

## Open points for the owner
- **Facts softened rather than asserted where the sources disagreed:**
  - Ca' di Dio's founding date: "the thirteenth century".
  - The Venissa bell tower: "medieval".
  - Il Palazzo Experimental's naval past: "is said to".
  - Florian and the Biennale: "the story goes".
  - The attribution of the Bovolo staircase: Spavento, "usually credited", with Candi named.
  - The Tiepolo frescoes at Aman: "from the circle of the Tiepolo".
- **Ca' Macana and Eyes Wide Shut:** the workshop's own site claims the film. A forum account says the production
  bought from several workshops, so the script says Ca' Macana "made some of them".
- **Sources that could not be fetched from this session:**
  - osteriaalletestiere.it is not on the session's network allowlist.
  - ristorantelocal.com, the Gritti/Marriott site, cini.it, fondazioneprada.org and domusweb returned 403.
  - The Florian site returned empty pages.

  For each of these, the facts came from other published sources. Those are listed in `SOURCES.md`.
