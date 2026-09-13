# Account deletion wrap-up: function redeployed, #864 merged, nothing owed

_2026-09-13 16:53 UTC · branch `account-delete-wrapup`_

**Account deletion: wrap-up, nothing left owed** (2026-09-13).

- Owner **redeployed** `delete-account` without the catalogue rebuild step. Re-checked live: gateway 401 with no auth, the function's own 401 for a non-user.
- [#864](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/864) merged → `27cd8c6c`, all checks green.
- Handoff `archive/HANDOFF-260913-account-delete.md` corrected: setup no longer owed; the rebuild note now matches the owner's 'next content publish' decision.
- ⚠️ Still unexercised: Apple token revocation, and the redeployed code on a real deletion. The next deletion's log should show only `account deleted`.
