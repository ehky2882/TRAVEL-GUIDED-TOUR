# HANDOFF — 2026-08-21 (session 101, web) — the upload wizard's second review round

**Branch:** `claude/wizard-comments-round2` → **[PR #558](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/558)**
**Builds:** TestFlight **1.1 (97)** (no notes — see the CI section) and **1.1 (98)** (same app, notes attached).
**Owner verdict on device: "I REVIEWED. GOOD."**

Code and CI only. **No SQL, no catalogue change, no schema change.** Catalogue untouched.

---

## What this session was

The owner walked the seven-step wizard on 1.1 (96) — the build that shipped the
rebuild in #552 — and sent notes step by step. Eleven of them, across six steps,
plus two more sent back as comments on the review page. All eleven built.

The visual record is an artifact with before/after phone frames for each note:
`https://claude.ai/code/artifact/300e7390-8d35-4837-8509-98c23f41f679`

---

## 🔴 THE ONE FINDING THAT EXPLAINS THREE OF THE COMPLAINTS

**A flexible child gets no room from a `ScrollView` whose content frame sets only
a `minHeight`.** The frame stretches to a screenful and top-aligns; the child
stays at its floor. So `maxHeight: .infinity` inside the wizard's step area has
**never done anything**, and the layout comment describing "the step's one
elastic element" was describing a mechanism that was not there.

It was three separate owner complaints:

| Step | What the owner saw | What it was |
|---|---|---|
| 1 | "Map is too small" | The map sat at its 200pt floor with a screenful of dead space below |
| 2 | Fields read as no box at all | Two dead frames; boxes drawn tight around one line of text |
| 6 | Transcript box a sliver on an empty page | Same, at two lines tall |

**Fixed three different ways, and the difference matters:**

- Step 1: give the map a real shape — `AtlasSpacing.heroAspectRatio`, the same
  square every other map and hero in the app takes. Symptom and dependency both
  gone.
- Step 2: size each box to its own character limit. The step no longer asks for
  elastic sizing at all.
- Step 6: a text box has no natural shape to give it, so **the step area is
  measured** (`stepAreaHeight` via `onGeometryChange` on the ScrollView) and the
  box takes what is left.

### ⚠️ AND THE OVERSTATEMENT THAT FOLLOWED — worth more than the finding

The PR originally flagged **step 3** as still carrying "the broken stretch
pattern". The owner asked what that meant, and the honest answer was: nothing.

**The symptom only appears when the stretched child has no size of its own.** A
map and a text box don't — they collapse to a floor. **Five rows of tags do**, so
the picker has always drawn at its natural height, top-aligned, with space
beneath. Which is what a list of five rows should look like. Nothing shipped
wrong and there was nothing for the owner to notice.

What *was* wrong on step 3 is what the file **said**: two comments claimed the
open tag group "absorbs whatever the closed ones leave", which never happened.
**What actually keeps that step finite is `architectResultCap` (8) plus the
type-to-search on the Architect row** — without it, 94 names is ~1,728pt of
chips. The dead lines are gone and the comments now describe the real mechanism.

**Durable lesson: a dead layout modifier is only a bug where the child has no
intrinsic size. Do not report the pattern as a defect without checking whether
the child collapses.**

---

## Step by step

### 1 · Location
Map is `atlasHeroSizing(nil)` — square, sharp corners, full width.

### 2 · Details
- Save is **`folder`**, not `tray.and.arrow.down` (which IS the download glyph).
  Collisions checked: `checkmark` appears four times, `clock` is the wizard's own
  in-review state.
- Boxes sized to their limits: **40 characters to a line at 13pt SF Mono in
  313pt** of text width → Title 2 lines, Short description 3, Description 15.
- **Hairline border on `wizardFieldStyle`.** The fill is pure black on a
  `#1C1C1E` page — an 11% difference that reads as no box. Sizing was named as
  the first lever last round and the border as the next one if sizing wasn't
  enough; the step 6 note proved it wasn't, so **every field on every step has
  one now**.
- **Tap anywhere that isn't a control to dismiss the keyboard.** ⚠️ A `.toolbar`
  "Done" is the usual iOS answer and is **not available in this wizard** — the
  toolbar bridge is what hung this screen for seven builds (#540).

#### 🐛 A bug introduced and caught inside the same branch
Sizing the title box to 60 characters meant `axis: .vertical`, and **a vertical
`TextField` treats Return as a NEWLINE.** A tour title could have carried a line
break into the catalogue, the share card and the lock screen. `oneLine` flattens
newlines to spaces *before* applying the limit, so the cut lands where the maker
sees it land; trailing spaces survive because trimming as you type eats the space
you just pressed. Five tests.

### 4 · Photos — "drag to reorder doesn't quite work"
**It works. Nothing said how to start it.** `.draggable` is a UIKit drag
interaction: the tile lifts after ~half a second of pressing, and until it lifts
a drag is just a scroll. The footer hint said *"drag to reorder"*.

🔴 **The hold is not a fault to fix — it is what keeps a reorder apart from a
scroll.** A drag that began on contact would leave one of the two to lose. So:

- The hint says **hold a photo to move it**.
- **MAKE COVER** on any tapped photo, in the corner where the cover itself says
  COVER. Promoting a photo is nearly all reordering is ever asked to do here and
  should not depend on the hardest gesture on the step.
- **Empty boxes take drops**, so the target is the whole grid. Dropping past the
  end means "put it last" — the one destination a filled tile cannot express,
  since a filled tile can only say *before this one*.

#### 🔴 A race designed around rather than discovered later
`commitActive` reads the photo's index when called and hands the **whole ordered
list** to `setPhotos` when it uploads. **`setPhotos` DELETES anything absent from
the list it is given.** Committing before the move captures the old index;
persisting after an upload has started races it with a list still naming the file
that upload is about to replace — so that race would not misorder a photo, it
would **destroy** one. `makeCover` reorders first and `commitActive` now returns
whether it took the write, so exactly one of the two writes.

### 5 · Audio — "after a recording is accepted there should still be an ability to discard it"
`canDiscard` read `recordedURL != nil`, and **`Use recording` clears that the
instant it hands the file to the upload.** So the one state a maker most wants
out of — narration attached and wrong — was the only state with no way out.

New **`MakerTourService.removeAudio(from:)`** restores the stop to exactly what
`createDraftTour` leaves and deletes the object from Storage (best-effort, last,
for `setPhotos`' reason).

- ⚠️ **Empty string, NOT null.** `stops.audio_url` is `text not null` and
  `audio_duration_seconds` is `int not null` (`backend/schema.sql`), so there is
  no null to write. A fresh draft already stores `""` and `0`, and `stopAudioURL`
  reads an empty string as no audio — this restores that exact state rather than
  inventing a third one.
- **NO CONFIRMATION, on either branch — owner decision, reversing my first
  pass.** I had put one on the attached-narration branch because it deletes an
  upload. Owner, on the mockup: *"don't need this portion."* Right, and on the
  app's own precedent rather than only preference: **the ✕ on a photo deletes an
  uploaded photo on the spot with nothing asked**, and the same owner had thrown
  out a confirmation screen on the Photos step days earlier for being a screen.
  Audio asking and photos not asking would have made two steps of one wizard
  disagree about how destructive a delete is. Re-recording is the undo.
- **The transcript is deliberately left alone** — the maker's words, and someone
  re-recording narration they have already corrected the text for should not have
  to type it again.
- Removing audio correctly **re-blocks Submit** (*"Record or import the
  narration"*): a tour cannot be published silent, and the gate says so rather
  than the button going quietly dead.

### 6 · Transcript
- `TextField(axis: .vertical)` grows to its text and **cannot scroll**, so the
  fill was painted tight around two lines. It is a **`TextEditor`** now — needs
  `scrollContentBackground(.hidden)` or UIKit's own fill paints over
  `wizardFieldStyle`'s — sized by the measured step area, and a twenty-minute
  narration fits inside it. **This is the one step that scrolls, and the owner
  authorised it.**
- 🔴 **The language menu and Transcribe again take their OWN `safeAreaInset`,
  applied BEFORE the footer's**, so the footer stacks below them and the divider
  the footer already draws along its top edge becomes the line between the two.
  - The first pass put them **inside** the footer's VStack and the owner rejected
    it: *"these should be 'above' the standard buttons, not added to be part of
    it."* They shared its panel, divider and capsule shape, so the row read as a
    **five-button footer where two buttons changed depending on the step**. **The
    footer is the one part of this screen that never changes between steps, and a
    step may not add to it.**
  - ⚠️ `keyboardOverlap` subtracts **both** heights now. Both stand in the
    keyboard's way; crediting only the footer would leave the box 52pt too tall
    with the keyboard up.
- The recogniser's note moved into the footer's hint slot, which already reserves
  two lines on every step. Two places for one step to speak was one too many.

### 7 · Review
- **Copy.** *"Already with us. We'll let you know either way."* was on screen
  **TWICE at once** — the page's footnote and the footer's disabled-button reason
  — and "either way" stood in for two outcomes it never named. They have
  different jobs and now sound like it:

  | | Was | Is |
  |---|---|---|
  | Page footnote | Already with us. We'll let you know either way. | In review. The status on your profile changes once we've looked at it — usually within a day. |
  | Footer hint | Already with us — we'll let you know either way. | Already submitted — there's nothing to send. |

  ⚠️ **Neither promises a message, and that is deliberate: nothing sends the
  maker one.** `notify-moderation` emails the *owner*. What a maker can actually
  observe is the status on their profile, so that is what the copy points at.

- 🔴 **The preview map showed no pin, and "0 stops".** It was recorded; the
  preview could not see it. **`TourRow.asMakerTour` builds its `Tour` with
  `stops: []`** because the profile feed wants a title, a status and an image and
  nothing else. Everywhere else that emptiness is invisible — **a page that draws
  a pin per stop and prints a stop count shows it plainly.** Third appearance of
  the gap that made `stopLocation(tourId:)` and `stopAudioURL(tourId:)`
  necessary.
  - The preview is handed the stop the wizard is already holding, which is also
    the **more honest** preview: `centerCoordinate` and `radius` are what Save is
    about to write, so the map shows where the tour WILL fire rather than where
    the server last heard it was.
  - ⚠️ **Display copy only** — the synthesized stop id is a fresh UUID, fine for
    an annotation and wrong for anything that writes. **A fourth caller needing
    real stops should fetch, not invent.**
  - ⚠️ **`Tour` has no explicit init and no defaults**, so the call site was
    **generated from the declaration's own property order** rather than typed. A
    wrong argument order there is the failure CLAUDE.md records as invisible in a
    CI log.

---

## 🔴 CI — A BUILD THAT SUCCEEDED AND REPORTED FAILURE

**TestFlight 1.1 (97) archived, signed, uploaded and finished processing — and
then the run went red on:**

```
Could not set changelog: An attribute value has invalid text.
- Text for whatsNew contains invalid characters:'[✕]'
```

One line of the build notes used a **✕** to name the button it described ("same
as the ✕ on a photo"). Apple's "What to Test" field refuses it.

So the build was **live and installable** while the run reported failure and the
build carried **no notes at all** — the worst of the three possible outcomes, and
precisely the mystery build Rule #9 exists to prevent.

⚠️ **THE ORDERING IS THE TRAP, NOT THE CHARACTER.** `upload_to_testflight`
uploads, waits out Apple's processing, and only **then** writes the changelog. So
a rejection lands seven minutes and one real build after the mistake, at a step
whose failure looks exactly like a build failure. **Nothing about a red run says
"your build is fine and already on the phone."**

**Fixed at the source: `scripts/ascii-build-notes.py`**, wired into
`testflight.yml` before the 4000-character cap.

- Known typography is **MAPPED, not deleted** — em dash → `-`, bullet → `-`,
  curly quotes → straight, ellipsis → `...`, ✕ → `x`, ✓ → `v` — because deleting
  them silently runs words together, and a note that reads wrong is barely better
  than none.
- Accents decompose (NFKD) so `café` → `cafe` rather than losing the letter.
- Anything still outside printable ASCII (emoji, arrows, box drawing) is dropped.
- **Deliberately conservative**: the exact set Apple refuses is undocumented, and
  the far side of a seven-minute build is not where to map it.
- `--selftest`: twelve cases plus a **12k-codepoint sweep** asserting only
  printable ASCII can come out. Runs offline, no network, no Swift.

⚠️ **Build 97 could not be given notes retroactively from here** — the workflow
has no distribute-only input, and `rerun_workflow_run` replays the same inputs
from the same commit, so it would fail identically. **1.1 (98) is the same app
with the notes attached.**

---

## Known costs, stated rather than buried

- 🔴 **THE NO-SCROLL RULE NOW HOLDS ON A 6.3″ PHONE AND NOT ON AN SE.** Sizing
  the boxes to their character limits puts step 2 at **511pt against a 529pt
  budget** — 18 to spare on the owner's phone, about **94pt over on an SE**,
  where it will scroll. That is the price of the change and it was said out loud
  rather than buried.
- **Step 6 scrolls on purpose** (owner-authorised), which is the whole reason its
  two controls had to leave the scrolling area.
- The no-scroll rule still depends on **Dynamic Type being off**. Unchanged from
  #552 and still unaddressed.

---

## Process notes

- **Every push needs an explicit `ci.yml` dispatch.** A web-session push to an
  open PR does not reliably fire `synchronize`. (Once the PR existed, the
  `pull_request` trigger did fire on each push — but do not rely on it.)
- **The squash commit inherits the PR body**, so the description was rewritten
  immediately before merging. The original was written five commits before the
  branch was done and named nine notes, not eleven.
- **Artifact comments were the review channel this session** and worked well: the
  owner commented on two specific frames of the mockup, both were built, replied
  to and resolved inside the same turn. Worth reaching for again — it is faster
  than describing a screen in prose and it anchors the comment to the pixel.
- **`Tour`'s call site was generated from its declaration**, not typed, per the
  CLAUDE.md lesson about invisible argument-order errors.
- No Swift toolchain in a Linux web session, so local checking was: brace/paren
  balance, duplicate result-builder attributes, and stale-reference greps. **CI
  is the only compile check.**

---

## Still open

- **The owner has more comments**, deferred to a fresh branch off the merged
  `main` rather than stacked on this one.
- **Device-review owed on the newest changes** — drag-to-reorder feel, MAKE
  COVER, the Discard path, the transcript box's scroll, and the preview pin all
  need a real account and a real recording. (Build 98 carries them; the owner
  reviewed 97/98 and approved.)
- **Dynamic Type** and the **SE overflow on step 2** both unaddressed.
