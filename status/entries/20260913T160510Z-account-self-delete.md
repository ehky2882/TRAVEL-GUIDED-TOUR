# Account deletion verified on device; snapshot refresh finding

_2026-09-13 16:05 UTC · branch `account-self-delete`_

**Account deletion verified end to end on TestFlight 155** (owner, 2026-09-13), with a throwaway email-alias account.

- Owner: sheet over the bottom module, deletion completed, signed out.
- Live checks afterwards (anon, header-only): **0** makers named "Former creator" (the throwaway's creator page was deleted, not left anonymised); **28** makers still owned by a login, same as before the test.
- 🔴 **Finding: the catalogue snapshot was NOT rebuilt.** `catalog_snapshot_age` still read 14:05 UTC, before the function existed. Likely cause: `refresh_catalog_snapshot()` does `set_config('role','anon')`, which needs membership in `anon`; the seed runs as the owner, the function as `service_role`, normally not a member. Not yet confirmed. No leak this time (the throwaway post-dated the snapshot), but a real deleted user's name would stay in the served catalogue until the next seed.
- Apple token revocation remains unexercised (the test used email).
- PR #853: `main` merged in (README index append conflict only), awaiting owner merge OK.
