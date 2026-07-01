# Share → Universal Link deep-linking — design

**Status:** implemented on `claude/share-universal-links`; **web/AASA host is a gated owner setup** (see § Owner setup). Not merged.

## Goal

Today the Share action puts **plain text** on the share sheet (`"<title> — by <maker> on Atlas"`). We want each shared tour to be a **real https link** that:

- **opens the app straight to that tour** if the recipient has Atlas installed, and
- otherwise opens a **web "coming soon" preview page** for that tour.

Atlas is **not in the App Store yet**, so the fallback is a preview page (owner's choice) — **no public TestFlight link**.

The mechanism is **Apple Universal Links** (an https link the OS routes to the app when installed, else to Safari), with the existing `dozent://` custom scheme kept as a secondary in-app path.

## Link format

```
https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/t/?id=<tourUUID>
```

- A **real file + query string** (`t/index.html` reads `?id=`), because GitHub Pages has **no server rewrites** — we can't do `/t/<id>` cleanly without a file per id.
- `id` is the tour's existing **UUID** from `Tours.json` (stable, already the app's primary key). Lowercased in the visible link to match `Tours.json`; matched case-insensitively everywhere.
- Custom-scheme equivalent (in-app fallback, e.g. from an older text link): `dozent://tour/<tourUUID>` or `dozent://tour?id=<tourUUID>`.

**Universal Link + query works:** AASA path/`components` matching is on the **path** (`/TRAVEL-GUIDED-TOUR/t/*`); the `?id=` query is carried through to the app untouched. Verified pattern.

## The crux — where the AASA lives

Apple fetches the **apple-app-site-association (AASA)** file only from the **domain root**:

```
https://ehky2882.github.io/.well-known/apple-app-site-association
```

But our assets live on the **project** Pages site under a subpath: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/` (the `gh-pages` branch of *this* repo). The domain **root** (`ehky2882.github.io/…`) is served by a **separate GitHub user-pages repo** named `ehky2882.github.io` — **which does not exist yet** (verified: `https://ehky2882.github.io/` → 404, and `…/.well-known/apple-app-site-association` → 404).

Apple will **not** look under `/TRAVEL-GUIDED-TOUR/.well-known/…`, so hosting the AASA on the project Pages site is useless. It **must** sit at the domain root.

### Options considered

1. **Create a `ehky2882.github.io` user-pages repo** that serves just `/.well-known/apple-app-site-association` at the root. Share links still point at `…/TRAVEL-GUIDED-TOUR/t/?id=…` (project site); the AASA's path pattern scopes the app association to `/TRAVEL-GUIDED-TOUR/t/*` only. **Simplest, free, no DNS.** Needs the owner to create one small repo. ← **RECOMMENDED**
2. **Custom domain** (buy e.g. `atlas.travel`), point it at Pages, AASA at its root. Cleaner long-term (nicer share URLs, own the namespace) but needs a **domain purchase + DNS** — more setup, ongoing cost. Defer to real launch.

**Recommendation: Option 1 now.** It unblocks Universal Links today with one tiny repo and zero cost, and doesn't preclude moving to a custom domain later (we'd just add a second `applinks:` entry + AASA).

### AASA rules (must all hold or the OS silently ignores it)

- Served over **HTTPS** (GitHub Pages is HTTPS ✓).
- **`Content-Type: application/json`** (GitHub Pages serves an extension-less file this way ✓ — verified against the existing `Tours.json` host).
- **No redirects** to reach it.
- **No `.json` extension** on the filename.
- Path: exactly `/.well-known/apple-app-site-association` at the domain root.

### AASA file contents

`appID` = `<TeamID>.<bundleID>` = **`CPC7M72JTP.com.ehky.TRAVEL-GUIDED-TOUR`**.

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["CPC7M72JTP.com.ehky.TRAVEL-GUIDED-TOUR"],
        "components": [
          {
            "/": "/TRAVEL-GUIDED-TOUR/t/*",
            "comment": "Atlas tour share links open in the app"
          }
        ]
      }
    ]
  }
}
```

Scoping to `/TRAVEL-GUIDED-TOUR/t/*` means only tour share links claim the app — any future content at the user-pages root stays normal web pages.

## App side

### Entitlement

Add **Associated Domains** to `TRAVEL GUIDED TOUR.entitlements`:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:ehky2882.github.io</string>
</array>
```

`CODE_SIGN_ENTITLEMENTS` already points both app configs at this file (added for Sign in with Apple), so no `.pbxproj` change is needed.

**Provisioning:** archive already uses automatic signing + `-allowProvisioningUpdates` (team `CPC7M72JTP`). As with Sign in with Apple (build 52), Xcode should regenerate the profile with the Associated Domains capability automatically. **If the archive fails on a stale/invalid profile, the owner may need to toggle "Associated Domains" on the App ID** in the Apple Developer portal (Certificates, IDs & Profiles → Identifiers → `com.ehky.TRAVEL-GUIDED-TOUR`) — mirrors the applesignin precedent. Flagged, not assumed.

### Routing

Pure, unit-tested parser (`Data/DeepLink.swift`):

- `DeepLinkParser.parse(URL) -> DeepLink?` handles both the https Universal Link (`…/t/?id=<uuid>` or `…/t/<uuid>`) and the `dozent://tour/<uuid>` fallback; returns `.tour(UUID)` or `nil`.
- Ignores anything else — including `dozent://login-callback` (which never reaches app URL handling anyway: it's consumed by `ASWebAuthenticationSession` inside supabase-swift, not delivered to `onOpenURL`). Defensive: the parser only matches host `tour`.

Wiring (`TRAVEL_GUIDED_TOURApp.swift`):

- `.onContinueUserActivity(NSUserActivityTypeBrowsingWeb)` → Universal Links.
- `.onOpenURL` → the `dozent://` custom scheme.
- Both are attached to a `Group` wrapping **both** the splash and content branches, so a **cold-launch** link that arrives during the 2 s splash isn't dropped.
- Resolution: parse → `dataService.tour(by: id)` → `tourPresenter.present(tour)` (the same channel every other entry point uses).
- **Cold launch vs already-running:**
  - *Already running / warm:* catalog is in memory, present immediately.
  - *Cold launch:* the link is parsed and **stashed** while `isLoading` (splash) is true, then presented once `ContentView` is mounted (drained in its `.task`, with a short settle delay so the UIKit bottom-layer presenter is ready). The catalog itself is available synchronously on `DataService` init (bundled seed → cache), so lookup works before the network refresh finishes.
- **Unknown / invalid id:** `tour(by:)` returns `nil` → **no-op**, app just opens to Home. No crash. (Edge case: a link to a brand-new tour not yet in the bundled seed could miss on a cold launch before the network refresh lands; acceptable — opens to Home. Could be hardened later by retrying after `refresh()`.)

Maker deep links are **out of scope** for now (tours are the priority); the parser is structured so a `.maker(UUID)` case is a small future addition.

### Share action change

`TourDetailView.swift` (overflow menu) and `PlayerView.swift` both switch their `ShareLink` from plain text to:

```swift
ShareLink(item: AtlasShareLink.tourURL(for: tour),
          subject: Text(tour.title),
          message: Text(shareMessage))   // "<title> — by <maker> on Atlas"
```

The recipient gets the **https Universal Link** (rich preview + tappable), with the title as the subject and the old identifying line as accompanying text. Same share-sheet UI.

## Web side

### Landing page — `t/index.html` (project gh-pages)

Client-side, no server needed:

1. Read `?id=` from the URL.
2. Fetch the already-hosted `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/Tours.json`, find the tour by id (case-insensitive).
3. Render **hero image, bilingual title, city + maker, short description**, and a clear **"Coming soon to the App Store"** message. Optional low-friction "notify me" `mailto:`.
4. Unknown id / no id → graceful **"Tour not found — explore Atlas"** state.

Atlas visual style: dark background, terracotta accent `#B85042`, mobile-first. Skipped the Apple **smart-app-banner** meta (only useful once the app is in the store; would show a broken banner now).

### AASA host

Per the crux decision — Option 1, on the **new `ehky2882.github.io` user-pages repo** (owner setup below). The AASA source of truth is checked in at `web/apple-app-site-association` in this repo so it can't drift.

## Owner setup (the gating item)

**Everything else is done; Universal Links stay dormant until this is in place.**

1. **Create the user-pages repo.** On GitHub → New repository → name it **exactly `ehky2882.github.io`** (must match the username), Public, "Add a README" checked → Create.
2. **Add the AASA file at the root path `.well-known/apple-app-site-association`** (no extension). Easiest in the GitHub web UI: **Add file → Create new file**, type the filename `.well-known/apple-app-site-association` (typing `.well-known/` creates the folder), paste the JSON from `web/apple-app-site-association` in this repo, Commit.
3. **Turn on Pages** if it isn't automatic: repo → Settings → Pages → Source = `main` branch, `/root` → Save. Wait ~1–2 min.
4. **Confirm the App ID capability** (only if the archive later fails on signing): Developer portal → Identifiers → `com.ehky.TRAVEL-GUIDED-TOUR` → enable **Associated Domains**.

Then Claude will `curl` to verify:

```
curl -i https://ehky2882.github.io/.well-known/apple-app-site-association
# expect: HTTP 200, Content-Type: application/json, the JSON body, no redirect
```

## Verification

- **Unit tests** (`DeepLinkParsingTests`): URL → `.tour(id)` parsing across https query form, https path form, `dozent://tour/…`, `dozent://tour?id=…`, uppercase/lowercase UUID, and rejection of junk / OAuth-callback / wrong-host / non-tour paths. Plus `AtlasShareLink.tourURL` round-trips back through the parser.
- **`test_sim`** green before push.
- **Simulated routing in the sim:** `xcrun simctl openurl <sim> "dozent://tour/<id>"` (and a Universal Link can't fully resolve in-sim without the live AASA + a device) → confirm the app routes to the tour.
- **On-device (owner, after AASA is live):** iMessage a share link to yourself → tap → opens the tour in Atlas. On a device *without* Atlas → same link opens the `t/` preview page.

## Decisions / open items

- **Query-param link** (not path) — forced by GitHub Pages' lack of rewrites; AASA `components` still matches on `/…/t/*`.
- **AASA host** = new user-pages repo (Option 1) over a custom domain — free, immediate, reversible.
- **Associated Domains portal toggle** — expected to be automatic via `-allowProvisioningUpdates`; flagged as a possible manual step (applesignin precedent).
- **Maker deep links** — out of scope for v1 (tours prioritized); parser leaves room for them.
