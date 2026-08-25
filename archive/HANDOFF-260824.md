# HANDOFF — 2026-08-24 (session 107, web: code)

**One fix, merged and device-verified.** [PR #573](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/573),
squash `1232cbd`. **TestFlight 1.1 (112)** — owner: *"looks great."* Three Swift files,
+43/−7. No SQL, no catalogue change.

---

## The report

The owner marked two regions of a tour-detail screenshot and wrote: *"1 and 2 marked in
the screencap are supposed to be same color. They look like they're just a little
different."* Region 1 was the chrome row (✕ · bookmark · ···); region 2 the page carrying
the GALLERY / MAP strip, with a line drawn across the boundary between them.

They were right, and it was not a rendering artefact of the screenshot.

## 🔴 The cause: an opacity + material pair defeating the token built to prevent exactly this

All three canonical chrome rows painted themselves:

```swift
.background(AtlasColors.secondaryBackground.opacity(0.8))
.background(.regularMaterial)
```

…over a page that is a plain `AtlasColors.secondaryBackground`.

**`secondaryBackground` is a hardcoded `UIColor(dynamicProvider:)` pair — `#1C1C1E` dark,
`#FFFFFF` light — and its own doc comment explains why it stopped being
`.secondarySystemBackground`:** that semantic colour resolved differently at `.base` vs
`.elevated` user-interface-level traits, which is what put a visible seam between the
bottom-module chrome (window 2) and the detail body (window 1) in dark mode. The literal
exists so every painted surface resolves to the *same RGB* regardless of window or
elevation.

Drawing that literal at 80% over `.regularMaterial` threw the guarantee away.
`.regularMaterial` resolves lighter than `#1C1C1E`, so the composite landed a few levels
above the page — small, but a straight edge across the full screen width makes a few
levels legible.

## ⚠️ The second half, which nobody had named: the mismatch was not a constant

A material **samples what is behind it**. The chrome row is a `.safeAreaInset(edge: .top)`,
so page content — including a full-width hero photograph — scrolls directly underneath it.
The row's shade therefore *drifted as you scrolled*.

That is the more useful half of the finding. A fixed offset would have been noticed and
filed years ago; a shade that only misbehaves mid-scroll reads as "something feels slightly
off" and never gets pinned down.

## The fix

One opaque `AtlasColors.secondaryBackground`. The material is dropped entirely, not kept
behind an opaque fill: at full opacity it contributed nothing visible and was only paying
for an offscreen blur pass per frame. (Same reasoning that deleted the app-wide
scale-and-blur in PR #559 — invisible behind the disc, still rendered.)

**Applied to all three pages that carry this row — `TourDetailView`, `PlaceView`,
`TourListDetailView`.** CLAUDE.md records these as byte-identical by design, with tour
detail canonical (owner, 2026-08-20). Fixing one would have started exactly the drift that
note warns about. Verified by hashing the `.safeAreaInset` block in all three **after** the
change: still identical.

## ⚠️ Do not reintroduce the material

The original intent was "solid material + tint backdrop" — the row's own comment said so,
and it was never solid. If a future pass wants translucency on this row, it cannot have
that *and* an invisible boundary with the page: **one token deliberately paints both
surfaces**, and any material will resolve off it. That is the same constraint recorded in
PR #563 for why light mode cannot separate the bars from the page they sit on. The
reasoning is now a comment at each call site so it is not re-derived from scratch.

## Verification

- **Owner device-verified on TestFlight 1.1 (112)** ([run 32724989508](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/actions/runs/32724989508)),
  cut from `80f2c0b` on the branch, notes attached via the workflow's `notes` input.
- **✅ Both colour schemes confirmed** — dark on the build (*"looks great"*), then light
  separately (*"light mode is fine"*, 2026-08-24). Light was flagged as reasoned-about
  rather than seen when this merged; that gap is now closed.
- CI green on the PR — simulator build, unit tests, validator.
- ⚠️ **Authored in a Linux web session with no Swift toolchain**, so nothing was compiled
  locally. CI on the PR was the `test_sim` stand-in, per Automation Rule #3.

## Process notes worth keeping

- **The branch was checked for staleness before the build was cut.** Its second commit
  *was* current `origin/main` (`0881fa46`), so 1.1 (112) carried everything on main plus
  the fix. This is the 1.1 (92) lesson — a build comes from the branch, not from main, and
  a stale branch ships as a pile of regressions.
- **Build notes were written in plain ASCII on purpose.** 1.1 (97) uploaded successfully
  and then went red seven minutes later because one line of its notes used a `✕`.
  `scripts/ascii-build-notes.py` transliterates now, but there is no reason to lean on it.
- `git fetch` timed out twice against the proxy in this session; branch freshness was
  established through the GitHub API (`list_commits` on the branch) instead. Worth reaching
  for when the shell's git is the thing that is broken.

---

# Follow-up, same session — the row is now one component

[PR #576](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/576), squash `c7fda39`.
**TestFlight 1.1 (113)** — owner: *"looks good."* Net **−61 lines** across the three
views, plus one new file. Refactor only; no visual change, which was the whole test.

## Why immediately after the fix rather than later

The fix above had to be made in **three places**. That worked, but it is the shape of
problem that eventually does not work: CLAUDE.md kept the three rows in step by
*asserting* they were byte-identical by design, and an assertion in a document is weaker
than code that makes it true.

## What moved

New **`Components/AtlasChromeRow.swift`** — `.atlasChromeRow { controls }` — owning the
four things the three pages must never disagree about: the row's shell (`sm` spacing,
`lg`/`sm` padding), parking it via `.safeAreaInset(edge: .top)`, the paint, and hiding
the system nav bar.

Each page still supplies its own **controls**, because those legitimately differ — the
list page hides its bookmark when there is nothing to save, and its `…` when Liked is on
screen. Contents at the call site, everything around them shared.

**🔴 The paint is the real prize, and it is a stronger guarantee than the fix above
achieved.** The row and the page are now filled from the **same expression**, not from
two expressions that happen to name the same token. #573 made them the same *value*,
written three times. This makes them incapable of differing.

**⚠️ `.toolbar(.hidden, for: .navigationBar)` moved in too, deliberately.** It is not
decoration: this row *replaces* the system bar, and iOS 26's glass-grouping stacks on
custom chrome when both are present (the "two layers" look, owner correction
2026-06-03). Bundling it means a fourth page gets the whole thing right by construction
rather than by remembering. A page can still set `.navigationTitle` afterwards — the
list page does, purely so VoiceOver has a label for a bar nobody sees.

## Verification

- **Owner device check on 1.1 (113)**: the three pages read as untouched.
- CI green — simulator build, unit tests, validator, and the TestFlight job itself.
- The modifier applies `safeAreaInset` → `background` → `toolbar` in the **same order**
  all three call sites did, so each resulting chain is unchanged; padding still precedes
  the background.
- No remaining references to the old `chromeRow` symbol; no remaining
  `secondaryBackground.opacity(0.8)` outside the new file's own history note.
- ⚠️ Still a Linux web session with no Swift toolchain — CI was the only compile check
  before the build.

## ⚠️ Branch staleness caught, and this time it mattered

`main` moved mid-session: the **Stockholm launch** (#575 — 45 tours, 33rd maker, catalog
1,467 → 1,512) landed while this PR was open. `main` was merged in **before** cutting
113, so that build carries the refactor *and* Stockholm. Building without it would have
shipped a binary whose bundled offline seed predated an entire city — the 1.1 (92)
lesson, live again. The merge was clean and touched none of the four files here, which
was checked rather than assumed.

**The general rule this keeps proving: check the branch against `main` immediately
before every build, not at the point the branch was created.** In this repo `main` can
move twice in an hour.

## Also

Removed a doc comment in `TourListDetailView` that was **already orphaned on `main`** —
it documented a helper `AtlasChromeButton` replaced, and its "down to the fill opacity"
had gone stale twice over.
