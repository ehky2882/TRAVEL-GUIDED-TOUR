# Supabase unreachable (HTTP 522) since 01:18 UTC 14 Sep; seed of #881/#882 owed

_opened 2026-09-14 · clear with `git rm status/owner/supabase-unreachable-260914.md`_

Since **01:18 UTC on 14 September** every request to the Supabase project times out: the catalogue RPC and the auth health check return **HTTP 522** (Cloudflare cannot reach the host), and the seed job's database connection times out. Supabase's public status page shows no matching incident, and the egress grace period was due to end on 13 September, so the project may be restricted.

**Owner:** open the Supabase dashboard and check whether project "Dozent" is paused, restricted or over quota.

- **Owed when it is back:** the catalogue seed for #881 and #882 (32 coordinate fixes). A session was probing every 2 minutes and re-running the failed seed on recovery; if that session has ended, re-run the latest failed `publish-catalog.yml` run (its seed job checks out `main`, so it applies everything).
- **Meanwhile:** the app falls back to the gh-pages catalogue mirror, which already carries the fixes. Sign-in and account features are down with Supabase.

Clear with `python3 scripts/status.py --clear-owner supabase-unreachable-260914` once the seed succeeds.
