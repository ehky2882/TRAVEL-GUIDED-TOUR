# Phase 1 delta RPC open as #912; stop-reorder claim retracted

_2026-09-15 13:03 UTC · branch `catalog-since-delta-rpc`_

**Phase 1 is open as [#912](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/912)**,
rebased onto #904's Phase 0 on branch `claude/catalog-since-delta-rpc`. Four files:
`backend/catalog_since.sql`, `backend/test-catalog-since.sh`, and the two checkers.
**Nothing #904 shipped is touched.**

`get_catalog_since(rev)` **filters the snapshot `get_catalog()` already serves** rather
than shaping rows, which is what satisfies the "one shaper, not two" constraint *by
construction*. Measured: **139 bytes** when nothing changed, **1,952** for a three-row
change against 954,218, and **every delta row byte-identical** to the full catalogue's
row for that id across all four sections — with that assertion proven able to fail.

⚠️ **The adaptation that mattered:** my original version queried `stops.rev`. Main's
`catalog_rev.sql` has **no rev on stops** — a trigger bumps the **parent tour's** rev on
stop insert/update/**delete** instead. That is better than what I wrote (it catches stop
deletions, which a stops-rev query cannot) and the RPC now relies on it.

🔴 **RETRACTED: the stop-reorder crash I reported earlier does not reproduce.** I claimed
#904 crashes the seed on any stop reorder, on the strength of a failure in a harness of my
own making. Main's `test-seed-idempotence.sh` — testing main's code, byte-identical to
what I tested — passes both its own "stop inserted mid-walk" case **and a reversal case I
added specifically to break it**, against a target tour of ≥4 stops. The owner item was
deleted and no PR was opened. **The lesson: when a test already covers the area, run the
claim through THAT test before reporting it.**

⚠️ **This session also duplicated Phase 0 before noticing #904 had shipped it.** Those
commits live on `claude/scale-pinned-tours-automation-dba3lx` and **must not be merged**.
#904's `upsert_tail` — generating the `set` and the `where` guard from one list, so they
cannot drift — is better than what I wrote.

⚠️ **Corrections that stand:** the live database **is** reachable from a web session via
the anon key in `SupabaseConfig.swift` (verified: `catalog_snapshot_age`, `tours.rev`
present, `get_catalog_since` → 404). **PostgreSQL installs here** (`apt-get install -y
postgresql`), so `test-migrations.sh` and all the seed tests run in a web session — earlier
claims that SQL work needs a Mac are wrong. 🔴 **Do not run `check-catalog-contract.py`
casually — it pulls the full 2.4 MB.**
