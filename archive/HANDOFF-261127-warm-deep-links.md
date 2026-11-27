# Handoff 2026-11-27 — links that did nothing when the app was already open

**Owner report:** a shared tour or creator link opened the right page when DOZENT was closed, and did
nothing when the app was already open on the phone.

## Cause

A cold link is held until the launch splash lifts (`pendingDeepLink` → `runLaunchGate`), by which
time the scene is active. A warm link went straight to `present(_:)` from `onOpenURL` /
`onContinueUserActivity`, which iOS delivers while bringing the app back — the scene is still
`.foregroundInactive`. `BottomLayerController.present` looks for its anchor only in a
`.foregroundActive` scene, found none, and returned silently. The presenter's state had been set
anyway, so tapping the same link again changed nothing either (the `.onChange` keyed on the id never
fired again).

A second way to miss: a page presented under the full player, or under a tour/creator page the user
had left open, lands out of sight.

## Fix (code PR — waits for owner OK + device test)

- `BottomLayerController.canPresentNow` — the same condition `present` uses, exposed.
- `presentWarmDeepLink` in `TRAVEL_GUIDED_TOURApp.swift` — waits (≤ 5 s, 50 ms polls) for
  `canPresentNow`; if `DeepLink.needsClearing` says something is in the way, closes the full player
  and dismisses the four layers through their direct `dismiss()` route, waits 550 ms for the
  slide-down, then presents. A newer link replaces an older one still waiting (`warmDeepLinkToken`).
- `DeepLinkScreenState` + `DeepLink.needsClearing` (pure) and `DeepLinkWarmRoutingTests`.
- Cold-launch and first-run paths are unchanged.

## Not verifiable here

Device-only: the activation timing cannot be reproduced in CI. Test on a TestFlight build — open the
app, background it, tap a tour link and a creator link (from Messages or Notes), with and without a
page or the full player left open.
