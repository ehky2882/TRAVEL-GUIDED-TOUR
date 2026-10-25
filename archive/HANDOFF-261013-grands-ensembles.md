# HANDOFF 2026-10-13: Grands Ensembles 🏢 — 8 original audio tours + 8 architect tags

**What shipped:** 8 single-stop audio tours of post-war housing estates around Paris, under a new creator,
**Grands Ensembles** (🏢, platform `dozent`, handle `grandsensembles`, maker id uuid5 `atlas-maker:grands-ensembles`
= `17711786-8c4b-5e81-8393-cda58a108f15`). It sits next to SovMod in `makers`: an original-audio creator, not a studio.
- Tours: Les Tours Aillaud (Nanterre), Cité de la Muette and the Drancy Memorial (Drancy, `history`), La Grande Borne
  (Grigny), Les Arcades du Lac (Montigny-le-Bretonneux), Les Étoiles de Renaudie (Ivry-sur-Seine), Les Orgues de
  Flandre (Paris), Les Arènes de Picasso (Noisy-le-Grand), Les Choux de Créteil (Créteil).
- Ids: `atlas-tour:grands-ensembles:<slug>`, stops `atlas-stop:grands-ensembles:<slug>:1`.
- Catalogue: tours 1933 → 1941, makers 679 → 680, cities 978 → 981 (Drancy, Grigny, Montigny-le-Bretonneux).
- **Architect tags (Job 5, contributor asked):** Émile Aillaud, Eugène Beaudouin, Marcel Lods, Renée Gailhoustet,
  Jean Renaudie, Martin Schulz van Treeck, Manuel Núñez Yanowsky, Gérard Grandval — all named in the tours' own
  scripts. Ricardo Bofill already existed. Engineers (Prouvé, Bodiansky) and painters (Rieti) deliberately not tagged.

**Assembler** (`drafts/grands-ensembles-batch1/tools/`): same rules as SovMod batch 2, except the caption takes the
next sentence too when the orientation line is under 60 characters (a bare address). Geofence 60 m for estates,
40 m for the Renaudie building.

**Checks:** coordinates — `check-coordinates.py` GROSS on Choux (geocoder matched a Paris café) and Arcades (311 m
from the estate's centroid; the point is on Le Viaduc, where the script stands you) are both false; every point
reverse-geocodes onto its site. Audio — faster-whisper tiny.en on the first 60 s, every file best-matches its own
script (0.75–0.83). Validator 0 errors, no warnings on the new tours. `join-places` 0.

**⚠️ An abandoned 2026-10-11 session (session_01HnqkkcVxcN2rGDCnmoP5UA)** had already pushed 35 photos for this
drop to gh-pages (`57fb673`) and stopped, with no PR or branch. 28 were byte-identical to the drop. Six held an
older version (the Drancy hero had a date stamp; the Aillaud hero was a different shot), so the drop's versions are
published under `-2` names rather than overwritten; the six old files and one extra are orphans. gh-pages commit
`efbddcc`: 14 additions (8 MP3 + 6 photos), nothing modified.

**For Edward:** place questions — the contributor asked for the tours to stack on the existing creator pins, which
they do; whether to make places is on the board as `place-grands-ensembles`. Photo licences unknown — on the board
as `grands-ensembles-photo-licences`.
