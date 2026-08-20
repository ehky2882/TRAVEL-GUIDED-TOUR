# STATUS — the live board

**What this file is.** A short, mechanical record of *what is in flight right now*: open PRs,
which TestFlight build carries which branch, and what is waiting on the owner. It is the thing
a session reads to answer "what is everyone else doing?" before it starts work.

**What this file is NOT.** History. `CLAUDE.md` § Current State is the narrative record of what
shipped and why, and it stays the authority for anything already merged. When an item here is
finished, it leaves this file and its story goes there. Never let this file grow a history
section — two histories drift, and drift is the problem this file exists to fix.

**Update rule (automatic, no prompting).** Any session that opens or merges a PR, dispatches a
TestFlight build, or discovers/clears an owner-blocked item updates the relevant table here in
the same commit. Re-derive rather than trust: `gh pr list --state open`, and read the build
numbers back from the Actions run list — never from what a PR body predicted.

**Last verified:** 2026-08-20 01:07 UTC

---

## 1. Awaiting owner — device review

**No open PRs.** #540 merged at 00:13 UTC (squash `fd741db`), which empties the code queue for the
first time today — #541 through #547 all landed earlier.

| Build | What it carries | State |
|---|---|---|
| **91** | **The first build from `main` with everything today together** — the wizard, Settings, the list page, the 5:4 heroes and the place-layer fixes | ✅ **on TestFlight, untested** |

**Uploaded 00:58 UTC.** The `Build and upload to TestFlight` step itself passed, which is the evidence
that matters — the `Done` step is an unconditional echo and proves nothing, while fastlane raises if
either the upload or the changelog write fails. So the build notes attached. It took **43m41s**,
longer than 89 (~29m) and 90 (~26m) but well inside the 70-minute timeout, and it finished on its
own — no re-run needed.

**This is the build that closes the gap the board has been flagging all evening.** Until now no
build carried `main`: 86 had only #544, 83 only #547, and 90 was the wizard branch cut from a base
predating both. 91 is cut from `fd741db` and carries all of it.

⚠️ **So the riskiest thing to check is not the wizard — it is the combination.** The merge resolved
a real conflict in `MakerTourService.swift`, the file that talks to Supabase, and that resolution
has never run on a device. CI is green on it (simulator build + unit tests), which proves it
compiles and passes, not that it behaves.

✅ **The saved-tour hang is closed** — owner-verified on build 90, and 91 carries the fix. Eight
builds, seven of which shipped the freeze (76, 77, 81, 84, 87, 88, 89), six wrong diagnoses. Cause:
`Map(position:)` bound to `.automatic` with nothing to frame, on the edit path only, because
`centerOnUser` guarded on `existingTourId == nil`.

🔴 **The durable lesson, now in `CLAUDE.md`: a crash log is ONE SAMPLE of a spin.** Six diagnoses
came from three different top frames of the same loop — toolbar bridge, `PlatformViewChild` walking
MKMapView's subtree, presentation. Every frame was real; none was the cause. **Diff the working
path against the broken one before trusting any stack.**

## 2. Blocked on owner — outside the repo

Nothing here can be done from a session. Ordered by what blocks the most.

| Item | Why it matters | State |
|---|---|---|
| **App Store 1.1 review** | Submitted 2026-08-18 03:22 UTC, build 66, `releaseType` MANUAL — approval does **not** publish, the owner presses Release. The licence agreement that was gating uploads is accepted as of 2026-08-19, so nothing blocks the update path now. | ❓ Status unverified — check App Store Connect |
| **Stripe platform review** | Response submitted; account flagged under Restricted Businesses. | ❓ Awaiting Stripe reply |
| **9 IAP tiers `MISSING_METADATA`** | Each needs a review screenshot at its real price. Deliberately blocked: every walk is $0.99 today, so a genuine $2.99 screenshot cannot exist yet. | ⏸ Blocked by design |
| **EU trader declaration** | App declared **non-trader** while selling ten IAP tiers into EU cities. Declaring trader publishes an address. | 🔴 Decision owed |
| **LLC vs sole proprietor** | Gates the Stripe payout path, and collapses the EU-trader and the AHWY/EHKY-initials trade-offs at once. | 🔴 Decision owed |

### SQL pastes owed (Supabase SQL Editor, project **Dozent**)

| File | Unlocks | Without it |
|---|---|---|
| `backend/add_country.sql` | The Countries row in Settings | ⬆️ **More urgent now — #544 is merged**, so the row is in shipped code and stays hidden until this runs |
| `backend/saved_places.sql` | Saved places syncing across devices | Saving works, stays on one device |
| `backend/places_photos.sql` | Places serving their own photographs | Optional — the app is correct without it |

## 3. Builds — which run number carries what

🔴 **Build numbers are `github.run_number` and are SHARED across every branch.** A build
dispatched as "the next one" comes back as whatever number the counter reached. Read it back
after dispatching; never promise one in advance.

| Build | Branch | Carries | Result |
|---|---|---|---|
| 86 | `settings-dozent-work-mark-r9enu6` | #544 Settings + gold wordmark | ✅ **merged to main 18:39** |
| 85 | `settings-dozent-work-mark-r9enu6` | #544, wordmark rendered white | ⚠️ superseded by 86 |
| 91 | `main` (`fd741db`) | **Everything from today, together** — wizard, Settings, list page, 5:4 heroes | ✅ **install this** |
| 90 | `tour-upload-polish-qiliop` | #540 + map never starts `.automatic` over empty content (`eea754b`) | ✅ owner-verified — hang closed |
| 89 | `tour-upload-polish-qiliop` | #540 + edit presents full-screen (`0e1edf3`) | 🔴 hung — superseded |
| 88 | `tour-upload-polish-qiliop` | #540 + all three stacked fixes (`e810651`) | 🔴 **still hangs** |
| 87 | `tour-upload-polish-qiliop` | #540 + a hang fix that did not work | 🔴 **still hangs** |
| 84 | `tour-upload-polish-qiliop` | #540 wizard | 🔴 hangs on the edit path |
| 83, 82 | `list-page-conformance` | #547 list page | ✅ **merged to main 18:47** |
| 81, 77, 76 | `tour-upload-polish-qiliop` | #540, earlier passes | 🔴 same hang |
| 80, 79, 74 | `maker-page-playlists-45xqhu` | #517 saved lists | ✅ merged |
| 78 | `main` | #543 edge-to-edge bars | ✅ owner-verified |
| 75 | `main` | post-#517 | ⚠️ superseded |

✅ **Build 91 closes the no-build-carries-main gap** that stood open all evening.

## 4. Branches

| Branch | State |
|---|---|
| `claude/tour-upload-polish-qiliop` | Merged (#540) — auto-delete should remove it |
| `claude/stripe-questions-fjhdo3` | ⚠️ No PR — verify contents before deleting |
| `claude/amsterdam-handoff-preserve-hlhyp8` | 🔒 Keep — only copy of staging pick-maps |
| `claude/web-landing-site-preserve` | 🔒 Keep — only copy of the Next.js landing site |
| `claude/london-batch3-scripts-260616` · `claude/paris-scripts-260622` · `claude/dreamy-wozniak-tags-260612` | 🔒 Keep (documented archival) |

## 5. Content

**Catalog 1418 tours / 31 makers / 1774 stops.** The audio-pending queue is **EMPTY** — ten
consecutive complete drops. `drafts/AUDIO-PENDING-SURVEY.md` on `origin/main` stays the
authority; read it from `origin/main`, never from a branch.

## 6. Known debt — real, not urgent

- **Supabase over-reports.** The RPC serves ~1,419 tours / 39 makers against a true 1,418 / 31.
  Upsert-only accumulation: rows deleted from `Tours.json` are never deleted from the database.
  Any count shown in-app inherits this.
- **2 dead gallery images** — The Oculus and The Charging Bull, Wikimedia 404s, deferred since
  2026-06-21.
- **Square Saint-Louis** is the one place still repeating an image; needs one sourced photo.
- **15 tours** missing a Place-type or Theme tag (validator warnings, content-only fix).
- **Policy pages** are long legal prose at 13px monospace — readability at length unconfirmed.
