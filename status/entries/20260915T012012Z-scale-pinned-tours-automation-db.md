# Phase 0 done: seed writes 14,176 rows -> 0; rev sequence; conditional snapshot rebuild

_2026-09-15 01:20 UTC · branch `scale-pinned-tours-automation-db`_

**Phase 0 of the delta-fetch design is DONE** (`docs/delta-catalog-fetch-design.md` § 6),
across `9d63cb8`, `dd69f0d`, `0b18e84`, `e32b0d0`. Backend generator + one migration
+ a new test. **No app code, no catalogue change, and nothing for the owner to paste** —
the seed applies its own schema idempotently.

**Measured, second seed, byte-identical input:**

| table | before | after |
|---|---|---|
| tours | upd=5,215 | **0** |
| makers | upd=424 | **0** |
| places | upd=303 | **0** |
| stops | 4,117 ins + 4,117 del | **0** |

**14,176 row writes per seed → 0.** At ~5.2 seeds/day that is ~73,700 no-op row
versions a day off the instance that OOM'd for ~11h45m on 2026-09-14. An unchanged
seed now also **skips the ~8 MB snapshot rebuild and leaves `refreshed_at` alone**,
so it no longer tells every phone to re-download 2.4 MB for nothing.

🔴 **The stops fix needed NO migration, against the design doc's expectation.**
Deleting by **`(id, "order")` pair** instead of by `id` removes the
`unique (tour_id, "order")` collision by construction, so the constraint never
needs deferring. Proven: a deliberately naive id-only delete fails with
`duplicate key value violates unique constraint "stops_tour_id_order_key"` —
**while still passing the "writes nothing" check**, so it would have shipped
looking correct and broken on the first stop reorder.

⚠️ **Deviation from the doc, deliberate:** it proposes moving the snapshot refresh
OUTSIDE the seed transaction. Not done. That gain was releasing row locks during the
rebuild, worth something at 14,176 writes and nothing at zero; the cost is a seed
that commits while the rebuild fails, leaving the tables ahead of what the app is
served, silently. Made it **conditional** instead — same intent, keeps atomicity.

**New: `backend/test-seed.sh`** — seeds a throwaway Postgres twice and reads
`pg_stat_user_tables` (comparing values cannot see a row written twice back to the
same value, which is what the old `place_id` reset did), then mutates the catalogue
three ways and proves reorder / removal / edit all still land. Both controls verified
to FAIL.

⚠️ **NOT verified: nothing has run against production.** No database was reachable
from the session container. Everything ran against throwaway PostgreSQL 16 clusters
built from the repo's own schema. **`postgresql` is now installable in a web session
(`apt-get install -y postgresql`), so `backend/test-migrations.sh` runs there too.**

**Next (Phase 1, 1–2 days, still no app release):** `get_catalog_since(rev)`.
