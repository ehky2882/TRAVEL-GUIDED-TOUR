# Supabase returning 522 — primary catalogue unreachable, seed owed

_opened 2026-09-14 · clear with `git rm status/owner/supabase-522.md`_

# Supabase is returning HTTP 522 — the primary catalogue source is unreachable

🔴 **Measured directly, 2026-09-14 01:33 UTC.** Not a slow query — **Cloudflare
522, "the origin web server timed out"**, which means the database itself is not
answering, and the gateway gave up before reaching it.

**Both of these failed, which is what makes it the database rather than one
expensive query:**

| Probe | Cost | Result |
|---|---|---|
| `rpc/catalog_snapshot_age` | 34 bytes | **522** |
| `rest/v1/tours?select=id&limit=1` (row count) | 47 bytes | **522** |

A 47-byte row count cannot time out on query cost. `session-start.sh` reported
this as a **57014 statement timeout** earlier in the same session, so it has
degraded further since.

⚠️ **The app is still serving.** `RemoteCatalogLoader` falls back to the
gh-pages mirror, then the on-disk cache, then the bundled seed — so users are
not seeing an empty catalogue. **This is why it can go unnoticed.**

**What it blocks right now:**

* **`backend/seed_from_toursjson.py` cannot run**, so the 33 link pins merged on
  `claude/new-tour-links-3th96b` reach the gh-pages mirror and **not Postgres**.
  Once it is back, that script must be run or the mirror is newer than the
  primary source.
* `merge-link-pins.py` could not check the 25 new creator handles against
  existing Dozent accounts. It printed `⚠️ COULD NOT CHECK`, which the runbook
  says is **not an all-clear**. Re-run `--check` once the DB answers.

**Only you can look at this** — it needs the Supabase dashboard (project
"Dozent"). Worth checking whether the project has been paused, or whether the
egress/compute limits recorded in `CLAUDE.md` have finally bitten.

_Clear this once the RPC answers 200 again AND `seed_from_toursjson.py` has been
re-run for the pins above._
