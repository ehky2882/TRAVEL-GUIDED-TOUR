# Account deletion: Apple key secrets added; function re-verified live

_2026-09-13 15:54 UTC · branch `account-self-delete`_

**Account deletion: Sign in with Apple secrets added** (owner, 2026-09-13).

- Owner created a Sign in with Apple key on primary App ID `CPC7M72JTP.com.ehky.TRAVEL-GUIDED-TOUR` and added `APPLE_SIWA_KEY` + `APPLE_SIWA_KEY_ID` as Edge Function secrets.
- Re-checked live afterwards: `delete-account` still returns its own 401 "Please sign in again" to a non-user, so nothing broke.
- ⚠️ **Not yet proven:** that the key actually revokes Apple tokens. Only a real deletion of a Sign in with Apple account exercises it; the result shows in the function's logs as `apple: revoked` or `failed: …`.
- **Still owed:** a throwaway-account deletion on TestFlight 155. `status/owner/account-delete-setup.md` stays open until then.
