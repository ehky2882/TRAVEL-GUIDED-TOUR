# HANDOFF 2026-09-10 — a link pin that cannot load now says so

**Session:** 154. **Branch:** `claude/creator-tours-china-visibility-wmnho7`.
**PR:** [#785](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/785) — app code, so it waits for
owner OK + device review. **TestFlight run 143** dispatched from the branch with build notes
attached.

---

## Where it started

The owner asked a question, not for a change: *"If we post creators tours from TikTok, IG or
YouTube, are those tours effectively not viewable while in China?"*

The answer is yes, and the code says so plainly. `LinkSource.embedURL` builds exactly three player
URLs — `www.tiktok.com/player/v1/{id}`, `www.instagram.com/{p|reel}/{code}/embed`,
`www.youtube.com/embed/{id}` — and mainland China blocks all three hosts. `LinkEmbedView`'s own
header already said the rest: **the bytes stream from the platform and are never fetched, stored or
re-served by us.** There is no copy to fall back on and there was never meant to be one.

### The numbers, re-derived from `Resources/Tours.json` (not quoted)

| | |
|---|---|
| link pins | **1,588** — TikTok 1,027 · Instagram 542 · YouTube 19 |
| hero images for those pins | **1,588 of 1,588 on `ehky2882.github.io`**, i.e. ours |
| China-region content | Hong Kong **218 pins + 52 tours**, Macau 6, Taiwan 6, mainland **1** (Beidaihe) |

So the exposure is **not** "our China content is broken" — Hong Kong and Macau sit outside the
firewall and are fine. It is that **a traveller physically in mainland China cannot watch any pin,
for anywhere in the world.** The Paris pins fail there exactly as hard as the Beidaihe one.

## What was actually wrong, and it was worse than "blocked"

The pin's own metadata all works — title, maker, city, map marker, search, and the hero image,
because that is on our CDN. Only the video dies. But it died **silently**: `LinkEmbedView` sets
`isOpaque = false` and `backgroundColor = .black` deliberately (a white flash on a dark tour page
reads as breakage), so an unreachable player rendered as **a black rectangle at the post's aspect
ratio, indefinitely**. No error, no retry, no hint that the network rather than the app was the
problem. It read as a broken app.

## 🔴 Why the obvious fix does not exist

`LinkEmbedView` **already had a `navigationDelegate`** and it was never going to see this. Two
reasons, and both are structural:

1. The shell is handed to WebKit with `loadHTMLString(_:baseURL:)`, so **the main frame never
   touches the network.** `didFailProvisionalNavigation` cannot fire for a blocked player.
2. The player is inside a **cross-origin iframe** we may not script, and WebKit does not surface a
   subframe's provisional-load failure to the navigation delegate at all.

The one signal available is the **`<iframe>` element's own `load` event** — it fires for a
cross-origin child even though the contents stay unreadable. The shell now carries a three-line
script that relays it (and `error`) over a `WKScriptMessageHandler` named `atlasEmbed`. Failure is
therefore inferred from the **absence** of a positive signal within a 12-second deadline.

## That inference is a guess, so the design makes being wrong cheap

This is the part to review, and the part worth remembering:

- 🔴 **The message is an OVERLAY over a player that stays mounted and stays loading.** A
  slow-but-working network that beats the deadline by arriving late clears the message by itself.
  Swapping the player out for the message would have made the deadline a **final verdict** and the
  exact number load-bearing.
- `frameLoaded` wins from **every** state, `.failed` included.
- A deadline that outlived the load it was measuring **cannot** unseat a player that has since come
  up (`deadlineExpired` is ignored unless the state is still `.loading`), and it is cancelled on
  success and on every new load anyway.
- An unrecognised message body is **ignored**, never treated as failure — a future message on this
  channel must not be able to blank a working player on builds that predate it.
- A retry reloads the shell in the existing webview (`reloadToken`) rather than rebuilding it.

**The only regression route is the false positive** — the message over a pin that works — and it
cannot be tested from a Linux session. That is the one thing the owner was asked to check first.

## The copy

Says **"can't be reached"**, never *"is blocked"*. We observe a player that did not load; we do not
know why, and the honest reasons are several (a country or network blocking the platform, a captive
portal, a post gone private, the platform down). Naming one as the cause would be wrong most of the
time — § 2 of `docs/lessons.md` pointed at the viewer instead of at the owner. The `.other` source
names no platform at all, because it is reached exactly when `LinkSource.from` did not recognise the
host. It also names the thing that still works: a tour downloaded before arriving.

## Files

| File | |
|---|---|
| `Components/LinkEmbedFailure.swift` | **new** — `LinkEmbedLoadState`, `LinkEmbedLoadEvent`, `LinkEmbedLoadRule` (the whole transition table), `LinkEmbedFallbackView` |
| `Components/LinkEmbedView.swift` | shell relays the iframe's `load`/`error`; the deadline; `reloadToken`; `onLoadEvent` |
| `Features/Tour/TourDetailView.swift` | holds the state, draws the overlay, resets per pin |
| `Models/Tour.swift` | `LinkSource.displayName` + `unreachableHeadline` + `unreachableDetail` |
| `TRAVEL GUIDED TOURTests/LinkEmbedFailureTests.swift` | **new** — 19 tests |

### Two traps hit while writing it, both caught before pushing

- **`onLoadEvent` must be declared AFTER `onFullscreenChange`.** The struct has no explicit
  initialiser, so the memberwise one takes its arguments in declaration order; the first draft
  declared it second and the call site read third. A compile error, and a silent one to a reader.
- **`Coordinator` already had a `private func report(_:)`** for fullscreen state. Overloading on the
  argument type compiles, and would have left two unrelated signals — bars-withdrawn and
  player-came-up — reading as one function at every call site. Renamed to `reportLoad`.

### One deliberate exception to the token rule

`LinkEmbedFallbackView` is **light-on-dark unconditionally**. The box underneath is `black` in both
appearances, so `AtlasColors.primaryText` (`Color.primary`) would be near-black text on a black
panel in light mode — invisible exactly where the whole point is to be read. Documented in the file.

## ⚠️ NOT answered, NOT in the PR, and bigger than the PR

Neither can be measured from a session, and neither should be asserted from a document:

1. **Is `ehky2882.github.io` reachable from mainland China?** It is the asset CDN — every hero
   image, every audio file, and the catalogue mirror, with **7,713 absolute URLs in `Tours.json`**
   pointing at it. `github.io` is historically unreliable behind the firewall. If it is not
   reachable, **real Atlas tours break there too** (no images, no downloads), which dwarfs the pin
   problem. Needs a mainland vantage point. Same question for
   `apkcihljybvuyuzpbnqd.supabase.co`, the primary catalogue source.
2. **Is Dozent on the China storefront at all?** No App Store Connect key in a web session, and a
   mainland listing needs an ICP filing. **Owner question.** If it is not listed there, the
   realistic audience is foreign visitors — and a visitor roaming on their home SIM usually routes
   out of the country and never meets the firewall, which makes the practical shape *"broken on
   Chinese wifi or a local SIM, fine on international roaming or a VPN."*

## Session-start state, for the record

`scripts/session-start.sh` ran clean: `dozent.world` 200, the gh-pages mirror 200, `get_catalog`
4/4 OK, App Store **1.1.1 released 2026-09-01** (public lookup, no key). App Store Connect was
**SKIPPED — no key in a web session**, so the unreleased/build/review state was **not checked** and
is not reported here. The full `git fetch` timed out, so the branch list in § 4 of that output was
stale; `origin/main` was fresh.

**Catalogue counts were re-derived, not quoted:** 1,552 tours · 1,588 link pins. No content changed
this session.
