# Supabase unreachable (HTTP 522) since 01:18 UTC 14 Sep; catalogue seed owed

_opened 2026-09-14 · clear with `git rm status/owner/supabase-unreachable-260914.md`_

Since **01:18 UTC on 14 September** every request to the Supabase project times out: the catalogue RPC and the auth health check return **HTTP 522** (Cloudflare cannot reach the host), and the seed job's database connection times out. Supabase's public status page shows no matching incident.

🔴 **The egress-restriction theory is WRONG — do not repeat it.** This file
originally guessed the project had been restricted because the egress grace
period ended on 13 September. **The owner confirmed on 14 September that they
upgraded to Pro on 10 September**, four days before the outage, so that grace
period could not have applied. Two sessions reached the same wrong conclusion
from the dates alone.

**What the evidence actually says.** The failure *decayed* rather than flipping:

| Time (14 Sep) | State |
|---|---|
| 01:07 UTC | `get_catalog` → **57014 statement timeout** — queries ran, too slowly to finish |
| 01:18 UTC | **522** on everything |
| 12:44 UTC | still **522**, 11½ hours in |

An administrative restriction takes effect at once. Slow → timing out → refusing
connections is the shape of a **resource being exhausted** — a full disk, or
compute wedged — which on Pro is a support case, not a billing one.

**Owner, in this order:**

1. **Open a Supabase support ticket.** The project is on **Pro**, which includes
   email support, and a paid project unreachable for 11½ hours warrants one.
   This is the step most likely to actually fix it.
2. Dashboard → **Database → Disk usage**, and the project's **Reports /
   Observability** (CPU, memory, disk IO). A full disk makes Postgres refuse
   connections exactly like this.
3. Check whether the project page offers a **Restore / Resume** button — an
   instance can sit stopped even once the reason is gone.

- **Owed when it is back:** the catalogue seed for #881 and #882 (32 coordinate fixes), **#886 (34 link pins) and #885 (38 link pins)**. A session was probing every 2 minutes and re-running the failed seed on recovery; if that session has ended, re-run the latest failed `publish-catalog.yml` run (its seed job checks out `main`, so it applies everything).
- **Meanwhile:** the app falls back to the gh-pages catalogue mirror, which already carries the fixes. Sign-in and account features are down with Supabase.

Clear with `python3 scripts/status.py --clear-owner supabase-unreachable-260914` once the seed succeeds.
