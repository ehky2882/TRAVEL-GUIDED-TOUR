# HANDOFF — 2026-08-26 (session 113, web/remote, code)

**Branch `claude/link-fullscreen-module`, commit `9ac38ca`, pushed. NOT merged, and
NO PR IS OPEN — see § "The PR could not be opened from here", which is the one thing
this session could not finish.**

Owner bug report: *"in the link videos, when you go full screen, the bottom module is
obscuring the full screen so it doesn't fully go full screen."*

---

## 1. What reproduces, and what does not

**TikTok and YouTube pins reproduce it. Instagram does not, and the reason is
structural rather than luck.**

`TourDetailView.imageSection` branches on the platform. Instagram resolves to a real
media file and hands it to `GalleryVideoView`, which gets the app's own fullscreen
viewer — presented from `BottomModuleRoot`, i.e. from *inside* the top window, which is
exactly why that path was never affected. Everything else renders `LinkEmbedView`.

Instagram cannot reproduce it even on its fallback path: when the resolve fails the
code does drop back to `LinkEmbedView`, but its embed is a static poster wrapped in a
link with no `<video>` in it, so there is no fullscreen control to tap. **A YouTube
Short is affected exactly like an ordinary YouTube video** — the shape differs, the
player does not.

## 2. The cause

Tapping the platform's own fullscreen control inside the iframe puts the player into
**WKWebView element fullscreen, presented in the MAIN window**.

The mini-player and tab bar are not in that window. `BottomModuleWindowController`
installs a separate `PassThroughWindow` at `windowLevel = .normal + 1`
(`BottomModuleWindow.swift`), which paints over anything the main window presents. So
the video goes fullscreen and 126pt of chrome stays on top of it.

**Nothing in `LinkEmbedView` had ever observed `fullscreenState`** — confirmed by
reading the file, not by grep alone.

## 3. Why this shape of fix, and the alternative that was rejected

The obvious-sounding alternative is to give the embed the app's own fullscreen the way
the gallery does: suppress the iframe's native control and present from
`BottomModuleRoot`. **It was considered and rejected, and the reason is not effort.**
The video is inside a **cross-origin iframe we are not allowed to script** — we cannot
hide its control, cannot read its player state, cannot drive it. That is precisely why
the Instagram work stopped trying to make its player behave and resolved the file
instead, and there is no file to resolve for TikTok (their API exposes no video-file
field at all).

So the move that is left is to withdraw the module for the duration, and
`setHidden(_:)` already exists for it — used by `CreateTourWizardView` and `MakerView`.
Its own doc comment carries the reason it hides the **window** rather than emptying it:
a hidden `UIWindow` does not hit-test, so it stops *claiming the bottom strip* as well
as painting it. Leaving it visible-but-empty is how the Group Listen banner's Leave
button ended up dead.

## 4. What changed

| File | Change |
|---|---|
| `Components/LinkEmbedView.swift` | Observes `fullscreenState` (KVO) and reports it out via a new `onFullscreenChange` callback. New pure `withdrawsBottomModule(for:)`. `dismantleUIView` + `Coordinator.deinit` restore. |
| `Features/Tour/TourDetailView.swift` | New `@MainActor` `setBottomModuleHidden` — sets `appShared.hidesBottomModule` **and** `bottomModuleWindow?.setHidden`. Unconditional restore in `.onDisappear`. |
| `ContentView.swift` | Injects `BottomModuleWindowController` into **all four** slide-up layers. |
| `Components/BottomModuleWindow.swift` | Doc only: `hidesBottomModule` no longer has a single writer. |
| `TRAVEL GUIDED TOURTests/LinkEmbedFullscreenTests.swift` | New, 5 cases over the pure rule. |

## 5. 🔴 THE FAILURE MODE THIS IS ACTUALLY BUILT AROUND

**Whoever hides the module owns unhiding it.** If the webview is torn down
mid-fullscreen — the page dismissed, the layer collapsed by a tab tap, the app killed —
and nothing restores it, **the user loses the tab bar and the mini-player for the rest
of the session with no way to get them back.** That is far worse than the bug being
fixed, and this app has shipped the bars-go-missing failure three times already.

So the restore is unconditional and reachable from teardown, not only from a "left
fullscreen" observation. Three of them, and `setHidden` being idempotent makes the
redundancy free:

1. `TourDetailView.onDisappear` — the ordinary path.
2. `LinkEmbedView.dismantleUIView` — SwiftUI's own teardown hook. **This is the one
   that covers the tab-tap path**: `BottomModuleRoot.tabSelection` calls
   `tourPresenter.dismiss()` on every tap (deliberately unguarded on
   `newTab != selectedTab`), so the whole layer goes away under the page.
3. `Coordinator.deinit` — the only one ARC guarantees.

**A kill mid-fullscreen cannot persist it either:** `isHiddenByRequest` is per-instance,
and `installBottomModule` / the launch gate unhide unconditionally at hand-off.

## 6. ⚠️ THE INJECTION WAS MISSING, AND WITHOUT IT THE WHOLE FIX IS A NO-OP

The four UIKit layers re-inject the environment **by hand**, and
`BottomModuleWindowController` was not among them. The lookup in `TourDetailView` is
optional (it has to be — the wizard's `.preview` mode has no window at all), so a
missing injection would have been **nil, silent, and a dead fix** — the
dropped-injection class that cost the batch-D Follow button a whole build, and which the
tour layer's own comment warns about three lines above where this was added.

All four layers now inject it, so a link pin reached from a place page, a list or a
maker page is covered too, not just one opened from Home.

## 7. Two decisions inside the fix that look like style and are not

- **`DispatchQueue.main.async`, never `Task { @MainActor in }`.** Main-queue blocks run
  strictly FIFO; the order two `Task`s reach the main actor in is **not guaranteed**,
  and a restore overtaking its own hide is exactly the permanent failure in §5.
  Dispatching unconditionally — rather than calling straight through when already on
  main — is what keeps that queue the single ordering authority. Costs one runloop turn,
  invisible against a fullscreen transition.
- **`.enteringFullscreen` counts as fullscreen, `.exitingFullscreen` does not.** The
  bars must be gone *before* the player finishes growing and may return only once it has
  finished shrinking. An unrecognised future state resolves to "show them" — the two
  failure directions are not equal.

## 8. 🔴 THE PR COULD NOT BE OPENED FROM HERE — this is what is owed

**`api.github.com` is blocked by this session's egress policy: 403 at the agent proxy,
authenticated or not. There is no `gh` CLI and no GitHub MCP tool in this session.** The
proxy README is explicit that a 403 is an organization policy denial and must be
reported rather than routed around, so it was.

`git push` works — it goes through the git proxy, which is a different path. The branch
is up.

**Consequence, and it is the important one: `ci.yml` runs on `pull_request`, `push` to
`main`, or `workflow_dispatch` — NOT on a push to a feature branch. So nothing has
compiled this code.** No Swift toolchain exists in a Linux web session, so CI is the
`test_sim` stand-in per Automation Rule #3, and it has not run.

Open the PR at:
`https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/new/claude/link-fullscreen-module`

What to check first when CI does run: the concurrency annotations. `AppSharedState` and
`BottomModuleWindowController` are both `@MainActor`, so the callback is typed
`@MainActor (Bool) -> Void` and bridged with `MainActor.assumeIsolated` inside a
main-queue block. That is the area most likely to need a nudge, and it is the same class
of error the fastlane SnapshotHelper work hit (six "main actor-isolated ... in a
synchronous nonisolated context" errors).

## 9. ⚠️ THIS WANTS A DEVICE CHECK, AND THE PR SHOULD SAY SO

Everything webview-related in this feature **has behaved differently on a phone than in
the simulator, twice** — #603 and #604 both shipped and both had to be undone. Build 128
(from `main`) is the current baseline.

There are live pins to test against: **18 link pins**, most on the American Museum of
Natural History place page — TikTok, YouTube, a YouTube Short and Instagram among them.

On device, in this order:

1. **TikTok pin → tap the platform's fullscreen control.** Bars gone, video genuinely
   full-bleed. Leave fullscreen → bars back.
2. **YouTube pin, then the YouTube Short.** Same, both orientations.
3. **The restore paths, which matter more than the fix.** Enter fullscreen, then
   (a) close the page with the X; (b) enter fullscreen and **tap a tab** — including the
   tab you are already on; (c) enter fullscreen, background the app, force-quit,
   relaunch. **In every case the tab bar and mini-player must come back.**
4. **Instagram pin** — should be unchanged (it takes `GalleryVideoView`), and is the
   control that proves nothing regressed on the good path.
5. **A tour with no link pin** — the module must behave exactly as before.

## 10. Not done, deliberately

- `STATUS.md` untouched — a coordinator session owns it.
- No `Tours.json`, no SQL, no catalogue change, no TestFlight build.
- Nothing merged.
