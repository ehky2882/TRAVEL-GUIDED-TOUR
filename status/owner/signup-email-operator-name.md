# Paste the YY LABS LLC footer into the Supabase signup email

_opened 2026-09-22 · clear with `git rm status/owner/signup-email-operator-name.md`_

# Paste the updated signup email into Supabase

The repo copy of the "Confirm signup" email (`backend/email-templates/confirm-signup.html`)
now says **"Dozent is operated by YY LABS LLC."** at the bottom (was AHWY/EHKY, PR #1064).
**The live email does not change until the new version is pasted into Supabase**, because
the email lives in a box on the Supabase dashboard, not in the repo.

1. Supabase Dashboard → project **Dozent** → **Authentication** → **Emails**
2. Open **Confirm signup** → **Message body**
3. Find the line `Dozent is operated by AHWY/EHKY. © 2026.` near the bottom
4. Change only `AHWY/EHKY` to `YY LABS LLC` → **Save**

To check it: sign up with a spare email address. The confirmation email should end
"Dozent is operated by YY LABS LLC."
