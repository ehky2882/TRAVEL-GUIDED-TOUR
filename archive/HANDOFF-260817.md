# HANDOFF — 2026-08-17 (session 93, web/remote, code)

**One line:** fixed 24 map pins that could never be opened, on both the
home map and the creator page, plus a drawer/rail disagreement found
underneath — [PR #512](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/512)
(squash `6824b26`), shipped as **TestFlight 1.1 (64)** and
**owner-verified on device** ("64 IS LIVE. CHECKED IT AND IT IS GOOD").

Catalog untouched: **1350 tours / 30 makers / 1696 stops.** No content,
no backend, nothing for the owner to run.

---

## What was reported

A screenshot of downtown Montréal: a gold **"2"** cluster pin sitting on
Square Dorchester. The owner's words:

> This pin in Montreal. There's 2 tours on top of each other? Issue 1. I
> cannot zoom and click any further on the pin and therefore no place
> card ever pops up. 2. If I drag up the drawer it only shows one tour
> which leads me to suspect that one of the pins it's counting a stop on
> a multi stop tour? Either way this is an issue

Both observations were real. The suspected cause of the second was not,
and a third defect turned up while checking.

---

## Defect 1 — a pin no camera can ever open

**Two different tours sit at exactly `45.4997, -73.5710`:**

| Tour | Kind | Why it's there |
|---|---|---|
| Dorchester Square and the Sun Life Building | single | the landmark's own tour |
| Downtown and the Underground City | multiStop, stop 0 | the walk's intro, wired at its first content stop — which *is* the square |

So the count of 2 was honest — it was **not** double-counting a stop, as
the owner suspected. The walk contributes exactly one pin (`order == 0`);
its other five stops draw nothing.

**Why the tap did nothing.** `MapClustering` buckets markers into grid
cells keyed off an absolute origin. Two markers at an *identical*
coordinate fall in the same cell at **every** cell pitch, so no camera
anywhere separates them. The cluster tap only ever called `zoomIn`.
Infinite no-op: no place card, no error, nothing in a log.

**It is 24 pins, not one, and the cause is structural.** Every pair is a
walk intro wired at the coordinate of the single-stop tour of the same
landmark — which is what the walk conventions ask for. **The data is
right; do not "fix" it by nudging a walk intro off its landmark.**

| Maker | Pins | Examples |
|---|---|---|
| Atlas Studio AMS | 5 | Dam Square, Rijksmuseum, Westerkerk, Centraal, Waterlooplein |
| Atlas Studio YYZ | 4 | CN Tower, ROM, AGO, Union Station |
| Atlas Studio ROM | 4 | Colosseum, Piazza del Popolo, Circus Maximus, Largo Argentina |
| Atlas Studio BER | 4 | Brandenburg Gate, Potsdamer Platz, Oberbaumbrücke, Hackesche Höfe |
| Atlas Studio YUL | 3 | Dorchester Square, Notre-Dame, Square Saint-Louis |
| Atlas Studio DXB | 3 | Al Shindagha, Textile Souk, Marina Walk |
| Atlas Studio LAX | 1 | Walt Disney Concert Hall |

No pair spans two makers, so each affected creator page shows its own.

**Re-derive the list** any time by sweeping the markers the maps actually
draw (`tour.kind == .single || stop.order == 0`) for coincident
coordinates. It will grow with every new city that ships a walk starting
at a landmark that also has its own tour.

**Fix.** `MapClustering.canSeparateByZoom` reports the degenerate case;
`needsDisambiguation` wraps it and adds a building-scale backstop (span
≤ `0.0006°`, ~65 m) for markers a metre or two apart. A cluster the
camera can't help with goes up to the host view, which raises **one
`PlacecardView` per tour, stacked above the pin**. Placecard state became
a list, so the ordinary single-pin path is just the one-element case.

---

## Defect 2 — a cluster tap could zoom OUT

`MapClustering.region(framing:)` floored its span at `0.01°` (~1.1 km) so
one tap couldn't drop the user into a one-block view. But markers merge
whenever they sit closer together than `span / cellsAcross`, so a cluster
routinely exists at a span **far below** that floor — and framing it then
*widened* the camera and re-rendered the same pin.

That is indistinguishable from a dead tap, and it is why zooming in
manually first didn't help either: tapping bounced the user back out.

**Fix.** `region(framing:within:)` takes the live span and clamps to half
of it, so every tap makes visible progress. The clamp only binds when the
floor was the thing widening the camera (a real cluster's bounding box is
at most one cell across, so its padded span is ~span/8 — already inside
half the current span). **Both maps had this bug.**

---

## Defect 3 — the header and the rail disagreed

The owner's second observation, with a different cause than suspected.

- **Drawer header** (`toursInViewCount`): counts a tour when **any of its
  stops** is inside the visible region.
- **In-view rail** (`inViewRail`): filtered on `tour.coordinate` — the
  **centroid**.

A walk's centroid is the mean of stops that can be a kilometre apart. The
Downtown walk's sits **197 m** north-east of Dorchester Square, outside a
tight viewport. So it was counted in the header and absent from the list:
"2 TOURS IN VIEW" above a single card.

**Fix.** The rail now uses the same any-stop predicate as the header.
*Ordering* still uses the centroid, which is the right summary of where a
whole walk is.

**🔴 Durable rule: when two surfaces describe the same set, they must
share the predicate.**

---

## The maker map, and how the decision got made

The creator page's MAP tab inherited the same dead pin. It differs from
the home map in two ways that mattered: it is **320pt tall** (`heroHeight`,
inset 24pt, inside a scrolling page), and it has **no place card at all** —
a pin tap routes straight into the tour via `openTourFromMap`.

I recommended a native **action sheet** (needs no map real estate, reuses
the existing routing, ~40 lines). The owner asked:

> can you show me first before i decide? i'm not totally following
> without visuals

So an **interactive mockup** was built — the real YUL page at real
geometry, with the pin tappable under each candidate behaviour — and the
owner picked **stacked cards** ("i actually prefer c") for consistency
with the home map, having seen exactly how much of the map they cover.

**Worth repeating: this owner settles UI questions by looking, not by
reading.** Same pattern as the session-77b profile work. One artifact
resolved what prose hadn't.

**Fitting the stack.** Two cards are ~178pt (each is a 64pt hero plus
`AtlasSpacing.sm` top and bottom, plus the gap and 14pt pin clearance),
and a plain recentre leaves only 160pt above the pin — the top card would
be clipped. New **`MapClustering.region(anchoring:at:span:)`** sits the
pin **72% of the way down** the frame instead (~215pt of room). ⚠️ North
is up, so the **camera centre moves north** to push the pin *south* —
easy to invert.

**⚠️ Single pins on the maker map still open the tour directly, no card.**
Only ambiguous pins preview. Deliberate — making every pin preview there
is a much bigger behavioural change than was asked for.

---

## Shared rather than duplicated

Two surfaces now need the same judgements, so they live in one place:

- **`MapClustering.needsDisambiguation`** — "can zooming help?"
- **`PlacecardView.standardWidth`** — the 2/3-screen card width `HomeView`
  had been keeping privately.

`HomeMapSection` lost its private copies of both.

---

## ⚠️ Why nothing caught this

**No check we run can see this bug class.** `validate-tours.swift`
passes — the coordinates are valid and distinct tours legitimately share
a place. `check-image-duplicates.py` is about bytes. CI compiles fine.
Every URL resolves. **It is visible only by tapping the pin.**

New `MapClusteringSeparationTests` pins the invariants, including that
coincident markers stay clustered from 1° down to 0.00001° — the premise
the whole fix rests on. Two `HomeRailsViewModelTests` cover the walk in
and out of view. `TestFixtures.makeTour` gained per-stop coordinates and a
centroid override so a walk can be built with a centroid away from its
stops; existing call sites are unchanged.

---

## CI / build notes worth carrying

- **🔴 A "Set up job" failure means the job died before checkout —
  re-running IS the diagnosis, not a hope.** Build 64's first attempt
  failed in 93 s with **HTTP 429** downloading `ruby/setup-ruby`, three
  retries, all refused. **This is NOT the certificate-cap fast-fail**,
  which dies later at Archive with "maximum number of certificates".
  `rerun_workflow_run` preserves both `run_number` **and** the
  `workflow_dispatch` inputs, so the re-run stayed **build 64** with its
  notes intact and went straight through.
- **⚠️ CLAUDE.md's advice on verifying build notes was stale, and is now
  corrected in place.** The `Done` step in `testflight.yml` is an
  **unconditional `echo`** — it prints "Uploaded build N … with these
  notes attached" regardless of outcome. The notes-attaching moved inside
  the `beta` lane in session 84. **The real evidence is the `Build and
  upload to TestFlight` step**: `bundle exec fastlane beta` with no
  `continue-on-error`, and `upload_to_testflight(skip_waiting_for_build_processing: false)`
  raises if either the upload or the changelog write fails.
- CI **did** fire on a web-session push to the open PR this time. The
  documented unreliability didn't bite — but it was checked, not assumed.
- The PR's **file count was checked against its stated scope before
  merge** (11 files, exactly the 11 touched) per the #469 lesson.
- `delete_branch_on_merge` removed the branch automatically.

---

## State at session end

- **`main` = `6824b26`.** PR #512 merged (squash), verified present in
  `origin/main` rather than taken on trust.
- **TestFlight 1.1 (64) is live and owner-verified on device.**
- **Catalog unchanged: 1350 / 30 / 1696.**
- Mockup artifact (the three maker-map options, interactive):
  `https://claude.ai/code/artifact/969dceab-4547-402f-97a0-57873975c5fe`

## Open / next

- **Nothing outstanding from this session.** Both maps verified on device.
- **⚠️ The coincidence sweep is worth re-running when a new city lands**
  with a walk that starts at a landmark that also has its own tour — the
  fix handles it automatically, but the count in CLAUDE.md will drift.
- Stack caps: **4 cards** on the home map, **3** on the maker map. The
  deepest coincident group in the catalog is **2**, so these are guard
  rails rather than live limits — more than that at one landmark would
  need a different answer than a taller stack.
- Launch status unchanged: nothing submitted to the App Store; the
  remaining payout gates are the owner's **Stripe live activation** and
  the **LLC vs sole proprietor** decision.
