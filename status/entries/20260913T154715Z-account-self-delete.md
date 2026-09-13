# Account deletion server half live: SQL applied + delete-account deployed, both verified

_2026-09-13 15:47 UTC · branch `account-self-delete`_

**Account deletion: server half is live** (owner, 2026-09-13, hand-held).

- **SQL applied:** `delete_my_account_content()`. Owner's receipt row was `true | false | true | true`. Independently re-checked live: an anonymous RPC call returns **42501 permission denied** (HTTP 401).
- **Edge Function `delete-account` deployed.** Checked live beforehand that no function of that name existed (404). Afterwards: no auth header gives gateway 401 `UNAUTHORIZED_NO_AUTH_HEADER`; the publishable key as bearer gives the function's own 401 "Please sign in again", which proves the deployed code is ours and that it refuses a non-user.
- **Still owed:** the Sign in with Apple key + secrets (step 3), then a throwaway-account deletion on TestFlight 155. `status/owner/account-delete-setup.md` stays open until then.
