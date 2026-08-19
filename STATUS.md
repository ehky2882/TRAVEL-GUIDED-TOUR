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

**Last verified:** 2026-08-19 18:40 UTC

---

## 1. Awaiting owner — device review

Code PRs cannot merge without a look on device (§ Merging PRs). This is the queue.

| PR | What it is | Build to install | Also needs |
|---|---|---|---|
| [#540](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/540) | Create-a-tour becomes a five-step wizard (Location → Details → Photos → Audio → Review). 19 files, +2646/−1772. Closes the draft-autosave gap. | **84** ✅ | Watch the **editor** for regressions — it now shares the wizard's audio step |
| [#544](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/544) | Settings: real wordmark, live version string, Makers→Dozents, city/country counts. | **86** ✅ (85 superseded) | **Paste `backend/add_country.sql`** or the Countries row stays hidden |
| [#547](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/547) | List page rebuilt on `PlaceView`'s structure; both maps become one shared `TourSetMap`. | **83** | Riskiest check is the **maker MAP tab** — a shipped screen rewired onto a shared component |

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
| `backend/add_country.sql` | The Countries row in Settings (#544) | Row hidden, not wrong — nothing breaks |
| `backend/saved_places.sql` | Saved places syncing across devices | Saving works, stays on one device |
| `backend/places_photos.sql` | Places serving their own photographs | Optional — the app is correct without it |

## 3. Builds — which run number carries what

🔴 **Build numbers are `github.run_number` and are SHARED across every branch.** A build
dispatched as "the next one" comes back as whatever number the counter reached. Read it back
after dispatching; never promise one in advance.

| Build | Branch | Carries | Result |
|---|---|---|---|
| 86 | `settings-dozent-work-mark-r9enu6` | #544 Settings + gold wordmark fix | ✅ **install this** |
| 85 | `settings-dozent-work-mark-r9enu6` | #544 Settings | ⚠️ superseded by 86 — wordmark rendered white |
| 84 | `tour-upload-polish-qiliop` | #540 wizard | ✅ |
| 83 | `list-page-conformance` | #547 list page | ✅ |
| 82 | `list-page-conformance` | #547 list page | ✅ |
| 81 | `tour-upload-polish-qiliop` | #540 wizard | ✅ |
| 80, 79 | `maker-page-playlists-45xqhu` | #517 saved lists | ✅ |
| 78 | `main` | #543 edge-to-edge bars | ✅ owner-verified |
| 77, 76 | `tour-upload-polish-qiliop` | #540 wizard | ✅ |
| 75 | `main` | post-#517 | ✅ |
| 74 | `maker-page-playlists-45xqhu` | #517 saved lists | ✅ |

## 4. Branches

| Branch | State |
|---|---|
| `claude/tour-upload-polish-qiliop` | Open PR #540 |
| `claude/settings-dozent-work-mark-r9enu6` | Open PR #544 |
| `claude/list-page-conformance` | Open PR #547 |
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
