# App Store screenshots — the marketing set

**This is the hand-captured, captioned set** shot on a real device and composed into
framed marketing images. It is **not** the CI path in
[launch-runbook.md](launch-runbook.md) § Phase D — `screenshots.yml` produces raw
unframed simulator captures, which is a different artifact for a different purpose.
This file records the copy, the rules that produced it, and the capture recipe, so a
re-cut does not start from scratch or re-learn the same traps.

First shipped: **2026-09-01**, alongside the 1.1.1 update.

---

## The caption set

Ten frames, in order. Line 1 sets bold and dark, line 2 lighter beneath it.

| # | Screen | Line 1 | Line 2 |
|---|---|---|---|
| 1 | Home, browse shelves | **Learn** a city by ear | from someone who knows it |
| 2 | Home, map + placecard | **Open** the map | to find a tour where you're standing |
| 3 | Full player | **Hear** the audio start | the moment you reach a stop |
| 4 | Tour detail, MAP tab, a walk | **Walk** a longer route | one stop at a time |
| 5 | Home, browse shelves (2nd) | **Go** looking for | history, architecture, art, food and drink |
| 6 | Library → Downloaded | **Download** a tour | and leave the signal behind |
| 7 | Listen together sheet | **Listen** together | while one phone leads and the rest follow |
| 8 | Tour wizard → Photos | **Become** a Dozent | and make a tour of your own city |
| 9 | Tour wizard → Audio | **Record** your own voice | on the streets you already know |
| 10 | Home, world-zoom map | **Explore** 1,900 tours | in 250 cities across 40 countries |

**Order is deliberate.** Apple renders only the **first three** in search results, so
those three carry: what it is, where you find one, and the thing no other tour app
does. The consumption arc runs 1–7; the creator story is 8–9, with the invitation
(*Become a Dozent*) before the mechanics (*Record your own voice*) — the wizard's own
step numbers run 4 then 5, so presenting them the other way round makes the counter
appear to run backwards.

---

## The rules that produced the copy

Follow these if you re-cut, or the set stops reading as one voice.

1. **Each caption is ONE sentence**, broken across two lines before a preposition or
   conjunction — *from, to, in, on, with, and, while, the moment*. Never break after a
   bare verb: `Discover / history…` and `Walk / on a multi-stop tour` were the two
   originals that failed, because line 1 is then a label and the eye stops dead.
2. **The first word is always an imperative verb.** No exceptions — an assertion like
   `The audio starts itself` breaks the pattern even when the sentence is good.
3. **Every verb belongs to one family: moving through a place, and listening to it.**
   This is the rule that catches otherwise-fine lines. `Put your phone away` was
   rejected on it — `put` is about handling a device, not about a city, and it jars for
   the same reason `tour downloads` did.
4. **Ten distinct verbs**, including the ones inside line 2. Repeats read as thin
   vocabulary at a glance.
5. **Line 1 is 2–4 words** so the type sets at the same size in every frame. A one-word
   line 1 sets huge; a six-word one sets small. Both break the rhythm across the set.
6. **The first frame must say what the app is.** `by ear` is what earns the audio point
   in #1 without spending line 2 on it — `Learn a city / from someone who knows it`
   alone never says audio, tour, or GPS.
7. **The set bookends.** #1 ends *from someone who knows it*; #9 ends *on the streets
   you already know*. That is what turns ten captions into one argument: you listen to a
   local, then you become one.
8. **Check line 2 at thumbnail size.** It sets smallest and is the first thing to fail
   in the search grid. `history, architecture, art, food and drink` is the widest line
   in the set and is at the limit.

---

## Capture recipe

Every item here cost a re-shoot at least once.

**1. Simulate a location inside a covered city.** The first cut was captured in Portugal
while showing NYC shelves, so the hero frame read **`5,364.1 km away`** — an image
telling a browsing user the nearest tour is on another continent. Porto or Barcelona
work well; the shipped set is Porto.

**2. Capture with a short-titled tour PLAYING — not paused, not idle.** The mini-player
title is a `MarqueeText`, which scrolls continuously and has no rest state, so a
mid-scroll capture truncates mid-word and reads as a rendering bug:

| Player state | Renders | Why |
|---|---|---|
| Idle | `.DY TO EXPLORE? LET'S FINI` | the welcome message is long and always scrolls |
| Paused | `aused · Atlas Studio RIO` | `Paused · ` is prepended to line 2, overflowing it |
| **Playing, short title** | `BIP BIP` / `Atlas Studio RIO` | **both lines fit, nothing scrolls** ✅ |

`BIP BIP` (Atlas Studio RIO) is the known-good choice. The alternative is the
`-UITestDisableMarquee` launch argument in `UITestSupport.swift`, which freezes it
outright — but it needs a build, and playing a short-titled tour does not.

**3. One capture session, one status bar.** Times within a few minutes of each other,
battery within a few percent, same carrier and signal state. Mixed status bars are the
easiest tell that a set was assembled piecemeal.

**4. On the walk detail frame, exclude the price but keep the play bar.** Every
multi-stop walk currently carries a blanket `$0.99` test price (CLAUDE.md § LIVE
PRICING — that is temporary state, not a pricing model), so it should not appear in a
screenshot. Scrolling far enough to lose it also loses the gold play bar, which leaves
the frame with no visible way to start the tour — scroll back until both conditions
hold.

**5. Frame #10 must show Asia.** At world zoom, an Atlantic-centred view excludes Tokyo,
Seoul, Bangkok, Hong Kong, Sydney and Melbourne — roughly a quarter of the catalogue —
so the on-screen `TOURS IN VIEW` count visibly contradicts the caption's total.

---

## Scale figures — re-derive, never quote

These change with every content merge. Nothing in this file or CLAUDE.md is authoritative
for them.

```bash
python3 -c "
import json
d=json.load(open('TRAVEL GUIDED TOUR/Resources/Tours.json'))
a=d.get('tours',[])+d.get('linkPins',[])
print('entries  :',len(a))
print('cities   :',len({r.get('city') for r in a if r.get('city')}))
print('countries:',len({r.get('country') for r in a if r.get('country')}))
"
```

Measured **2026-09-01**: **1,930 entries** (1,552 tours + 378 link pins), **250 cities**,
**40 countries**.

**Round down, never up.** `1,900` and `250` are true; `2,000` and `260` are not. The
exposure is not Apple — it is that frame #10 displays its own live `TOURS IN VIEW` count,
so an inflated caption contradicts the image it is printed on.

⚠️ **Open item at time of writing:** the submitted frame may carry `2,000 tours / 260
cities`. Verify against the live listing; screenshots can be replaced without a new
build via the `upload_screenshots` lane (`skip_app_version_update: true`), which submits
nothing for review.

---

## After uploading — verify against Apple, not against fastlane

`upload_to_app_store` has printed **"Successfully uploaded all screenshots"** while
leaving **ten images live, four of them duplicates** (2026-08-17): its verification pass
raced Apple's processing, decided the first four were missing, and re-uploaded them. The
job went green. Only querying App Store Connect caught it.

So after any upload, walk `apps → appStoreVersions → appStoreVersionLocalizations →
appScreenshotSets → appScreenshots` and confirm the exact expected count, in order, all
`COMPLETE`. Full detail in CLAUDE.md § "App Store screenshots were unshippable and
reported success".
