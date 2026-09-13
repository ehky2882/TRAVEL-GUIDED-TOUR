# Four kept branches need a yes or no: private-friend app half, transcript square, Paris/London scripts

_opened 2026-09-13 · clear with `git rm status/owner/branch-decisions.md`_

Nothing is broken, and nothing is urgent. These kept branches each need a yes or no from you:

1. **`claude/private-friend-account-33psch`: finish the app half?** The database fix is live and now
   recorded on `main` (#873). The matching app change never shipped: when a private creator's list is
   hidden from you, it still says **"No followers yet."** instead of saying the list is private.
   *Yes* = a PR and a TestFlight build for you to try. *No* = the branch is deleted.
2. **`claude/transcript-square-floor`: ship it?** It is your 2026-08-21 request, *"for transcript box,
   you can also just make square to be safe"*, and it never landed. *Yes* = a PR and a build. *No* = deleted.
3. **`claude/paris-scripts-260622` and `claude/london-batch3-scripts-260616`: keep or delete?** Both
   cities are live. These branches are the only copy of the written scripts, so deleting them loses the
   source text but changes nothing in the app.

Clear this with `python3 scripts/status.py --clear-owner branch-decisions` once all three are answered.
