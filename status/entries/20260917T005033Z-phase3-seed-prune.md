# Phase 3, server half: seed_from_toursjson.py now PRUNES tours and pins that left the catalogue. The guard keys on the MAKER, not the tour — status is not a discriminator (all 4,382 live rows are 'published'), but a seeded tour always belongs to a catalogue maker and an in-app upload never does. Deletes 0 rows today. Two ceilings: a 1000-entry input floor that refuses a truncated catalogue, and a 300-row check inside the transaction. Client reconciliation still to build.

_2026-09-17 00:50 UTC · branch `phase3-seed-prune`_
