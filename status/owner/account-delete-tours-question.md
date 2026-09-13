# Account deletion: what happens to a maker's published tours?

_opened 2026-09-13 · clear with `git rm status/owner/account-delete-tours-question.md`_

✅ **DECIDED 2026-09-13 — build it.** Owner: *"i think it makes sense to have a
way to delete your own account from the app. we should build it."* Queued as its
own session; nothing is owed by you to start it.

🔴 **One question will come back to you early, and it cannot be assumed.** The
database blocks the naive answer: `purchases.tour_id` and `purchases.maker_id`
are `on delete restrict`, and `tours.maker_id` is too — so **a tour that has been
bought cannot be deleted, and neither can its maker.**

So: when a maker deletes their account, what happens to tours they published?
Unpublish and retain · keep published with no owner · delete where no purchase
blocks it. **Anyone who bought a tour keeps their access either way** — that is
what the `restrict` is for.

**The rest is already specified by your own privacy policy**, which promises
removal of profile, synced library and creator content, with legally-required
records *"retained in minimal form"* — and the schema already implements exactly
that shape via cascade and set-null.
