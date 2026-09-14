# Supabase back after 11.5 h; coordinate fixes seeded and verified live

_2026-09-14 13:06 UTC · branch `board-supabase-recovered-260914`_

Supabase answered again between **12:44 and 13:00 UTC on 14 September**, after about 11.5 hours of HTTP 522 (from 01:18 UTC). The cause was never confirmed.

- The failed catalogue seed was re-run (publish run 34838244837, the #885 merge; the job checks out `main`, so it applied everything merged during the outage) and **succeeded**.
- Verified by reading back from the live API, not from the job: Park Avenue Armory, Egyptian Theatre, Edifício Copan, Boulders Beach and the Saigon cathedral at their repaired coordinates; Square Saint-Louis place moved; Hackesche Höfe place gone; `catalog_snapshot_age` 13:01:41 UTC.
- Owner item `supabase-unreachable-260914` cleared.
