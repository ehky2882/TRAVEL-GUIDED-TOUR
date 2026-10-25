# Paste one line of SQL so sign-up can check usernames

_opened 2026-10-25 · clear with `git rm status/owner/handle-available-anon.md`_

# Let sign-up check whether a username is free (one-line SQL paste)

The onboarding sign-up form asks the database whether a username is taken.
The database only answers signed-in people, and someone signing up is not
signed in yet, so the check gets "permission denied" and never says "taken"
(verified on the live database, 2026-10-25).

**Paste this into the Supabase SQL Editor and press Run:**

```sql
grant execute on function public.handle_available(text) to anon;
```

Expected result: "Success. No rows returned."

Safe: with nobody signed in the function can only answer available / taken /
reserved / invalid, and usernames are already public on every profile.
Source: backend/handle_available_anon.sql.

Clear with: python3 scripts/status.py --clear-owner handle-available-anon
