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

**Last verified:** 2026-08-20 03:13 UTC

---

## 1. Awaiting owner — device review

| PR | What it is | Build | Also needs |
|---|---|---|---|
| [#549](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/549) | **Library launch jitter + loading perf.** Lists were memory-only, so every launch made three network round-trips *awaited in sequence* and the tab re-laid-out twice in front of you. Now a per-account disk snapshot hydrated at init, with the three loads concurrent. Also replaces linear scans over 1,418 tours with dictionaries — those `by id` lookups run from ~20 sites per body evaluation. | ✅ **92** (6m22s) | A signed-in device: cold launch → Library → Lists should show its final shape immediately |

**Build 92 is the one to install.** Cut from `17fb3fc`, the code commit; the branch has since moved
to `73d1238`, which is **docs only** — so 92 is stale by SHA and not by substance. The
`Build and upload to TestFlight` step passed, so the notes attached.

⚠️ **The jitter cannot be reproduced in the simulator** — it holds no session, so there are no lists
to pop in. This one genuinely needs your phone.

🔴 **The risk it introduces is staleness.** An index not rebuilt when the catalog changes returns nil
for a row plainly on screen, which reads as missing content rather than a bug. Every mutation goes
through one door (`applyCatalog` / `applyMakers` / `setPlaces`) and new tests pin it — but that is
the thing to watch for. `test_sim` 346/346.

✅ **#548 merged** (docs — the Settings pass and the `.tint` that repainted the wordmark white for
months). Docs-only, auto-merge class, all four checks green.

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
| 92 | `library-launch-jitter` | #549 Library jitter + lookup perf (`17fb3fc`) | ✅ **install this** |
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
