# Paste backend/catalog_since.sql into Supabase (#912 merged, RPC still 404)

_opened 2026-09-15 · clear with `git rm status/owner/apply-catalog-since-sql.md`_

**#912 is merged, but the delta RPC is NOT live until you paste this.**
`get_catalog_since` returns **404** in production right now.

**Where:** Supabase dashboard → **SQL Editor** → New query → paste → Run.

**What to paste:** the whole contents of `backend/catalog_since.sql` from `main`.
It is ~157 lines; most of it is comments explaining why it is shaped this way.

**It is safe.** It adds exactly two new functions (`catalog_pick` and
`get_catalog_since`) and **redefines nothing that already exists** — not
`get_catalog`, not `get_catalog_built`, not `get_catalog_core`, not
`get_catalog_core_base`. Re-running it is harmless. There is no `drop`, so the
"destructive operations" warning should not appear; if it does, read what it
names before continuing.

**Afterwards, two checks — in this order:**

1. **Confirm it deployed** (cheap, ~139 bytes):
   ask `get_catalog_since` with a huge cursor and expect an empty envelope
   carrying `rev`, rather than a 404.
2. 🔴 **Then `python3 scripts/check-catalog-contract.py`** — CLAUDE.md Rule 11:
   run it **after** any SQL touching `get_catalog`, never before. ⚠️ It pulls the
   **full 2.4 MB catalogue**, which is this project's actual problem, so run it
   **once** and not casually.

⚠️ **Nothing changes for users until [#914](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/914)
also ships.** The RPC is the server half; the app cannot ask for a delta until the
client half is in a release. Applying this early is still worth it — it makes #914
testable on device, which is otherwise a no-op.
