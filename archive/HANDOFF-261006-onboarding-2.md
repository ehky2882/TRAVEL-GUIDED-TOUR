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

## Round 2 (same session): account creation is REAL

Owner: *"why would 'create an account' be anything except a real account"*. Screens 5–6 now create one:

| Path | What happens |
|---|---|
| Apple | Native Apple flow from our own capsule (`OnboardingAppleSignIn`) → `AuthService.signInWithApple`. Apple's name (first authorisation only) prefills the form, which asks names + home city; Continue names the profile |
| Google | `AuthService.signInWithGoogle` (OAuth sheet); name from `full_name` metadata (`AuthService.providerFullName`) |
| Email | Form gains **Email** + "Password (6+ characters)". Continue checks the username (`handle_available`), then `signUp`. Signed in → profile name + username saved. **Confirmation required (the project default)** → "Check your email" card, run continues, name + username held in `OnboardingState.pendingDisplayName/pendingUsername` and applied on the account's first sign-in (`applyPendingProfile`, App `.onChange(of: authService.userId)`) |

- 🔴 An existing profile is never overwritten (`applyProfile` only fills an account with no maker row; username only when it is still automatic).
- `isCreatingAccount` stops the "I already have an account" watcher from skipping the form when a provider sign-in happens on screen 5.
- Screen 14: Follow buttons only when signed in; an unconfirmed email account sees "Confirm your email to follow them."
- Apple's error codes are replaced with a sentence (`friendlyAccountError`).
- `SignInView`'s nonce helpers moved to `AppleNonce` (shared).

## Round 3 (2026-10-25): sign-up checks, layout, the face hand-off — builds 187

Owner reviewed build 187 on device: *"things look good"*. **PR #1093 is still NOT merged** — wait for the owner to say "merge".

| Change | Detail |
|---|---|
| Sign-up form checks | Email format + typo suggestion ("Did you mean gmail.com?"); live username check (`handle_available`, 450 ms debounce — needed `backend/handle_available_anon.sql`, applied and verified live); home city must be picked from `PlaceSearchService` suggestions (shown inline ABOVE the field); password eye + 8-character minimum (sign-in still accepts 6); `OnboardingTermsLine` on screen 5 and the email form |
| Warnings colour | `AtlasColors.destructive`, never `mapPin` — that token IS the brand brass |
| Face | 44pt (radius 22, the splash mark's size) on every card; was 84pt |
| Buttons | `OnboardingButton` and the Apple/Google/Email capsules are 44pt (were 54/50). Form fields stay 52pt |
| Button position | The actions area is a fixed `44 + 40 + 40` (button + two link slots), top-aligned, so the button sits on one line on every screen. The email form's Terms line moved UNDER Skip to fit |
| Face hand-off 2 → 3 | One face via `matchedGeometryEffect` (`onboardingFaceSpace` env + `.onboardingFace()`). `isFaceHandOff` on the coordinator slows that one move to `.smooth(0.75)`. Both cards use `.onboardingHold` (an animatable no-op transition — a plain `.scale(1)` removed screen 2 instantly; `.opacity` dimmed the disc mid-slide); screen 3's bar/copy/buttons fade in via `chromeIn` |
| Guides | No outline on the spotlight or the demo finger |

Still device-only and not yet confirmed by the owner: Email / Apple / Google sign-up, "I already have an account", screen 14's real follows.

## Round 4 (2026-10-25): faces, the send-off, no-zoom first launch — MERGED and SUBMITTED as 1.1.4

**PR #1093 was squash-merged to `main` (c7988e66) on the owner's say-so, and 1.1.4 (build 190, built from `main`) was submitted to App Review** — state `WAITING_FOR_REVIEW`, release MANUAL, 7-day phased release set. The owner releases it after approval (`status/owner/release-1-1-4.md`), then `MARKETING_VERSION` needs its bump. Builds 188 and 189 were the branch builds the owner approved on device.

| Change | Detail |
|---|---|
| Six faces | `DozentExpression`: `rest` (closed eyes, the original — calm screens only), `smile` (dot eyes, wide smile), `content` (smiling eyes), `beam` (big laugh), `wow` (little o), `excited` (smiling eyes + laugh). Picked by the owner from an option sheet; `wink` retired. Each card and guide stop names its face |
| Send-off guide | `CoachMark.ready`, after the bar: no spotlight, the same 0.62 dim, Home as it opens (tab Home, drawer `.medium`), "That's the tour … These tips are always in Settings.", button "I'm ready to explore!". The final tap fades the overlay over 0.7s |
| No-zoom first launch | On a first launch `runLaunchGate` → `handOffToOnboarding()`: screen 2 is mounted under the resting splash at the splash's exact geometry (`LaunchZoom.origin`, wordmark centre `22 + md` below), and the splash is lifted at the top of a breath (`SplashView.breathIsAtPeak`). Screen 2 waits for `launchState.isCovering == false` before its face fades in. Later launches keep the zoom |
| Face fade | The face now fades in over a SOLID disc — the old cross-fade dipped it to ~75%, which the zoom had hidden |
| Pending profile | `OnboardingState.pendingEmail`: a waiting name/username applies only when that email signs in (`pendingProfileDecision`); another account leaves it waiting; one saved before the field existed is discarded |
| Release tooling | `scripts/push-appstore-metadata.py` now sends What's New + review notes, `--create-version`, `--build N`, `--skip field` (PR #1156) |
| Store text | `fastlane/metadata/en-US/release_notes.txt` (What's New) and `review_information/notes.txt` (first-launch section, 2,100+ tours, swipe to the Price chip) — both pushed and re-checked. Promotional text deliberately NOT pushed: blank in ASC, the repo copy's numbers are stale |

Checked: dark mode and iPad (portrait-only window, as 1.1.3 shipped) on every onboarding screen and guide.

## Not verifiable in the Simulator — check on device

- **Every real account path**: Apple, Google, Email sign-up (+ the confirmation link → first sign-in applying the name/username). Creating an account on the live Supabase from a session is not allowed, and the Simulator has no Apple Account.

- Signing in from "I already have an account" (no test account; we do not type real credentials).
- Screen 14's real follow writes (needs a session).

## Still not built

- Screen 14's six are a fixed list; answers don't personalise Home yet; `caption` is fixed 13pt.

## Testing notes for the next local session

- Fresh onboarding: `xcrun simctl uninstall <udid> com.ehky.TRAVEL-GUIDED-TOUR`, then `build_run_sim`. A plain rebuild restarts an unfinished run; a finished one needs the uninstall (or Settings → Take the app tour / Show tips again).
- Splash holds ~10–15 s on a cold install while the catalogue loads.
- Screenshots from both tools can lag a frame or two behind taps — re-shoot before concluding something failed.
- The owner taps in the same Simulator while you test; an unexpected extra step is usually that.
