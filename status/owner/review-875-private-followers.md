# Try build 159: a private account's followers screen should say it is private

_opened 2026-09-13 · clear with `git rm status/owner/review-875-private-followers.md`_

Install TestFlight **build 159** and try the five steps in its "What to Test" notes. The test that matters is opening a private creator you don't follow and tapping their followers: it should say the account is private, not "No followers yet."

If it looks right, say so and #875 gets merged. Then `claude/private-friend-account-33psch` can be deleted, because everything on it will be on `main`.

Clear with `python3 scripts/status.py --clear-owner review-875-private-followers`.
