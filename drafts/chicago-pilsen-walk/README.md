# Pilsen — Eighteenth Street, East to West · 🇺🇸 Chicago WALK 5 (image-staging COMPLETE)

*"Nothing on this street arrived intact."* A little over a mile west along 18th Street in four stops: a Catholic church that was bought used and dragged here, an opera house built out of somebody's memory of Prague, an Aztec calendar stone rendered in house paint on an elevated platform, and a museum whose stated frame is *sin fronteras*. The through-line: **everything came from somewhere else and changed on the way, and the changing is the subject.**

**New image sourcing: 3 files** — stops 1, 3 and 4. **Hero and stop 2 reuse the two live owner images** from single tour 25. **2 photographer credits + 2 unresolved mural rights — see the sensitivity section, this walk is not clean.**

Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

## Structure

- **kind:** `multiStop`
- **Stop 0 = intro** (18th and Halsted, facing west) — `00_intro.txt`; `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
- **Stops 1–4** — `triggerMode: geofenced`, `radiusMeters: 40`.
- **Audio: 5 MP3s** (intro + 4 stops); slug stems `chicago_pilsen_multistop_00_intro` … `_04_mexican_art_museum`.

## Stops → image

| # | Stop | script | image | coord | source |
|---|------|--------|-------|-------|--------|
| 0 | Intro (18th & Halsted) | `00_intro` | — (walk hero) | `41.85760, -87.64690` | manual |
| 1 | Casa Aztlan | `01_casa_aztlan` | `chicago-pilsen_stop1.webp` | `41.85755, -87.65590` | **new** · owner-supplied · ⚠️ mural |
| 2 | Thalia Hall & Saint Procopius | `02_thalia_procopius` | `pilsen-18th-street_hero.webp` | `41.85750, -87.65760` | reuses the live single hero (tour 25) |
| 3 | Eighteenth Street station | `03_18th_street_station` | `chicago-pilsen_stop3.webp` | `41.85760, -87.66700` | **new** · Commons CC BY-SA · ⚠️ mural |
| 4 | National Museum of Mexican Art | `04_mexican_art_museum` | `chicago-pilsen_stop4.webp` | `41.85585, -87.66830` | **new** · Commons CC BY-SA |

- **heroImageURL (walk):** `pilsen-18th-street_2.webp` — St Procopius's green spire and Thalia Hall's turret facing each other down 18th Street. Owner-supplied, already live; **reused deliberately** because stock sourcing for Pilsen failed almost completely (see below).
- **additionalImageURLs** (4, in stop order): `chicago-pilsen_stop1.webp`, `pilsen-18th-street_hero.webp`, `chicago-pilsen_stop3.webp`, `chicago-pilsen_stop4.webp`.
- **Note the deliberate swap:** the two live tour-25 images are used *crossed over* — `_2` (both buildings) is the **walk hero**, `_hero` (Thalia Hall alone) is **stop 2**. Both were verified by opening the files, not by slug.

## 🔴 UNRESOLVED MURAL RIGHTS — stops 1 and 3 (shipped at owner direction)

**This walk is the one exception in the whole `drafts/` corpus. Do not treat it as precedent.**

Two stop images depict **copyrighted murals as principal subjects**:

| stop | mural | artist(s) |
|------|-------|-----------|
| 1 | *Hay Cultura en Nuestra Comunidad*, Casa Aztlan | Ray Patlan (d. 2024); 2017 repaint with Roberto Valadez (living) |
| 3 | 18th Street station platform murals incl. the Aztec sun stone | Francisco Mendoza (d. 2012) and students |

The US has **no freedom of panorama for artworks** — 17 USC §120 exempts *architectural works* only — so photographing a mural creates a derivative work. In both images the mural is the reason to look at the picture, so **de minimis does not apply**.

A buildings-only alternative was offered, priced and initially chosen; the owner then supplied these two images and confirmed shipping them after the consequence was restated. **Logged as an open obligation in `drafts/CREDITS.md`, not as a cleared one.**

**Two traps for whoever picks this up:**

1. **An owner-supplied photo does NOT clear a mural.** It clears the photographer. Stop 1 is the owner's own photograph and still carries the Patlan/Valadez right.
2. **Do not reason from the Chicago Picasso.** Tour 14's sculpture really *is* public domain in the US, by *Letter Edged in Black Press v. Public Building Commission of Chicago* (1970) — a specific ruling about a specific work, and the opposite of the general rule. These murals have no such exception, and neither does Calder's *Flamingo* on the Loop walk.

Single tour 25 (Pilsen) remains **clean** — it was built entirely from buildings on purpose. Keep it that way.

## ⚠️ Pilsen is a stock desert — 95 images sourced, 1 usable

Recorded so nobody repeats the run. Four pools were fetched across Unsplash, Pexels, Pixabay and Wikimedia:

| pool | fetched | usable |
|------|---------|--------|
| Pilsen streetscape (for the hero) | 39 | **0 verifiable as Pilsen** |
| National Museum of Mexican Art / Harrison Park | 25 | 1 (stop 4) |
| 18th Street station | 16 | **0** |
| St Procopius Church | 15 | **0** |

The stock pools returned Chicago skylines, the Chicago Theatre, Chinatown, Navy Pier, the Shedd's penguins, and stock models posing in front of unrelated murals. The church pool returned every Chicago church *except* St Procopius — one file is captioned *Saints Peter and Paul*. **This is the "thin subject → owner photograph" pattern already recorded for the Obama Center and Thalia Hall; reach for the owner earlier here.**

**Two Commons category traps found:**

- **`Category:Pilsen, Chicago` and an `18th Street station` search both returned Plzeň, Bohemia** — a thatched Czech cottage landed in two separate pools. Apt, given the walk opens on exactly that name confusion, but check the country before trusting a Pilsen category.
- **Casa Aztlan has no file on Commons at all** — zero, not thin. Probably the mural rule operating upstream.

**One upscale:** `chicago-pilsen_stop3.webp` came from a 1254×834 source, below the 1200×900 bar, so it was enlarged ~1.08×. It is the only enlarged image in the Chicago batch.

## ⚠️ transcriptText — a fifth header format

```
ATLAS — CHICAGO
W5: PILSEN — EIGHTEENTH STREET, EAST TO WEST
Segment nn — <title>
Position: <where to stand>      ← "Position:", not "Vantage:" or "Voice:"
---
```

Two further differences from the other four walks:

1. **Beat markers are bare `[beat]`, not `*[beat]*`** — no asterisks. Strip both forms.
2. **The `_TTS.txt` files carry no header block** (same as walk 4) and are heavily phoneticised (`pul zen`, `ahs tlahn`, `kwow teh mock`). **`transcriptText` must come from the clean `.txt`** — the TTS text would ship gibberish to the reader.

Start after the `---` rule. See the other walk READMEs for formats one to four.

## Wire-in checklist (when audio arrives)

1. Under maker **Atlas Studio ORD** 🇺🇸, add ONE tour, `kind: multiStop`.
   - Deterministic ids: `atlas-tour:ord:pilsen-walk`; stops `atlas-stop:ord:pilsen-walk:<n>` (uuid5, `NAMESPACE_URL`).
   - Stop 0 intro: `triggerMode: manual`, `introAudioURL: null`, `imageURL: null`.
   - Stops 1–4: `triggerMode: geofenced`, `radiusMeters: 40`, per-stop `audioURL` + `imageURL` + coord above.
   - `totalDurationSeconds` = Σ (intro + 4 stops) — read from the delivered MP3s.
   - `walkingDistanceMeters`: **~1800** (the intro says a little over a mile).
   - `centroid` (avg of the 4 geofenced stops): **`41.85713, -87.66220`**.
   - Category: `culturalHeritage`; `priceUSD: 0`; `city: "Chicago"`.
   - Tags: `District`, `Immigration`, `Art`, `History`, `Free to Visit`.
2. **Credits: 2 photographer rows + 2 unresolved mural rights** — `drafts/CREDITS.md`, "Chicago walk 5 (Pilsen)".
3. Master single-stop pick-map: `drafts/chicago-batch1/README.md`.
