# Merged #853: in-app account deletion

_2026-09-13 16:22 UTC · branch `account-delete-merged`_

**Merged: [#853](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/853) → `0438466f`** (owner OK 2026-09-13, after trying TestFlight 155 and deleting a throwaway account).

- All checks green at merge: Account deletion (SQL + Edge Function), Build (iOS Simulator), Run unit tests, Validate Tours.json, Vercel. GitHub deleted the branch on merge.
- In-app account deletion now ships with the next App Store build cut from `main`. The server half (SQL function, `delete-account`, Apple key secrets) is already live.
- 🔴 **Still open:** the catalogue snapshot is not rebuilt after a deletion. Suspected cause: `service_role` is not a member of `anon`, which `refresh_catalog_snapshot()`'s role switch needs. Waiting on the owner's read-only `pg_has_role` check before proposing a one-line grant.
