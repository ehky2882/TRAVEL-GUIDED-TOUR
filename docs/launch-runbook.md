# Launch runbook — getting Atlas onto the App Store

A numbered walkthrough from where the project is today to the app being live.
Do the steps in order. Each one says **who** does it and **how you know it
worked**. Do not skip ahead — several steps depend on the one before.

If you want to understand how the machinery works rather than just use it, read
[docs/fastlane.md](fastlane.md).

**Rough timing:** the work below is a few hours spread over several days, most
of it waiting for Apple. Review itself is usually 24–48 hours.

---

## Before you start

**What is already true:**

- The app builds, signs and uploads itself to TestFlight from a button in GitHub.
- **The App Store listing is already updated and live** (pushed 2026-08-07):
  description, keywords, subtitle, promotional text and support URL all match
  `fastlane/metadata/`. Steps 10–11 below are done.
- App Store Connect already holds an editable version record in *Prepare for
  Submission* — **1.1**, matching the project, as of 2026-08-18 (see Step 3).
  The app's name at Apple is **Dozent**.
- Screenshots can be captured automatically.
- The release submission is one button with a safety catch on it.

⚠️ **fastlane cannot run on this Mac** — macOS ships Ruby 2.6 and the current
gem tree needs newer. Lanes run in GitHub Actions instead; metadata can also be
pushed locally with `scripts/push-appstore-metadata.py`, which needs no Ruby.
See [docs/fastlane.md](fastlane.md).

**What is not done yet, and why it needs you:**

- Two decisions only you can make (Steps 2 and 3).
- Some App Store Connect forms Apple does not allow any tool to fill in.
- Nobody has looked at the screenshots yet, because they have not been taken.

---

## Phase A — Prove the plumbing

### Step 1 — Cut one TestFlight build the new way

**Who:** Claude, on your say-so.
**Why first:** the build path was just rewritten to use fastlane. Before
trusting it with a real submission, prove it still produces the same TestFlight
build you have been installing for months.

GitHub → **Actions** → **TestFlight build** → **Run workflow**, on `main`, with
build notes describing it as a plumbing test.

**You know it worked when:** the build appears in TestFlight on your phone as
usual, and tapping it shows your notes under *What to Test*.

**If it fails:** stop here and fix it. Everything downstream uses the same build
path, so a problem now is much cheaper than a problem during submission.

---

## Phase B — Two decisions

### Step 2 — Decide the app's name ✅ *decided 2026-08-07: **Dozent***

**Owner decision:** the app is called **Dozent**, consistently, everywhere.

Applied to all of it:

| Where | Now |
|---|---|
| App Store Connect app name | Dozent |
| Home screen under the icon (`CFBundleDisplayName`) | Dozent |
| Store description and review notes | Dozent |
| **Location + microphone permission dialogs** | Dozent |

That last row is easy to miss and users see it at first launch — the strings
lived in both `Info.plist` and the Xcode project and both said "Atlas".

⚠️ **Still called Atlas, deliberately, and NOT covered by this decision:** the 24
in-app creator studios (*Atlas Studio NYC*, *Atlas Studio LDN*, …) in
`Tours.json`. Renaming those is a content and backend job, not an app-name
change — the studio IDs are derived from strings like `atlas-maker:nyc`, they
exist as rows in Supabase, and every tour references them. **If you want the
studios renamed too, say so and it gets scoped separately.**

A customer would find you under one name and then have a different word on their
phone. It also splits your search ranking. Pick one:

- **Use "Atlas"** — matches the store listing, the docs, the studio names
  ("Atlas Studio NYC"), and the in-app branding. Claude changes
  `CFBundleDisplayName` to match.
- **Use "Dozent"** — Claude updates `fastlane/metadata/en-US/name.txt` and the
  store record instead.

**Tell Claude which**, and it will make the two agree.

### Step 2b — iPad and monetisation ✅ *decided 2026-08-07*

**iPad is dropped from the app entirely.** `TARGETED_DEVICE_FAMILY` went from
`"1,2,7"` to `"1,7"` — iPhone and Apple Vision Pro. The store description no
longer claims iPad either.

⚠️ **Consequence:** iPad owners can no longer install Dozent, including anyone
already running it from TestFlight on an iPad. Reversible by restoring the `2`,
but anyone who lost the app has to reinstall.

**Creator studios keep the Atlas name** — *Atlas Studio NYC* and the other 23
stay as they are. They appear in the screenshots and in the app; that is
accepted, and is a deliberate separation between the app's name and the
publisher names inside it.

**The app launches free, with paid tours as in-app purchases.** That means
Steps 6 and 13 below are **in scope, not optional** — Apple will not review an
in-app purchase until the tax and banking agreements are cleared.

### Step 3 — Decide the version number ✅ *decided 2026-08-07: **1.1***

**Owner decision:** stay on **1.1**. The odd-looking debut number is accepted.

App Store Connect's editable version record was renamed 1.0 → **1.1** so it
matches the Xcode project, which means all the listing copy stayed attached to
it. No new version record was needed and nothing had to be re-pushed.

---

## Phase C — App Store Connect groundwork

These are Apple's own forms. No tool is permitted to fill them in — they must be
done by the account holder in a browser.

### Step 4 — Fill in App Privacy

**Who:** you, with Claude reading the answers out.

App Store Connect → your app → **App Privacy**. Apple asks what data the app
collects. **Your submission cannot proceed until this is complete.**

Ask Claude to walk you through it question by question — it knows what the app
actually collects (location, account email, saved tours) and what it does not.

**You know it worked when:** the App Privacy section shows a green tick rather
than "Get Started".

### Step 5 — Set the age rating and pricing

**Who:** you.

Same screen area: the age-rating questionnaire, and price (the app itself is
free — paid tours are separate in-app purchases).

### Step 6 — Complete tax and banking ⚠️ *required — start this first*

**Who:** you.

App Store Connect → **Business** → agreements, tax forms, bank details.

⚠️ **This is the slowest step in the whole runbook.** Apple's tax forms can take
days to clear, and **no in-app purchase can be reviewed until they have.** If
paid tours are part of your launch, start this now, in parallel with everything
else. If you are launching free-only, skip it.

---

## Phase D — Screenshots

### Step 7 — Capture them

**Who:** Claude.

GitHub → **Actions** → **App Store screenshots** → **Run workflow**.

This opens the app in each device size Apple requires and photographs each
screen. It takes roughly half an hour and **sends nothing to Apple**.

**You know it worked when:** the finished run has an *Artifacts* section
containing `app-store-screenshots`.

### Step 8 — Look at them properly

**Who:** you. This step is not optional.

Download the artifact and open the images. Screenshots are the single most
visible thing on your App Store page — most people decide from them alone.

Ask yourself:

- Is the map showing an interesting, full part of the catalogue, or an empty
  patch of sea?
- Is any screen caught mid-animation, half-drawn, or mid-scroll?
- Would someone who has never heard of Atlas understand what it does?

**If a screenshot is missing**, the run's log contains a line starting
`SCREENSHOT SKIPPED` naming the screen it could not reach. Tell Claude and it
will fix the walkthrough and re-run.

**If a screenshot is ugly rather than missing**, say what is wrong with it. The
route through the app is code and can be changed.

### Step 9 — Upload the approved screenshots

**Who:** Claude, once you have said they are good.

GitHub → **Actions** → **Upload screenshots to App Store Connect** → **Run
workflow**, giving it the run ID of the screenshot run you approved. It sends
those exact images and **submits nothing for review**.

⚠️ **A green run is not proof.** On 2026-08-17 the upload reported
"Successfully uploaded all screenshots" and left the listing holding **ten**
images, four of them duplicates: Apple had not finished processing the first
upload when fastlane re-checked, so it re-sent the four it thought were
missing. Claude must query App Store Connect afterwards and confirm the exact
set — see § "App Store screenshots" in `CLAUDE.md` for how.

---

## Phase E — The listing

### Step 10 — Read the store text ✅ *pushed 2026-08-07, but still read it*

**Who:** you.

The listing has already been updated — the previous copy was inaccurate (it
described a New-York-only early-access catalogue, and claimed *"Nothing leaves
your phone"*, which stopped being true when accounts and sync shipped). What is
live now is exactly what is in `fastlane/metadata/`.

Open [`fastlane/metadata/en-US/description.txt`](../fastlane/metadata/en-US/description.txt)
and read it as a stranger would. Also worth a look:

| File | What it is |
|---|---|
| `subtitle.txt` | The line under the app name |
| `keywords.txt` | What people can find you by searching |
| `release_notes.txt` | "What's New" |

Edit freely, or tell Claude what to change. It is just text.

### Step 11 — Push the listing to Apple ✅ *done 2026-08-07*

**Who:** Claude.

Fills in your App Store page without submitting anything for review. Safe and
reversible; the previous listing is backed up.

To push again after editing any file in `fastlane/metadata/`:

```bash
python3 scripts/push-appstore-metadata.py           # shows a diff, sends nothing
python3 scripts/push-appstore-metadata.py --apply   # writes
```

⚠️ **Do not add `release_notes.txt` yet.** Apple refuses "What's New" on a first
release, and because the update is atomic that one rejected field takes the
description and keywords down with it. Add it at version 1.1.

### Step 12 — Add the reviewer contact details

**Who:** you, directly in App Store Connect.

🔴 **Do NOT put the phone number in this repo. This repository is PUBLIC**
(`gh api repos/… --jq .private` → `false`, and an unauthenticated fetch
succeeds). Committing a personal phone number would publish it to the open
internet permanently — a later deletion does not remove it from git history.

**Owner decision, 2026-08-16:** the reviewer phone number is entered **by hand in
App Store Connect** and deliberately kept out of the repo. A session offered to
commit it, caught that the repo was public, and stopped before pushing.

**Where to put it:** App Store Connect → the app → the version (1.1) → **App
Review Information** → *Contact Information* → phone field → Save.

`fastlane/metadata/review_information/` therefore has **no `phone_number.txt`,
and that absence is intentional** — do not "fix" it. `upload_to_app_store` only
sends fields it has files for, so the value you type in App Store Connect is
left alone by the metadata and release lanes.

ℹ️ `email_address.txt` **is** in the repo, and that is not worth undoing: the
same address is the author on all 631 commits, so it is already public by the
nature of git. Removing the file would stop the metadata push re-asserting it
but would not un-publish it.

⚠️ **Why the repo cannot simply be made private:** `gh-pages` in this same
repository serves every tour's audio and images to the live app. GitHub Pages on
a private repo requires a paid plan, so flipping visibility would break content
delivery for the whole catalogue until that is resolved.

---

## Phase F — In-app purchases ⚠️ *required*

### Step 13 — Attach the purchases to this submission

**Who:** you, hand-held by Claude.

The ten paid-tour products exist in App Store Connect, but **all ten are
currently in state `MISSING_METADATA`** (verified 2026-08-07):

```
tour.tier.099 · 199 · 299 · 399 · 499 · 699 · 899 · 999 · 1499 · 1999
```

That means none of them can be submitted yet. Each needs a **display name**, a
**description**, and a **review screenshot** showing where it appears in the
app. **Apple requires the first non-consumable purchase to be reviewed alongside
a new app version**, and fastlane cannot attach them — this is by hand.

⚠️ **A purchase Apple cannot test will be rejected.** Make sure at least one
tour is actually priced before submitting, or reviewers will find nothing to
buy. Ask Claude to set one.

---

## Phase G — Submit

### Step 14 — Final check

**Who:** you and Claude together.

Run down this list. Everything must be a yes:

- [ ] Step 1 produced a working TestFlight build
- [ ] The app name is consistent (Step 2)
- [ ] The project's version and the App Store version record agree (Step 3)
- [ ] App Privacy is complete (Step 4)
- [ ] Age rating and pricing set (Step 5)
- [ ] Tax and banking cleared (Step 6) — **required**
- [ ] You have personally looked at every screenshot (Step 8)
- [ ] You have personally read the description (Step 10)
- [ ] Reviewer phone number added (Step 12)
- [ ] In-app purchases attached (Step 13) — **required**
- [ ] You have installed the current TestFlight build and used it today

### Step 15 — Submit

**Who:** Claude, on your explicit go-ahead.

**Before you run it:** confirm the version page shows the screenshots you
approved, and only those. This lane **does not upload or repair screenshots** —
Step 9 is the only thing that puts them there. Whatever the listing holds at
this moment is what Apple sees.

GitHub → **Actions** → **App Store release** → **Run workflow**, typing
`RELEASE` in the confirmation box. It refuses to run from any branch but `main`,
and refuses to run at all if the confirmation does not match exactly.

⚠️ **This lane used to destroy the screenshots at the moment of submission.**
It passed `overwrite_screenshots: true` — "delete every screenshot on the
listing, then upload the ones in `fastlane/screenshots`" — against a directory
that is empty in a fresh CI checkout, because screenshots are gitignored on
purpose. The delete would have run; the upload would have had nothing to send.
Fixed on 2026-08-18: the lane now passes `skip_screenshots: true` and leaves
them alone. Do not reintroduce `overwrite_screenshots` here.

The **App Review contact details** are safe by contrast, and this was checked
rather than assumed: deliver only writes review-information fields it has a
non-empty value for, so the reviewer phone number you typed into App Store
Connect by hand survives this lane even though it is deliberately absent from
the repo (Step 12).

**You know it worked when:** App Store Connect shows the version as *Waiting for
Review*.

---

## Phase H — After submitting

### Step 16 — Wait

Usually 24–48 hours. Apple emails you either way.

### Step 17a — If approved

The version does **not** go live on its own. Open App Store Connect and press
*Release this version* when you are ready.

Release is **phased**: Apple rolls the update out over 7 days rather than to
everyone at once, so a serious bug reaches a fraction of users and you can pause
it. Leave phased release on.

### Step 17b — If rejected

Do not be alarmed — first submissions are rejected routinely, usually over
something small and fixable.

The reason arrives by email and in App Store Connect under **Resolution
Center**. Send it to Claude verbatim. Most rejections are one of:

- **Guideline 2.1 — incomplete information.** A reviewer could not work out how
  to test something. Usually fixed by improving the reviewer notes.
- **Guideline 5.1.1 — permission wording.** The explanation for location or
  microphone access was not specific enough.
- **In-app purchase problems.** Usually the tax forms are not cleared, or no
  product was actually purchasable.

Fix, then repeat from Step 15. Resubmissions are typically reviewed faster.

---

## Afterwards

Once you are live, worth doing but not urgent:

- **Retire the certificate workaround.** Every build currently revokes the
  account's development certificates to stay under Apple's cap. The proper fix
  is fastlane `match`. Deliberately left until after launch because it changes
  how signing works, and launch is the wrong time. See
  [docs/fastlane.md](fastlane.md).
- **Add more languages.** The listing is English only. A second language is a
  new folder under `fastlane/metadata/`.
