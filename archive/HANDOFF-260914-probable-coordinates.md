# HANDOFF — 2026-09-14: the 17 "probably off" coordinates

Third and last set from the catalogue-wide sweep of 2026-09-12 (report:
https://claude.ai/code/artifact/3a3e10d1-ced8-4837-a5cf-669619c9d48b). Earlier sets: 13 hand-typed
(#881, `HANDOFF-260913-coordinates.md`) and 19 drop-pipeline (#882, `HANDOFF-260914-pipeline-coordinates.md`).

Owner: *"OK DO IT."*

## What moved: 16 locations, 20 stops

Each moved to where its own script stands the listener, then reverse-geocoded onto the venue:

| Entry | Now at | Moved |
|---|---|---|
| Wat Arun | the central prang | 318 m |
| Casa das Canoas | the house | 173 m |
| Artipelag | the gallery's north side, from the boardwalk | 165 m |
| Hosen-in | the temple hall | 155 m |
| Silver Temple (Wat Sri Suphan) | the temple grounds | 140 m |
| Kew Gardens Palm House | in front of the Palm House | 135 m |
| Mona Vale Rockpool | the pool | 133 m |
| Southwark Cathedral | the cathedral | 116 m |
| Östermalms Saluhall | the Östermalmstorg side | 110 m |
| Queen's House (tour + Measure of the World stop 3) | its west front | 108 / 101 m |
| Jay Pritzker Pavilion (tour + Lakefront stop 2) | on the Great Lawn, facing the bandshell | 105 m |
| Neue Wache (**"Neue Wache & the Zeughaus" tour** + Imperial Spine stop 3) | on Unter den Linden, in front of it | 97 m |
| Naoshima New Museum of Art | the museum | 96 m |
| Museu Tàpies (tour + Dreta de l'Eixample stop 3) | 255 Carrer d'Aragó | 74 m |
| Cutty Sark (tour) | the ship | 72 m |
| King Power Mahanakhon | the tower's street front | 43 m |

- Two copies the sweep had not listed moved with their originals: the **"Neue Wache & the Zeughaus"**
  single tour shared the Imperial Spine stop's coordinate, and Museu Tàpies's walk stop shared its tour's.
- ⚠️ OSM maps Millennium Park's **Great Lawn south of the bandshell**, not east where the old point sat.
- Walks touched (Measure of the World, Dreta de l'Eixample, Imperial Spine, Lakefront): centroids
  re-derived; no route changed by more than 10%, so no walking distance changed. None of the moved
  stops is a walk's stop 0, so no place membership moved.

## Checked and left as is

**Tian Tan Buddha.** Flagged at 92 m, but its script says *"You're at the base of the steps… two
hundred and sixty-eight stone steps between you and the base of the statue"*: the point is where it
should be. Overpass (both mirrors) was unavailable to fetch the staircase line; the call rests on the
script.

## Checks

`validate-tours.swift` 0 errors, warnings identical to `main`; `validate-tours-mirror.py` 0 errors,
selftest 32/32; seed generates cleanly. `check-place-candidates.py` gains exactly one TIGHT pair:
**Cutty Sark / Greenwich Foot Tunnel at 22.4 m**, two separate things beside each other (co-location is
not identity); left for the owner's place menu, not auto-grouped.

## What is left from the sweep

- ~1,140 coordinates with no automatic verdict, weighted toward pipeline cities.
- 1,972 link pins, never swept.
- The pipeline's residual ~20 m northward offset on entries not grossly wrong.
