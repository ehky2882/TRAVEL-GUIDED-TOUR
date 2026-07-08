# Dozent — product vision & strategy

Status: **living strategy doc** (first written 2026-07-08, from an owner ↔ Claude strategy
session). This is the *compass* — the "why" and the "in what order." It sits above the
feature designs (`group-listen-design.md`, `journeys-design.md`) and the `ROADMAP.md`
execution checklist. When a decision feels unclear, come back here.

---

## The one thing
> **Dozent is a guided audio layer over the real world — made by people, for exploring
> anywhere: the far side of the planet *or* your own block.**

Everything else is a facet of that single sentence. The power of the product is that its
many ambitions aren't competing directions — they're **one product seen from five angles.**
Protect that coherence; it's what keeps Dozent feeling like *one app* instead of a Swiss
Army knife.

## The five facets (all of it — but as facets, not separate products)
| Facet | What it is | Its job |
|---|---|---|
| **Travel companion** | Exploring *away* | **Acquisition** — how people discover Dozent |
| **Know your city** | Exploring *home* | **Retention** — why locals stay (weekly) |
| **"Anyone can be a Dozent"** | Made by people | **Supply** — how content scales beyond the founder |
| **Explorer → Dozent ladder** | An identity you grow into | **Meaning** — gives engagement a shape |
| **Journeys · Group Listen · Social** | Collect, share, experience together | **Depth + virality** |

(Dozent = *docent* = a guide. Everyone can guide.)

## Who it's for — and the key audience insight
- **Tourists** are the **acquisition** hook (episodic, huge inbound volume — e.g. NYC's ~60M
  visitors/yr), but they don't come back weekly.
- **Locals rediscovering their own city** are the **retention** engine — the only audience
  for whom *weekly* use is genuine, because there's always another corner they've walked
  past a thousand times.
- So: **travel gets them in; local exploration keeps them.** Both matter; they're different
  jobs.

## The marketplace truth (why the chicken-and-egg trap doesn't apply)
Two-sided marketplaces usually die launching **empty on both sides**. Dozent isn't empty:
- **Supply was seeded by the founder** — ~500+ pro tours across ~9 cities. So Dozent is a
  **great single-player content app that is *opening* a supply side**, not a marketplace
  launching from zero. (The Airbnb/OpenTable/DoorDash "do things that don't scale" pattern.)
- Therefore **solve demand first.** A maker's real question is "will anyone hear my tour?" —
  they need an audience. Listeners just need good tours, which already exist. **Build
  listeners on the seeded content, *then* recruit makers by offering them that audience.**
- **Stay single-player-valuable.** Every feature should deliver value to one user before it
  needs a crowd (a tour, a downloaded Journey — all valuable solo). Network effects are a
  bonus on top, never the prerequisite.
- **The two sides are blurred on purpose** — "anyone can be a Dozent." Listeners *are*
  future makers; curating a Journey is the on-ramp from consumer → creator (listen → save →
  curate → create → certified Dozent). You're not recruiting two disjoint populations.
- **Marketplaces are really N local marketplaces** — a Kyoto listener doesn't want Lisbon
  tours. **Go deep in a beachhead, not wide.**

## The beachhead: NYC
Chosen because it's the deepest city already *and* **the founder lives there** — the single
biggest unfair advantage, because winning a beachhead requires unscalable local moves only a
resident can do:
- **Walk every tour in situ** and make the on-the-ground experience (esp. the GPS trigger)
  flawless — this is the least-verified, highest-leverage part of the whole app.
- **Be the first power user**; **meet makers face-to-face** (NYC is dense with licensed
  guides, docents, historians, architecture writers); **distribute physically** where
  tourists/walkers already are.

**"Winning NYC" =** dense coverage + a flawless on-the-ground experience + a few real local
Dozents besides the founder + shared Journeys circulating. That becomes the *reference city*
you copy to city #2. (Open question for the owner: what's the concrete proof that "Dozent
won NYC"? Define it — it tells you what to optimize.)

## Retention is a *positioning*, not a mechanic
The honest reason to open Dozent weekly isn't points — it's a reframe:
> **Not "a travel app for when you travel" (episodic) — but "your ongoing relationship with
> the places around you" (perpetual). Know your city, for life.**

Genuine weekly hooks that fall out of that positioning (no gimmicks):
- **Freshness** — "New this week near you"; a curated weekly local pick. (Strongest hook —
  same reason you open a podcast/Spotify.)
- **The walk-a-week ritual** — "a 15-min walk near you you haven't taken." A *service*.
- **Relationships** — following Dozents you love → their new tours/Journeys (the social layer).
- **Planning** — a Journey for an upcoming weekend/trip, added to over days.
- **Ambient serendipity** — "you're near a 5-min tour." Used sparingly = delight.

## The Explorer → Dozent ladder (meaning, not manipulation)
A single identity progression that spans the whole app and embodies "anyone can be a Dozent":
> **Explorer → … → Dozent.** Start curious (listen, "collect your city"). Go deeper
> (curate Journeys). Create (make tours). Earn **certified Dozent** status — a leveled
> blue-check that doubles as a **trust/quality signal** for listeners and an aspirational
> ladder for creators.

**Design principle:** the ladder is a **mirror of genuine engagement, not a carrot that
manufactures it.** Reward *real* behavior (a tour actually walked on-location), never vanity
(opening the app). Status that earns itself off real use feels good; status chased for its
own sake feels hollow. Build the first kind.

## The discipline: all of it — in sequence, not at once
"All of it" is the right ambition *and* the #1 way ambitious solo products die (a little of
everything, nothing great). The vision isn't cut — it's **sequenced**, each layer earning
the next:

1. **Core magic** — the NYC walk itself is *undeniable* (GPS fires, tours delight). Nothing
   downstream matters without this. ← **the first domino.**
2. **Retention** — "know your city": fresh local content, the walk-a-week, Journeys.
3. **Meaning** — the Explorer → Dozent ladder.
4. **Network** — social + open supply (recruit local Dozents once there's demand to offer).
5. **Money** — Pro Guide / paid tours, last, once there's a thriving base.

## The first domino (do this before anything else)
**Go make the core NYC walking experience undeniably great** — walk a real multi-stop tour
on the ground (AMNH Four Facades is the ready test case), validate the geofence trigger, and
feel whether the magic is real. If it is, every later layer gets easy. If it isn't yet,
no marketing, makers, or features matter. The founder lives in NYC — this is a *this-weekend*
move, not a someday move.

## How the designed features serve the vision
- **Journeys** (`journeys-design.md`) — the curation on-ramp (consumer → creator), a
  planning workspace, and a shareable growth vector. Serves retention + supply + virality.
- **Group Listen** (`group-listen-design.md`) — delight + the "Pro Guide" monetization seam;
  works offline for travelers. Serves depth + money.
- **Social layer** (designed next) — following = the relationships hook + the discovery feed
  that makes Journeys and the ladder come alive.
- Sequencing of these lives in `ROADMAP.md`; *why* they exist lives here.

## Open strategic questions (owner)
- Define "Dozent won NYC" concretely (the proof moment).
- Is the shift to **"know your city" as the primary identity** (locals first, travel second)
  one the owner fully embraces? It's powerful but changes who you build for first.
- Monetization timing — keep the core free as the demand magnet; charge the edges later.
