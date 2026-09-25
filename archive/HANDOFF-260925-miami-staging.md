# Handoff 2026-09-25: Miami staged — 30 scripts, coordinates, 74 images

Named for its subject: `HANDOFF-260925-six-creator-batch.md` and
`-where-to-taste.md` were already taken. Check the directory before picking a
filename — two handoffs were overwritten on 2026-09-14 by not doing so.

## What happened

The owner delivered **30 Miami tour scripts** (clean + TTS, 01–30, no gaps,
every one paired) and asked for images to be sourced. No audio yet.

Staged on `claude/new-city-staging-260925`. Tracker row landed on `main` the
same session (PR #1089), so `TOTAL PENDING` now reads 30.

Miami will be the **36th bureau** — Atlas Studio MIA,
`aed488af-23d3-514f-90f1-035ca2285d0d`, verified by recomputing ATL's id
against the live catalogue before use. The city had **no Atlas tours** and 39
creator link pins.

## Coordinates — the expensive part

**The scripts carry no coordinates**, only a prose position paragraph. This is
the Atlanta shape, where eleven of thirty derived points came out wrong and
every one was invisible to the validator, to CI and to every URL check.

All 30 were derived, audited and hand-read. `check-coordinates.py` reported
**GROSS none** and **no directional bias** (10/24 north, median −0.0 m,
p = 0.54) — so this drop is *not* from the pipeline that pushed Barcelona and
Milan ~10 m north. Six came back **UNVERIFIABLE**, which is not a pass; each
was reverse-geocoded at its own point and recorded in the pick-map.

**Two coordinates a geocoder returns wrongly** — both caught, both documented:

| subject | what search returns | why it is wrong |
|---|---|---|
| Cuban Memorial Boulevard | the park relation's centroid | the median runs **south** from Calle Ocho while the Bay of Pigs column stands at its **north** end — the centroid is **576 m away** |
| Bayfront Park | a **Metromover station** | search ranks the transit stop above the park |

**Trigger radii are sized per stop (30–120 m), not fixed at 30.** Eleven stops
are written from across the street or along a pedestrian mall, where a 30 m
circle on a building centroid cannot contain the listener. The catalogue
already runs 30–120 m. **Do not normalise them back.**

🔴 **Lummus Park is two different parks 5 km apart** — stop 06 on Miami Beach,
stop 18 downtown. Slugs are `ocean-drive-art-deco` and `lummus-park-downtown`;
**neither may be shortened to `lummus-park`**. That collision is how London's
Natural History Museum played Los Angeles' narration for six and a half weeks.

**Stops 08 and 25 overlap deliberately** — Máximo Gómez Park and the Tower
Theater genuinely share a corner, 33 m apart. Flagged to the owner, left as-is.

## Images — 74 live, hash-verified

206 candidates verified from 1,487 sourced; owner picked 77 across 26 tours;
**74 uploaded and byte-verified live** (all matched, none missing, none
mismatched). All PD/CC0 Commons, so **no attribution is owed** and
`drafts/CREDITS.md` gains no rows.

### Three lessons this batch paid for

1. 🔴 **A 429 is not an empty result.** The Holocaust Memorial first read as
   *zero coverage* — its only query had been throttled. Re-run, it returned 35
   usable candidates and 7 verified. An important subject was one step from
   being reported unsourceable.
2. 🔴 **`verify.py` re-sorted every pool by pixel area**, silently discarding
   the relevance ranking, so the gates kept seeing the biggest wrong-city
   photos. Stop 09 went from 0 verified to 6 the moment it was fixed. The line
   now carries a comment: *ranked order — do NOT re-sort by size*.
3. 🔴 **A gate prompt can be wrong.** Gate B for stop 09 said "a grey marble
   column", copied from the script. The monument is **dark polished granite**,
   so the gate correctly rejected the one right image. ⚠️ **The script's
   "this column of gray marble" does not match the stone — worth telling the
   author.**

### What ranking had to defend against

Sorting by megapixels surfaced whichever wrong-city photo had the best camera:
the **Great Miami River in Ohio** (Dayton, I-75 bridges) for stop 01, a **US
Army 173rd Airborne ceremony** for stop 09 (my own `brigade` token pulled it
up), and **DuPont in Wilmington, Delaware** for stop 14. All correctly rejected
by Gate B, but they wasted verification budget until the ranking was fixed.

### Unsplash contributed nothing

**Zero verified images across 144 candidates.** Stock returns the city, not the
place — `freedom tower miami` has no results at all while `miami` has 4,497.
Use Commons for named subjects; Unsplash only for atmosphere.

## 🔴 Owed

- **Three picks not uploaded** — `dupont-building_hero`,
  `little-haiti-cultural-complex_hero`, `bacardi-building_3`. Wikimedia
  rate-limited after ~2,000 requests and the obtainable copies crop below
  1200×900. **Held rather than shipped upscaled** — two are heroes. All three
  originals are comfortably large; re-fetch the original `upload.wikimedia.org`
  URL when the limit clears. **Nothing needs re-picking.**
- **Four tours have no picks** — 07 `lincoln-road`, 21 `south-pointe-park`,
  27 `overtown-interchange`, 30 `virginia-key-beach`. Candidates are sourced.
- **Four subjects want owner photographs** — `little-haiti-cultural-complex`
  (1 candidate), `gesu-church`, `tower-theater`, `lyric-theater` (3 each).
- **Narration audio for all 30.** Ask for a Dropbox `/scl/fo/` folder link,
  **never** a Transfer `/t/` link — Transfer has no direct-download URL and
  Chromium cannot reach Dropbox through this proxy.

⚠️ `miami-circle_6.webp` shipped with a **1.06× upscale** (crop was 1132×849).
Six percent, not visible — recorded so it is not rediscovered as a defect.

## Where things are

| | |
|---|---|
| scripts, pick-map, coordinates, image manifest | `claude/new-city-staging-260925`, `drafts/miami-batch1/` |
| tracker row | `main` (PR #1089) |
| 74 images | `gh-pages`, commit `499486e3` |
| picking page | a private Artifact; rebuild from `picks_manifest.json` if needed |
