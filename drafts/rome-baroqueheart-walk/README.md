# Rome walk — "Baroque Heart" (multiStop, 5 stops) — STAGED, awaiting narration 🇮🇹

Piazza del Popolo → Spanish Steps → Trevi Fountain → Pantheon → Piazza Navona. ~2 km, flat.
Under **Atlas Studio ROM**. Scripts: `00_intro.txt` + `NN_name.txt` (+ `_TTS.txt`).

**Reuses live single-stop heroes for every stop — zero new image sourcing.**

## Wire-in spec

- `kind:"multiStop"`, tour slug `rome-baroqueheart-walk`, id `atlas-tour:rom:rome-baroqueheart-walk`.
- Stop 0 = intro (`triggerMode:"manual"`, `imageURL:null`). Stops 1–5 geofenced, radius **40 m**.
- `audioURL: rome-baroqueheart-walk_stopN.mp3`; `transcriptText` verbatim (drop `[beat]`).
- Centroid = avg of the 5 coords. `walkingDistanceMeters ≈ 2000`.

| stop | subject | imageURL slug (reuse) | coord (lat, lon) |
|------|---------|-----------------------|------------------|
| 1 | Piazza del Popolo | `piazza-del-popolo` | 41.9109, 12.4763 |
| 2 | Spanish Steps | `spanish-steps` | 41.9058, 12.4823 |
| 3 | Trevi Fountain | `trevi-fountain` | 41.9009, 12.4833 |
| 4 | Pantheon | `rome-pantheon` | 41.8986, 12.4769 |
| 5 | Piazza Navona | `piazza-navona` | 41.8992, 12.4731 |

**Walk hero:** `trevi-fountain_hero` (default; owner may swap). **Category:** `culturalHeritage`. **MP3s: 6**. All images ship-safe.
