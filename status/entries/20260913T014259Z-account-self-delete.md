# In-app account deletion built — remove unsold, keep sold

_2026-09-13 01:42 UTC · branch `account-self-delete`_

**In-app account deletion built** (Apple Guideline 5.1.1(v)) — branch `claude/account-self-delete`, code-class, awaiting owner OK + device pass.

- **Owner decided twice, 2026-09-13: "Remove unsold, keep sold."** Unsold tours deleted with files; bought tours stay published, credited to "Former creator". PR #850's "unpublish and retain" is **superseded** (commented there) — and a `taken_down` tour is hidden from buyers too, so it would not have kept their access.
- Apple's live text re-checked: deletion must be **initiated in-app**; a website may only finish it. Sign in with Apple accounts should have tokens revoked — built, needs an Apple key (owner item).
- Only the account holder can trigger it: Edge Function takes the id from the GoTrue-verified session; `delete_my_account_content()` has no parameters and uses `auth.uid()`; anon refused; a unit test fails if the request ever grows a field.
- Username held 30 days in `released_handles` (from the usernames session's review).
- Verified: simulator build green; **655/655 unit tests** incl. 5 new. SQL + Deno type-check run in CI (`account-deletion` job) — **no local Postgres/Deno**, so CI is the first real run of those.
- NOT verified: the Edge Function against live Supabase (not deployed), and the screen on a signed-in device.
- Privacy policy + terms now name the in-app route. Docs: `docs/account-deletion.md`.
