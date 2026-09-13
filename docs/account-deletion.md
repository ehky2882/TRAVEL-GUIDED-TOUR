# In-app account deletion

Settings → Account → **Delete account**. Built 2026-09-13 on the owner's decision:
*"i think it makes sense to have a way to delete your own account from the app. we should build it."*

## Why

**Apple App Review Guideline 5.1.1(v)**, checked against Apple's live text on 2026-09-13:
*"If your app supports account creation, you must also offer account deletion within the app."*
Apple's support page adds that deletion must be **started** in the app — a link to a website is
acceptable only to *finish* it, never instead of it — and that **apps using Sign in with Apple
should revoke the user's tokens** through Apple's REST API.

## What it does — built to the privacy policy

`site/privacy/index.html` already promised: *"Delete your account and we remove your profile,
synced library and creator content; records we must keep for legal or financial reasons are
retained in minimal form."* That sentence is the specification.

| Removed | Kept, in minimal form |
|---|---|
| Profile and creator page (name, photo, bio, links, username) | Purchase records, with the account removed (`purchases.user_id` → null) |
| Synced library, saved places, lists, listening + search history | **Tours someone bought** — they stay available to buyers, credited to "Former creator" |
| Follows, both directions | |
| **Tours nobody bought**, with their audio and photos | |

**Usernames:** the deleted person's handle is written to `released_handles` and so held for
**30 days** before anyone else can take it (the usernames design's anti-impersonation rule), then
the maker row is deleted or its handle replaced with `former.<id>`.

**Owner decision 2026-09-13 — "Remove unsold, keep sold"**, confirmed a second time the same night
after PR #850 had recorded "unpublish and retain". That alternative was rejected partly because a
`taken_down` tour is hidden from **buyers too** (catalogue builder and tours RLS both filter to
`published`), so it would not have kept their access without new work. The database forces a choice here:
`purchases.tour_id` and `tours.maker_id` are `on delete restrict`, so a bought tour cannot be
deleted. The alternatives were *finish sold cases by hand within 30 days* and *keep every tour
published under the creator's name* (which would break the privacy policy's promise).

⚠️ **A kept tour stays on sale.** New sales of a "Former creator" tour still record a purchase
against the retained maker row, which has no one behind it to pay. On 2026-09-13 no user-created
tour was paid (the only published one is free), so this is a rule for later, not a live case.

## 🔴 Only the account holder can trigger it

The standing decision is that **we never delete a user's account**. This is a person deleting
their own, so nothing in it can name a user:

- `delete-account` reads the user id from the caller's session, **verified against GoTrue**, never
  from the request. The only accepted body field is a Sign in with Apple authorization code.
- `delete_my_account_content()` takes **no parameters**, acts only on `auth.uid()`, and is not
  executable by `anon`.
- `AccountDeletionTests.testRequestCarriesNoUserIdentifier` fails if the request ever grows a field.

## The pieces

| File | Role |
|---|---|
| `backend/account_deletion.sql` | The database function, plus grants and a receipt row |
| `backend/functions/delete-account/index.ts` | The Edge Function: runs the SQL as the user → removes uploads → revokes Apple → deletes the login → deletes or releases the creator page → rebuilds the catalogue snapshot |
| `backend/test-account-deletion.sh` | Proves the SQL against a throwaway Postgres; run by `ci.yml` |
| `Features/Settings/DeleteAccountView.swift` | Explanation → confirmation dialog → (Apple accounts: Continue with Apple) → done |
| `Data/AccountDeletion.swift` | The request body, error messages, and the on-device cache sweep |

**Order matters:** the login is deleted **last**, so a failure at any earlier step leaves the
person signed in and able to retry, and every step is safe to repeat.

⚠️ **Egress:** each deletion rebuilds the catalogue snapshot, so every phone downloads the
catalogue again on its next launch (~2.3 MB each). Deletions are rare, so this is acceptable, but it
is the reason not to call the function in a loop.

## Owner setup (Supabase dashboard — about 10 minutes)

### 1. Run the SQL
1. Supabase → project **Dozent** → **SQL Editor** → **New query**.
2. Paste the whole of `backend/account_deletion.sql` (Claude pastes it into chat for you) → **Run**.
3. It **deletes nothing** when you run it — it only creates one function. The result is one row:
   `is_security_definer = true`, `anon_can_run = false`, `signed_in_can_run = true`,
   `service_can_refresh = true`. Any other values: stop and tell Claude.

### 2. Deploy the function
1. Supabase → **Edge Functions** → **Deploy a new function** → **Via editor**.
2. Name it exactly **`delete-account`**.
3. Replace the sample code with `index.ts` (Claude pastes it) → **Deploy**.
4. Leave **Verify JWT** **ON** (the default).

### 3. Sign in with Apple revocation (Apple asks for this)
Deletion works without it; this adds the step Apple requires for accounts that sign in with Apple.
1. **developer.apple.com** → Certificates, IDs & Profiles → **Keys** → **＋**.
2. Name it `Dozent account deletion`, tick **Sign in with Apple** → **Configure** → choose the
   Dozent app → Save → Continue → **Register** → **Download** the `.p8` (once only).
3. Supabase → **Edge Functions** → **Secrets** → add:

| Name | Value |
|---|---|
| `APPLE_SIWA_KEY` | the whole `.p8` file, opened in TextEdit, including the BEGIN/END lines |
| `APPLE_SIWA_KEY_ID` | the Key ID shown next to the key |

### 4. Check it on a TestFlight build
Use a **throwaway** account, never a real one: sign up → Settings → Delete account → confirm. You
should see "Your account has been deleted", and signing in with that account again should fail.
