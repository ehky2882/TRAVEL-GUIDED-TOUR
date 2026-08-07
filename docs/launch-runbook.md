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
- The App Store description, keywords and subtitle are written and live in
  `fastlane/metadata/`.
- Screenshots can be captured automatically.
- The release submission is one button with a safety catch on it.

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

### Step 2 — Decide the app's name

**Who:** you.

Right now the app has **two different names**:

| Where | Name |
|---|---|
| App Store Connect | Atlas Audio Tours |
| On the home screen under the icon | Dozent |

A customer would find you under one name and then have a different word on their
phone. It also splits your search ranking. Pick one:

- **Use "Atlas"** — matches the store listing, the docs, the studio names
  ("Atlas Studio NYC"), and the in-app branding. Claude changes
  `CFBundleDisplayName` to match.
- **Use "Dozent"** — Claude updates `fastlane/metadata/en-US/name.txt` and the
  store record instead.

**Tell Claude which**, and it will make the two agree.

### Step 3 — Decide the version number

**Who:** you.

The app is currently version **1.1**, because the old TestFlight builds used up
1.0. A first public release labelled 1.1 is allowed, but reads oddly as a debut.

- **Reset to 1.0** — cleaner for a launch. Claude changes `MARKETING_VERSION`.
- **Stay on 1.1** — no work, slightly odd.

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

### Step 6 — Complete tax and banking *(only if you are launching paid tours)*

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

---

## Phase E — The listing

### Step 10 — Read the store text

**Who:** you.

Open [`fastlane/metadata/en-US/description.txt`](../fastlane/metadata/en-US/description.txt)
and read it as a stranger would. Also worth a look:

| File | What it is |
|---|---|
| `subtitle.txt` | The line under the app name |
| `keywords.txt` | What people can find you by searching |
| `release_notes.txt` | "What's New" |

Edit freely, or tell Claude what to change. It is just text.

### Step 11 — Push the listing to Apple

**Who:** Claude.

This fills in your App Store page without submitting anything for review. Safe
and reversible.

### Step 12 — Add the reviewer contact details

**Who:** you.

Apple needs a phone number for the review contact, which is not in the repo.
Give it to Claude and it will add it.

---

## Phase F — In-app purchases *(skip if launching free-only)*

### Step 13 — Attach the purchases to this submission

**Who:** you, hand-held by Claude.

The ten paid-tour products already exist in App Store Connect but sit in
*Prepare for Submission*. **Apple requires the first non-consumable purchase to
be reviewed alongside a new app version**, and fastlane cannot attach them — it
must be done by hand.

Each product also needs a **review screenshot** showing where it appears in the
app.

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
- [ ] App Privacy is complete (Step 4)
- [ ] Age rating and pricing set (Step 5)
- [ ] Tax and banking cleared, *if launching paid tours* (Step 6)
- [ ] You have personally looked at every screenshot (Step 8)
- [ ] You have personally read the description (Step 10)
- [ ] Reviewer phone number added (Step 12)
- [ ] In-app purchases attached, *if launching paid tours* (Step 13)
- [ ] You have installed the current TestFlight build and used it today

### Step 15 — Submit

**Who:** Claude, on your explicit go-ahead.

GitHub → **Actions** → **App Store release** → **Run workflow**, typing
`RELEASE` in the confirmation box. It refuses to run from any branch but `main`,
and refuses to run at all if the confirmation does not match exactly.

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
