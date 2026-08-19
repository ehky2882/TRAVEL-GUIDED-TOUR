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

**Last verified:** 2026-08-19 21:38 UTC

---

## 1. Awaiting owner — device review

Code PRs cannot merge without a look on device (§ Merging PRs). This is the queue.

| PR | What it is | Build to install | Also needs |
|---|---|---|---|
| [#540](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/540) | Create-a-tour becomes a five-step wizard (Location → Details → Photos → Audio → Review). Closes the draft-autosave gap. | ✅ **88 — installable, untested** | A device pass — that is the only test |

**Build 88 is up and installable**, cut from `e810651` — the PR head exactly, so it is not stale. It is the first build carrying
all three stacked fixes: the toolbar and its NavigationStack removed outright (`730b1af`), a 650 ms
wait before `loadExistingTour` touches state (`a045a5aa`), and the load collapsed from four write
batches into one with its fetches overlapped (`e810651`).

🔴 **Do not read that as fixed.** The freeze has survived **five** builds — 76, 77, 81, 84 and 87 —
and build 87 was itself cut from a commit claiming to fix it. What is verified here is only what 88
*contains*. Whether the hang is gone is decided on the device, not in a commit message.

⚠️ **The diagnosis has moved with every crash log** — toolbar bridge, then `PlatformViewChild`
walking MKMapView's subtree — which reads as repeated samples of one busy loop caught at different
stations. The current theory names the *fuel* rather than any one bridge: state writes flushing
graph transactions from inside the sheet's presentation transition. If 88 also hangs, that is six
round-trips through the owner's phone, and the next attempt should wait for a local Mac session
that can reproduce it in the simulator.

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
| 88 | `tour-upload-polish-qiliop` | #540 + all three stacked fixes (`e810651`) | ✅ built — **untested on device** |
| 87 | `tour-upload-polish-qiliop` | #540 + a hang fix that did not work | 🔴 **still hangs** |
| 84 | `tour-upload-polish-qiliop` | #540 wizard | 🔴 hangs on the edit path |
| 83, 82 | `list-page-conformance` | #547 list page | ✅ **merged to main 18:47** |
| 81, 77, 76 | `tour-upload-polish-qiliop` | #540, earlier passes | 🔴 same hang |
| 80, 79, 74 | `maker-page-playlists-45xqhu` | #517 saved lists | ✅ merged |
| 78 | `main` | #543 edge-to-edge bars | ✅ owner-verified |
| 75 | `main` | post-#517 | ⚠️ superseded |

⚠️ **No build carries current `main`.** #544, #546 and #547 all merged today; 86 carries only
#544, 83 only #547, and 87 is the wizard branch cut from a base predating both. A build from
`main` is the only way to see them together.

## 4. Branches

| Branch | State |
|---|---|
| `claude/tour-upload-polish-qiliop` | Open PR #540 |
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
