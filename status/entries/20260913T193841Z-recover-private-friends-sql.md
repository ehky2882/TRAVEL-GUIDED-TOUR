# Branch cleanup: 12 deleted and confirmed by re-listing, the applied migration recovered (#873)

_2026-09-13 19:38 UTC · branch `recover-private-friends-sql`_

Acting on the 2026-09-13 branch audit (#872). Everything below was re-verified server-side
(GitHub compare API), because the shared checkout is a **shallow clone**.

## 🔴 The applied migration is recovered — #873

`backend/private_friends_social.sql` was **applied in production** but existed only on
`claude/private-friend-account-33psch`. #873 brings it to `main`, byte-identical (blob `b4817462`).
**Checked live:** `POST rpc/can_see_social` → HTTP 200 (4 bytes), so the function really is there.

⚠️ **That branch's app half never landed either** — `FollowService.swift`, `FollowListView.swift`,
`MakerView.swift` (the empty state says the list is hidden instead of "No followers yet."), plus its
`test-migrations.sh` fixture. That is code, so it is the owner's decision; see
`status/owner/branch-decisions.md`.

## ✅ 12 branches deleted — confirmed by re-listing, not by exit code

Deleted with `DELETE /git/refs/heads/…`, **not** `git push --delete`, which has returned 403 and
still exited 0 here. Re-listed afterwards: 22 branches → 10, and every deleted name returns **404**.

`amazing-rubin-pkub81` · `clever-wozniak-mmyxa6` · `tour-links-26dmsx` · `img-encoding-test` ·
`project-tracking-dashboard-1kggmu` · `status-account-delete-decided` · `status-delete-decision` ·
`stripe-questions-fjhdo3` · `web-landing-site-preserve` · `link-fullscreen-probe` ·
`dreamy-wozniak-tags-260612` · `seed-hang-note`

Two corrections to the audit, both checked before deleting:
- `link-fullscreen-probe` had **two non-probe commits** besides the `TEMP-PROBE` ones (element
  fullscreen, and watching the video's own `UIWindow`). Both are on `main` in `LinkEmbedView.swift`
  (`isElementFullscreenEnabled = true`, `UIWindow.didBecomeVisibleNotification`), and no probe code is.
- `web-landing-site-preserve`'s second commit also **closed a paywall bypass in the `•••` menu**
  (Listen together and Download on a locked tour) and made the pending-purchase queue per-account.
  Both are on `main` (`TourDetailView.swift` `!isLockedPaid`, `PurchaseService` `atlas.pendingPurchases.<uid>`).

## Kept, untouched

`amsterdam-handoff-preserve-hlhyp8` (the only copy of the 30 Atlanta scripts) · `transcript-square-floor`
(an unlanded fix) · `private-friend-account-33psch` · `paris-scripts-260622` and
`london-batch3-scripts-260616` (the only source scripts; owner to rule) · `more-tours-a1xhw4`
(+1, not in the audit, left alone).
