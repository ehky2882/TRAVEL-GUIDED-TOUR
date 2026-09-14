# Handoff 2026-09-14 — Dozent 1.1.2 (160) submitted to App Review

**Branch:** `claude/mystifying-chatelet-00d18a` · local Mac session (App Store Connect key).

## Outcome

**1.1.2, build 160, is WAITING_FOR_REVIEW**, submitted 2026-09-14 00:59 UTC, release
type MANUAL. Verified via the ASC API after the owner pressed Submit. The owner owes
the Release button on approval (`status/owner/release-112-when-approved.md`).

## What changed on the listing

| | |
|---|---|
| What's New | Owner cut it to the filters paragraph + "General improvements and bug fixes." The file had still held 1.1.1's notes verbatim |
| Reviewer notes | "tap the WALKS chip" → **Price → Paid** (the chip no longer exists — a reviewer who cannot find the IAP can reject). New ACCOUNT DELETION section asking the reviewer to use a new account, not the demo login. Repo `review_information/notes.txt` now matches ASC (it had drifted — ASC's copy was the newer one) |
| Screenshot 10 | Re-captioned in place: "Explore 3,500 tours / in 530 cities across 67 countries". Other nine and all phone images unchanged (they still show the old filter row) |
| URLs | support/marketing `https://dozent.world`, privacy `https://dozent.world/privacy/` — repo and ASC agree, all 200 |

## Verified before submitting

- Build 160 VALID, not expired, train 1.1.2, `usesNonExemptEncryption=false`, code at `7d394965` identical to `main` for app files.
- App-code delta 139 (`22aed9a0`, 1.1.1) → 160 read commit by commit; tag vocabulary +100 strings.
- 66 paid tours, all $0.99, read from the live `tours.price_tier` (Tours.json carries no price). Tour Tier 0.99 APPROVED; nothing to attach.
- Owner tested account deletion on 160 themselves.
- New version inherited description, keywords, URLs, all 10 screenshots and the review detail **including the demo login** — no password handling needed.

## Traps worth knowing next time

- **Screenshot re-captioning works without recapturing.** Originals download at full size from `appScreenshots.imageAsset.templateUrl` (1320×2868 PNG, **RGBA** — save RGB). Background `#F0EBE0`, title SF Pro (`/System/Library/Fonts/SFNS.ttf`) **91 px** `#131318`, top at y=211; subtitle **80 px** `#6B6B74`, top at y=324; both centred. Verified by re-typesetting the old caption and diffing ink boxes to within 2 px.
- **A screenshot set caps at 10: `409 STATE_ERROR.SCREENSHOT_TOO_MANY`.** To replace one you must DELETE first, then reserve/upload/commit. The new one appends last, so replacing #10 needs no reorder; any other position would.
- **New version via API = `POST appStoreVersions` with the build relationship inline.** Localizations, screenshots and review detail are copied from the previous version.
- **This session's permission classifier refused the final `reviewSubmissions` submit (and then a read-only GET right after) as "Production Deploy".** Everything up to Submit went through; the owner pressed Add for Review → Submit to App Review. Plan for that split.
- `release` lane builds a NEW binary — never use it to submit an existing TestFlight build.
- Not verified: how 1.1.1 treats tag strings it does not know (the "invisible to 1.1.1" claim is from the board, consistent with `Tag.vocabulary` being an allowlist).

## Left as-is

- Phone images in all screenshots still show the old filter row (owner chose text-only).
- `description.txt` understates pins ("more than 500 short videos"; 2,043 exist) — not changed, not asked.
- Promotional text read back empty on 1.1.2's localization. 1.1.1's was not checked, so whether it was dropped or was never set is unknown. It can be set without a review.
