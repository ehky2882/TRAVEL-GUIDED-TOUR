# Lyon batch 1: 34 single-stop scripts in the style of an architect's city guide (drafted 2026-11-12)

**Status: scripts only. Not wired, no audio, no images.** Written in the Atlas British voice
(`atlas-audio-tour` skill), one tour per venue, in six categories: Dine, Drink, Stay, Visit, Observe, Shop.

`scripts/` has four files per tour: `NN_<slug>_clean.txt` / `.md` and `NN_<slug>_tts-safe.txt` / `.md`. The clean
version keeps `[beat]` as an authoring marker and digits for years. The TTS-safe version has phonetic respellings
(lowercase, no hyphens), every year spelled out, no brackets or markup, and each `[beat]` turned into a paragraph break.
Titles are respelled too. All 34 have a `[beat]`, so all 34 have a TTS-safe version.

**Do not hand-edit `scripts/`.** It is generated: edit `tools/src*.txt` (the clean text), then run
`python3 -I tools/build_tts.py scripts tools/src*.txt`. The respelling table is in `tools/build_tts.py`.

`coordinates.tsv` gives the Google Maps name, WGS-84 coordinates and how each point was found (OpenStreetMap / Nominatim;
expect a few metres' difference from Google's pin). Four are street or address points rather than venue points:
01 Halles, 20 Lugdunum, 25 Tour Rose and 34 Marché de la Création. 30 is the park's main gate, not its centre.
Run `check-coordinates.py` before wiring.

## Corrections to the original guide list, found while sourcing
- **Les Apothicaires closed on 28 April 2023.** Replaced by **Ombellule**, the same chefs' current restaurant
  (Tabata and Ludovic Mey, opened autumn 2024, one Michelin star in 2025), 36 Cours Franklin-Roosevelt.
- **Village des Créateurs closed in January 2023.** The tour is now **Passage Thiaffait**, the traboule it occupied,
  which now houses a responsible-fashion hub and textile lab.
- **Le Fantôme de l'Opéra is a cocktail bar**, not a wine bar.
- **Mokxa:** its original 2011 shop (3 Rue de l'Abbé Rozier) has been La Boîte à Café under other owners since 2023.
  The tour is set at the current Mokxa café, 5 Rue Victor Fort.
- **Musée urbain Tony Garnier was renamed Cité Musée Tony Garnier in 2024.**
- **Tour Rose** is at 16 Rue du Bœuf. The earlier list's point was the hotel at 22.

## Content notes (lines that will date or rest on thinner sources)
- 01 cites the 2026 Food & Wine ranking (3rd in the world).
- 32 Le Bal des Ardents: in July 2026 the shop was reported to be changing owners. The script deliberately doesn't name an owner.
- 27 Jardin Rosa Mir: opening hours change by season. The script says only "Saturdays, spring to autumn".
- 08 Fantôme and 07 Antiquaire: few sources available; drinks named from Lyon Tourism and Le Fooding listings.
- 03 Abel: sources disagree on its age (1928 vs 1726); the script uses 1928 for the restaurant and calls the building far older.
- 25 Tour Rose: the house's dating is disputed (16th vs 17th century), and the script says so.

## Sources read (primary or official where reachable)
Official sites: halles-de-lyon-paulbocuse.com (home, Notre histoire) · danieletdenise.fr · lamerebrazier.fr ·
le-sucre.eu · courdesloges.com · beauvallon.com/villa-florentine-lyon · mobhotel.com/lyon · couventdelatourette.fr ·
lyon.fr (Grand Hôtel-Dieu, Jardin Rosa Mir, Parc de la Tête d'Or, Marché de la Création) · chocolats-pralus.com (history,
2023 press kit) · traveltrade.lyon-france.com (Fantôme de l'Opéra).
Reference and press: Wikipedia (La Tourette, Musée des Confluences, Opéra de Lyon (fr), Gratte-Ciel (fr), Gare
Saint-Exupéry (fr), Institut Lumière (fr), Passage Thiaffait) · Lyon Capitale (Apothicaires closure, Ombellule,
Sucrière, Mur des Canuts 2013, Le Sucre) · LyonMag 2007 (Bouchon des Filles opening) · Le Fooding (L'Antiquaire) ·
NZ Herald (Mokxa founders) · Lyon Tourism (La Commune) · Yonder (Cour des Loges, MOB) · spacesarchives.org (Rosa Mir) ·
Livres Hebdo / ActuaLitté (Bal des Ardents) · Métropole de Lyon 2023 press release (Village des Créateurs) · architects'
texts via Wikipedia / Dezeen (Cube Orange) · Michelin Guide (Ombellule, MOB).
