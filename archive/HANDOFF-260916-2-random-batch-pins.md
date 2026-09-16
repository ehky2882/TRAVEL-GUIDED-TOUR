# HANDOFF — 2026-09-16 — the "random" 55-link batch

**53 link pins from 50 creators, [#946](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/946).**

## What the owner asked for

A bare list headed `NEW TOUR LINKS` — 55 URLs, 43 Instagram reels and 12 TikToks,
labelled "Random started 9/14". No creator in common: **52 distinct accounts across
55 posts**, which is the thing that made this batch different from every previous
one. There was no account to enumerate, no house caption format to learn, and no
single subject area — the posts run from Rome brutalism to Orlando water parks.

## Triage

`triage-account.py` on all 55: **0 already pinned**, 43 SINGLE, 6 MULTI, 6 THIN.
As the runbook warns, the flags ordered attention rather than replacing reading —
three of the six MULTIs were single points (Multnomah Falls flagged for naming the
Columbia River Gorge Highway; the Coral Rock House for "tucked along Collins
Avenue"), and two of the six THINs were perfectly good pins whose subject was simply
burned into the video instead of typed into the caption.

## The cover frame is the only frame — and that is the lesson

**11 of 55 captions named no subject.** Nine were identified anyway, and the method
that worked was reading the **oEmbed cover image**: the National Trust sign for
2 Willow Road, the Golden Arches for the Downey McDonald's, "Helena Modern Riviera"
and "Clearwater Beach Marriott Resort on Sand Key" literally typeset across the
frame. Three more came from research off a fragment — the Pinacoteca from exposed
brick plus steel walkways, Santa Maria della Visitazione from "Busiri Vici,
1965–71", Woning Van Wassenhove from "Lampens 1973, outside Ghent, go if you can".

🔴 **The owner then asked the question that matters: "46 has captions within the
video that clearly tell you the address. Are you able to read those?"** The honest
answer is **no, and it is worth writing down why**, because it is a structural limit
rather than an oversight:

- oEmbed returns **one image — the cover frame**. Text that appears three seconds in
  is not in it and never reaches this session.
- `make-link-pin.py` **deliberately never downloads the video** (TikTok's terms; see
  its module docstring), so there is no local file to sample frames from.
- For Instagram specifically it is moot: **21 of these 43 reels use licensed music,
  and Instagram withholds the media file for those entirely** — #46 among them. Even
  setting the policy aside there is no video to read.

So a subject revealed mid-video is genuinely unreachable, and the right move is to
say so and ask, which is what happened: the owner supplied **Fort Lee Historic Park**
and **778 Park Avenue** in seconds. Do not grind on these — ask early, name the
limit, and say it is the cover frame you read.

## Coordinates

Nominatim alone was not enough — it **missed eight** outright, and its name search
failed on venues it had no node for. What closed the gap:

| Route | What it solved |
|---|---|
| **US Census geocoder** (free, keyless, US only) | Helena Modern Riviera, The Ranch Hudson Valley, Conrad Orlando, 778 Park Ave — every US street address Nominatim refused |
| **Photon** (`photon.komoot.io`, OSM name search) | Chinese Scholar's Garden, U Residenzstraße, St Mary's Villa at 150 Sisters Servants Ln |
| **Raw OSM API** (`api.openstreetmap.org/api/0.6/map?bbox=`) | Edinburgh Airport's control tower — `tower:type=aircraft_control`, `height=56.7`. **Overpass is still 406 from a web container, as documented, but the plain map API is not**, and a small bbox plus a way-centroid computation gets the same answer |
| **Reverse-geocode as corroboration** | Mirbeau Beacon's coordinate came off the resort's own map link, which could have been inferred rather than read — reversing it to *Wolcott Avenue* (Route 9D) matched the historical description of the Tioronda estate independently |

⚠️ **A second source is what makes either usable.** The Ranch agreed to 40 m across
Census and OSM; 778 Park Ave to 15 m. Where only one source existed it is recorded
as such.

## Decisions the owner made

- **Skip both multi-place posts** — Meiji Mura + Yodoko Guest House, and Leighton
  House + Sambourne House. So no `#<fragment>` ids were minted this batch.
- Fort Lee Historic Park and 778 Park Avenue supplied by hand.
- Defaults taken and not countermanded: all eight duplicate subjects kept, all
  eleven hotel/resort promos kept, Multnomah Falls filed under **Bridal Veil, Oregon**.

## Verification

- `validate-tours-mirror.py`: **0 errors**, selftest 37/37, and **none of the 107
  warnings names a pin from this batch** (checked by matching subjects, not by eye).
- `merge-link-pins.py --check` then the real merge: 53 added, 0 skipped, 38 new
  creators, **no Dozent-account handle collisions** across 38 new handles.
- gh-pages: `git ls-files` delta exactly **68**. ⚠️ **One avatar collided** —
  `avatar-tiktok-chloebytheocean6.webp`, a creator already in the catalogue. Hashed
  both before deciding: **byte-identical**, so skipping it was a true no-op rather
  than a judgement call about overwriting. Pages took **~8 minutes**.
- `check-image-duplicates.py --pins`: all **53 heroes distinct in bytes**, and a
  10-URL live-vs-local hash sample matched 10/10. Its one ERROR is **not from this
  batch** — `beverly-mai-ninosbuildings` / `the-concourse-ninosbuildings`, the
  Singapore pair from #940, which wrote two identical files where the runbook says a
  multi-pin post shares one. Cosmetic, both pins show the right picture; left alone.

## For the owner — place candidates

`check-place-candidates.py`: **17 EXACT groups, 6 of them involving a new pin.**

- Gaylord Palms Resort ×2 · Museum of Ethnography ×2 · Rainier Tower ×2
- La Piscine ×3 (two already there, the pair the owner spotted, plus this one)
- The Skunk Train + Skunk Train Railbikes — two creators, one Fort Bragg depot
- **165 Broadway: "The Lost Singer Building" + "A::Light by Pierre Huyghe"** — the
  interesting one. Same coordinate, different subjects: a demolished tower's site and
  an artwork in the lobby that replaced it. `docs/places.md` says co-location is not
  identity, so this is a judgement call, not an automatic place.

**11 further EXACT groups predate this batch** and are still unresolved — the
Pantheon (4 entries), Casa Batlló, Hollyhock House and the Westin Bonaventure
(3 each), TWA, Leça/Piscina das Marés, MAXXI, Lloyd's, the Glass House, Hudson Yards.

## Counts

Re-derived on `4b5ff68`, and the Key facts line was stale on **all three** figures
before this batch added anything (#938, #940 and #941 landed in the hours after the
last correction): **2,318 / 429 / 305 against a real 2,474 / 469 / 323**, cities
579 → 600 and countries 68 → **69** — the third country move in four days, on the
figure that line keeps calling the one that never moves.

---

# PART TWO — what the owner found after the batch merged

The pin work above was finished and merged. Everything below started because the
owner **watched one of the videos.**

## 🔴 A pin was in the wrong city, and the evidence was already in the catalogue

`The Hudson Yards platform` (@ninosbuildings, from #940) is actually **1111
Lincoln Road** — Herzog & de Meuron's Miami Beach car park. The owner spotted it
in seconds. What makes it worth recording is that **nothing needed to be fetched
to catch it**: the stored caption reads *"Would you want to live in a parking
garage?"* beside a title saying Hudson Yards. Caption and title contradicted each
other in the same row and no check compares them.

Auditing that creator's other 69 pins on exactly that signal found a second:
a pin still titled with its raw caption (`How do you like niemeyer? …`), whose own
hero filename read `palacio-itamaraty` — so the subject *had* been identified and
only `--title` was omitted. Its coordinate was wrong too, on **N1** where the
palace is on **S1**. Both fixed in #948.

⚠️ A parallel session (#952) then found two more in the same batch — a pair filed
as **The Glass House** that were **Grace Farms, 6 km away**, and **Geisel Library**
on the wrong branch library, 5.4 km out. **Five wrong locations in one 70-pin
batch**, all of it identified from thumbnails. That method's failure rate is the
finding.

**32 pins catalogue-wide still carry a raw caption as their map label**, across
seven creators. Left alone on the owner's instruction; recorded on the board.

## My own error, from Part One

Five titles and three cities went in as plain ASCII — `Musée`, `Archéologie`,
`Besançon`, `São Paulo`, `San José del Cabo`, `Café`, `Residenzstraße`. I wrote
the batch table by hand and stripped the diacritics. **`Sao Paulo` became a
separate city** from the 48 entries spelled `São Paulo`. An accent-folded check
found it and the pre-existing `Zurich`/`Zürich` pair, so the city count went
**down by two** — the first time that line has ever decreased.

## The cache bug, and how badly I diagnosed it

The owner then reported 1111 Lincoln Road not showing as a **place** on their
phone. It took far too long, and the way it went wrong is the lesson:

🔴 **I twice told them to go and look, on the strength of SERVER state.** "The
data exists" and "the phone has it" are different claims. I read
`catalog_snapshot_age` as proof of delivery; it is proof of publication. Two
wasted round trips.

🔴 **The check that finally gave hard data is the one `CLAUDE.md` rule 11 names
first** — ask the live RPC what keys it returns. I ran it fifth.

What settled it was a **screenshot**: the marker was a **circle**, and
`MapPins.swift` has `ClusterPin` as a circle and `PlacePin` as a capsule. So the
place was not being applied at all. The catalogue was then exonerated end to end
(334 places, valid members, mirror identical, hero 200, place object
structurally identical to one working on the same phone). **Delete and reinstall
fixed it. The mechanism was never found**, and a partial publish was ruled out —
the seed is one transaction with `refresh_catalog_snapshot()` as its last
statement.

## What shipped because of it (#955, build 165)

1. **Settings → Clear Cache now clears the catalogue.** It cleared `URLCache` and
   the image cache only — so the one cache a user might need to clear was the one
   it left alone. `discardCache()` already did the right thing; nothing could
   reach it.
2. **A token match no longer buys unlimited trust** — bounded by `maxCacheAge`
   (7 days) plus a length check. ⚠️ Both guards **decline rather than discard**,
   so a failed download leaves the existing copy serving.
3. **Settings → About shows "Updated"** — when the catalogue last arrived. Added
   after the owner's verdict on build 164: *"honestly hard to test any of it."*
   They were right; the fix had shipped with nothing observable, which is the
   same property that let the original bug survive an hour of restarts.

**Merged on the owner's OK after build 165.** ⚠️ The device could not prove the
recovery works — nobody knows how to reproduce the bad cache. The four unit tests
are the real verification, including one asserting the 34-byte probe still
short-circuits, because guards like these are an easy way to silently re-inflate
the egress bill.
