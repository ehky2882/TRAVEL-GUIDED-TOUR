# Handoff — 2026-09-20 · Dozent 1.1.3 submitted to the App Store on build 176

**Submitted:** 2026-09-20 22:13 UTC · state `WAITING_FOR_REVIEW`
**Version:** 1.1.3, ASC id `62bfdb31-ac50-45a0-b03f-b1dcf8235a7a`
**Build:** **176** — uploaded 2026-09-19, `VALID`, run 35460055093, from `a0671e39`
on `claude/map-clustering-screen-space`. Owner-tested on device: *"looks good! merge it"*.
**No new binary was produced.**

## The whole point of this session: submit the build that already exists

`fastlane release` — and `release.yml`, which is only a wrapper around it — calls
`build_ipa`. Running either would have **compiled a fresh binary and submitted
that**, not the one the owner tested. The same lane runs `upload_to_app_store`
with `force: true` and `skip_screenshots` only, so it would also have pushed
`fastlane/metadata/` with no confirmation prompt.

So the submission was driven directly against the App Store Connect REST API with
the key at `~/Downloads/AuthKey_*.p8`. Six calls, each verified before the next:

| Step | Call | Result |
|---|---|---|
| Create the version | `POST /v1/appStoreVersions` — `1.1.3`, `IOS`, `releaseType: MANUAL`, copyright `2026 Dozent` | 201 · `PREPARE_FOR_SUBMISSION` |
| What's New | `PATCH /v1/appStoreVersionLocalizations/{en-US}` | 200 · 1,086 chars |
| Attach the build | `PATCH /v1/appStoreVersions/{id}/relationships/build` → build 176 | 204 |
| Phased release | `POST /v1/appStoreVersionPhasedReleases` — `INACTIVE` | 201 |
| Add for review | `POST /v1/reviewSubmissions` + `POST /v1/reviewSubmissionItems` | 201, 201 |
| Submit | `PATCH /v1/reviewSubmissions/{id}` — `submitted: true` | 200 · `WAITING_FOR_REVIEW` |

## Build 176 is current — verified, not assumed

```
git diff --stat a0671e39 HEAD -- '*.swift' '*.pbxproj' Info.plist 'TRAVEL GUIDED TOUR/Assets.xcassets'
```

is **empty**. Everything merged since 176 was cut is content, scripts and docs,
and content reaches phones over the air from Supabase. There was nothing to
rebuild, which is what made submitting the existing binary the correct move
rather than a shortcut.

## Screenshots: carried forward untouched, and that was checked at the byte level

Creating a version through the API **copies the previous version's localization
and media**, which is the behaviour the UI's *"+ Version"* button has. All ten
`APP_IPHONE_67` images appeared on 1.1.3 immediately, `COMPLETE`, and every one
has a **`sourceFileChecksum` identical to 1.1.2's** — the same files Apple
approved and the store serves today.

🔴 **Nothing was uploaded, deliberately.** `fastlane/screenshots` is empty and
gitignored on purpose, so any lane that "uploads screenshots" replaces the live
set with nothing. Screenshots only ever reach Apple through
`.github/workflows/upload-screenshots.yml`, which takes the artifact of a
screenshot run a human has already approved.

Before creating the version, all ten were pulled down at full resolution
(1320×2868) from their `imageAsset.templateUrl` as insurance against the copy
not happening. It happened; they were not needed. ⚠️ That download needs `curl`,
not `urllib` — `urllib` fails SSL verification on this Mac, a trap already in
the lessons file.

⚠️ **Not a blocker, but worth knowing:** screenshot 10's caption reads *"Explore
3,500 tours in 530 cities across 67 countries"*. The catalogue now holds 1,582
tours plus 3,083 link pins across 704 cities and 89 countries, so the caption
understates the map. It is the approved set and was left alone; refreshing it is
a screenshot run plus `upload-screenshots.yml`, not something to do inside a
submission.

## In-app purchases: correctly not attached

Fourteen tier products exist. **Three are `APPROVED`; eleven are
`READY_TO_SUBMIT`** — and that is their intended resting state, not a backlog:
`docs/paid-tours-design.md` records them as *"left deliberately undone until
go-live"*, and 1.1.2 shipped the same way.

The App Review notes that carried forward to 1.1.3 already say so to the
reviewer, which settles it from Apple's side too:

> *"The other tier products are price points for our creator-set pricing model;
> none is attached to a published tour yet, so they are not part of this
> submission and will be submitted as they come into use."*

Nothing is new or changed for 1.1.3, so no `inAppPurchaseV2` review-submission
item was added.

## Everything else on the version page

| | |
|---|---|
| Release | **MANUAL** — approval does **not** put it on the store |
| Phased release | **ON**, `INACTIVE` until released, then 7 days |
| Export compliance | build reports `usesNonExemptEncryption: false`, from `ITSAppUsesNonExemptEncryption=NO` in `Info.plist` — nothing to answer |
| IDFA | `usesIdfa` null, exactly as 1.1.2 |
| Description / keywords / URLs | copied from 1.1.2 unchanged |
| App Review contact + demo account | copied from 1.1.2 unchanged (`appreview@dozent.app`) |

## What's New — and why the repo already held it

The text submitted is `fastlane/metadata/en-US/release_notes.txt`
**byte-for-byte**, diffed against the owner's own copy before it was sent.

That file only became correct hours earlier, in [#1028](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1028). Until then it still held
1.1.2's *"Filters, rebuilt"* copy word for word — an update describing the
previous update, silent on semantic search, More like this, the saved-tours rail,
map clustering and delta sync. Had the release lane been run, `force: true` would
have pushed that to Apple with no prompt.

## What is owed next

1. **Owner — press *Release this version*** when Apple approves. Manual release
   means it sits and waits. Tracked at `status/owner/release-1-1-3-when-approved.md`.
2. **A session — bump `MARKETING_VERSION` 1.1.3 → 1.1.4**, its own PR, **after**
   it goes live. A released version's upload train closes and the next TestFlight
   upload is refused with 90186 *Invalid Pre-Release Train*. Build 173 was
   rejected exactly this way three days ago.
3. **Minor, pre-existing:** the test and UI-test targets carry stray
   `MARKETING_VERSION = 1.0` alongside the app target's 1.1.3. They do not ship.

## Checking this rather than believing it

The released version needs no key:

```bash
curl -s "https://itunes.apple.com/lookup?bundleId=com.ehky.TRAVEL-GUIDED-TOUR&country=us"
```

⚠️ It **lags App Store Connect by hours**, so on release day it will still say
1.1.2 while ASC says otherwise. Anything about the unreleased version or its
review state needs the ASC key and `scripts/session-start.sh` — a web session has
no key and must say it could not check rather than quoting this file.
