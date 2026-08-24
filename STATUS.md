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

**Last verified:** 2026-08-24 17:30 UTC

**⚠️ This board is no longer polled on a timer.** The coordinator session ran a 25-minute check
from 04:50 to 12:25 and found something worth reporting on two of fifteen ticks, at roughly 20k
tokens a tick — so it is now **on demand** (owner decision, 2026-08-20). It goes stale the moment
a parallel session merges something. **Re-derive before trusting it**, per the update rule above.

---

## 1. Awaiting owner — device review

✅ **Build 114 is from `main`** (`8d2ad947`, 15:55) and **zero PRs are open** — the cleanest state
this board has recorded. It carries the fullscreen video viewer, the Swedish architects, the Akalla
hero and the `get_catalog` hardening.

🔴 **ONE THING MERGED AFTER IT AND IS NOT IN ANY BUILD: [#583](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/583)** (17:21) — *a reused hero
view kept the previous tour's photograph*. **You may well have hit this on 114 itself**: the
"Continue listening" row read **VIA 57 WEST while showing the Colosseum**.

- **The cause is a SwiftUI reuse trap worth remembering.** `HeroImageView` guarded its fetch with
  *"already cached, nothing to do"* — but `.task(id: imageName)` fires when the URL **changes under
  a view SwiftUI has reused**, and at that moment the state still holds the *previous* URL's
  photograph. `State(initialValue:)` seeds only the first use of a view identity and is discarded on
  reuse. So the early return left the old picture under the new title, permanently, with nothing
  logged anywhere.
- **⚠️ It only affects a view that SWAPS TOURS** — Continue listening, the map placecard, a resume
  banner. Anything inside a `ForEach` keyed by tour was always correct, which is exactly why the
  rails beside it looked fine and made the bug read as a data fault.

✅ **#582 closes the loop on this session's opening problem** — *`create or replace get_catalog()`
destroys the place layer, and four files still do it*. That is the regression that took out places,
prices and private accounts on 2026-08-19; the files that could repeat it are now identified.
Contract check still passes: **1,513 tours, 25 places, 41 maker rows**.

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

🔴 **Build numbers are `github.run_number` and are SHARED across every branch.** Read them back
after dispatching; never promise one in advance. And a build carries its branch's **merge-base**,
not `main` — GitHub reports a PR's base as main's current tip, which is misleading.

| Build | Branch | Carries | Result |
|---|---|---|---|
| **114** | **`main`** | Fullscreen video, Swedish architects, Akalla hero, `get_catalog` hardening (`8d2ad947`) | ✅ **install this** — but see #583 |
| 113 | `chrome-row-modifier` | #576 chrome row extracted — head merged `main` at 13:14 (`e90d9995`) | ✅ superseded |
| 112 | `color-mismatch-elements-pj2ptt` | #573 chrome row made opaque | ✅ merged |
| 111 | **`main`** | #565 architects, #566 launch mark, #567 + #568 offline photographs (`891702fd`) | ✅ last true from-main build |
| 110 | **`main`** | Everything to 22 Aug, plus #563 light mode (`b421bde9`) | ✅ superseded |
| 109 | `launch-performance-animations-df4d7p` | #559 launch sequence (`52a86cfa`) | ✅ superseded by 110 |
| 108 | `launch-performance-animations-df4d7p` | Same work, one commit earlier | ⚠️ superseded |
| 98 | `wizard-comments-round2` | #558 wizard round two (`e0132c90`) | ✅ merged |
| 97 | `wizard-comments-round2` | Same work, one commit earlier | 🔴 **Live and installable, run shows RED, no notes** |
| 96 | `upload-wizard-improvements-ejopz3` | #552 the seven-step wizard | ✅ owner-verified — *"so much better"* |
| 95 | `ellipsis-button-consistency-vdorpi` | Became #555 — Liked on the shared list screen | ✅ merged |
| 94 | `ellipsis-button-consistency-vdorpi` | #553 list page as a layer | ✅ owner-verified, merged |
| 93 | `library-launch-jitter` | #549 Library launch jitter | ✅ merged |
| 91 | `main` | Wizard, Settings, list page, 5:4 heroes | ✅ owner-verified |
| 90 | `tour-upload-polish-qiliop` | #540 + the saved-tour hang fix | ✅ owner-verified — hang closed |

✅ **#552 merged `main` in before merging out** (`a9a3b32`, two real conflicts resolved by hand) — so
the stale-base warning this board carried against build 96 was dealt with by the session itself.


## 4. Branches

| Branch | State |
|---|---|
| `claude/library-launch-jitter` | Merged (#549 at 03:52) — auto-delete should remove it |
| `claude/upload-wizard-improvements-ejopz3` | Merged (#552 at 19:05) |
| `claude/wizard-comments-round2` | Merged (#558) and deleted |
| `claude/launch-performance-animations-df4d7p` | Merged (#559 at 16:43) — built as 108/109 |
| `claude/milan-tours-upload` · `claude/milan-docs-260822` | Merged (#560, #561) |
| `claude/coordinate-guard` | Merged (#562 at 17:20) |
| `claude/ellipsis-button-consistency-vdorpi` | Merged twice from one branch (#553, #555). ⚠️ The second stacked on already-merged history, which CLAUDE.md says to avoid — it worked, but no PR existed while build 95 was installable |
| `claude/tour-upload-polish-qiliop` | Merged (#540) — auto-delete should remove it |
| `claude/stripe-questions-fjhdo3` | ⚠️ No PR — verify contents before deleting |
| `claude/amsterdam-handoff-preserve-hlhyp8` | 🔒 Keep — only copy of staging pick-maps |
| `claude/web-landing-site-preserve` | 🔒 Keep — only copy of the Next.js landing site |
| `claude/london-batch3-scripts-260616` · `claude/paris-scripts-260622` · `claude/dreamy-wozniak-tags-260612` | 🔒 Keep (documented archival) |

## 5. Content

**Catalog 1,513 tours / 33 makers** — **Stockholm (Atlas Studio STO, 45 tours) landed 2026-08-24**
and is live in the RPC, along with VIA 57 West. Milan (48 tours) landed 2026-08-22. ⚠️ The RPC reports **40** maker rows against a true 32: upsert-only accumulation,
long-standing. The audio-pending queue is **EMPTY**. `drafts/AUDIO-PENDING-SURVEY.md` on `origin/main` stays the
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
