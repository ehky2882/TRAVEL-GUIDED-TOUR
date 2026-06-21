# HANDOFF — 2026-06-21 (session 41, web/PM — V2 backend design)

Bridge note for the next session. Durable detail lives in `CLAUDE.md`
(§ Current State 2026-06-21) and `ROADMAP.md` (§ V2 — execution plan).

## What this session was
Pure **design/PM** session on the Linux web environment — **no Xcode, no Mac,
no Supabase runtime**. So everything produced is docs + non-shipping SQL + one
Edge Function (auto-merge class). **Nothing ships in the app yet.** The work
designs the V2 maker-platform backbone so the eventual app + DB build is
execution against a fixed spec.

## Shipped (all merged to `main`)
- **#218 — Step 2 catalog foundation:** `backend/schema.sql`, `backend/seed_from_toursjson.py`
  (verified 5/307/316 parity), `backend/README.md`, `docs/backend-design.md`.
  Supabase Postgres; `get_catalog()` RPC returns the exact shape `ToursData` decodes.
- **#220 — Step 3 accounts/auth:** `backend/accounts.sql`, `docs/accounts-design.md`.
- **#222 — Step 4 maker dashboard P1 + media storage:** `backend/storage.sql`,
  `docs/maker-dashboard-design.md`.
- **#219 — doc-sync:** catalog counts 300 → 307/5/316.
- **#221 — V2 roadmap:** tracked step plan + recorded owner decisions in `ROADMAP.md`.

## Green-pending at session end (merge on CI green)
- **#223 — Step 4 Phase 2 multi-stop authoring** (`docs/maker-dashboard-phase2-design.md`).
- **#224 — Step 5 minimal moderation** (`backend/functions/notify-moderation/index.ts`,
  `backend/moderation.sql`, `docs/moderation-design.md`).
- **This handoff PR** (CLAUDE.md + archive).
- Repo **auto-merge is OFF** — owner agreed to enable Settings → General → Pull
  Requests → Allow auto-merge; until then these need a manual merge on green.

## Owner decisions captured this session
- Backend = **Supabase (Postgres)**.
- Makers = **self-serve** + **per-tour moderation** (publish is admin-only).
- Sign-in = **Apple + email + Google**.
- Consumer accounts = **now** (optional; cross-device library/saved sync; anon still works).
- Moderation (for now) = **"email me"** on submit/report, act manually; web admin tool later.

## TODO — deferred by owner, REMIND THEM
**2 dead gallery images** found in a 1,460-URL link sweep (heroes are fine):
- **The Oculus** — `additionalImageURLs[1]` (`Oculus_NYC.jpg`, Wikimedia 404)
- **The Charging Bull** — `additionalImageURLs[2]` (`Bowling_Green_td_…Charging_Bull.jpg`, 404)
Fix = remove the two entries, or re-source CC0/PD replacements via the image pipeline.
(Catalog is otherwise clean: no dup ids, no bad coords, no missing fields; gh-pages in sync.)

## Next steps (owner + Mac — NOT doable in a web session)
1. **Stand up Supabase** (free tier): run `schema.sql` → `accounts.sql` → `storage.sql`
   → `moderation.sql` → seed (`backend/README.md`); configure Apple/email/Google
   providers; deploy `notify-moderation` + set Resend secrets + the two DB webhooks;
   make yourself admin (`update profiles set is_admin=true where id='<uid>'`).
2. **App-side (Mac, gated by `test_sim` + simulator review):** add **supabase-swift**
   (first 3rd-party dep — the deliberate V2 exception to "Apple frameworks only"),
   point `RemoteCatalogLoader.remoteURL` at the `get_catalog` RPC, build sign-in UI,
   wire the local stores to the `user_*` sync tables, then the `Features/Maker/` authoring UI.
3. **Step 6 payments** is the next design — blocked on owner calls: pricing model
   (per-tour purchase / subscription / both) and payout processor (Stripe Connect default).
   Apple IAP is mandatory for the consumer purchase side on iOS.

## Branch cleanup (git proxy blocks `--delete` from here — use GitHub UI)
- **Delete (merged):** `claude/backend-foundation`, `claude/accounts-design`,
  `claude/maker-dashboard-design`, `claude/docsync-catalog-307`, `claude/v2-roadmap`,
  `claude/zealous-galileo-86z05a`, and (once their PRs merge) `claude/maker-phase2-design`,
  `claude/moderation-design`, `claude/handoff-260621`.
- **KEEP (unmerged work):** `claude/london-batch3-scripts-260616` (audio-pending staged
  London batch 4 + 5 multi-stop walks), `claude/dreamy-wozniak-tags-260612` (tag taxonomy).

## Tribal knowledge reaffirmed
- This env's **git proxy silently blocks branch deletion** (returns "Everything
  up-to-date") — branches must be deleted in the GitHub UI.
- **squash-merge hides branches from `git branch --merged`** — don't trust it to find
  spent branches; check by PR/known-merge instead.
- No `gh` CLI here — use the GitHub MCP tools. No `send_later`/timed-reminder tool in
  web sessions; durable reminders go in this handoff (read at session start).
