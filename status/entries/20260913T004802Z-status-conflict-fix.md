# Restructured the board so parallel sessions stop colliding

_2026-09-13 00:48 UTC · branch `status-conflict-fix`_

`STATUS.md` was one file every session prepended to at the same three line
numbers. 67 commits in a week; #776, #820 and #843 each blocked by a conflict in
it, none a disagreement about code. Live state is now one file per entry under
`status/`, which cannot collide. Proven by simulating two sessions both ways.

## Also from this session, folded in from the superseded #843

**`1.1.2 (152)` is live on TestFlight** (owner-confirmed 2026-09-13) — cut from
`main` at `432dca42`, the first build from `main` rather than a feature branch.
Full detail in `status/builds/152.md`; the device review is owed in
`status/owner/device-review-152.md`.

**[#842](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/842) merged overnight**
— 86 `@blessedarch` link pins (+3 `@__dreamspaces`). ⚠️ **Catalogue counts moved
again; re-derive them, never quote.** That merge is also what knocked
[#843](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/843) into conflict while
it sat open — the third such block in two days, and the reason this restructure
exists.

🔴 **#843 is closed rather than merged, deliberately.** It updated the OLD
single-file board; this PR replaces that file wholesale, so merging both would
have meant one conflicting with the other for no gain. Its substance is here and
in the fragments above — nothing from it is lost.

## The account-deletion gap, re-verified rather than relayed

[#844](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/844) flagged that no
self-delete exists and said to re-check before acting. Re-checked
independently on 2026-09-13:

* **App:** no match for delete/close/erase-account in any `*.swift`. Settings
  offers **Sign out · Clear Cache · Manage downloads · Privacy Policy · Terms** —
  and no deletion.
* **Backend:** nothing in `backend/` or the Edge Functions.
* **Website:** no deletion page.

🔴 **The finding holds. But there is a wrinkle #844 did not name:** the published
policy already *promises* deletion. `site/privacy/index.html` says *"You can ask
us … to delete your account and its contents. Write to the address below and we
will respond within 30 days,"* and `site/terms/index.html` says *"may ask us to
delete your account."*

So the commitment is **already made in writing**, and the only route is emailing
`hello@dozent.world` — which is **ImprovMX forwarding, receive-only**. A deletion
request today lands in the owner's Gmail and is handled by hand, with no
mechanism behind it.

⚠️ **What I did NOT verify:** whether Apple accepts a web/email route in place of
in-app initiation for this app. Guideline 5.1.1(v) is generally read as requiring
the app itself to offer it, with narrow exceptions. **Check the current guideline
text before designing around either answer** — do not take this entry as settling
it.

Evidence that Apple has not enforced it here *so far*: 1.1.0 and 1.1.1 were both
approved with accounts shipping. That is Apple declining to notice, not
permission.
