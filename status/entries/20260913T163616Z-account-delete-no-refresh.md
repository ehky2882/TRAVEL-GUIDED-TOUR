# Account deletion: function stops rebuilding the catalogue (timeout); next publish rebuilds it

_2026-09-13 16:36 UTC · branch `account-delete-no-refresh`_

**Account deletion: the function no longer rebuilds the catalogue** (owner decision, 2026-09-13).

- **Cause, from the function's own log:** `catalog snapshot refresh failed 500 {"code":"57014", … "canceling statement due to statement timeout"}`. The rebuild runs longer than Supabase allows one API request. The same log line showed the deletion itself was fine: `account deleted { removedTours: 0, keptTours: 0, filesRemoved: 0, apple: "no code sent" }`.
- ⚠️ **My first theory was wrong, and was caught before any change was made.** The owner's `pg_has_role('service_role','anon','member')` returned `false`, but that is beside the point: `SET ROLE` checks the session user (PostgREST's `authenticator`, already a member), not `service_role`. No grant was pasted.
- **Owner chose "next content publish"** over a daily scheduled rebuild (~2.3 MB per phone per day) and raising `service_role`'s statement timeout. `publish-catalog.yml` rebuilds as the database owner with no limit; it ran 10× in the last day, with gaps up to ~7 h, but has no schedule.
- **Owner action owed:** redeploy `delete-account` with the updated code. Until then every deletion still succeeds but logs that harmless error.
