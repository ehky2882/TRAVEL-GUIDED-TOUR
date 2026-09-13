# Usernames shipped end to end: #849 merged after owner device check on build 153; #851 #854 #855 merged

_2026-09-13 02:18 UTC · branch `usernames-wrapup`_

**Usernames are done.** Owner tested build 153 ("seems to work"); [#849](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/849) merged as `c1d4b81c`. Also merged: #851 (build 153 record), #854 (`former.` prefix reservation, applied), #855 (`merge-link-pins.py` warns when a new pinned creator's handle is held by a Dozent account). `status/owner/usernames-device-review.md` cleared.

⚠️ **Vercel is rate-limited on every PR** ("retry in 24 hours"). It only deploys `site/`. A merge watcher that waits on ALL checks (`gh pr checks --watch`) silently never merges while that lasts. Gate on the non-Vercel checks instead. Full account in `archive/HANDOFF-260913.md`.
