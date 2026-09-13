# Account deletion: three Supabase/Apple setup steps, then a throwaway test

_opened 2026-09-13 · clear with `git rm status/owner/account-delete-setup.md`_

**Built, not live.** The app half ships in a TestFlight build; the server half needs three dashboard steps from you, hand-held in `docs/account-deletion.md` § Owner setup — Claude pastes each block into chat:

1. **SQL Editor:** run `backend/account_deletion.sql`. Deletes nothing when run; ends with a receipt row (`anon_can_run = false`, `signed_in_can_run = true`).
2. **Edge Functions:** deploy `delete-account` (Verify JWT ON).
3. **Apple (recommended):** create a "Sign in with Apple" key and add `APPLE_SIWA_KEY` + `APPLE_SIWA_KEY_ID` as function secrets, so Apple accounts get their tokens revoked as Apple requires.

Then test on TestFlight with a **throwaway** account only.

🔴 Until steps 1–2 are done, tapping Delete account in the app fails with a "please try again" message — it cannot delete anything half-way, because nothing server-side exists to call.

Clears when all three steps are done and a throwaway deletion has been checked.
