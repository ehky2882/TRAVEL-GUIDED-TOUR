# HANDOFF 2026-08-19 — keeping and sending a list

Session 94. **[PR #517](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/517)**,
branch `claude/maker-page-playlists-45xqhu` (restarted off `main` — its previous
PR #462 had merged). **TestFlight 1.1 (74)**, notes attached, awaiting device
review. **No SQL for the owner.**

Two asks, one PR:

1. *"for a public profile. i want to be able to save a playlist"*
2. On the mockup: *"think there should be a '...' menu. a playlist should be able
   to be shared also."*

## The thing worth knowing before touching lists again

**`saved_journeys` and `get_journey` had existed, unused, since session 59.**
The table, its RLS policy and the RPC were all written and granted to `anon`
when Journeys first shipped, and neither had ever been called from Swift. This
whole feature needed **no schema change** as a result.

**Read `backend/journeys.sql` before building list plumbing.** Verify against
the live database rather than assuming — both were confirmed with curl before
any Swift was written.

## A saved list is a reference, and the hidden case is the subtle one

The owner still owns it. It can gain tours, be renamed, be hidden or be deleted,
and the saver sees all of that.

**If an owner flips a saved list to Only me,** RLS returns a null embed and the
row drops out of the saver's Library — **but the save row is kept**. Deleting it
on the owner's behalf would be wrong: re-sharing should bring it back. A list
genuinely deleted takes the save with it via the existing cascade.

That is why **`savedListIds` is tracked separately from `savedLists`**: a list we
can no longer render is still saved, its bookmark must stay filled, and
un-saving must still work. `hasLoadedSaves` distinguishes "no saves" from
"haven't looked yet" so a list-detail open doesn't re-query on an empty set.

## Decisions

- **Saved lists get their own section**, below your own and above Following, in
  **both** Library and the profile LISTS tab. One flat column would put *delete
  this list* and *remove my save* a gesture apart, looking identical.
- **Owner's name in the subtitle**, resolved through `Maker.userId` against the
  in-memory catalog — no extra query (`TourListOwner.name(of:in:)`).
- **⚠️ Saving can't work signed out.** `saved_journeys` is keyed on the account,
  unlike `LibraryStore`, which is precisely why Liked works signed out. Save is
  **absent** rather than present-and-failing, matching the Follow button. Share
  stays, since it needs no account.
- **One `…` menu, Share first on both.** Yours: Share · Edit details · Edit
  tours · Delete. Theirs: Share · Save to your lists · Go to creator. Neither
  offers an item that would fail.
- **🔴 A list marked Only me has nothing to share.** Its link opens an empty
  screen for the recipient, so Share becomes a prompt offering to make it
  visible first. Changing who can see a list is a real decision, asked plainly
  rather than folded into a share flow.

## Receiving a link — three pieces

- **`DeepLink.list`** on `/l/` and `dozent://list`. ⚠️ The single-letter markers
  (`t` / `m` / `l` / `g`) are matched as **whole path components**; a test pins
  that, because a substring match would route every link containing an "l".
- **`TourListService.list(byId:)`** finally calls `get_journey`. SECURITY
  INVOKER, so RLS decides. **Gone, hidden and never-existed are deliberately
  indistinguishable** — saying which would itself leak something.
- **Presented as an ordinary sheet with its own nav stack**, not the UIKit
  slide-up layer tours and makers use: a shared list arrives with no screen
  behind it to slide over.

## gh-pages

`/l/index.html` is **live** (gh-pages `9f9b854`), mirroring `/t/` and `/m/`.
Lists aren't in `Tours.json`, so it calls `get_journey` with the same publishable
key the app uses; RLS still applies, so a hidden list renders "List not
available" there too. Tour titles come from the catalog — if that fetch fails
the list still renders, just without its rundown.

Verify with a real link:
`https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/l/?id=68fa8623-5c2a-4229-9edb-cc6a18c8b273`

## 🔴 Found while checking this, NOT caused by it

**No `apple-app-site-association` is served from gh-pages at all** — root and
`.well-known/` both 404. **Universal Links therefore do not open the app today,
for tours and creators either**; only the `dozent://` scheme does. Every share
link in the app is affected. Should be fixed before launch, as its own job.

Also noted: **`/g/` (Group Listen join) has no landing page** — a scanned QR
opens a 404 in a browser if the app isn't installed.

## Process notes

- **The owner reported CI red. It was a different branch** —
  `claude/place-cluster-counts` from a parallel session, green again on its next
  run. PR #517's own checks were all green. The repo-wide Actions tab mixes every
  session's branches; **read the PR's checks page**.
- **The mockup loop settled the design in one round again.** The first pass
  shipped a bookmark-only toolbar button; the owner looked at it and asked for a
  menu. Artifact: `https://claude.ai/code/artifact/4deea15b-e7c2-4f91-bf9f-557521222bd4`
- The branch was **restarted from `main`** rather than reusing merged history,
  per the merged-PR rule. Its remote had already been auto-deleted, so the
  force-with-lease push failed with "stale info" until the local tracking ref was
  pruned — that is the deletion, not a conflict.

## Device review

1. Another creator's list → `…` → Share; then Save to your lists.
2. Library → Lists → **SAVED LISTS** with their name; same on your profile.
3. Tap Save again → gone from both.
4. Your own list → `…` → Share / Edit details / Edit tours / Delete all work.
5. Mark a list **Only me** → Share → the warning and the offer appear.
6. An Atlas studio → three tabs, empty Liked, no crash.
7. Signed out → Share present, Save absent.
8. Light **and** dark.
