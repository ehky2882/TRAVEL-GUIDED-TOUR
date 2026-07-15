# Rome walk — "Ghetto & Trastevere" (multiStop, 5 stops) — STAGED, awaiting narration 🇮🇹

Largo Argentina → Jewish Ghetto → Tiber Island → Trastevere → Janiculum (Gianicolo). ~2.5 km,
flat then a climb to the terrace. Under **Atlas Studio ROM**. Scripts: `00_intro.txt` +
`NN_name.txt` (+ `_TTS.txt`).

**Reuses live single-stop heroes for every stop — zero new image sourcing.**
_Sensitivity: the Jewish Ghetto stop uses the dignified Portico d'Ottavia / Great Synagogue
exteriors (no graphic imagery), per the standing requirement._

## Wire-in spec

- `kind:"multiStop"`, tour slug `rome-ghettotrastevere-walk`, id `atlas-tour:rom:rome-ghettotrastevere-walk`.
- Stop 0 = intro (`triggerMode:"manual"`, `imageURL:null`). Stops 1–5 geofenced, radius **40 m**.
- `audioURL: rome-ghettotrastevere-walk_stopN.mp3`; `transcriptText` verbatim (drop `[beat]`).
- Centroid = avg of the 5 coords. `walkingDistanceMeters ≈ 2500`.

| stop | subject | imageURL slug (reuse) | coord (lat, lon) |
|------|---------|-----------------------|------------------|
| 1 | Largo di Torre Argentina | `largo-argentina` | 41.8955, 12.4768 |
| 2 | Jewish Ghetto (Via del Portico d'Ottavia) | `jewish-ghetto` | 41.8919, 12.4779 |
| 3 | Tiber Island (via Ponte Fabricio) | `tiber-island` | 41.8901, 12.4779 |
| 4 | Trastevere (Piazza Santa Maria) | `santa-maria-trastevere` | 41.8894, 12.4696 |
| 5 | Janiculum terrace (Gianicolo) | `gianicolo` | 41.8917, 12.4617 |

**Walk hero:** `santa-maria-trastevere_hero` (default; owner may swap — `gianicolo` also strong). **Category:** `culturalHeritage`. **MP3s: 6**. All images ship-safe.
