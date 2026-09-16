# REGRESSION FIXED (mine, from #929): the Generator self-tests step ran unconditionally while its dependency install was gated on 'is a rebuild owed?'. So every content merge that changed no embedded text failed with 'FAIL numpy available' - three merges (771d4ac4, 2dc80d48, c4d1c79a) before it was noticed. The self-test was right to fail; the workflow was wrong to run it without numpy. Now gated identically. Mirror and Supabase were never affected because publish/seed carry if-not-cancelled.

_2026-09-16 20:08 UTC · branch `selftest-gate-pxuxdh`_
