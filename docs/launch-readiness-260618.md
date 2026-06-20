# Atlas — Public App Store Launch Readiness Audit

**Date:** 2026-06-18 · **Audited against:** `main` @ `5bf960d` · **Current TestFlight build:** 1.0 (46) · **Catalog:** 300 tours / 4 makers (100 NYC · 80 London · 66 Lisbon · 54 Porto)

> This is a read-only audit. No code, content, or config was changed. It answers one question: **"We have a working app on TestFlight with 300 tours. What actually remains before it can go live on the public App Store?"**

---

## Executive summary

Atlas is **functionally a finished V1 app** — 300 tours stream over a live remote catalog, the player and home map are polished, and 95/95 tests pass. But "works on TestFlight" and "approvable on the public Store" are different bars, and the gap is **not in the code — it's in the unglamorous launch-packaging work that has been deferred the entire project**: there is **no real app icon** (still the placeholder green sphere), **no screenshots** (none exist, at any size), and **no public Store listing copy** (name, subtitle, description, keywords, support URL). None of these block a TestFlight build, which is exactly why they've never been forced — but the public Store **will reject the submission without all three.** On top of that, the app's signature feature (multi-stop walking tours) has **never been validated on-device** and only 2 of 300 tours exercise it.

Realistically you are **days, not weeks, of focused non-engineering work** from a *submittable* build — but the design pass the owner keeps deferring is the difference between "submittable" and "something you'd want reviewers and first users to see." None of the blockers are hard; they've just never been anyone's job until now.

### Top 3 blockers (these alone stop a submission today)

1. **🔴 App icon is still the placeholder green sphere.** Only the 1024px light slot is filled — with the green sphere. Apple rejects placeholder/default icons on the public Store (TestFlight tolerates them). A real, finished icon is non-negotiable and gates the design pass.
2. **🔴 Zero screenshots exist.** The Store listing cannot be submitted without at least 6.9" iPhone screenshots, and because Atlas ships the iPad device family, **iPad 13" screenshots are also required.** Nothing — no assets, no plan, no fastlane scaffold — exists in the repo today.
3. **🔴 No public listing metadata drafted.** Description, subtitle, keywords, promotional text, support URL, and category are all unstarted. (The App Store Connect *record* and the privacy nutrition label exist from the TestFlight setup — but the public "Prepare for Submission" listing fields are a separate, empty form.)

---

## 🔴 Must-have for submission — App Store **will reject** without these

### 1. Real app icon — **NOT DONE (placeholder)**
- **Current state:** `Assets.xcassets/AppIcon.appiconset/` contains exactly one image — `atlas-icon-1024.png`, which is the **placeholder green sphere on black**. The `Contents.json` declares a dark-appearance slot and a tinted slot, but **both are empty (no filename assigned)**, and all 12 macOS icon slots are empty too. So the only thing that renders is the green sphere, on light, dark, and tinted home screens alike.
- **What's needed:** A finished 1024×1024 icon (light), and ideally the iOS 18+ **dark** and **tinted** variants filled in (light is mandatory; dark/tinted are strongly recommended for a polished launch but not a hard reject). This is the visual front door of the app and is **part of the design pass** (§ Should-have item 1).
- **Verdict:** Hard blocker. Cannot submit.

### 2. Screenshots — **NOT DONE (none exist)**
- **Current state:** No screenshot assets, no fastlane/metadata folder, no screenshot plan anywhere in the repo.
- **What's needed (minimum set for this app's device family `iPhone, iPad, Vision`):**
  - **6.9" iPhone** (e.g. iPhone 16 Pro Max / 17 Pro Max) — **required.** 1–10 images.
  - **iPad 13"** — **required, because the app ships the iPad device family.** If you don't want to produce iPad screenshots, the alternative is to drop iPad from `TARGETED_DEVICE_FAMILY` (currently `1,2,7`) — a code/project change and a product decision, not a doc task.
  - 6.5"/6.7" iPhone is now auto-scaled from 6.9", so a single iPhone set usually suffices.
  - **Apple Vision:** only required if you actually submit a visionOS app — see § Should-have item 5 (device-family decision).
- **Note:** These are easy to generate from the simulator (the catalog is live, the home map + player are photogenic), but they have to be *captured, framed, and uploaded* — budget real time for it.
- **Verdict:** Hard blocker. Cannot submit.

### 3. Public Store listing metadata — **MOSTLY NOT DONE**
The App Store Connect *app record* already exists (created for TestFlight, 2026-05-19), but the **public listing fields** are a separate form and there is no evidence any of it is drafted:
| Field | Required? | Evidence in repo | Status |
|---|---|---|---|
| App name | ✅ | "Atlas" used throughout; bundle name is the Xcode target name | Needs final decision + uniqueness check on the Store |
| Subtitle (30 char) | ✅ | none | **Unstarted** |
| Description | ✅ | none drafted | **Unstarted** |
| Keywords (100 char) | ✅ | none | **Unstarted** |
| Promotional text | optional | none | Unstarted |
| Support URL | ✅ | none found (no support page) | **Unstarted — needs a hosted page** |
| Marketing URL | optional | none | Unstarted |
| Primary/secondary category | ✅ | not chosen (likely *Travel*) | **Needs selection** |
| Age rating questionnaire | ✅ | done for TestFlight (carries over) | Likely complete — **verify** |
| App Privacy nutrition label | ✅ | done for TestFlight (per ROADMAP) | Likely complete — **verify** (see Privacy below) |
- **What's needed:** Draft the subtitle/description/keywords (Claude can write these), choose a category, and **stand up a Support URL** — the privacy page already lives on gh-pages, so a sibling `/support/` page is the cheap path. Verify the age-rating and privacy answers in ASC.
- **Verdict:** Hard blocker (description, keywords, support URL, category specifically).

### 4. Privacy — **MOSTLY DONE, verify the questionnaire**
- **`Info.plist` usage strings — present and App-Store-quality:**
  - `NSLocationWhenInUseUsageDescription`: *"Atlas uses your location to surface audio tours near you and trigger stop-by-stop audio when you arrive at a stop."* ✅
  - `NSLocationAlwaysAndWhenInUseUsageDescription`: *"Atlas uses your location while the app is in the background so tour stops can trigger automatically as you walk between them."* ✅ (Background-location + the `UIBackgroundModes=audio` entitlement are well-justified by the geofenced-audio feature — but expect App Review to look closely at background location; the strings defend it well.)
  - These are specific and benefit-framed — reviewer-ready.
- **Privacy policy:** Live and reachable — `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/privacy/` returns **HTTP 200**. ✅
- **`ITSAppUsesNonExemptEncryption`:** Set to `NO` in both `Info.plist` and the build setting (`INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`). ✅ Avoids the export-compliance prompt on every upload.
- **App Privacy nutrition label (in ASC):** Reportedly completed during TestFlight setup. **Verify it states the truth for V1:** Location is collected/used (for app functionality, not tracking), and — because V1 has no backend/auth/analytics — **nothing else is collected and there is no tracking.** This is a clean, easy label, but it must be confirmed in ASC before submission.
- **Verdict:** In good shape. The only open item is *verifying* (not creating) the ASC questionnaire answers.

---

## 🟡 Should-have before public launch — quality & risk

### 1. The deferred design pass — **the single biggest pre-launch effort**
This has been explicitly deferred since day one (ROADMAP principle #1: "Functionality first; design and tone deferred"). For a public 1.0 it is not an Apple *reject* trigger (except the icon, which is), but in the **owner's own framing** it is the gate between "ship to TestFlight" and "ship to the world." What it entails:
- **App icon** (also the §Must-have #1 blocker) — replace the green sphere with a real Atlas mark.
- **Color palette** — `Theme/AtlasColors.swift` tokens are placeholders: `placeholderWarm`/`placeholderCool` resolve to system `.tertiarySystemFill`/gray, and the accent (`AccentColor.colorset`) is the placeholder terracotta `#B85042`. Every surface currently borrows system fills.
- **Typography** — `Theme/AtlasTypography.swift` is explicitly placeholder (SF Pro / SF Mono stand-ins "until the design pass picks a paired type system").
- **Custom map pins** — currently generic `StopPin` circles; a branded pin is part of the pass.
- **Editorial copy pass** — tour descriptions + maker bios review (`M-polish-copy`), an editorial-tone sweep, owner/content-team work.
- **Splash screen** — noted bare-bones (`P3-6`), deferred with this pass.
- **Decision needed from the owner:** Is a 1.0 with placeholder tokens (but a real icon) acceptable to ship, or is the full design pass a personal launch blocker? Apple will accept the placeholder-token app *if the icon is real*; the owner's quality bar is the real gate here. **Recommendation:** do the icon now (required anyway), ship V1 on the current functional-but-placeholder theme, and treat the full palette/type/pin pass as a fast-follow 1.1 — unless the owner wants to hold the launch for it.

### 2. Multi-stop functional QA (`M-qa`) — **OPEN**
- The on-device M-qa pass passed every *single-stop* check (build 1.0 (5), 2026-05-22), but the **multi-stop steps — geofenced stop advancement and manual next-stop — have never been validated on-device**, because for most of the project no multi-stop tour existed.
- **Multi-stop content is thin:** only **2 of 300 tours** are multi-stop — *AMNH: Four Facades* (5 stops) and *Fifth Avenue Walk* (6 stops). 5 more London multi-stops are drafted but **not shipped**.
- **Risk:** The walking-tour geofence trigger is the app's *defining* feature and the part most likely to misbehave in the field (GPS drift, background wake, stop-to-stop hand-off). Shipping it publicly without a real on-the-ground walk-through of at least one multi-stop tour is the biggest *functional* risk to a confident launch.
- **What remains:** Walk AMNH Four Facades (and ideally Fifth Avenue Walk) on a real device, confirm each stop's audio auto-triggers on arrival and manual next-stop works, then sign off M-qa.

### 3. Real-device checks still pending from recent UI work
Carried in HANDOFFs as "needs a real-device check" (simulator can't exercise them):
- Player **drag-to-dismiss** feel, **volume slider**, and **AirPlay** button (MPVolumeView is device-only / sim can't drag).
- The "no Atlas tours here yet" map hint timing on a cold far-region pan.
- Compass visibility after a ⌥-drag rotate.
These are low-risk polish confirmations but worth clearing in the same device session as M-qa.

### 4. iOS 26.2 deployment-target reality check
- `IPHONEOS_DEPLOYMENT_TARGET = 26.2` means the app **only installs on iOS 26.2+.** That's a very narrow install base for a public launch (most users won't be on 26.2 for a while). This may be intentional (the app uses iOS-26 APIs), but it sharply limits the addressable audience on day one. **Owner decision:** is 26.2-only acceptable for the public launch, or should the minimum be lowered? Lowering it is an engineering task (back-compat work), not a doc task — flagging it so it's a conscious choice, not an accident.

### 5. visionOS device-family decision
- `TARGETED_DEVICE_FAMILY = 7` (Vision) is set alongside iPhone+iPad. This means the project is configured to build a **native visionOS app** — which, if submitted, is a **separate App Store product with its own screenshots, its own review, and its own QA**, none of which exist or have been done.
- **Recommendation:** For a focused iPhone/iPad launch, **do not ship the visionOS native app in V1** — either submit only the iOS app (leave Vision unsubmitted) or drop family `7` so there's no ambiguity. Shipping an unreviewed, unscreenshotted visionOS build is an unnecessary surface. (Users on Vision can still run the iPad app via "Designed for iPad" without a native target.)

---

## 🟢 Nice-to-have / post-launch — safely deferrable

- **TestFlight upload automation (ASC API key).** Uploads are still manual via Organizer (`todo-testflight-upload-automation`). A convenience, not a launch gate. ~5-min API-key setup whenever the owner wants it.
- **`MKMapItem.placemark` iOS-26 deprecation warning** in `PlaceSearchService.swift:139`. One compiler warning, intentionally retained (the replacement API shape was uncertain). Cosmetic; fix during the next Search pass. *(This is the only known deprecation; a grep of the Swift source found **no `TODO`/`FIXME`/`HACK`** debt — the "placeholder" hits are all intentional design-token names and UI placeholder fills, not unfinished work. Code health is clean.)*
- **Categories-vs-tags refactor (`M-rethink-categories`).** Owner-endorsed direction, deferred so content could ship. Post-launch.
- **More multi-stop content** (ship the 5 drafted London walks) — grows the catalog's signature feature, but additive and ships over the live remote catalog without a build.
- **Release notes / "What's New" copy** for the public version — trivial to write at submission time.
- **Phased release** (Apple's 7-day staged rollout) — recommended to *enable* at submission, but a one-click ASC toggle, not prep work.

---

## Build / release mechanics — current state

- **`MARKETING_VERSION = 1.0`**, `CURRENT_PROJECT_VERSION = 46`. 1.0 is the right public version number — no change needed. The next archive you submit to the Store can be the same 1.0 (47) lineage.
- **Catalog ships independently of builds** (PR #209 + #212): `Tours.json` auto-publishes to gh-pages on merge-to-main, and the app fetches it live. So **content fixes no longer require an App Store review** — a real advantage for a content-heavy app post-launch.
- **Upload is manual** (Organizer → Distribute → Upload). Note the known gotcha: the **Program License Agreement must be current** or the upload throws a misleading "No iOS Distribution certificate" error (see `reference-testflight-pla-gotcha`).
- **No phased rollout or release notes configured yet** — both are submission-time ASC settings, not repo work.

---

## Suggested sequence — today → submitted

1. **Decide scope** (owner, 30 min): (a) ship on placeholder theme with a real icon, or hold for the full design pass? (b) iPhone+iPad only — drop/ignore visionOS? (c) is iOS 26.2-only minimum acceptable? These three answers shape everything below.
2. **App icon** (design — the long pole): produce the finished 1024 icon (+ dark/tinted if doing them). This is required no matter what scope is chosen.
3. **On-device M-qa** (owner + device, ~half a day): walk AMNH Four Facades + Fifth Avenue Walk, confirm geofenced stop advancement and manual next-stop; clear the pending player/volume/AirPlay device checks in the same session.
4. **Screenshots** (~half a day): capture 6.9" iPhone + iPad 13" sets from the simulator against the live 300-tour catalog; frame and stage them.
5. **Listing copy** (Claude can draft, owner approves): subtitle, description, keywords, promotional text, category; stand up a **Support URL** page on gh-pages (sibling to `/privacy/`).
6. **Verify privacy + age rating** answers in App Store Connect; confirm the nutrition label reflects "location for functionality, no tracking, nothing else collected."
7. **Archive build 1.0 (next) with the real icon**, upload, attach screenshots + metadata, set phased release, **submit for review.**
8. *(Optional fast-follow 1.1):* full design pass (palette, typography, map pins, splash), editorial copy sweep, ship the 5 drafted London multi-stops.

**Bottom line:** the engineering is done; what's left is **icon + screenshots + listing copy + one real-world multi-stop walk.** None of it is hard — it has simply never been required until you point the app at the public Store.
