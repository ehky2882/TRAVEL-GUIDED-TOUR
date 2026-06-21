# Moderation design (V2 Step 5, minimal)

Status: **design + code** (2026-06-21). Builds on the accounts/auth layer
([`accounts-design.md`](accounts-design.md), #220), which already has the `tour_status`
lifecycle, the `reports` table, the `is_admin()` gate, and the `moderation_queue` view.

## Decision (owner, 2026-06-21)
For now, moderation is **"email me."** No queue UI to build. When a maker submits a tour
for review, or a consumer reports one, **the Atlas team gets an email**; the team then
acts manually. Upgrade to a small web admin tool later if volume grows.

## How it works
1. **Trigger points** (already in the schema):
   - A tour's `status` becomes `in_review` (new submission, or a maker editing a published
     tour, which resubmits as `in_review`).
   - A row is inserted into `reports` (report-a-tour).
2. **Notify** — two Supabase **Database Webhooks** POST the changed row to the
   `notify-moderation` Edge Function ([`../backend/functions/notify-moderation/index.ts`](../backend/functions/notify-moderation/index.ts)),
   which emails the team (Resend in the example; any provider works — only one function
   body changes). The email includes the tour/report details and the exact SQL to act.
3. **Act manually** — after reviewing in Supabase, the team runs a one-liner
   ([`../backend/moderation.sql`](../backend/moderation.sql), admin-gated):
   - `select publish_tour('<id>');` → `status='published'`, sets `published_at`; the tour
     then flows through `get_catalog()` to consumers on their next catalog refresh.
   - `select takedown_tour('<id>');` → `status='taken_down'`.
   Reports are triaged by updating `reports.status` (open → reviewed / actioned / dismissed).

This keeps the whole moderation gate server-side and audited (publish/takedown can't be
done by a non-admin — both the RLS in #220 and these helpers enforce `is_admin()`), while
costing essentially nothing to operate at launch volume.

## Files
- `backend/moderation.sql` — `publish_tour(uuid)` / `takedown_tour(uuid)` admin helpers
  (run after `accounts.sql`).
- `backend/functions/notify-moderation/index.ts` — the email Edge Function.

## Owner setup (when standing up Supabase)
1. `supabase functions deploy notify-moderation`.
2. `supabase secrets set RESEND_API_KEY=… MODERATION_EMAIL=you@example.com FROM_EMAIL="Atlas <moderation@yourdomain>"`.
3. Add two Database Webhooks (Dashboard → Database → Webhooks), both POSTing to the
   function: **tours / UPDATE** and **reports / INSERT**.
4. Run `backend/moderation.sql`.
5. Make yourself an admin once: `update profiles set is_admin = true where id = '<your auth uid>';`
   (run as the service role / SQL editor — the admin flag is self-grant-protected).

## Scope & later
- **In:** email notification on submit/report + admin publish/takedown helpers.
- **Later (only if volume grows):** the small web admin tool (review queue, inline
  audio/photo/map preview, one-click publish/takedown, report triage) — designed against
  the same schema; no migration needed.

## Verification
- **No consumer-app change.** Taken-down / in-review tours are already excluded from
  `get_catalog()` by RLS (#218/#220).
- **End-to-end (owner, on Supabase):** flip a tour to `in_review` → an email arrives;
  `select publish_tour(id)` → it appears in `get_catalog()`. Insert a `reports` row → an
  email arrives. A non-admin calling `publish_tour` gets `not authorized`.
