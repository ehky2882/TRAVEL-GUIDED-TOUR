# HANDOFF — 2026-08-27 (session 116)

**Twenty San Francisco architecture TikToks. Nineteen shipped; the twentieth is
gone from TikTok's own servers.** Branch `claude/new-tour-links-nniny1`, cut
fresh from `origin/main` at `c5e8862`. Content only — no Swift, no SQL, no
build. **linkPins 57 → 76, makers 79 → 90.**

**NO PR OPENED** — this session's harness forbids opening one unasked. The work
is complete, validated and pushed; the branch is ready for a PR whenever the
owner wants one.

---

## What the owner sent

Twenty `tiktok.com/t/…` share links under the heading **"SF Architecture"**.
URLs and nothing else — no coordinates, no captions, no titles. Every location
in this batch was read out of the post's own caption or its own opening frame,
forward-geocoded, then reverse-verified at zoom 18.

---

## 🔴 THE ONE THAT WOULD HAVE SHIPPED WRONG: a hashtag is not a location

Link 12's entire caption is *"designed by frank lloyd wright ❤️‍🔥 came here again
on my day off and found some more gems #franklloydwright #architecture
#midcenturymodern **#sanfrancisco**"*.

There is exactly one famous Frank Lloyd Wright building in San Francisco — the
**V.C. Morris Gift Shop, 140 Maiden Lane** — and OSM carries it under that name,
so the obvious geocode returns a confident, precise, wrong answer.

**The frame says otherwise.** It shows a long open-air corridor under a
barrel-vaulted translucent skylight, terracotta walls, a planted median, gold
anodised screens, and office doors numbered 303 / 304 / 404. That is the
**Marin County Civic Center** in **San Rafael**, Wright's last major work, about
30 km north across the Golden Gate. The V.C. Morris shop is a small retail
interior with a brick facade and a spiral ramp — nothing like it.

The pin ships `city: "San Rafael"` at `37.9980274, -122.5306570`, which
reverse-geocodes to *"Judge Haley Drive & Civic Center Drive, 3501 Civic Center
Drive, San Rafael"*. **This is the Gaylord Palms case with a much larger
displacement: the creator tagged the metro they think of, not the county the
building stands in.** Do not "correct" the city back from the hashtag.

---

## 🔴 "PIAZZA ANGELA" DOES NOT EXIST — IT IS PIAZZA ANGELO

Link 4's caption reads *"Magic Space #4: **Piazza Angela** Courtyard in San
Francisco"* and the burned-in on-screen text agrees: *"ANGELA COURTYARD,"*. A
bounded forward geocode for that spelling returned **zero hits**, which is the
only reason it got checked at all.

The place is **Piazza Angelo** at **Trinity Place, 8th and Mission** — a
privately owned public square named for the developer **Angelo** Sangiacomo, with
Lawrence Argent's 92-foot *Venus* at its centre, which is precisely the twisting
mirror-polished figure in the frame. **OSM names it exactly**, as a `square` at
`37.7782857, -122.4133021`.

**The pin is titled `Piazza Angelo`; the caption is kept verbatim, so the
misspelling stays the creator's and is repeated nowhere in our data.** Same
convention as the Schweizer/"Schweitzer" case in the Orlando batch.

⚠️ A zero-hit geocode is a *signal*, not a dead end. Had the name been off by
something a fuzzy match could absorb, this would have sailed through.

---

## ⚠️ ONE CAPTION NAMES NO PLACE AT ALL

Link 2's caption is **"Tours at 1pm!!! #interiordesign #sanfrancisco
#lightingdesign #design #lighting"** — no venue, no address, no landmark.

Identified from the frame: a white neoclassical temple with a Corinthian
portico, three bronze doors and urns along the parapet, with **"THE INTERNET
ARCHIVES"** burned across it in the creator's own on-screen text. That is the
**Internet Archive** at **300 Funston Avenue** — the former Fourth Church of
Christ, Scientist — which runs building tours at 1pm. OSM names it exactly.

---

## 🔴 THE TWENTIETH LINK IS DEAD AT THE SOURCE — DO NOT RETRY IT

`https://www.tiktok.com/t/ZP8vkb5bP/` resolves to a real, well-formed id
(`@aggie.sanfrancisco/video/7660328152421387534`) and everything past that
fails:

- **oEmbed returns an empty shell** on three attempts spaced 20 s apart —
  `author_name: "@"`, `title: ""`, **no `thumbnail_url`**.
- The video page returns **HTTP 200 with 367 KB of *"Something went wrong /
  Video currently unavailable"*** and **zero `og:` tags**.

So there is no caption (hence no subject and no location), **no thumbnail (hence
no hero, and a pin with no hero cannot ship)**, and no creator name. This is the
same shape as the tenth link of the 2026-08-26 batch. **Only the owner
re-sharing a live link fixes it.**

⚠️ Unlike the eleventh link of the later Orlando batch, this one is **not** a
`/photo/` URL — it is an ordinary `/video/` post that has simply gone. The
photo-carousel limitation is a separate, permanent one.

---

## ✅ All nineteen heroes opened and read against their captions — zero wrong subjects

Twelve carry the subject's name burned into the frame: *SHELL BUILDING* carved
in granite, *CROCKER GALLERIA / San Francisco*, *The Bohemian Club* over Jo
Mora's Bret Harte relief, *THE INTERNET ARCHIVES*, *AURA 📍Grace Cathedral*,
*Tonga Room*, *Legion of Honor 📍 San Francisco*, *PARISIAN PALACE AT LANDS END
/ LEGION OF HONOR*, *Portsmouth Square Redesign*, *Four Seaons San Francisco at
Embarcadero* (sic), *How San Francisco's Chinatown Survived*, *VISITED SAINT
MARY'S*.

The rest are confirmed by subject: **One Maritime Plaza**'s exposed X-braced
steel exterior frame (exactly what its caption is about), the **SFPL Main
Library**'s five-storey elliptical skylit atrium, **California Academy of
Sciences**' undulating living roof with its circular skylight domes, the **Palace
Hotel Garden Court**'s leaded-glass dome and Austrian crystal chandeliers, and
**Hearst Castle**'s Neptune Pool with its Greco-Roman temple facade.

⚠️ **Two look-alike risks were checked deliberately**: the two **Legion of
Honor** posts (same building, two creators — see below), and **Saint Mary's
Cathedral** against Grace Cathedral, which are the city's two cathedrals and
could not be less alike once opened (a 1971 hyperbolic-paraboloid concrete
saddle vs. a Gothic Revival nave).

---

## ⚠️ TWO PINS SIT ON ONE COORDINATE, AND THAT IS CORRECT

Links 13 (`@lyndsielocks`) and 14 (`@theluriegroup`) are **two different posts
about the same building** — the Legion of Honor — so both pins carry
`37.7845556, -122.5009620`. Their heroes are visibly different (the Court of
Honor colonnade through the triumphal arch vs. the arch seen over flowering
protea), and the perceptual sweep does not even rank them among the five
closest pairs in the batch.

Coincident markers can never be separated by zooming — grid clustering buckets
identical coordinates into the same cell at every pitch — which is exactly what
`MapClustering.needsDisambiguation` and the stacked placecards from session 93
exist for. **Nothing to fix; recorded so nobody "deduplicates" it later.**

---

## 🔴 THE HANDLE SUFFIX ON THE HERO SLUG EARNED ITS KEEP THREE TIMES

`hero_slug()` appends the creator's handle because a bare subject slug collides
with the Atlas tour of the same subject on gh-pages. Three of this batch's
nineteen would have collided:

| bare stem already on gh-pages | what it belongs to | what shipped instead |
|---|---|---|
| `images/grace-cathedral_hero.webp` | the Atlas SFO tour | `grace-cathedral-andrewtourssf_hero.webp` |
| `images/california-academy-of-sciences_hero.webp` | the Atlas SFO tour | `california-academy-of-sciences-worthyourwallet_hero.webp` |
| `images/chinatown_hero.webp` | an Atlas tour | `chinatown-urbanistariel_hero.webp` |

Without the suffix each of those pushes would have **overwritten a live Atlas
tour's hero**, and since #567 a phone that has downloaded that tour reads its
photographs off its own disk and would never see the correction. **Three
near-misses in one batch is the strongest evidence yet that this rule is load-bearing.**

---

## ⚠️ THREE HEROES WERE RE-CROPPED BY HAND — the vertical `--focus` gap, again

`render_hero` crops with `centering=(focus, 0.5)`. **`--focus` moves the square
sideways and there is still no vertical lever** — and for a 9:16 phone video the
square is width-limited, so `--focus` does nothing at all on this batch's
sources. The centred square is the only square the tool can produce.

Three of nineteen needed a different one, re-rendered through a mirror of the
tool's own pipeline (same `trim_bars`, same square-then-blurred-pad, same
encode) with a vertical centering parameter, under the **same filename** so
`Tours.json` is untouched:

| pin | why | vertical focus |
|---|---|---|
| **Saint Mary's Cathedral** | the centred square was almost entirely the creator's face; the cathedral's saddle roof — the whole point — was above the crop | **0.0** |
| **The Garden Court, Palace Hotel** | sliced *"A stunning / Afternoon"* through the middle, leaving a stranded *"Tea"* | **0.15** |
| **The Shell Building** | the carved *SHELL BUILDING* sat hard against the top edge | **0.30** |

⚠️ **One clipped hero was deliberately LEFT ALONE**: California Academy of
Sciences loses nothing but the creator's own *"This is one of Californias
coolest museums"* strapline, which is a format label, not the subject's name.
**Read what the clipped text says before reaching for a fix** — the Super
Nintendo World precedent.

**A vertical `--focus` remains the obvious follow-up and was again kept out of a
content batch.** This is the third batch to pay for it by hand.

---

## ⚠️ EIGHT ARCHITECTS VERIFIED THIS SESSION, AND ONLY TWO ARE IN THE VOCABULARY

**In, and used by name:** **Frank Lloyd Wright** (Marin County Civic Center) and
**Renzo Piano** (California Academy of Sciences). Both carry `Designed by a
Master` alongside the named tag — `Tag.matches` performs no implication and the
curated home shelf is keyed on that literal string, so **do not "tidy" the
generic tag away**.

**Absent, so those pins ship the generic `Designed by a Master` fallback:**

- **Pietro Belluschi** and **Pier Luigi Nervi** — Saint Mary's Cathedral
- **Julia Morgan** — Hearst Castle
- **Skidmore, Owings & Merrill** — One Maritime Plaza, and 345 California Center
  (the Four Seasons tower; SOM is named in that post's own caption)
- **George Kelham** — the Shell Building
- **James Ingo Freed / Pei Cobb Freed & Partners** — SFPL Main Library
- **Lewis Hobart** — the Bohemian Club (untagged; the caption discusses no
  authorship, so not even the generic tag)
- **Trowbridge & Livingston** — the Palace Hotel Garden Court (same reasoning)

Adding names is a `Models/Tag.swift` **code** change and was deliberately kept
out of a content batch. **Julia Morgan and SOM are the two most conspicuous
absences in the catalogue right now.**

⚠️ **Lawrence Argent was correctly NOT tagged** for Piazza Angelo. He made the
*Venus* that stands in the square; he did not design the square. The Kiki Smith
rule — a single artwork inside or on a place is not authorship.

---

## ⚠️ THREE SOURCE CLAIMS WERE DELIBERATELY NOT CARRIED INTO OUR DATA

1. **The Four Seasons video's on-screen text reads "Four Seaons"** — the
   creator's typo, burned into the frame only. The pin is titled **Four Seasons
   San Francisco at Embarcadero**; the TikTok caption itself spells it correctly,
   so nothing in our data repeats the error.
2. **Grace Cathedral's post is about AURA**, a projection-mapped show the caption
   says runs *"now through the end of December"* — i.e. it has ended. **The pin
   is titled for the venue, not the show**, so it cannot go stale; the caption
   preserves the AURA details, the discount code and the address verbatim. Same
   convention as the UFL/Inter&Co pin.
3. **Portsmouth Square's post shows a REDESIGN that has not been built** —
   renderings by SWA and MEI, per the caption. The pin is titled for the square
   as it is; nothing we author asserts the new park exists.

---

## ⚠️ THE FOUR SEASONS PIN REVERSE-GEOCODES TO A DIFFERENT STREET, AND IS RIGHT

`222 Sansome Street` reverse-geocodes at zoom 18 to *"Serenity Dental Spa, **345
California Street**"*. That is not an error: the **Four Seasons Hotel San
Francisco at Embarcadero occupies floors 38–48 of 345 California Center**, whose
hotel entrance is on Sansome. The reverse lookup landed on the correct enclosing
building — the Super Nintendo World / Universal Epic Universe shape.

Two others land on ground-floor tenants at the right address and are likewise
fine: the Shell Building returns *"Happy Donuts, 100 Bush Street"*, and Crocker
Galleria returns *"Julie's Kitchen, 50 Post Street"* — **and "Julie's Kitchen" is
legible in that pin's own hero photograph**, which closes the question
independently.

---

## 🔴 PINNED CREATORS NOW OUTNUMBER ATLAS STUDIOS NEARLY TWO TO ONE

`SettingsView` renders `dataService.makers.count` raw. After this batch:
**34 Atlas studios against 56 pinned creators**, out of 90 makers — 46 TikTok,
9 YouTube, 1 Instagram. The number has been flagged as misleading since it stood
at four pins.

**The owner still has the three options — count only makers with a `userId`,
count only makers with a published Atlas tour, or split the row into "Dozents"
and "Creators" — and still has not made the call.**

---

## Verification

- **30 images to gh-pages by pure plumbing** (`upload-images.py` needs the `gh`
  CLI a web session lacks): blobless fetch → temp `GIT_INDEX_FILE` →
  `hash-object -w` → `write-tree --missing-ok` → `commit-tree`.
  **`git ls-remote` re-checked immediately before the push**; tree diff
  **exactly 30 additions, 0 deletions, 0 modifications, nothing outside
  `images/`**; none of the 30 among gh-pages' 7,716 existing paths. Commit
  `7bb88e78` on base `afe3bc27`.
- **19 heroes + 11 avatars = 30 files; 30 referenced, 0 orphaned.** Every
  creator got a real profile picture — no maker falls back to the platform mark
  this batch.
- **0 byte-duplicate heroes.** A perceptual 32×32 sweep puts the **closest pair
  at 30.5** (identical pictures score under 1), and it is ivy-green Bohemian Club
  against the gilded Garden Court — the tonal false positive the two-stage
  checker exists to reject.
- **0 duplicate tour ids, 0 duplicate stop ids, 0 duplicate maker ids, 0
  already-pinned sourceURLs, 0 hero-filename collisions** (checked against both
  the catalogue and the full gh-pages tree).
- **`make-link-pin.py --selftest` 71/71** (62 before Pillow was installed — the
  nine image checks are skipped without it, which is worth knowing).
- **A Python validator mirror** — vocabulary parsed from **both**
  `Models/Tag.swift` **and** `scripts/validate-tours.swift`, refusing to run if
  they disagree or either parse is empty (they agree at **373 tags**) — was
  **self-tested against 43 injected fault classes, 43/43 caught**, then run
  clean: **0 errors, 2 warnings across 1,552 tours + 76 link pins**. **Both
  warnings are pre-existing**, confirmed by running the same mirror against
  `origin/main`, which reports the identical pair (VIA 57 West's transcript gap,
  Bedrock Caverns' deliberate null `walkingDistanceMeters`). **This batch
  contributes zero errors and zero warnings.**
- `Tours.json` confirmed **byte-stable under a Python re-dump at `indent=2`
  before editing**; diff **961 insertions / 0 deletions**.
- **CI has not run: no PR is open.**

---

## Owed / flagged

- **The dead link** — `https://www.tiktok.com/t/ZP8vkb5bP/`. Nothing on our side
  can recover it; the owner would need to re-share a live link.
- **A vertical `--focus` for `make-link-pin.py`** — third batch hand-cropped.
- **Julia Morgan, SOM, Belluschi, Nervi, Kelham, Freed, Hobart** for
  `Models/Tag.swift`, whenever an architect-vocabulary PR is next cut.
- **The Settings → About creator count** — owner decision, still open.
- **No PR opened.** The branch is pushed and ready.
