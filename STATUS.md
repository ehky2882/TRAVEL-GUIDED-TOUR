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

**Last verified:** 2026-08-20 18:20 UTC

**⚠️ This board is no longer polled on a timer.** The coordinator session ran a 25-minute check
from 04:50 to 12:25 and found something worth reporting on two of fifteen ticks, at roughly 20k
tokens a tick — so it is now **on demand** (owner decision, 2026-08-20). It goes stale the moment
a parallel session merges something. **Re-derive before trusting it**, per the update rule above.

---

## 1. Awaiting owner — device review

🔴 **READ FIRST — A BRANCH BUILD CARRIES ITS BRANCH'S BASE, NOT `main`.** Build **92** was cut from
`library-launch-jitter`, which split off `main` on **18 Aug**, so it shipped *without* the upload
wizard, the bottom-bar island-form fix, Universal Links and the Settings pass. **The owner read the
missing wizard and the reappearing place-page bar as regressions — which is exactly what they look
like.** They were not: 92 simply predated them.

**This board told the owner to install 92 without saying that.** The same point had been made
correctly about build 87 eleven hours earlier ("87 is the wizard branch, cut from a base predating
those merges") and was not carried forward. **From now on, every branch build's row states what its
base predates**, and a branch that has not merged `main` recently should merge it before its build.

| PR | What it is | Build | Also needs |
|---|---|---|---|
| [#549](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/549) | **Library launch jitter + lookup perf.** Lists were memory-only, so every launch made three sequential round-trips and the tab re-laid-out twice. Now a per-account disk snapshot hydrated at init, loads concurrent. Also replaces linear scans over 1,418 tours with dictionaries. | ✅ **93** | ✅ **MERGED 03:52** — still worth the device pass, but it is on `main` now |
| [#552](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/552) | **The tour wizard is seven steps, and a step is a screenful** (retitled — it was five). Original problem: Owner's rule: no step may scroll — if it doesn't fit it becomes another step. Four of five overflowed; step 1 was 596pt into 411pt. Mini-player and tab bar withdraw while the wizard is up (126pt back), step 1 asks where **once** instead of three times, and the map takes the slack. | ✅ **96** | Owner OK + a look. ⚠️ **96 predates #549, #553 and #555** — no library fix, no list-as-layer, no shared Liked screen |
| [#553](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/553) | **The list page behaves like every other top-level screen.** Started as the gold ringed `…` the owner flagged — drift, not a choice: it was a bare `ellipsis.circle` that drew its own ring and inherited the accent. Became three changes, ending with the list page **sliding up from the bottom** like tour detail and the place page, with an X instead of a back chevron. Signed out, the bookmark greys rather than vanishing. | ✅ **94** | ✅ **MERGED 11:36** — owner reviewed it on 94: *"LOOKED AT TESTFLIGHT. LOOKS GOOD."* |

✅ **Build 93 is the one to install for #549, and it is a proper build.** Cut from `c2e8594`, which
**merges `main` into the branch** — so it carries the wizard, Settings, list page and Universal
Links *plus* the library fix. Two commits have landed since and neither touches the binary: one
untracks `.xcodebuildmcp/config.yaml`, one is docs.

🐛 **That untracked file is worth knowing about.** `.xcodebuildmcp/config.yaml` was committed and
named **the other clone** plus `iPhone 16 Pro`, which is no longer installed — so every local
session had to reset both before its first build, and **one that forgot compiled untouched code and
believed it had tested the change.** Untracked now rather than corrected: no defaults fails loudly
on the first build, a wrong path fails silently. Found independently by two sessions today.

⚠️ **#549's jitter cannot be reproduced in the simulator** — it holds no session, so there are no
lists to pop in. Genuinely needs the phone. 🔴 Its risk is **staleness**: a dictionary index not
rebuilt when the catalog changes returns nil for a row plainly on screen, reading as missing
content rather than a bug. All mutations go through `applyCatalog` / `applyMakers` / `setPlaces`
and tests pin it.

✅ **#553 is in, and it was the risky one.** It added a **fourth** `BottomLayerController` — the
machinery behind this app's repeat regressions (the dead tab bar, layers not torn down, bars showing
content through the island's gaps). The new layer took its line in **both** lists a layer has to
appear in (`isAnyLayerPresented` and `tabSelection`); the place layer shipped missing from one, then
the other, in consecutive builds. The owner reviewed it on device.

⚠️ **Build 94's merge-base was `8c1eb4b0`, one behind main at the time**, so it did not carry #549's
Library launch-jitter fix. That did not block the review — the two are unrelated screens — but it is
why the Lists tab may still have shuffled on it. **Both are on `main` now.**

⚠️ **#552 opened deliberately unbuilt** — to get `ci.yml` to compile eight commits that had never
been built. Its riskiest check is **opening a saved tour**: the map is now sized from a
`GeometryReader`, which adds a layout dependency to the exact view that hung for seven builds. The
PR says plainly that its confidence there is reasoning rather than evidence.

## 1b. ✅ RESOLVED — the catalog regression, fixed and verified

**Owner ran `backend/restore_catalog_keys.sql` 2026-08-20, and has since confirmed on device that
the place pages and capsule pins are back.** Verified against the live RPC as well, not just the
success message:

| | Before | After |
|---|---|---|
| `places` | absent | **25** ✅ |
| `priceTier` | absent on 1419 tours | present on 1419, **66 priced** ✅ |
| `isPrivate` | absent on 39 makers | present on **39** ✅ |
| `country` | 1418 | **1418** — held ✅ |
| `videoURLs` · `userId` | intact | intact ✅ |

All 25 places carry ≥2 tours, so every one renders. **`country` holding is the specific proof that
mattered** — re-running `places_apply.sql` instead would have restored places and knocked country
back out, which is why the separate file existed.

**Cause, for the record:** `add_country.sql` rebuilt `get_catalog()` from `schema.sql`'s body —
correctly, by its own design — but `schema.sql` had never carried `places`, `priceTier` or
`isPrivate`, all added by later migrations. Nothing errored; all three are optional in Swift, so
the features silently stopped existing. **Not a code fault, and not build 91's.**

**Hardened, two ways.** `schema.sql` now carries both missing keys plus a 🔴 warning that the
function is wrapped in production and every later key must be added there too. And there is now a
check that runs whether or not anyone is paying attention:

**`scripts/check-catalog-contract.py`** — queries the live RPC and diffs its key set against the
Swift models. The expected keys are **parsed out of `Models/Tour.swift`, `Maker.swift` and
`Place.swift`**, never hardcoded, so adding a field starts requiring it on the next run with no
edit to the script. A hardcoded list would drift and quietly stop testing anything, which is the
exact class of bug it exists to catch.

**It works: its first run found a fourth missing key nobody knew about** — `tours[].createdAt`.
That one is **pre-existing, not a regression** (the RPC has never served it). `Place.ranked` sorts
NEWEST FIRST on it, so that rule has no dates to sort on and falls through to its tiebreaks.
⚠️ **Do not "fix" it by emitting `tours.created_at`** — that column is `default now()` and the seed
never carries the authored date, so it holds *seed* time; most of the catalog shares 2026-06-27,
the original bulk seed. It would look fixed and rank wrongly. The real fix is to make
`seed_from_toursjson.py` carry the authored `createdAt` first. Recorded in the script as a **known
gap**: printed as a warning every run, but not a failure — a check that always fails gets ignored,
and then it catches nothing.

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

✅ **Applied:** `add_country.sql` (Countries row live) · `restore_catalog_keys.sql` (places, priceTier,
isPrivate restored 2026-08-20).

| File | Unlocks | Without it |
|---|---|---|
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
| 96 | `upload-wizard-improvements-ejopz3` | #552, the seven-step wizard (`98fd9028`) — merge-base `8c1eb4b0`, so it predates **three** code merges: #549, #553, #555 | ✅ built 18:12 |
| 95 | `ellipsis-button-consistency-vdorpi` | Became **#555** (`435436b1`) — Liked rendered through the shared list screen | ✅ merged 13:39 |
| 94 | `ellipsis-button-consistency-vdorpi` | #553 list page as a layer (`1d7ed910`) — merge-base `8c1eb4b0`, so **no #549 library fix** | ✅ owner-verified — **#553 merged** |
| 93 | `library-launch-jitter` | #549 **after merging main** (`c2e8594`) — #549 has since merged, so this is on `main` | ✅ the one that has the Library fix |
| 92 | `library-launch-jitter` | #549 on an 18 Aug base — **no wizard, no Settings pass** | ⚠️ looked like regressions; it was just old |
| 91 | `main` (`fd741db`) | **Everything from today, together** — wizard, Settings, list page, 5:4 heroes | ✅ owner-verified |
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
| `claude/library-launch-jitter` | Merged (#549 at 03:52) — auto-delete should remove it |
| `claude/upload-wizard-improvements-ejopz3` | Open — #552, **the only open PR**, head `98fd9028`, built as 96. Merge-base `8c1eb4b0` predates **three** merges |
| `claude/ellipsis-button-consistency-vdorpi` | Merged twice from one branch (#553 at 11:36, #555 at 13:39). ⚠️ The second stacked on already-merged history, which CLAUDE.md's rule says to avoid — it worked here, but a PR did not exist while build 95 was installable |
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
