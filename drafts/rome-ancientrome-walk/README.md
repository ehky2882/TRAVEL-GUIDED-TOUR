# Rome walk — "Ancient Rome" (multiStop, 5 stops) — STAGED, awaiting narration 🇮🇹

Colosseum → Arch of Constantine → Roman Forum → Trajan's Column → Campidoglio. ~1.5 km, flat
then a gentle climb. Under **Atlas Studio ROM**. Scripts: `00_intro.txt` + `NN_name.txt`
(+ `_TTS.txt`) in this folder.

**Reuses live single-stop heroes** — only Trajan's Column was newly sourced (staged live).

## Wire-in spec

- `kind: "multiStop"`, tour slug `rome-ancientrome-walk`, id `atlas-tour:rom:rome-ancientrome-walk`.
- **Stop 0 = intro:** `triggerMode:"manual"`, `imageURL:null`, `audioURL: rome-ancientrome-walk_intro.mp3` (or `_stop0`), order 0.
- **Stops 1–5:** `triggerMode:"geofenced"`, radius **40 m**, `audioURL: rome-ancientrome-walk_stopN.mp3`, `transcriptText` verbatim from the stop `.txt` (drop `[beat]`).
- `introAudioURL:null`. Centroid = avg of the 5 geofenced coords. `walkingDistanceMeters ≈ 1500`.

| stop | subject | imageURL slug (reuse) | coord (lat, lon) |
|------|---------|-----------------------|------------------|
| 1 | Colosseum | `rome-colosseum` | 41.8902, 12.4922 |
| 2 | Arch of Constantine | `arch-of-constantine` | 41.8898, 12.4906 |
| 3 | Roman Forum (from Via dei Fori Imperiali) | `roman-forum-overlook` | 41.8925, 12.4853 |
| 4 | Trajan's Column | `trajans-column` | 41.8958, 12.4837 |
| 5 | Campidoglio | `campidoglio` | 41.8933, 12.4828 |

**Walk hero:** `rome-colosseum_hero` (default; owner may swap). **Category:** `history`. **MP3s: 6** (intro + 5). All images ship-safe.
