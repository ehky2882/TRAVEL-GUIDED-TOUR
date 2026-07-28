# HANDOFF 2026-07-28 — lists on other people's maker pages, LIKED on everyone's

Session 77c. Pass 2 of the maker-page work started in
`HANDOFF-260727-4.md`. Code + two SQL blocks.
**[PR #462](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/462)**,
branch `claude/maker-page-playlists-45xqhu`.

## Owner has ONE thing to run

`backend/public_liked.sql` — Supabase dashboard → SQL Editor → New query →
paste → Run. Safe to re-run. **Until it runs, every profile's LIKED list
shows empty**, including real creators who have saved things.

`backend/public_lists.sql` is already run and verified live (25 makers all
emit `userId`; 6 real accounts, 19 nulls; 985 tours intact).

## What shipped

**Lists on other people's pages.** The blocker was one missing field: lists
are filed under an **auth account id**, and the creator profile the app
holds carried none. Three links now exist —
`get_catalog()` emits `makers.user_id` → `Maker.userId: UUID?` →
`TourListService.publicLists(ofUser:)`.

**⚠️ `Maker.userId` must stay optional.** The gh-pages mirror and the
bundled offline seed are generated from `Tours.json`, which has no such
column, and both must keep decoding. Nil means "no lists" — correct for the
19 Atlas studios, which carry `user_id = NULL` by design.

**⚠️ Checked before shipping: `seed_from_toursjson.py` does not name
`user_id`.** If it ever does, the next content merge will null out every
real user's link to their maker row and silently break lists, follows and
the profile. Re-check if that script grows a maker column.

**Visibility defaults flipped.** `journeys.is_public` now defaults to
`true`, and every existing list was flipped visible — explicitly requested,
and one-way. **Disclosed to the owner that the flip touched two accounts,
not just theirs**: 3 lists total ("Upper West Side"; "Brooklyn" + "BK").
The editor toggle now reads **"Only me"** rather than "Public", matching how
the owner describes it.

**LIKED on every profile, Atlas studios included.** Owner: *"each user
should have a default 'LIKED' list, even if it's empty"* and *"an atlas
studio should be treated as a regular user."* A page without it read as
broken rather than empty — that was the **black square** in the device
review of 1.1 (54). An Atlas studio's LISTS tab holds an empty Liked and
fills in on its own when those accounts get emails backfilled; **no code
change needed then**.

**⚠️ Reading someone else's Liked needed a server path, and the shape of it
matters.** Liked is backed by `LibraryStore` (UserDefaults) precisely so
saving works signed out, and that store only ever holds *yours*.
`liked_tour_ids(p_user)` is `SECURITY DEFINER`, which makes its body the
security boundary — so it is deliberately tiny: one table, one filter, one
column out. **Downloads, playback progress and completion sit in the same
`user_library` row and are not returned.** Do not widen it to `select *`.

**Key badge** (`OnlyMeBadge` in `TourListRows.swift`) on the cover of a list
only its owner can see — same job the `WALK` pill does on the maker feed. It
needs no "is this mine" condition: a list you can see that is marked private
is by definition your own.

**MAP with nothing on it** now draws the world centred on the Atlantic
(`MakerMapSection.worldRegion`), not a grey box. Span is deliberately past
what Mercator can draw so MapKit clamps to fully zoomed out.
`initialRegion(for:)` became non-optional as a result.

**LIKED is permanent by construction** and that is now written into
`LikedListView`'s doc comment, where someone might otherwise "fix" it. It is
not a `journeys` row with its controls hidden — there is no row to delete
and no editor to open. The moment Liked becomes a real list, an un-save
stops being the only way to remove a save, which is the rule the whole
saving design rests on.

## Two things worth carrying

**I told the owner this needed no backend work. That was wrong.** `userId`
came from an exploration report describing `MakerRow` — the *private
Supabase DTO* inside `MakerProfileService` — not the `Maker` the app
renders. Caught before code depended on it, but the lesson is that a
report's field list describes whatever type it was looking at, and there
were two types with that field name.

**The owner couldn't follow my explanation** — *"i'm really not
understanding what you're saying"*. I had said "this needs a backend
change". The plain fact was **"the app doesn't hold their account ID"**.
Lead with the fact, not the category of work.

## Files

New: `backend/public_liked.sql`.
Modified: `Models/Maker.swift`, `Data/TourListService.swift`,
`Data/MakerProfileService.swift`, `Features/Maker/MakerView.swift`,
`Features/Maker/MakerMapSection.swift`,
`Features/Library/TourListRows.swift`,
`Features/Library/LikedListView.swift`,
`Features/Lists/TourListDetailView.swift`,
`Features/Lists/TourListEditorSheet.swift`,
`Features/Profile/ProfileView.swift`, `backend/schema.sql`,
`backend/journeys.sql`, `backend/public_lists.sql`.

## Device review, riskiest first

1. **Another creator's page** → LISTS shows their Liked, then their visible
   lists, **no** New list row and no edit controls inside a foreign list.
2. **An Atlas studio** → all three tabs; LISTS holds an empty Liked; no crash
   (this is the nil-`userId` path).
3. **Your own profile** → unchanged: New list, Liked, your named lists.
4. A list marked **Only me** wears the key badge; a shared one doesn't.
5. **MAP on a maker with no tours** → world view centred on the Atlantic,
   pannable.
6. **Signed out** → a public page's lists still load (RLS allows `anon`).
7. Light **and** dark.

## Still deferred

- Saved tours layered on the map — treatment approved (solid brass dot vs
  hollow ring, so it survives greyscale and colour-blindness); only the
  colour and the timing are open.
- Shared / Only-me **follower** visibility for private accounts.
- **Private-hides-everything.** Its own project — it collides with the
  single public catalog. See CLAUDE.md § "Private should hide everything".
- The rest of the owner's *"lots to do"* maker-page list, still undescribed.
