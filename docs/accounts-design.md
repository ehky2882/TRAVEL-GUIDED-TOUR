# Accounts, auth & maker self-serve design (V2 Step 3)

Status: **design + SQL** (2026-06-21). Builds on the catalog backend foundation
([`backend-design.md`](backend-design.md), PR #218). The SQL lives in
[`../backend/accounts.sql`](../backend/accounts.sql) and runs **after**
`backend/schema.sql`. No app code yet — the app-side wiring is later Mac work.

## Why
The catalog foundation made content server-backed. This step adds **identity**:
who a user is, so that (a) outside makers can own and author tours, and (b) consumers
can sync their library across devices. It's the gate the whole maker platform and all
consumer-account features depend on. Sequence (from ROADMAP "Maker platform"):
**backend → auth + moderation → maker UI.** This is the "auth + moderation" middle.

## Owner decisions (2026-06-21)
- **Makers are self-serve.** Any signed-in user can create one maker profile and author
  tours. No application/approval gate to *become* a maker — control is at publish time.
- **Sign-in: Apple + email + Google** from launch.
- **Consumers get accounts now.** Optional sign-in syncs library / saved makers / recent
  searches / recently viewed across devices. Anonymous use still works fully on-device.

## Auth
Supabase Auth (GoTrue) with three providers — **Sign in with Apple** (the spec's primary
primitive; required by Apple when any third-party sign-in is offered), **email/password**
(useful for the future web Atlas Studio), and **Google**. Provider setup is console/config,
not SQL:
- Apple: Services ID + key in Supabase Auth → Providers.
- Google: OAuth client ID/secret.
- Email: enable confirmations.

Every successful sign-in yields a row in `auth.users`. A trigger
(`handle_new_user`) auto-creates a matching `public.profiles` row, pulling
display name / avatar from the provider metadata when present.

## profiles
1:1 with `auth.users`, for **every** signed-in user (consumer or maker):
`id` (FK to auth.users), `display_name`, `avatar_url`, `is_admin`, timestamps.
- `is_admin` marks the Atlas moderation team. A trigger
  (`protect_profile_admin_flag`) prevents a non-admin from ever setting their own
  `is_admin` — it can only be granted directly (service role).
- RLS: a user reads/updates only their own profile; admins read all.
- A maker's *public* identity stays in the existing `makers` row (public-read);
  `profiles` is private.

## Maker self-serve
`makers` already has `user_id` (from the foundation). This step adds:
- A partial unique index so each real user owns **at most one** maker
  (`user_id` unique where not null — the Atlas-owned studios keep `user_id = NULL`).
- RLS write policies: a user may insert/update a maker row where `user_id = auth.uid()`.
- Tour/stop ownership via helpers `owns_maker(maker_id)` / `owns_tour(tour_id)`
  (SECURITY DEFINER so they don't recurse through RLS).

## Moderation lifecycle
Uses the foundation's `tour_status` enum: `draft → in_review → published / taken_down`.
- A maker can **create/edit** tours and stops they own, but only in a non-published
  status — **publishing is admin-only** (`tours_admin_all`). The app submits a finished
  tour with `status='in_review'`; editing an already-published tour is submitted with
  `status='in_review'` too, sending it back through review.
- The **moderation queue** is simply `tours.status = 'in_review'` (exposed as the
  `moderation_queue` view); admins see all tours regardless of status and publish by
  setting `status='published', published_at=now()`.
- **report-a-tour:** a `reports` table (reason/details/status); anyone (anon or
  signed-in) may insert; only admins read/triage. Backs the consumer "Report a concern"
  action already stubbed in the tour-detail overflow menu.

## Consumer account sync
Server mirrors of the on-device stores, each keyed by `user_id` with own-row-only RLS:
- `user_library` (saved/downloaded/listened_seconds/last_listened_at/completed_at) —
  mirrors `LibraryStore` / `LibraryEntry`.
- `user_saved_makers`, `user_recently_viewed`, `user_recent_searches`.
**Model: offline-first, last-write-wins.** The local stores stay the source of truth
while offline; on sign-in the app reconciles by `updated_at`/timestamps and then keeps
both in sync. Signed-out users are unaffected — everything works locally as today.

## RLS model summary
| Table | anon | signed-in user | maker (owner) | admin |
|---|---|---|---|---|
| `makers` | read | read | read + write own | full |
| `tours` | read published | read published | read/write own (non-published) | full incl. publish |
| `stops` | read (published tours) | read (published) | read/write own | full |
| `profiles` | — | read/update own | (same) | read all |
| `user_*` sync | — | read/write own | (same) | (same) |
| `reports` | insert | insert | insert | read/triage |

## App-side work (later, on a Mac — not in this step)
- **First third-party dependency:** add **supabase-swift** (auth + PostgREST + storage
  client). V1 was Apple-frameworks-only; this is the deliberate V2 exception (implied by
  choosing Supabase). Alternative: hand-rolled GoTrue REST + `AuthenticationServices`
  for Apple — heavier, not recommended.
- **Sign-in UI** in the "Me" tab (replaces the placeholder entry): Apple / Google / email.
- **Consumer sync:** wire `LibraryStore` / `RecentSearchStore` / `RecentlyViewedStore` /
  saved-makers to push/pull against the `user_*` tables when signed in (offline-first).
- **report-a-tour:** wire the existing overflow-menu action to `insert into reports`.
- **Maker dashboard UI is OUT of scope here** — that's the spec's Phase 1/2 maker-platform
  work (recording, pinning, transcript, metadata editor), a separate later step that
  *builds on* this schema.
- All gated: `test_sim` + simulator review before merge (touches `Data/` + new UI).

## Dependencies & sequence
Depends on the catalog foundation (#218). Precedes the maker-dashboard UI and Tier-2
monetization. **Out of scope (forward-design, later tiers):** `purchases` (Apple IAP),
`payout_accounts` (Stripe Connect), `analytics_events`, follow-a-maker push.

## Verification
- **SQL applies clean** after `schema.sql` on a Supabase project (no Postgres on the
  web session — owner-side).
- **RLS checks** (run as different roles / JWTs):
  - anon: can read only published tours; cannot read any `user_*` row or `reports`.
  - user A: cannot read user B's `user_library`; can insert a `reports` row.
  - maker: can insert a tour only with status `draft`/`in_review`; an `update … set
    status='published'` is rejected by RLS.
  - admin: can set a tour to `published`; `moderation_queue` lists `in_review` tours.
  - signup: inserting an `auth.users` row auto-creates a `profiles` row.
- **App end-to-end** (Mac): sign in with each provider → library saved on device A
  appears on device B; sign out → local-only still works.
