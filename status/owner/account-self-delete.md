# Can a user delete their own account? Apple requires it — and 1.1.2 is a submission candidate

_opened 2026-09-13 · clear with `git rm status/owner/account-self-delete.md`_

🔴 **Found by #844 while checking usernames against industry standards.** Apple's
App Review Guideline **5.1.1(v)** has required since 2022 that any app offering
account creation also let people **start deleting that account from inside the
app**. A search of the app, the backend SQL, the Edge Functions and the website
on 2026-09-12 found no such feature.

⚠️ **Independently re-checked by the coordinator session before this item was
opened** — see the session entry. Treat the conclusion as verified, not relayed.

**Why it is urgent now rather than eventually:** `1.1.2 (152)` is on TestFlight as
an **App Store candidate**. 1.1.0 and 1.1.1 were both approved with accounts
shipping, so Apple has not enforced it here so far — but that is Apple declining
to notice, not permission, and it can surface on any submission.

🔴 **It meets the standing decision head-on.** *"Never delete a user account"*
governs what **we** may do on someone's behalf. Apple's rule is about what **the
account holder** may do for themselves. Those are not in tension, but the
implementation must not become a route for anyone else to delete accounts.

**A decision for you, not a patch:** what deletion should mean here — the account
and its content, or the account with published tours reassigned or retained.
