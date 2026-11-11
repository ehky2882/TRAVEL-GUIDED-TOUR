# Santiago batch 1 — Atlas Studio SCL (22 singles) — LIVE 2026-10-30

Source: contributor drop (Dropbox, arthur.yung), 22 `output <Name> <lat>, <lon>` folders with scripts numbered 01–22.
Each folder holds `NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt` (title line + one `[beat]`), one MP3 (100–122 s,
44.1 kHz / 128 kbps) and 2–7 photos at 1200×900 WebP (95 in all, no byte duplicates). Accented folder names arrived
mangled by the zip (`Borag#U00f3`, `Santa Luc#U00eda`); the assembler matches on the folder-name prefix. The monastery's
photos are named `_02-hero.webp` / `_02-N.webp`, unlike the rest; the assembler handles both.

`scripts/` holds both texts as delivered. `coordinates.tsv` is slug · lat · lon · radius · category · city, as wired.
Every coordinate comes from its folder name, except three, all approved by the contributor at triage:
- **Mercado Urbano Tobalaba** moved 260 m south, from Avenida El Bosque Norte to OSM's point for MUT,
  **-33.4172801, -70.6011321** (Apoquindo 2750, above Tobalaba station).
- **Chilean Museum of Pre-Columbian Art** moved ~90 m south to OSM's point for Bandera 361, **-33.4390245, -70.6521952**.
- **Plaza de Armas** moved ~115 m east, off Bandera behind the cathedral and into the south part of the square,
  **-33.4379, -70.6505** (the script has the listener in the square facing the post office).
The other 19 sit within ~50 m of their street addresses. Mestizo Italia, Taller Roca Negra and the Umbral could not be
matched automatically; their points are plausible but unverified.

`tools/wire_santiago.py` is the assembler (`python3 -I wire_santiago.py <unzipped drop> <stage dir>`), adapted from
`drafts/turin-batch1/tools/wire_turin.py`. Run it once: it refuses colliding tour ids. Slugs carry an **`scl-`
prefix**: audio at `audio/scl-<slug>.mp3`, images at `images/scl-<slug>_hero.webp`, `_2.webp`, … in the drop's order.

- **City:** `Santiago` for all 22, on the contributor's instruction, including Providencia / Vitacura / Las Condes and
  the two mountain tours (Taller Roca Negra in San José de Maipo, the Umbral on the Farellones road in Lo Barnechea).
- **Geofence:** 40 m for venues; 50 m for the monastery, the tower, MUT and Santa Lucía; 60 m for the Plaza de Armas.
  No two Santiago tours' circles overlap.
- **Bilingual `English | Spanish`** on 5: Benedictine Monastery of the Holy Trinity | Monasterio Benedictino de la
  Santísima Trinidad, Chilean Museum of Pre-Columbian Art | Museo Chileno de Arte Precolombino, Patricia Ready Gallery |
  Galería Patricia Ready, Santa Lucía Hill | Cerro Santa Lucía, Plazoleta Negra Threshold | Umbral Plazoleta Negra.
- **Titles tidied:** "Cenco Costanera Mall Shopping" → **Gran Torre Costanera** (the tower is the subject);
  "La Cle Atelier & Cuisine" → **Cristián Donoso Atelier & La Clé** (the script and audio are about the furniture
  atelier; La Clé is the café inside it); "Drugstore Boulevard" → Drugstore; "LA CALMA by Fredes & Ovalle" → La Calma;
  MUT gets its acronym.
- **Two roadside tours** kept on the contributor's instruction: Taller Roca Negra is a private home (the caption says to
  look from the road) and the Umbral sits on hairpin 22 of a ski road (caption: pull in safely).
- **Mestizo Italia** kept although one spring 2026 report described it as still opening.

Full account: `archive/HANDOFF-261030-santiago.md`.
