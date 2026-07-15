# Rome walk — "Aventine & Testaccio" (multiStop, 4 stops) — STAGED, awaiting narration 🇮🇹

Circus Maximus → Orange Garden (Aventine) → Knights of Malta Keyhole → Testaccio. ~2.5 km,
one climb up the Aventine then downhill. Under **Atlas Studio ROM**. Scripts: `00_intro.txt` +
`NN_name.txt` (+ `_TTS.txt`).

**Two stops reuse live heroes** (Circus Maximus, Aventine Orange Garden); **two newly sourced** —
the Keyhole (its own stop here, distinct from the Aventine single) + Testaccio (staged live).

## Wire-in spec

- `kind:"multiStop"`, tour slug `rome-aventinetestaccio-walk`, id `atlas-tour:rom:rome-aventinetestaccio-walk`.
- Stop 0 = intro (`triggerMode:"manual"`, `imageURL:null`). Stops 1–4 geofenced, radius **40 m**.
- `audioURL: rome-aventinetestaccio-walk_stopN.mp3`; `transcriptText` verbatim (drop `[beat]`).
- Centroid = avg of the 4 coords. `walkingDistanceMeters ≈ 2500`.

| stop | subject | imageURL slug | coord (lat, lon) |
|------|---------|---------------|------------------|
| 1 | Circus Maximus | `circus-maximus` (reuse) | 41.8859, 12.4853 |
| 2 | Giardino degli Aranci (Orange Garden) | `aventine` (reuse) | 41.8842, 12.4797 |
| 3 | Knights of Malta Keyhole | `aventine-keyhole` (new) | 41.8836, 12.4802 |
| 4 | Testaccio (Monte Testaccio + market) | `testaccio` (new) | 41.8760, 12.4757 |

**Walk hero:** `aventine_hero` (default; `circus-maximus` also strong). **Category:** `culturalHeritage`.
**MP3s: 5** (intro + 4). Images ship-safe **except** `testaccio_hero` (Wikimedia CC BY 2.0 — see CREDITS.md).
