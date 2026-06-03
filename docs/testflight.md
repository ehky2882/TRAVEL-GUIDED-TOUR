# TestFlight upload — runbook

Step-by-step for uploading a new build of Atlas to TestFlight, so
internal testers (just the owner during V1) can install it on real
devices. This file is a **runbook**: read it before each upload,
follow the steps, ignore the historical / troubleshooting sections
unless something breaks.

First-time setup happened on 2026-05-19 (see `archive/HANDOFF-260519.md`
for the session that did it). This doc captures what's permanent so
future sessions don't rediscover the gauntlet.

---

## TL;DR — per-release upload (the recurring ~3 min owner action)

Assumes first-time setup is done (it is, on 2026-05-19).

**Claude does automatically (no owner action needed):**
1. Bumps `CURRENT_PROJECT_VERSION` in `project.pbxproj` and pushes to `main`.
2. Runs `xcodebuild archive` to produce the `.xcarchive` (2–5 min, fully scripted).

**Owner does (2–3 min in Xcode Organizer):**
3. Open Xcode — it will already be open after Claude's archive run.
4. **Window → Organizer** (or it opens automatically after archive).
5. Select the new archive → **Distribute App** → **App Store Connect** → **Upload** → keep defaults on every screen → final **Upload**.
6. Wait 1–3 min for the upload to finish ("Upload Successful" alert).
7. Wait **15–30 min** for Apple to process the build. You'll get an email titled "Your build has finished processing."
8. App Store Connect → your app → **TestFlight** tab → click the new build → optionally paste **"What to Test"** notes.
9. New build auto-distributes to whoever is already in your Internal Testing group. On the iPhone, the **TestFlight app** shows the new version with an Install button.

That's it. No phone plugging, no certificate dance — those are already set up.

### Full automation (future — when ready)

Once an App Store Connect API key or Apple ID app-specific password is set up,
Claude can run the Organizer step too via `xcrun altool --upload-app`. That
reduces owner action to zero. See § "Full upload automation" below to enable.

---

## Archive command (Claude runs this)

```bash
cd ~/Desktop/"TRAVEL GUIDED TOUR"

xcodebuild archive \
  -project "TRAVEL GUIDED TOUR.xcodeproj" \
  -scheme "TRAVEL GUIDED TOUR" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath /tmp/Atlas-$(date +%Y%m%d-%H%M).xcarchive \
  | xcpretty 2>/dev/null || true

open /tmp   # Organizer also opens automatically; either way, the archive lands there
```

The archive uses Automatic Signing with the Apple Distribution certificate already
in the Keychain — no flags needed. After it completes, Xcode Organizer opens the
archive ready for Distribute App.

---

## Full upload automation (set up when ready)

When you want to skip the Organizer step entirely, do this one-time setup:

**Option A — App-Specific Password (5 min)**

1. Go to [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security →
   App-Specific Passwords → Generate.
2. Name it "Atlas Xcode Upload". Copy the password (shown once).
3. Tell Claude the password. Claude stores it in Keychain:
   ```bash
   xcrun altool --store-password-in-keychain-item "ATLAS_ASC_PASSWORD" \
     -u "YOUR_APPLE_ID_EMAIL" -p "THE_APP_SPECIFIC_PASSWORD"
   ```
4. From then on, the upload is fully automated after archive:
   ```bash
   xcrun altool --upload-app \
     -f /tmp/Atlas-YYYYMMDD-HHMM.xcarchive/Products/Applications/*.ipa \
     --type ios \
     -u "YOUR_APPLE_ID_EMAIL" \
     -p "@keychain:ATLAS_ASC_PASSWORD"
   ```

**Option B — App Store Connect API Key (10 min, preferred for CI)**

1. App Store Connect → Users & Access → Integrations → App Store Connect API.
2. Generate a key with **App Manager** role. Download the `.p8` file.
3. Note the **Key ID** (10-char string) and **Issuer ID** (UUID).
4. Place the `.p8` file at `~/.appstoreconnect/private_keys/AuthKey_KEYID.p8`.
5. Upload command:
   ```bash
   xcrun altool --upload-app \
     -f /path/to/app.ipa --type ios \
     --apiKey YOUR_KEY_ID --apiIssuer YOUR_ISSUER_ID
   ```

---

## How it fits together (vocabulary)

Useful background for when something goes weird. Skip if everything's working.

- **Apple Developer Program** (the $99/yr enrollment that lets you ship apps). One account; "team" = you + anyone you invite.
- **App ID** (a registered identifier in your team's account, e.g. `com.ehky.TRAVEL-GUIDED-TOUR`). Locked once an app is shipped with it.
- **Bundle Identifier** (the same string baked into the Xcode project — must match the App ID exactly).
- **App Store Connect record** (the marketing-side database row for the app — keywords, description, screenshots, privacy questionnaire, TestFlight, App Store review). Distinct from the App ID; references it.
- **Signing Certificate** (your team's cryptographic identity that proves a binary came from you). Two flavors:
  - **Apple Development** — used by Xcode's ▶︎ Run button to install on USB-connected iPhones. Requires the iPhone's UDID to be registered.
  - **Apple Distribution** — used by Archive → Upload. Doesn't care about devices.
- **Provisioning Profile** (a file bundling: app ID + signing cert + device list + entitlements). Xcode auto-creates these when "Automatically manage signing" is on. Stored under "Xcode Managed Profile."
- **Archive** (a release-configuration build of the app, packaged for distribution; lives in `~/Library/Developer/Xcode/Archives`).
- **TestFlight** (Apple's beta distribution channel — installs builds on registered testers' phones without going through App Store review). Internal Testing (up to 100 testers from your team) doesn't need Apple review; External Testing does.

---

## Versioning

Each upload to App Store Connect must have a **unique Build Number** within the same Marketing Version. Apple rejects re-uploads of the same version+build pair.

| Field | Where | When to bump |
|---|---|---|
| **Marketing Version** (e.g. `1.0`, `1.1`, `2.0`) | Xcode → target → General → Version | When you cut a public release — typically a meaningful change in features. Visible to App Store users. |
| **Build Number** (e.g. `1`, `2`, `3`, `4`) | Xcode → target → General → Build | Every TestFlight upload. Increment by 1 each time. |

Examples:
- First TestFlight upload of v1.0: `1.0 (1)` ✅
- Bug-fix iteration on v1.0: `1.0 (2)` ✅
- Another fix: `1.0 (3)` ✅
- Public release: bump to `1.0 (4)` and submit for App Store review, or jump to `1.1 (1)` if treating as a minor release
- Next major version: `2.0 (1)`

There's no requirement to bump Marketing Version between TestFlight builds — many betas can share the same `1.0`. Just bump Build Number.

---

## Adding a new physical device

If you ever upgrade phones or add a tester's phone, the device needs to be registered with your team — same dance as 2026-05-19.

1. Plug the new iPhone into your Mac via USB-C or Lightning.
2. On the iPhone, tap **Trust** on the prompt + enter passcode.
3. In Xcode: **Window → Devices and Simulators** (⇧⌘2). Wait for the phone to appear with no "preparing for development" or dyld errors. First-time may take a few minutes.
4. On the iPhone: **Settings → Privacy & Security → Developer Mode → On** (only appears after step 1). Restart when prompted, then confirm "Turn On" after restart.
5. In Xcode → main app target → Signing & Capabilities → if you see "Device 'X' isn't registered in your developer account" with a **Register Device** button, click it. Wait 10 seconds. Errors clear.
6. After registration, you can Run from Xcode to the new phone. For TestFlight specifically, just installing the TestFlight app on the new phone and adding the Apple ID as an Internal Tester is enough — no Xcode involvement.

---

## Inviting external testers (family, friends, beta testers)

The first-time TestFlight setup used **Internal Testing** for just
the owner. For anyone else — family, friends, anyone outside the
Apple Developer team — use **External Testing**. The distinction
matters: Internal testers must be added as users on the Developer
team (which gives them access to App Store Connect, billing,
certs); External testers just need an email address.

### Setting up a group (one-time per group)

For V1, one group is enough (e.g. `Family` or `Close beta`).
Future builds just get added to the existing group.

1. App Store Connect → your app → **TestFlight** tab.
2. Left sidebar → **External Testing** → click **+** next to it.
3. Name the group.
4. Inside the group → **Testers** tab → **+** → enter testers'
   email addresses. Each must match the email tied to their Apple
   ID on their iPhone.
5. Inside the group → **Builds** tab → **+** → pick the build to
   share (e.g. `1.0 (1)`).

### Beta App Review (one-time per major version)

When you add the first build to an External Testing group, Apple
requires a one-time Beta App Review (~24h first time, minutes-to-
hours on subsequent builds). When prompted, fill in:

- **What to Test** — same text used elsewhere. Re-derivable from
  the M-qa 10-step checklist in `ROADMAP.md`.
- **Beta App Review Information:**
  - **Contact Information** — your name, email, phone. Used if
    the reviewer needs to ask a question; not shared with testers.
  - **Sign-in required?** — **No** (Atlas has no accounts in V1).
  - **Notes** — 1–2 sentences for the reviewer. Example: "Atlas
    is a GPS-anchored audio-tour app for walking around NYC. No
    account required. Tap any tour from the home screen list or
    map to start playback. Audio is hosted on a CDN; standard
    HTTPS requests only."
- **Export Compliance** — should auto-skip due to
  `ITSAppUsesNonExemptEncryption = NO` in build settings. If it
  asks, "uses encryption" = Yes (standard HTTPS), "exempt from
  compliance" = Yes.

Submit. Apple reviews. After approval, invitation emails go out
to testers automatically.

### What testers do

1. Install the **TestFlight** app from the App Store on their
   iPhone (if not already).
2. Open the email invitation from Apple → tap the redemption link.
3. TestFlight opens → tap **Install** → app appears on home screen.

**Send testers a heads-up before the invite email arrives** —
something like "You'll get an email from Apple about a beta;
install the 'TestFlight' app from the App Store first, then tap
the link." Family/friends with no prior beta experience tend to
delete the invite as spam without this.

### Subsequent builds in the same group

After the group exists, adding new builds is fast:

1. Upload the new build per the per-release TL;DR at the top.
2. Wait for processing.
3. App Store Connect → TestFlight → External Testing group →
   **Builds** tab → **+** → pick the new build.
4. Apple usually fast-tracks or skips review when beta metadata is
   unchanged. Testers get notified automatically.

### Things to know

- **Build expiry — 90 days.** TestFlight builds auto-expire 90
  days after upload. Testers get a notification before. If you're
  not pushing builds regularly, plan a refresh before expiry.
- **Tester limit — 10,000 per group.** Far more than V1 will need.
- **Public link option.** Each external group can publish a
  shareable URL that anyone can redeem. Useful later for broader
  open beta; for family/friend invites, direct email is better.
- **Removing a tester.** Group → Testers tab → swipe / click the
  tester → Remove. They lose access to future builds immediately;
  existing installs keep working until the build expires.

---

## Troubleshooting

(Specific incidents that bit us on 2026-05-19 — fixes captured here so they're not re-debugged.)

### 1. "Communication with Apple failed: Your team has no devices..."

Two red errors in Signing & Capabilities, fail Archive in ~3 seconds with **`No profiles for 'com.ehky.TRAVEL-GUIDED-TOUR' were found`**.

**Cause.** Even though Archive uses Distribution signing (which doesn't need devices), Xcode's Automatic Signing tries to generate BOTH Development and Distribution profiles at build time. The Development profile generation fails when zero devices are registered, and that whole-build-fails-out.

**Fix.** Plug an iPhone in (see § Adding a new physical device above) so the team has ≥1 registered device. After that, Automatic Signing can generate both profiles.

**Alternative if no device handy.** Switch the main app target to **Manual Signing** (uncheck "Automatically manage signing"), then create a Distribution profile manually in https://developer.apple.com/account/resources/profiles/list and select it in the Release subtab. More steps but no device needed.

### 2. "dyld_shared_cache_extract_dylibs failed"

Appears in Devices and Simulators after first connecting a new iPhone. Xcode is trying to extract iOS system-library symbols from the phone for on-device debugging.

**Cause.** Insufficient disk space (the extraction needs several GB of scratch space). Common when the Mac is below ~5 GB free.

**Fix.** Free up space (10 GB minimum). Easy wins:
```bash
# Quit Xcode first, then:
rm -rf ~/Library/Developer/Xcode/DerivedData/*           # build cache
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*    # device symbols
# Or use xcrun simctl delete unavailable for unused simulators
```
Reopen Xcode and reconnect the phone. The dyld extraction will retry automatically.

Note: dyld extraction only matters if you want to **Run from Xcode** to the connected device for debugging. For Archive → Upload, you can ignore it.

### 3. "Device 'X' isn't registered in your developer account" (with **Register Device** button)

Appears in Signing & Capabilities **after** the phone is plugged in, dyld is happy, and Developer Mode is on.

**Fix.** Click the **Register Device** button right in that error block. Wait 10 sec. Done. Xcode handles the API call to Apple, the device gets added to the team, and the signing flow can proceed.

### 4. Archive succeeds but Upload fails

Usually a temporary Apple-side issue. Quit Organizer, reopen, try again. If it keeps failing, check https://developer.apple.com/system-status/ for App Store Connect outages.

### 5. Build processing on Apple's side takes >60 min

Apple's typical processing is 15–30 min, sometimes longer during peak hours. If still pending after 2 hours, check email for a rejection (e.g. ITMS-XXXX validation error). Common rejections:

- Missing app icon for a required size — fix in `Assets.xcassets/AppIcon.appiconset/` and re-upload with a new build number.
- Encryption declaration mismatch — already set to `ITSAppUsesNonExemptEncryption = NO` in 2026-05-19 to avoid the per-archive dialog.
- App Privacy mismatch — if you start collecting data, update the questionnaire in App Store Connect before uploading.

### 6. Distribution certificate expired

Distribution certs expire after 1 year. When they do, Xcode signing turns red again. With Automatic Signing on, click "Try Again" and Xcode usually renews itself. If not:

1. Xcode → Settings → Accounts → Manage Certificates… → trash the expired Apple Distribution → click **+** → Apple Distribution to create a new one.
2. Provisioning profiles auto-regenerate against the new cert next Archive.

---

## File map

```
TRAVEL GUIDED TOUR/
├── TRAVEL GUIDED TOUR/
│   ├── Assets.xcassets/AppIcon.appiconset/atlas-icon-1024.png   # placeholder icon
│   ├── ContentView.swift
│   └── ... (rest of the source)
├── TRAVEL GUIDED TOUR.xcodeproj/
│   └── project.pbxproj                                          # signing settings live here
├── docs/
│   ├── testflight.md                                            # ← this file
│   ├── design-tokens.md
│   ├── cdn-decision.md
│   └── troubleshooting.md                                       # Xcode + git landmines (broader scope)
└── (gh-pages branch, separate)
    ├── audio/<filename>.mp3                                     # tour audio served by GitHub Pages
    └── privacy/index.html                                       # privacy policy
```

App Store Connect record + Apple Developer team data is **off-repo** (in Apple's database). The links to manage that:

- App Store Connect: https://appstoreconnect.apple.com
- Apple Developer portal: https://developer.apple.com/account
- Apple system status (for outages): https://developer.apple.com/system-status/

---

## Future improvements (deferred)

- **Automate via Fastlane.** Once we're shipping every week, Fastlane can do Archive + Upload + version bumping from one command. Not needed at V1 cadence.
- **CI-driven uploads.** GitHub Actions can run `xcodebuild archive` + `xcrun altool` to push builds without a human. Requires storing the App Store Connect API key as a secret. Pre-cursor: Fastlane.
