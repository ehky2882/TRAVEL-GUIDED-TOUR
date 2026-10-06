# Handoff — onboarding Simulator round 1 (2026-10-06, local Mac session)

Follows `archive/HANDOFF-261006-onboarding.md`. Same PR, same branch.

🔴 **Re-derive live state, never quote this file:** `bash scripts/session-start.sh`, then
`git fetch && git log --oneline origin/main..origin/claude/eloquent-knuth-uutk4y`.

| | |
|---|---|
| PR | https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1093 — **open, NOT merged** |
| Branch | `claude/eloquent-knuth-uutk4y` |
| TestFlight | none made this session — **182 does NOT contain anything below** |
| Owner instruction | Merge and TestFlight only on the owner's explicit say-so |

## What changed (all reviewed by the owner in the Simulator, round by round)

| Area | Change | Why |
|---|---|---|
| Screen 3 | Definition now "a person who leads guided tours, especially through a museum, gallery or historic place." Invented usage example removed | Owner asked whether it was Merriam-Webster/Oxford — it was neither; chose a wording that tracks the real sense |
| All cards | **Reels-style**: tap left third = back, elsewhere = forward; swipe left/right. Buttons kept. Lives in `OnboardingScaffold` (`onForward`, `tapsNavigate`) | Owner |
| Screens 4/5 | Forward tap/swipe = **Skip**, not "next" | Tapping through walked into the sign-up form |
| Skip | `skipAccount()` skips ONLY the account screens → "Welcome." (was: finished onboarding). Back from Welcome restores them. Clears typed names | Owner: skip shouldn't skip to the guides |
| Screen 6 | Every field required (brass `*`), Continue disabled until filled, Skip link added. Taps off on the form; swipe forward saves | Owner |
| Screen 14 | Signed in → **real** follows via `FollowService` (loads live state, reverts on failure). Skipped / signed-out replay → no Follow buttons + "Create an account any time to follow them." | Owner: option 2, and "of course it needs to truly follow" |
| "I already have an account" | Opens the real `SignInView` (email/password, Apple, Google). Signed in → `didSignIn()` drops account screens → "Welcome back." Already signed in at screen 4 → skipped. Watches `isSignedIn` too (user publishes a beat after dismiss) | It used to lead into the sign-up form |
| Guides | Left-third tap / right swipe = back. Back on the **first** guide reopens onboarding's last card (`reopenAtLastCard`, only when onboarding handed over). Tour always starts with the drawer at **mid-detent** | Owner |
| Drawer guide | Anchor moved onto the panel inside `BottomSheet` (`coachMark:` param) and the 110pt clamp removed | It lit the search bar: `BottomSheet.body` is a full-screen GeometryReader |
| App | Onboarding overlay now gets `AuthService` + `FollowService` (it sits outside the environment chain and had neither) | Needed by screens 4/5/7/14 |

## Not verifiable in the Simulator — check on device

- Signing in from "I already have an account" (no test account; we do not type real credentials).
- Screen 14's real follow writes (needs a session).

## Still not built

- **"Create an account" does not create an account** — the onboarding form only stores names. `SignInView` already does real sign-up; wiring screens 5/6 to `AuthService.signUp` / Apple / Google is the obvious next step (offered to the owner).
- Screen 14's six are a fixed list; answers don't personalise Home yet; `caption` is fixed 13pt.

## Testing notes for the next local session

- Fresh onboarding: `xcrun simctl uninstall <udid> com.ehky.TRAVEL-GUIDED-TOUR`, then `build_run_sim`. A plain rebuild restarts an unfinished run; a finished one needs the uninstall (or Settings → Take the app tour / Show tips again).
- Splash holds ~10–15 s on a cold install while the catalogue loads.
- Screenshots from both tools can lag a frame or two behind taps — re-shoot before concluding something failed.
- The owner taps in the same Simulator while you test; an unexpected extra step is usually that.
