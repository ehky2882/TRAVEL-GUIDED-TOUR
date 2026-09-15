# Paste backend/catalog_rev.sql into the Supabase SQL Editor

_opened 2026-09-14 · clear with `git rm status/owner/apply-catalog-rev-sql.md`_

# Paste one SQL block into Supabase (Phase 0 of the delta-fetch work)

_opened 2026-09-14 · clear with `git rm status/owner/apply-catalog-rev-sql.md`_

**What it does, in one line:** stops the database rewriting all ~3,700 tours five
times a day when nothing about them has changed.

**Why it matters:** that pointless rewriting is wasted work on the database that
was unreachable for 11h45m on 14 September, and it is also what makes "send only
what changed" impossible — every row currently looks changed, all the time.

**This is safe.** It only ADDS things (one counter, one column on three tables,
some triggers). It does not change what the app downloads, does not remove
anything, and can be pasted twice with no harm. It checks its own work before
saving and refuses to finish if anything is wrong.

**Steps:**
1. Supabase dashboard → project **Dozent** → **SQL Editor** (left sidebar) → **New query**.
2. Paste the contents of `backend/catalog_rev.sql` — ask any Claude session to
   paste it into chat for you, or copy it from
   https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/blob/main/backend/catalog_rev.sql
3. Press **Run**. It should finish in a few seconds and print a line ending
   `verified — no-op held at rev N, a real change advanced it.`
4. Tell a session it is done, and they will merge the PR that goes with it.

⚠️ **Order matters, slightly.** Paste this FIRST, then merge the PR. The other
way round still works, with one exception: until this is applied, reordering the
stops of a walk would fail the content seed. Nothing else is affected.

**If it errors:** paste the error message into a session. Do not re-run blind —
though re-running is itself harmless.
