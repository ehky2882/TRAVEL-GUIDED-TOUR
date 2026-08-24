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
