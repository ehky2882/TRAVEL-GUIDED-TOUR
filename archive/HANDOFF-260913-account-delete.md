# Handoff — 2026-09-13 — in-app account deletion

**Branch:** `claude/account-self-delete` · code-class → owner OK + device pass before merge.
**Full reference:** `docs/account-deletion.md`.

## What was decided
- Owner, 2026-09-13: build it. Then, asked early, **"Remove unsold, keep sold"**. Asked a second
  time after PR #850 (another session) had recorded "unpublish and retain", and confirmed again.
  #850 was commented as superseded.
- ⚠️ #850's premise was wrong: a `taken_down` tour is hidden from **buyers too**. Both the catalogue
  builder and the tours RLS policy filter to `published`.

## What was verified, live, before building
- Apple's text (developer.apple.com, 2026-09-13): 5.1.1(v) says *"you must also offer account deletion
  within the app"*. The support page says deletion must be **initiated** in-app (a website may only
  finish it) and that Sign in with Apple tokens should be revoked.
- **Every account gets a maker row at signup** (`handle_new_user`). So `makers.user_id on delete set
  null` alone would have left every deleted person's name, photo and bio on an orphaned creator
  page, contradicting the privacy policy. The brief's FK table did not surface this.
- Live: 28 user-owned makers, and **one** published user tour, which is free. 66 paid tours exist,
  none of them user-owned as far as anon can see. Drafts and `purchases` are invisible to anon.
- Usernames are **live** (`makers.handle` etc. exist). The guard's 30-day rule blocks a handle change
  while `user_id` is set, so the handle is released after the login is gone. On the usernames
  session's advice it is also **held 30 days** in `released_handles`.

## What was verified after building
- Simulator build green; **655/655 unit tests pass** (5 new in `AccountDeletionTests`).
- ⚠️ **No local Postgres or Deno.** `backend/test-account-deletion.sh` and `deno check` run only in
  the new `ci.yml` job `account-deletion`, so the PR's CI is the first execution of either. Read that
  job's log for the `RUN` stamp and the `PASS` line, not just its colour.
- ⚠️ **NOT verified:** the Edge Function against real Supabase (not deployed), the Storage list and
  delete calls, the Apple revoke, and the screen on a signed-in device. The simulator cannot sign in
  without real credentials.

## Owner owes — nothing (all done 2026-09-13, hand-held)
- SQL applied; the owner's receipt row was `true | false | true | true`, and a live anon call returns 42501.
- `delete-account` deployed, then **redeployed** without the catalogue rebuild step (#864). Both times
  re-checked live: 401 with no auth, and the function's own 401 for a non-user.
- Sign in with Apple key created; `APPLE_SIWA_KEY` + `APPLE_SIWA_KEY_ID` set as secrets.
- Throwaway email-alias account deleted on TestFlight 155. Afterwards: 0 "Former creator" rows,
  28 login-owned makers (unchanged), `status/owner/account-delete-setup.md` cleared.
- Merged: #853 (feature) → `0438466f`, #863 (docs) → `89951bd5`, #864 (drop rebuild) → `27cd8c6c`.

⚠️ **Still unexercised:** the Apple token revocation (the test used email), and the redeployed code
on a real deletion. The next deletion's log should show only `account deleted`, with no
`catalog snapshot refresh failed` line.

## Open for later
- A kept ("Former creator") tour **stays on sale**, and new sales accrue to a maker row with no one
  behind it. No such tour exists today.
- **A deleted person's name stays in the downloadable catalogue until the next content publish**
  rebuilds the snapshot (owner decision 2026-09-13, #864). The in-function rebuild was removed
  after it hit 57014 statement timeout. Rejected: a daily scheduled rebuild (~2.3 MB per phone per
  day) and raising `service_role`'s time limit. 🔴 Don't add an API-side rebuild back. The
  `service_role`-not-in-`anon` theory was checked and is beside the point, because `SET ROLE` checks
  the session user.
- A buyer who deletes their account cannot restore those purchases to a new account.
  `record-purchase` answers 409, because the row's `user_id` is null. The screen says so.
