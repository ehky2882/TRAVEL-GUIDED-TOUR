# Releasing Atlas with fastlane

This is the reference. If you just want to get the app onto the App Store,
read **[docs/launch-runbook.md](launch-runbook.md)** instead — it is a numbered
walkthrough. This file explains how the machinery works and why it is built the
way it is.

## The idea in one paragraph

Everything about releasing the app — building it, signing it, the App Store
description, the screenshots, the submission itself — is now **files in this
repository** rather than steps someone remembers to do in a browser. Each piece
of the process is a named job called a *lane*. The same lane runs identically on
a Mac and on a cloud machine, so a release stops depending on who ran it, from
which computer, in what order.

## The lanes

| Lane | What it does | Talks to Apple? |
|---|---|---|
| `beta` | Builds, signs, uploads to **TestFlight**, and writes the build notes into "What to Test". | Yes — uploads |
| `screenshots` | Opens the app in each required device size and photographs each screen. | **No** |
| `metadata` | Pushes the App Store text: description, keywords, subtitle, URLs. | Yes |
| `upload_screenshots` | Sends the reviewed screenshots to App Store Connect. | Yes |
| `release` | **The real submission.** Builds, uploads everything, submits for review. | Yes |
| `test` | Runs the unit tests in a simulator. | No |
| `certificates` | Signing identities via `match`. **Not wired into anything yet** — see below. | Yes |

Run one with `bundle exec fastlane <lane>`, e.g. `bundle exec fastlane beta`.

## How you actually trigger these

You do not need a Mac or a terminal. Each lane has a button in **GitHub →
Actions**:

| Workflow | Lane it runs | Notes |
|---|---|---|
| **TestFlight build** | `beta` | Also runs automatically when you add the `build` label to a pull request. |
| **App Store screenshots** | `screenshots` | Attaches the images to the run for you to download. Uploads nothing. |
| **App Store release** | `release` | Requires typing `RELEASE` to confirm, and refuses to run from any branch but `main`. |

## Credentials

Everything authenticates with an **App Store Connect API key** — never an Apple
ID and password. Three GitHub secrets carry it, and they are already set up:

| Secret | What it is |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | The key's ID, about 10 characters |
| `APP_STORE_CONNECT_ISSUER_ID` | A long UUID, shown at the top of the Keys page |
| `APP_STORE_CONNECT_API_KEY` | The entire contents of the downloaded `AuthKey_XXXX.p8` |

The `.p8` file itself is never committed — `*.p8` is in `.gitignore`, and the
lane writes it to `~/private_keys/` at run time with owner-only permissions.

> A key pasted through a web form often arrives with literal `\n` instead of
> real line breaks, which fails to parse in a baffling way. Both the Fastfile
> and the certificate script normalise this, so it is handled.

## Screenshots

`fastlane screenshots` builds the app, launches it in each simulator listed in
`fastlane/Snapfile`, and runs `ScreenshotUITests.swift`, which walks through the
app calling `snapshot("...")` at each screen worth showing.

**Why the test declines the location permission.** It sounds backwards, but with
no location fix the map falls back to a fixed New York region — the densest part
of the catalogue, and identical on every run and every machine. Allowing
location would frame the map on wherever the simulator thinks it is that day,
and your screenshots would drift.

**When the UI moves, screenshots break.** This is the unavoidable cost of
automating them: the test finds things on screen by their labels, so renaming a
button can lose a screenshot. The test is written defensively — a step it cannot
complete is skipped and logged rather than failing the whole run — so you get a
partial set plus a log line naming what it could not find:

```
SCREENSHOT SKIPPED: could not reach the player.
```

Fix that by updating the matching helper in `ScreenshotUITests.swift`.

**Changing which devices are captured.** Edit `devices` in `fastlane/Snapfile`.
Those are simulator *names* and they change between Xcode versions; if a run
fails with "No simulator found", list what the machine really has:

```bash
xcrun simctl list devicetypes
```

## Metadata

Your App Store page lives in `fastlane/metadata/`. One file per field:

| File | Field | Limit |
|---|---|---|
| `en-US/name.txt` | App name | 30 |
| `en-US/subtitle.txt` | Subtitle under the name | 30 |
| `en-US/description.txt` | The main description | 4000 |
| `en-US/keywords.txt` | Search keywords, comma-separated | 100 |
| `en-US/promotional_text.txt` | Editable **without** a review | 170 |
| `en-US/release_notes.txt` | "What's New" — **absent on purpose until v1.1**, see below | 4000 |
| `en-US/support_url.txt`, `privacy_url.txt` | Links | — |
| `review_information/` | What Apple's reviewer needs | — |
| `primary_category.txt`, `secondary_category.txt` | Categories | — |

Editing your store page is now a pull request you can read, rather than a form
someone typed into once.

> ⚠️ **An empty file clears the field.** If you do not want to manage a field,
> delete the file rather than blanking it.

### Two metadata traps already paid for

**"What's New" cannot be set on a first release.** Apple answers `409
STATE_ERROR — Attribute 'whatsNew' cannot be edited at this time`, because there
is no previous version for anything to be new against. This is why there is no
`release_notes.txt` in the repo yet: **add it at version 1.1**, not before.

**The version update is atomic.** All of description, keywords, promotional text
and support URL go up in a single request, so **one rejected field silently
takes the whole batch down with it**. That is exactly how the `whatsNew` error
above also blocked four perfectly valid fields. If a push reports anything other
than HTTP 200, assume **nothing** landed and read the error before retrying.

## Decisions and traps recorded here on purpose

**The app has two different names.** App Store Connect calls it *Atlas Audio
Tours*; the app installs on the home screen as *Dozent* (`CFBundleDisplayName`).
`name.txt` currently matches App Store Connect, so pushing metadata changes
nothing. **This needs a decision before launch** — users seeing one name on the
store and another under the icon is a genuine confusion, and the store name is
also what search ranks.

**Signing still uses the certificate-revocation workaround.** Every cloud build
machine mints a fresh Apple Development certificate, and they pile up until they
hit Apple's cap and archiving fails. `scripts/revoke-dev-certs.py` clears them
before each build. The proper fix is `match` (the `certificates` lane), which
keeps one shared set of identities in a private repo — but `match` uses **manual**
signing, and forcing manual signing on this project has already failed once
("conflicting provisioning settings"). Migrating is real work and belongs
**after** launch. Do not wire it in to "tidy up" before shipping.

**In-app purchases cannot be submitted by fastlane.** The paid-tour products
must be attached to the first submission by hand in App Store Connect. Apple
requires the first non-consumable purchase to be reviewed alongside a new app
version.

**The App Privacy questionnaire is manual too.** Apple's privacy "nutrition
label" is filled in through App Store Connect and there is no supported way to
automate it.

**Release is phased and not automatic.** `release` submits for review but does
not publish. When Apple approves, you press the button yourself, and the rollout
is then spread over 7 days so a bad bug reaches a fraction of users.

## Running it on your own Mac

⚠️ **fastlane cannot be installed on a stock Mac, and this was confirmed the
hard way (2026-08-07).** macOS ships Ruby 2.6; the current gem tree needs newer.
Installing fails, and pinning older dependency versions just moves the error:

```
multi_json requires Ruby version >= 3.2. The current ruby version is 2.6.10.
domain_name requires Ruby version >= 2.7.0. The current ruby version is 2.6.10.
```

That is dependency whack-a-mole with no end. **Do not keep pinning gems.** There
are three real options:

1. **Use GitHub Actions** — fastlane is preinstalled there and the secrets
   already exist. This is the intended route and needs no setup.
2. **Install a newer Ruby** — needs Homebrew, which is not on this Mac and whose
   installer requires an admin password. Once done: `bundle install && bundle
   exec fastlane beta`.
3. **For metadata only**, use [`scripts/push-appstore-metadata.py`](../scripts/push-appstore-metadata.py)
   — pure Python, no Ruby, reads the same `fastlane/metadata/` files and makes
   the same REST calls `deliver` makes underneath, so the two cannot drift.

```bash
export APP_STORE_CONNECT_KEY_ID=...
export APP_STORE_CONNECT_ISSUER_ID=...
export APP_STORE_CONNECT_API_KEY_PATH=~/private_keys/AuthKey_XXXX.p8

python3 scripts/push-appstore-metadata.py           # dry run — prints a diff
python3 scripts/push-appstore-metadata.py --apply   # writes
```

## Files

| Path | Purpose |
|---|---|
| `Gemfile` | Pins fastlane so every machine runs the same version |
| `fastlane/Appfile` | Which app, which Apple team |
| `fastlane/Fastfile` | The lanes — the actual release logic |
| `fastlane/Snapfile` | Which devices and languages screenshots cover |
| `fastlane/metadata/` | Your App Store page, as text files |
| `fastlane/screenshots/` | Captured images (generated) |
| `scripts/revoke-dev-certs.py` | Keeps the account under Apple's certificate cap |
| `scripts/push-appstore-metadata.py` | Pushes metadata without Ruby, for when fastlane cannot run locally |
| `TRAVEL GUIDED TOURUITests/` | The UI test that takes the screenshots |
