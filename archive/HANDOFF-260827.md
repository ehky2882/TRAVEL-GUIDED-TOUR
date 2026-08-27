# HANDOFF — 2026-08-27 (session 116, web/PM: content)

**Ten Atlanta TikToks, all ten shipped.** The owner sent ten share links under the heading
*"Atlanta Architecture"* — URLs and nothing else, no coordinates and no captions. Branch
`claude/new-tour-links-yr5o7r`, restarted clean off `origin/main` (`c5e8862`). **linkPins 57 → 67,
makers 79 → 89.** Content only — no Swift, no SQL, no build. **NO PR OPENED** (this session's
harness forbids opening one unasked).

---

## 1. What shipped

| # | Pin | Category | Creator | Coordinate |
|---|---|---|---|---|
| 1 | Swan House | architecture | TikTok @jr.enrile | 33.8404381, -84.3875580 |
| 2 | Atlanta Marriott Marquis | architecture | TikTok @sahiltnt | 33.7616624, -84.3851103 |
| 3 | Historic Oakland Cemetery | history | TikTok @erininatlanta | 33.7486896, -84.3721635 |
| 4 | Cosm Atlanta | musicAndPerformance | TikTok @wheresdonnanow | 33.7848937, -84.4108705 |
| 5 | The Garden Room | foodAndDrink | TikTok @gloriandjustin | 33.8399596, -84.3826880 |
| 6 | World of Coca-Cola | culturalHeritage | TikTok @lifebyculture | 33.7628981, -84.3925521 |
| 7 | Georgia Aquarium | natureAndParks | TikTok @divyadiscovers | 33.7632675, -84.3951173 |
| 8 | Fernbank Museum of Natural History | culturalHeritage | TikTok @fernbankmuseum | 33.7739301, -84.3278358 |
| 9 | Fernbank Forest | natureAndParks | TikTok @itsjanasoli.co | 33.7756184, -84.3213757 |
| 10 | Mercedes-Benz Stadium | architecture | TikTok @morganjamesjr | 33.7554123, -84.4008493 |

**Ten links, ten creators, ten pins — no duplicates, nothing parked.** The first batch since the
link-pin work began where every link was alive, every one was a `/video/` URL, and every one
carried a caption, an author and a thumbnail. Contrast the two Orlando batches, which lost one
link each (a dead post, then a dead `/photo/` post).

---

## 2. 🔴 THE HANDLE SUFFIX ON A HERO SLUG STOPPED A REAL OVERWRITE THIS SESSION

`hero_slug()` appends the creator's handle to every pin hero's filename stem
(`mercedes-benz-stadium-morganjamesjr_hero.webp`). Session 114 folded that in and its comment
called a bare subject slug "a real bug". **It was, today.** gh-pages already carries, from the
Atlanta tour batch another session is staging:

```
images/mercedes-benz-stadium_hero.webp
images/oakland-cemetery_hero.webp
images/atlanta-flatiron_hero.webp   (+ 6 more)
```

**Two of my ten subjects would have written straight over an existing Atlas tour's hero** — and
since #567 a phone that has downloaded a tour reads its photographs off its own disk and never
asks the server again, so that corruption would never have been corrected on a downloaded tour.
With the suffix: **0 of 20 target paths pre-existed**, checked against all 5,801 `images/` paths
on the branch.

**⚠️ THE CONSEQUENCE, WHICH IS NOT A DEFECT BUT IS WORTH THE OWNER KNOWING:** once the staged
Atlanta tour batch merges, **Mercedes-Benz Stadium and Oakland Cemetery will each have an Atlas
tour AND a link pin at the same site.** That is exactly what the place layer exists for — but a
place requires **exact coordinate equality** and human approval, so nothing was created here.

---

## 3. Locations — none supplied, all derived and reverse-verified

Every coordinate was read out of the post's own caption or frame, forward-geocoded against
Nominatim **bounded to an Atlanta viewbox**, then reverse-verified at zoom 18.

- **🔴 THE GARDEN ROOM WAS THE THIN ONE, AND THE TRAP WAS THE ONE WAREHAUS FOUND.** Its whole
  caption is *"Garden Room dinner ftw 🤍 #atlantarestaurants"* — a venue name, no city block, no
  address. OSM has **no Garden Room node at all**. The restaurant's own site gives **88 West Paces
  Ferry Road NW**, and that address returns **three** OSM candidates within 80 m. **The
  `place/house` node literally tagged "88" reverse-geocodes to First Citizens Bank at number 79 —
  the other side of the street.** The two that reverse-verify onto 88 W Paces Ferry are the St.
  Regis building and the Atlas restaurant node inside it; the pin takes the latter.
  **When one address returns several hits, reverse each candidate and read the road back — the
  house-numbered one is not automatically right.**
- **✅ AND THE PIXELS CLOSED IT.** The hero has **"Dinner vibe at The Garden Room"** burned into
  the frame, over a skylit glasshouse dining room with palms, olive trees and chandeliers —
  matching the restaurant's own description. The identification is confirmed by the image, not
  only by a web search.
- **⚠️ TWO REVERSE-GEOCODES LANDED ON SOMETHING ELSE AND BOTH COORDINATES ARE RIGHT.** Swan House
  reverse-geocodes to *a car park on Andrews Drive*, and Fernbank Forest to *a house on Barton
  Woods Road* — but **both points were proved to lie inside their own named OSM polygon** (Swan
  House `way/267926896`, Fernbank Forest `way/28912795`, tested by point-in-polygon against the
  fetched geometry). This is the Inter&Co Stadium case: the reverse-geocoder prefers the nearest
  *addressable* feature and will happily name something the point merely sits near.
  **A reverse-geocode landing on a road, a car park or a neighbour's house is not evidence of a
  bad point — fetch the polygon and test containment.**
- **⚠️ COSM ATLANTA IS NOT IN OSM.** Every unbounded search returns nothing. It is inside **The
  Interlock**, 1115 Howell Mill Road NW, which OSM does carry and which reverse-verifies by name
  exactly. The Evermore Bay precedent: pin the host feature the video is actually inside.
- **⚠️ OAKLAND CEMETERY's centroid reverse-geocodes to "Old Hunter Street Drive"** — one of the
  cemetery's own internal avenues, and the point is inside the `landuse=cemetery` polygon
  (verified). The Lymmo case again.
- **⚠️ FERNBANK MUSEUM AND FERNBANK FOREST ARE TWO PINS, 626 m APART, AND THAT IS DELIBERATE.**
  The museum is the Gund building at 767 Clifton Rd; the forest is the 65-acre old-growth
  preserve on the same campus. Two creators, two subjects, two videos — the MAC USP / Super
  Nintendo World shape. **The forest pin sits at its polygon's centroid rather than at the
  trailhead**, which keeps the two pins clearly distinct on the map; the closest in-polygon point
  to the museum is only 66 m away and would have collided visually.
- **⚠️ CITY IS `Atlanta` ON ALL TEN, INCLUDING THE TWO FERNBANK PINS, AND THAT IS A JUDGEMENT.**
  OSM files Fernbank Forest under *"Druid Hills, North Decatur, DeKalb County"* with no Atlanta at
  all. But the museum's postal address is Atlanta 30307, OSM's own museum record carries Atlanta,
  and the forest video's **own burned-in text reads "📍 Atlanta, Georgia."** The Old Town /
  Celebration shape: OSM's `place` assignment disagreeing with the postal city. **Do not "correct"
  these to Druid Hills.**

---

## 4. ⚠️ ONE HERO IS FLAGGED, NOT REFUSED — the Mercedes-Benz Stadium frame may not be a photograph

The thumbnail is an aerial of Mercedes-Benz Stadium with the eight-petal oculus roof partly open
over a football pitch. **The subject is unambiguously right.** What is uncertain is whether the
frame is a real photograph: zoomed in, the halo board's crests read as indistinct flag-shaped
blobs, the crowd is a uniform noise texture, and the surrounding streetscape has the smoothed,
smeared quality of an AI upscale or render. The caption's hashtags —
`#tiktokgrowthchallenge #MegaProjects #EngineeringTimelapse #ArchitectureReveal` — are the
signature of a generated-megaproject account.

**A link pin re-hosts only the thumbnail and we never download the video, so no other frame
exists** (the Brick Award lesson). The options are ship-and-flag or drop the pin. It is shipped
and flagged, following the **DIFC Gate precedent**, where a likely-AI hero was raised to the owner
and kept on their instruction. **Removing it is a one-line deletion from `linkPins` plus its
maker row.** The other nine heroes are ordinary phone footage.

---

## 5. Hero audit — all ten opened and read against their captions, zero wrong subjects

**Six carry their subject's name burned into the frame:** *The Hunger Games Hotel!! Atlanta, GA*
(over Portman's ribbed atrium), *Things to do in Atlanta 📍 COSM ATL*, *Dinner vibe at The Garden
Room*, *World of Coca-Cola / Atlanta*, *FERNBANK FOREST 📍 Atlanta, Georgia*, and Oakland's
*"Atlanta's oldest public park … 48 acres"*. The rest are confirmed by subject: Swan House's
Shutze facade above its cascading fountain stair; the Georgia Aquarium's Ocean Voyager window with
a whale shark (the only US aquarium that has one); Fernbank's Great Hall under the *GIANTS OF THE
MESOZOIC* mounts, posted by the museum's own account.

**⚠️ ONE HERO IS CLIPPED AND WAS DELIBERATELY LEFT ALONE.** Oakland Cemetery's centred square crop
slices the bottom caption mid-line. **Read what the clipped text says before reaching for a fix** —
what is lost is a descriptive sentence, not the subject's name, and the mausoleum is whole and
centred. The vertical `--focus` lever `render_hero` still lacks (it crops with
`centering=(focus, 0.5)`) remains the open follow-up from session 115.

**⚠️ OAKLAND'S OWN VIDEO CALLS IT "Atlanta's oldest public park"**, which is what settled its
`Park` place-type tag over a monument or civic one.

---

## 6. Tags, and what was deliberately not asserted

**⚠️ THREE MORE ARCHITECTS VERIFIED AND NONE IS IN THE VOCABULARY:** **Philip Trammell Shutze**
(Swan House, 1928), **John Portman** (Marriott Marquis, 1985) and **Graham Gund** (Fernbank
Museum, 1992) — checked against all 323 architect tags, zero hits. Swan House and the Marquis ship
the generic **`Designed by a Master`**; adding the names is a `Models/Tag.swift` **code** change,
kept out of a content batch as usual. **Fernbank was NOT given the master tag** — the video is
about the dinosaurs, not the building, and the tag would be asserting something the pin does not
show.

**⚠️ NO DATE, COST OR SUPERLATIVE FROM ANY CAPTION WAS CARRIED INTO OUR DATA.** The stadium
caption's *"$1.5B+"*, the aquarium's *"more aquatic life than anywhere else in the world"*, the
Swan House caption's ticket price and its *"antebellum days"* framing (the house is 1928, not
antebellum) all stay inside `longDescription`, which is the creator's own words verbatim. **Nothing
we author repeats them.**

---

## 7. Verification

- **20 files to gh-pages by pure plumbing** (`upload-images.py` needs the `gh` CLI a web session
  lacks): blobless fetch → temp `GIT_INDEX_FILE` → `hash-object -w` → `write-tree --missing-ok` →
  `commit-tree`. Tree diff **exactly 20 additions, 0 deletions, 0 modifications, nothing outside
  `images/`** (commit `a93c06d4`).
- **⚠️ gh-pages MOVED TWICE AROUND THIS PUSH.** It went `7bb88e78 → 384e0e24` while the heroes were
  being generated, so the tree was **rebuilt on the new base** rather than pushed over it; and it
  moved again to `97292af7` immediately after. **`git ls-remote` was re-checked in the same command
  as the push**, and afterwards `a93c06d4` was confirmed **still an ancestor of head with all 20
  paths in the head tree.** On a busy day this branch moves within minutes.
- **0 byte-duplicate heroes.** Closest perceptual pair in the batch **47.2** on a 32×32 sweep
  (identical pictures score under 1; the last two batches' closest were 33 and 35).
- **0 duplicate tour ids, 0 duplicate stop ids, 0 duplicate maker ids, 0 already-pinned
  sourceURLs, 0 hero-filename collisions**, all checked against the merged catalog.
- **No new pin is within 500 m of any existing catalog tour** — Atlanta has no Atlas tours live
  yet. Closest pair inside the batch is **241 m** (World of Coca-Cola ↔ Georgia Aquarium, genuinely
  adjacent in Pemberton Place and plainly different subjects).
- **Validator: 0 errors, 2 warnings across 1,552 tours + 67 pins — and both warnings are
  pre-existing**, confirmed by running the same mirror against `origin/main`'s catalog, which
  reports the identical pair (VIA 57 West's transcript gap, Bedrock Caverns' deliberate null
  `walkingDistanceMeters`). **Atlanta contributes 0 errors and 0 warnings.** No Swift toolchain in a
  Linux web session, so this ran through a **Python mirror of `validate-tours.swift`** that parses
  the vocabulary from **both** `Models/Tag.swift` **and** the Swift validator and refuses to run if
  they disagree or either parse is empty (they agree at **373 tags**), **self-tested against 40
  injected fault classes first — 40/40 caught.**
- `Tours.json` confirmed **byte-stable under a Python re-dump at `indent=2`** before editing; diff
  **532 insertions / 0 deletions**.
- `make-link-pin.py --selftest` **71/71** (it reports 62/62 without Pillow — install Pillow before
  reading the number as a pass).
- **CI has not run: no PR is open.**

---

## 8. Noticed, not acted on

- **⚠️ FIVE LINK PINS SHARE ONE `sourceURL`, AND IT IS DELIBERATE.** `linkPins` holds 57 entries
  against 53 distinct source URLs; the repeat is
  `@malata.antwerp/video/7529985928014679328`, shipped as five pins — Lucca, Arezzo, Milan,
  Piazzola sul Brenta, Parma — which is how somebody resolved the *"Top 5 Italian antique markets"*
  link that session 112 parked as *"covers five cities and cannot honestly be one pin."* The ids
  are distinct and the validator is clean. **A dedupe check that keys on `sourceURL` alone will
  read this as a defect. It is not.**
- **⚠️ `scripts/session-start.sh` reports `(gh unavailable)`** in this container and takes over two
  minutes to return. Its live HTTP and branch sections still work.
- **✅ THE ATLANTA TOUR BATCH IS IN THE TRACKER — checked, not assumed.**
  `drafts/AUDIO-PENDING-SURVEY.md` on `origin/main` carries the row as of 2026-08-26: **30
  single-stop tours, no walks, 30 MP3s outstanding, under a new Atlas Studio ATL**, staged on
  `claude/amsterdam-handoff-preserve-hlhyp8`. The earlier "staged with no tracker row" flag is
  resolved. **This confirms the overlap above is real and imminent** — that batch's Mercedes-Benz
  Stadium and Oakland Cemetery tours will land alongside this batch's pins for the same two places.
  ⚠️ **The audio-pending queue is NOT empty**; do not report it as such.
- **⚠️ Pinned creators now outnumber Atlas studios 55 to 34 in the raw `dataService.makers.count`
  the Settings → About row renders** — this batch took them 45 → 55. The owner's options (userId-only,
  published-tour-only, split the row) are unchanged and the decision is still owed.
