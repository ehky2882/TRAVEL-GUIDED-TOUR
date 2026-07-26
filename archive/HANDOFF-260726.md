# HANDOFF 2026-07-26 (session 74) — saving consolidated: one save action, "Liked" is the default list

**Type:** code (web/remote session, Linux — no Mac). One PR:
**[#447](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/447)**, open for owner review.
No content, asset-catalog, or backend changes.

## What the owner asked for

It started as *"every bookmarked tour should default into a default journey's folder like a
simple 'liked' playlist,"* but the owner sharpened it mid-session and that sharpening is the
whole point:

> "the whole point is to consolidate so that there's only one way to save tours, rather than
> different ways to do it and different repositories. it's about consolidating. similar to what
> we did with makers — consolidating saving and following."

That reframe mattered. The first plan written this session only merged the *views* — it renamed
the Saved tab and pinned a Liked row, while leaving the bookmark and "Add to a Journey" writing
to two different tables. That would have shipped the exact redundancy the owner was trying to
remove. Worth remembering: **"add a default folder" and "consolidate saving" are different
briefs**, and only the second one is what was built.

## The problem

Two unrelated ways to keep a tour, two stores, no knowledge of each other:

| | Wrote to | Surfaced in |
|---|---|---|
| Bookmark | `LibraryStore.savedAt` (UserDefaults → `user_library`) | Library "Saved" tab |
| "Add to a Journey" | a `journey_items` row | that journey |

A tour in "Lisbon Weekend" was **not** bookmarked and never appeared in Saved; a bookmarked tour
belonged to no list. Precisely the redundancy removed for makers in PR #398, where
bookmark-a-maker was **deleted** rather than kept beside Follow.

## The model now

- **Saved = in at least one list.** No separate saved flag alongside membership.
- **Liked is the default list** — where a tour lands when the user doesn't pick somewhere.
  Owner's ruling: *"if the user doesn't specify, there should always be a default 'liked' folder
  that things are saved into."* Filing a tour into a named list puts it **there, not also in
  Liked**. Nothing is ever moved implicitly.
- **Bookmark tap, by context** — the owner's own UX call, and better than the blunt
  "remove from everything?" confirm that was proposed first:

  | Tour is in | Tap does |
  |---|---|
  | nothing | adds to Liked |
  | exactly one list | removes it from that list — a second tap always undoes the first |
  | two or more | opens the membership sheet, everything ticked; user unticks what they want out |

## The constraint that shaped everything

**Bookmarking works signed out** (`LibraryStore` is UserDefaults, no auth check anywhere) while
**lists are cloud-only** (`JourneyService` throws `notSignedIn`; RLS enforces
`owner_user_id = auth.uid()`).

So **Liked stays backed by `LibraryStore`** and named lists stay in Supabase — one concept, two
backends, no seam the user sees, anonymous saving preserved. **Making Liked a real server row
would have gated bookmarking behind an account. Don't.**

`LibraryStore` and `SyncService` are **not modified**. The existing `user_library` sync,
including the explicit-null `encode` that makes an un-save clear remotely (the session-49 bug),
keeps working untouched. **No backend change, no migration, nothing for the owner to run.**

## What changed

- **`Data/SaveState.swift`** (new) — the rules as pure functions, unit-tested without either
  store: `isSaved`, `placeCount`, and the 0/1/many `tapAction`.
- **`Data/TourSaveActions.swift`** (new) — binds those rules to the two stores; shared by the
  cards, tour detail and the player so they can't drift. Deliberately **not** `@MainActor`,
  matching how the existing journeys sheet already reaches into `JourneyService` from view
  bodies and button actions.
- **`Data/JourneyService.swift`** — `membership` map + flat `allListedTourIds`, both derived
  from the embed `loadMyJourneys()` already fetches; kept in step by every mutation.
- **`TourListMembershipSheet.swift`** replaces `AddToJourneySheet` — removes as well as adds,
  and **leads with Liked** so a signed-out user gets a working sheet instead of a sign-in wall.
- **`LibraryView`** — Saved tab becomes **Liked** and is the single home for kept things: Liked
  tours, your lists (incl. "New list"), followed creators.
- **`MakerView`** — the profile's Journeys row **removed** rather than left as a second door.
  `JourneysListView` deleted; `JourneyEditorSheet` split into its own file.
- **`SaveStateTests`** — 12 cases incl. signed-out parity with a plain bookmark toggle.

## Two things worth remembering

**`isSaved` is on the hot path.** It's read by every card in every rail (`CardHeroControls` via
`RailCarousel` and `FilterResultCard`), so per-tour membership queries were never viable.
`loadMyJourneys()`'s `journey_items(tour_id, position)` embed **already returns every tour id in
every list**, so `allListedTourIds` is free. If membership ever needs to be fresher than
"since the last list load," don't reach for a per-tour query — reload the list.

**Fixed in passing:** `JourneyService.clear()` existed but was **never called anywhere**, and
`myJourneys` wasn't cleared on sign-out, so a stale list could survive an account switch. Now
cleared whenever the signed-in uid differs from the one the cache was loaded under.

## Open — owner's call

- **The name.** User-facing copy now says **"list"**; the Swift types and Supabase tables are
  still `Journey` / `journeys` (cosmetic, no migration). The owner raised "Journey" as
  cumbersome and the diagnosis held up: it **breaks on the default bucket** ("Liked" is not a
  journey) and it **collides with Walk**, the app's own name for a multi-stop tour — so a
  collection of them reads as "a journey of journeys." `docs/journeys-design.md` §3 had punted
  the name from the start, so this decides rather than overturns. Rename measured at ~20
  user-facing strings across 9 files.
- **Dropping the profile's lists row** — done here on the consolidation argument (Library =
  what you collected). One-line restore if the owner disagrees.

## ⚠️ Device check owed — the simulator cannot prove this

The signed-out path is the whole design constraint and there's no session in the sim:

1. **Signed out**, bookmark a tour → it lands in **Liked**.
2. Sign in → it syncs and is still there.
3. Add a tour **straight to a named list** → its bookmark reads filled, and it is **not** in Liked.
4. A tour in **two** lists → tapping the bookmark opens the sheet showing both.
5. Untick one → still saved. Untick both → unsaved.
6. Regression: browse, play, download, and list create/reorder/delete unchanged.

## State at session end

- PR #447 open. Validator job **green**; the iOS Simulator build + unit tests were still running
  when this was written — **confirm both before merge** (code PRs need owner OK + device review
  regardless).
- Branch `claude/journey-bookmarks-default-folder-c8ur85`.
- Catalog untouched: 948 tours / 18 makers / 1174 stops.
