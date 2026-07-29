# Rome walk — "Vatican & Borgo" (multiStop, 4 stops) — STAGED, awaiting narration 🇮🇹

Ponte Sant'Angelo → Castel Sant'Angelo → Via della Conciliazione → St Peter's Square. ~1.25 km,
flat. Under **Atlas Studio ROM**. Scripts: `00_intro.txt` + `NN_name.txt` (+ `_TTS.txt`).

**Two stops reuse live single-stop heroes** (Castel Sant'Angelo, St Peter's Square); **two were
newly sourced** — Ponte Sant'Angelo + Via della Conciliazione (staged live).

## Wire-in spec

- `kind:"multiStop"`, tour slug `rome-vaticanborgo-walk`, id `atlas-tour:rom:rome-vaticanborgo-walk`.
- Stop 0 = intro (`triggerMode:"manual"`, `imageURL:null`). Stops 1–4 geofenced, radius **40 m**.
- `audioURL: rome-vaticanborgo-walk_stopN.mp3`; `transcriptText` verbatim (drop `[beat]`).
- Centroid = avg of the 4 coords. `walkingDistanceMeters ≈ 1250`.

| stop | subject | imageURL slug | coord (lat, lon) |
|------|---------|---------------|------------------|
| 1 | Ponte Sant'Angelo | `ponte-santangelo` (new) | 41.9016, 12.4664 |
| 2 | Castel Sant'Angelo | `castel-santangelo` (reuse) | 41.9031, 12.4663 |
| 3 | Via della Conciliazione | `via-della-conciliazione` (new) | 41.9022, 12.4610 |
| 4 | St Peter's Square | `st-peters-square` (reuse) | 41.9022, 12.4568 |

**Walk hero:** `st-peters-square_hero` (default; `ponte-santangelo` also strong). **Category:** `sacredSites`. **MP3s: 5** (intro + 4). All images ship-safe.
