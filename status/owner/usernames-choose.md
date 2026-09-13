# Choose from the unique-usernames design

_opened 2026-09-13 · clear with `git rm status/owner/usernames-choose.md`_

`docs/usernames-design.md` landed as #841 — **nine choices, nothing built.**
Handle beside display name, unique per `(platform, handle)`, automatic backfill
for all live rows, pinned handles reserved. **No account deleted, merged or renamed.**

Nothing proceeds until you pick. Raised by you on 2026-09-12:
*"at minimum, we definitely need every user to have a unique username."*

It also leaves a question that is yours rather than a patch: **every signup gets
a public creator page**, and `makers` is directly readable, so hiding rows from
`get_catalog` would make nothing private.
