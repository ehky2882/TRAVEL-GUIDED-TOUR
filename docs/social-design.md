# Social layer — design (V2 batch D)

Status: **design** (2026-07-04). Backend SQL sketched in `backend/social.sql` (not yet applied). App side not started. This is the last of the owner's 11 profile/maker polish notes ("follower function", "public vs private accounts", "friend request auto/manual").

## Owner decisions (2026-07-04)

- **Follow model** (asymmetric, Instagram-style) — *not* symmetric Facebook "friends". You follow a profile; they needn't follow back.
- **New accounts default PUBLIC.** Public = instant follow. Private = each follow is a request the owner approves. This one switch *is* "public/private accounts" **and** "friend request auto vs manual accept" — no separate friend system.
- **v1 scope = the relationship layer:** follow/unfollow, follower + following counts on profiles, followers/following lists, and (private accounts) approve/decline. A **"tours from creators you follow" home feed** is a later extension — it needs no schema change (reads the same `follows` table).

## Why one system covers all three notes

| Note | Covered by |
|---|---|
| follow/followed counts | `follow_state(maker)` → followers + following counts (asymmetric) |
| public vs private accounts | `makers.is_private` — public follows auto-accept, private go `pending` |
| friend request, auto/manual | a `pending` follow on a private account = the "request"; owner approves |

## Data model (`backend/social.sql`)

A profile **is** a maker, so "following someone" = following their `makers` row. Follower = the auth user; followee = a `makers.id`.

- **`makers.is_private boolean default false`** — the privacy switch.
- **`follows(follower_id → auth.users, followee_id → makers, status, created_at)`**, PK `(follower_id, followee_id)`.
  - `status`: `'accepted'` (public followee, or approved) | `'pending'` (private followee, awaiting approval).
  - A `before insert` trigger blocks self-follow and sets `status` from the followee's `is_private`.
- **RLS:** insert as yourself; you can read/delete your own follows (who you follow, your pending requests) and the follows *to* your maker (your followers + requests); the followee-owner can update `pending → accepted` (approve) or delete (decline/remove).
- **Reads via SECURITY DEFINER RPCs** (accurate across RLS, with the public/private visibility rule inside):
  - `follow_state(m)` → `{followers, following, isFollowing, isPending, pendingRequests}` for the current viewer — the one call the maker page needs.
  - `list_followers(m)` / `list_following(m)` → maker rows; **public maker → anyone, private → owner only**.
  - `list_follow_requests()` → the pending followers waiting for the caller.
- **`get_catalog`**: add `'isPrivate', m.is_private` to the makers block (counts stay on the RPCs, not the catalog — profiles are viewed one at a time).

**No denormalized counts in v1** — the RPC counts are always correct and simplest. If maker cards ever need a follower count inline (search/Library), denormalize `follower_count` on `makers` via a trigger then.

## App side (to build, gated by test_sim + sim review)

- **`Models/Maker.swift`**: add `isPrivate: Bool` (optional-decoding safe, default false).
- **`Data/FollowService.swift`** (`@MainActor @Observable`): `state(maker)`, `follow(maker)`, `unfollow(maker)`, `approve(follower:for:)`, `decline(follower:for:)`, `followers(maker)`, `following(maker)`, `requests()`. Follow/unfollow are direct `follows` inserts/deletes (the trigger sets status); counts/lists call the RPCs. Every write is login-only → owner-device-verified, like the rest of Step 3/4.
- **`MakerView` header:** follower / following **counts** (tap → list screens); a **Follow button** with the state machine below. Not shown on your own profile.
- **Own profile:** a **Requests** affordance (badge = `pendingRequests`) → an approve/decline list (private accounts only; hidden when 0).
- **Privacy toggle:** a "Private account" switch — in `ProfileEditorView` or Settings — writing `makers.is_private`.
- **Lists:** Followers / Following / Requests screens reuse the existing maker-row + `MakerAvatarView`.

### Follow button state machine

```
        not following ──tap──▶  (public)  Following   ──tap──▶ not following
                        └─────▶  (private) Requested  ──owner approves──▶ Following
        Requested      ──tap──▶  cancel (delete pending) ──▶ not following
```

- Public followee: `Follow` → instant `Following`.
- Private followee: `Follow` → `Requested` (pending); when the owner approves, becomes `Following`.
- `Following` / `Requested` tap → unfollow / cancel.

## Suggested increments

1. **D1 — foundation + follow/unfollow + counts.** Apply `backend/social.sql` (owner, hand-held). `Maker.isPrivate`, `FollowService`, the Follow button (public path) + follower/following counts on the maker page, and the **Private account** toggle. Ship.
2. **D2 — followers / following lists.** The two list screens off the count taps.
3. **D3 — private requests.** The `Requested` state + the owner's Requests approve/decline screen (+ optional email on a new request, reusing the `notify-moderation` pattern).
4. **Later — following feed.** A Home rail of new/updated tours from creators you follow. Needs feed-ordering decisions; no schema change.

## Open questions for later (not blocking D1)

- Notify on a new follower / follow request? (email now via the moderation-function pattern; in-app notifications are their own feature).
- Blocking / removing a follower — delete is supported by RLS; surface a UI later.
- Follower count on maker *cards* (would need denormalization) — deferred.
