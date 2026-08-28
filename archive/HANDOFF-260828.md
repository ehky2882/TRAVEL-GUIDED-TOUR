# HANDOFF 2026-08-28 — thirty link pins; Luxembourg and Norway join the catalogue

Session 120. Branch `claude/linked-tours-send-ahlhiy`, cut clean off `origin/main`
at `b35cdc9`. Content only — no Swift, no SQL, no build. **NO PR OPENED** (this
session's harness forbids opening one unasked).

**linkPins 124 → 154, makers 133 → 155, countries 30 → 32.** Tours unchanged at
1,552; places unchanged at 31.

> **⚠️ AMENDED AFTER MERGE — the owner pulled four pins and two creators, so the
> shipped figures are `linkPins` **150** and makers **153**.** See
> "Owner pulled four pins" at the end of this file. Everything between here and
> there describes the batch as originally wired.

---

## What arrived

Thirty links: 21 TikTok, 8 Instagram, 1 YouTube. Eleven carried a subject name
and/or a coordinate; nineteen were bare.

**✅ ALL THIRTY WERE PINNABLE** — no dead posts, no `/photo/` carousels. Third
fully intact batch running.

## The things worth carrying forward

### 🔴 A PLUS CODE IS A COORDINATE FORMAT NOBODY HAD SEEN HERE BEFORE, AND IT DECODES CLEANLY

Two subjects arrived as **Open Location Codes** rather than lat/lon —
`FVM9+24 London` and `PXWR+6W New York`. `pip install openlocationcode` fails to
build a wheel in this container, so OLC encode/decode/`recoverNearest` were
implemented by hand (`/tmp/olc.py` in-session; ~40 lines).

**⚠️ VERIFY AN OLC IMPLEMENTATION AGAINST THE OFFICIAL TEST VECTORS BEFORE
TRUSTING IT.** My first sanity check used a *remembered* code for Google HQ and
"failed" — the recollection was wrong, not the code. The two official vectors
(`7FG49QCJ+2V` → 20.3700625, 2.7821875 and `7FG49Q00+` → 20.375, 2.775) both
match exactly and encode round-trips. Both decoded points then reverse-geocoded
onto their subject **by name**: *Embassy of the United States, 33 Nine Elms Lane*
and *555 West 18th Street, Chelsea*.

### 🔴 THE YOUTUBE LINK NAMES NO PLACE AND THE PAGE CANNOT BE FETCHED — THE THUMBNAIL SETTLED IT

Title: *"Why Canada's Lost Utopia Failed"*. The watch page resolves to Google's
`/sorry/` interstitial from this datacenter IP (documented, session 112), so the
description is unreachable; `WebFetch` returned only the nav shell. **The
maxresdefault thumbnail identified it in one look: Safdie's stacked concrete
boxes — Habitat 67, Montreal**, confirmed against OSM's `Habitat '67` node at
2600 Avenue Pierre-Dupuy. ⚠️ oEmbed still works from here; only the watch page
is blocked, so `--url` on the canonical watch URL is unaffected.

### 🔴 OVERPASS IS UNREACHABLE FROM THIS CONTAINER — ALL THREE MIRRORS

`overpass-api.de` resets the connection; `overpass.kumi.systems` and
`overpass.private.coffee` both return `Internal Server Error` on any query,
valid or not. The agent proxy reports `recentRelayFailures: []`, so it is them,
not us. **Nominatim works fine.** Every geometry question this batch needed was
answered with forward + reverse geocoding at zoom 18 plus targeted web lookups.
Budget for this: previous sessions leaned on Overpass for containment tests.

### 🔴 THE HANDLE SUFFIX PREVENTED TWO LIVE-HERO OVERWRITES

`images/habitat-67_hero.webp` and `images/little-island_hero.webp` are **live
Atlas tour heroes on gh-pages**, and two of my subjects are those same places.
A bare subject slug would have written straight over both — and since #567 a
phone that has downloaded a tour reads its photographs off its own disk and
would keep the wrong picture forever. With the suffix: **0 of 46 target paths
pre-existed**, checked against all 5,894 `images/` paths.

**⚠️ One file WAS already live and was EXCLUDED rather than overwritten:**
`avatar-tiktok-urbanistariel.webp`. `@urbanistariel` already had a maker row and
the uuid5 scheme reproduced the identical id and avatarURL, so the merge
collapsed it. **46 files generated, 45 uploaded.**

### 🔴 A MISSING TRAILING NEWLINE SILENTLY DROPPED A FILE FROM THE UPLOAD

`'\n'.join(files)` written with no trailing newline, fed to `while read -r f`,
loses the **last** line. The first tree came out **44 files, not 45** — the
Washington Square Arch hero would have shipped as a 404 hero. Caught by
comparing the staged count against the list length before pushing.
**`grep -c .` counts entries; `wc -l` counts newlines, and they differ by one
exactly when this bug is present.**

### ⚠️ THREE COORDINATES MOVED, EACH FOR A DIFFERENT REASON

- **Handel Hendrix House** — supplied point reverse-geocoded to *Laurence Coste,
  20a Brook Street*, a jeweller on the **opposite pavement**. OSM names the
  museum exactly at number 25, 24 m away. Moved. The Leinster Gardens shape:
  read the road **and the number**.
- **Amagansett** — the museum is not findable by name in Nominatim's fuzzy
  search, but a search on its published address (**160 Atlantic Avenue**)
  returns `Amagansett U.S. Life-Saving & Coast Guard Station` exactly. Moved
  26 m onto that node.
- **The Macy's holdout** — supplied point landed on a 34th St–Herald Square
  subway entrance on **6th Avenue**. The building is the **Million Dollar
  Corner, 1313 Broadway**, 30 m west; the pin now sits on it. ⚠️ **My first
  guess, 1372 Broadway, was 262 m wrong** (that address is in the Garment
  District at 37th) — the web search corrected it.

### ⚠️ THREE HEROES ARE SYNTHETIC AND ONE IS DIGITALLY DAMAGED — FLAGGED, NOT RESOLVED

- **Empire Theatre (#1)** — the caption **self-discloses**: *"(Images were
  recreated, but the history is the story.)"* and the frame IS the recreation
  (smeared crowd, generic machinery). The Verrazzano signature, but there the
  pixels proved genuine; here they do not.
- **The Brooklyn Bridge Caissons (#3)** — an AI composite with **no disclosure**:
  over-rendered caisson workers, muddled cable geometry on the bridge below.
- **The Octagon (#5)** — an AI render with no disclosure, and it **materially
  misrepresents the building**: the real Octagon is a five-storey blue-grey
  rotunda attached to two modern apartment wings; the frame shows a
  free-standing two-storey pavilion in cherry blossom.
- **Habitat 67 (#12)** — the building is genuine and correctly drawn, but the
  frame is **digitally damaged**: cracked windows, a spray-painted maple leaf,
  dead planters, a storm sky. Habitat 67 is well-maintained and sought-after.

**Shipped and flagged on the DIFC Gate footing — but the Mercedes-Benz Stadium
precedent says the owner may well pull one or more.** A link pin re-hosts only
the thumbnail, so no other frame exists.

### ⚠️ THREE HEROES ARE WEAK BUT NOT WRONG

**Handel Hendrix House** shows archive footage of Hendrix on stage; **the
Guggenheim** shows a sketchbook and hands; **the Met** shows a Twombly canvas
with a cartoon warthog sticker over it. Right subjects, no view of the place —
the Yonemoto Coffee / Hotel Komugi shape.

### ⚠️ ONE HAND RE-CROP; THE VERTICAL `--focus` GAP, SIXTH BATCH RUNNING

`render_hero` crops at `centering=(focus, 0.5)`, so for a 9:16 phone video the
square is width-limited and **`--focus` does nothing at all**. The **Eastern
Street gas lamp** was re-rendered at vertical focus **0.24** through a mirror of
the tool's own pipeline (same `trim_bars`, same blur/pad, same filename so
`Tours.json` is untouched), recovering the creator's own title
**被遺忘的煤氣燈 / 西營盤** which the centred square had sliced.

**⚠️ Four other clipped headers were deliberately LEFT ALONE** — US Embassy
(lost line is *HIDDEN*), IAC (*THE WORLD'S BEST*), Empire Theatre and Habitat
67. All are topic straplines, not the subject's name (the California Academy
rule). **Habitat 67 could not be fixed anyway**: it is a 16:9 source, so the
square is height-limited and the title spans nearly the full width — the Depot
MVRDV case.

### ⚠️ ARCHITECT TAGGING RULE APPLIED, AND ONE JUDGEMENT CALL DECLARED

The documented rule is caption-driven (the Jules Dalou / Ammann rule): tag the
architect only where the source makes authorship the point. Applied with one
addition — **where the subject already exists as an Atlas tour, match that
tour's architect tagging**, so the two entries share shelves and a future place
page is coherent.

- **Kept:** `Christian de Portzamparc` (named in the caption), `Frank Gehry`,
  `Frank Lloyd Wright` (named), `Stanford White`, `George Gilbert Scott`,
  `Thomas Heatherwick` — the last five all matching their sibling Atlas tour.
- **Dropped:** `Alexander Jackson Davis` from The Octagon and `Designed by a
  Master` from the US Embassy — no Atlas sibling and no mention.
- **⚠️ `John Soane` on Dulwich Picture Gallery is a JUDGEMENT, not the rule.**
  The caption never names him; I kept the tag because the post is an
  architecture podcast asking whether this is the first purpose-built public art
  gallery in the world, which makes the design the subject. Reversible.
- **Absent from the vocabulary, shipping the generic tag:** **Moshe Safdie**
  (Habitat 67), **John Augustus Roebling** (Brooklyn Bridge), **William Henry
  Barlow** (St Pancras train shed), **KieranTimberlake** (US Embassy),
  **José Ignacio Linazasoro** (Escuelas Pías — *named on screen by the
  creator*). **Safdie and Roebling are the two most conspicuous absences.**

### ⚠️ ONE CREATOR NOW HOLDS THREE MAKER ROWS

`@lectec` exists as **YouTube**, `@lectec.science` as **TikTok**, and this batch
adds `@lectec.science` on **Instagram**. The maker id is uuid5 over
`<platform>:@handle`, so that is the scheme working as designed — but it is the
first time one person has appeared three times (wienerberger was the first at
two). Merging would be a hand-edit.

### ⚠️ ALL NINE INSTAGRAM CREATORS SHIP `avatarURL: null`, BY DESIGN

Instagram's embed exposes no creator avatar; the tool's own selftest pins this.
They fall back to the platform mark. **0 dangling avatar URLs**, checked
explicitly.

### ⚠️ FIVE NEW PLACE CANDIDATES, NONE CREATED

`check-place-candidates.py` reports the batch's pins beside their existing Atlas
tours: **Guggenheim 29 m · Met 38 m · Little Island 89 m · IAC Building 268 m ·
Habitat 67 372 m**. Its one EXACT group remains the **pre-existing Barcelona
deferral**. Two more the checker's title rule does not catch and a human should:
**Washington Square Arch vs Washington Square Park (26 m)** and **St Pancras
International vs "St Pancras & King's Cross" (121 m)**.

**🔴 AND ONE OF THOSE PAIRS EXPOSES A PRE-EXISTING DEFECT IN AN ATLAS TOUR.**
The **IAC Building** tour sits at `40.7432, -74.0083`, which reverse-geocodes to
**West 15th Street** — 268 m south of the building at 555 West 18th Street. It
is **geofenced**, so at a 30 m radius that tour would never fire at the
building. Flagged, not fixed: moving a geofenced tour changes where its audio
plays, and coordinate and radius are one decision. **⚠️ By contrast the Habitat
67 tour's 372 m offset is NOT an error** — it sits on the Promenade de la
Cité-du-Havre, the public vantage opposite a private residential building, which
is the documented Chicago/Barcelona convention. Do not "correct" it.

### ⚠️ TOOLING GAP, FIFTH BATCH RUNNING

`check-image-duplicates.py` still cannot scope to a link-pin batch (`--maker
<CODE>` or `--all`; a pin batch has no maker code). Covered here by running the
same two-stage check by hand. **A `--since <ref>` or `--pins` flag remains the
obvious fix.**

---

## Verification

- **Validator mirror** — vocabulary parsed from **both** `Models/Tag.swift` and
  `scripts/validate-tours.swift`, refusing to run if they disagree or either
  parse is empty (they agree at **377 tags across 5 facets**). **Self-tested
  against 44 injected fault classes — 44/44 caught.** Then **0 errors, 2
  warnings across 1,552 tours + 154 pins**, and **both warnings are
  pre-existing** — the same mirror against `origin/main` reports the identical
  pair (VIA 57 West's transcript gap; Bedrock Caverns' deliberate null
  `walkingDistanceMeters`).
  **⚠️ TWO WARNINGS WERE MINE AND WERE FIXED RATHER THAN SHIPPED:** Little
  Island and KOK Oslo each had a Place type and an experience tag but **no
  Theme** — now `Architecture` and `Maritime`.
- `make-link-pin.py --selftest` **71/71** (62/62 without Pillow — install it
  first or that number is a false pass).
- **0** duplicate tour/stop/maker ids, **0** already-pinned sourceURLs, **0**
  filename collisions. The one sourceURL used by five pins is the documented
  deliberate Italian antique-markets entry.
- **0** byte-duplicate heroes. One perceptual pair nominated at Hamming 35,
  pixel-diff **33.1** — the IAC's pale glass against the Met's cream Twombly
  canvas, the tonal false positive the two-stage check exists to reject
  (identical pictures score under 1).
- `Tours.json` confirmed **byte-stable under a Python re-dump at `indent=2`**
  before editing; diff **1,550 insertions / 0 deletions**.
- gh-pages: `git ls-remote` re-checked **in the same command as the push**; tree
  diff **exactly 45 additions, 0 deletions, nothing outside `images/`**
  (`21a82711`); deploy read **`in_progress`, not `cancelled`**.
- **46 referenced = 45 uploaded + 1 already live, 0 orphaned**, checked by
  filename against the emitted catalogue entries.
- **CI has not run: no PR is open**, so the authoritative Swift validator has
  not seen this and the mirror is the only check.


---

## Owner pulled four pins and two creators (after PR #633 merged)

Owner, shown the flagged heroes: *"Pull empire theatre, Brooklyn bridge caissons
and the octagon. In fact pull the user nycunfilteredstories."*

Removed: **`Instagram @nycunfilteredstories`** and all three of their pins —
*Empire Theatre, 42nd Street*, *The Octagon, Roosevelt Island*, and
**⚠️ *Verrazzano-Narrows Bridge***, which was **not** one of the three named and
had shipped the previous day. Session 119 had checked that hero at pixel level
and cleared it as genuine despite its caption carrying the identical *"images
were recreated"* disclosure. It was flagged to the owner **before** removal, not
discovered afterwards, and is trivially restorable.

Also removed: **`Instagram @theironwil`** and their pin *The Brooklyn Bridge
Caissons*. That was their only pin, so the creator row went with it — the
Mercedes-Benz Stadium precedent (session 117), where the pin and its sole
creator row were pulled together.

**`linkPins` 154 → 150, makers 155 → 153** (Instagram creators 12 → 10).
Countries stay at 32; Luxembourg and Norway are unaffected. Diff: **198
deletions, 0 insertions**. Validator mirror re-run after the removal: **0
errors, 2 warnings, both pre-existing**; self-test **44/44**;
`check-place-candidates.py` unchanged (none of the four was a candidate).

**⚠️ Four gh-pages heroes are deliberately left orphaned** — nothing references
them, and a deletion push onto a branch other sessions write to buys nothing
(the Mercedes-Benz Stadium handling):
`verrazzano-narrows-bridge-nycunfilteredstories_hero.webp`,
`empire-theatre-42nd-street-nycunfilteredstories_hero.webp`,
`the-octagon-roosevelt-island-nycunfilteredstories_hero.webp`,
`brooklyn-bridge-caissons-theironwil_hero.webp`. No avatars were orphaned —
both creators are Instagram and ship `avatarURL: null` by design.

### 🔴 The lesson, and it supersedes the precedent this batch was shipped on

**"Shipped and flagged" is not a resolution.** This is the second time in three
sessions that a flagged AI hero has been pulled by the owner — Mercedes-Benz
Stadium (session 117) and now three at once. **DIFC Gate is no longer the
representative precedent.** Raise a suspect-synthetic hero and expect it to go.

**And say up front which OTHER pins removing a creator would take.** "Pull the
user" is a wider instruction than "pull these pins", and here it reached a pin
that had already been examined and cleared.


### 🔴 The removal did not reach the live app, and the mirror hid that

After #634 merged and `publish-catalog` ran, **the Supabase RPC still served all
four pins and both creators.** `seed_from_toursjson.py` is **upsert-only by
design** — so a deletion in `Tours.json` reaches the gh-pages mirror and the
bundled offline seed and **never reaches Postgres**, which is what the app reads
first. Checking the mirror alone would have shown the pins gone and been wrong.

**A removal is a two-part change: the catalogue edit, plus SQL the owner runs.**
`backend/pull_nycunfilteredstories.sql` is the worked example.

Ordering matters and is load-bearing. Delete the four `tours` rows first —
`stops`, `user_library`, `user_recently_viewed`, `journey_items` and
`group_sessions` all cascade, and `reports.tour_id` is `on delete set null`;
`purchases.tour_id` is `on delete restrict`, but these are free pins so nothing
can reference them there. **Then** the two `makers` rows, because
`tours.maker_id` is `on delete restrict`. That restrict doubles as the safety
net: a surviving pin makes the maker delete fail and rolls the whole
transaction back rather than half-applying.

⚠️ `status = 'taken_down'` would hide the pins (`get_catalog` filters
`status = 'published'`) but would **not** let the creator rows go, for the same
restrict — so a full "pull the user" needs the delete, not a takedown.
