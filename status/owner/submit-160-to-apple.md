# Optional: send 1.1.2 (160) to Apple as an App Store update

_opened 2026-09-14 · clear with `git rm status/owner/submit-160-to-apple.md`_

**Not owed — an option held open.** Owner, 2026-09-14: *"160 is live. looks good."*
Earlier: *"if it's good it i might send it to apple for a app store update."*

**The public is on 1.1.1** (released 1 September). Build 160 is the candidate and
is reviewed as good.

**What shipping it would release:**

* 🔴 **In-app account deletion** — Apple has required this since 2022 (Guideline
  5.1.1(v)) and 1.1.1 does not have it. **The strongest single reason to ship.**
* **Usernames**, shown, searchable and changeable.
* The rebuilt filter row, the breathing splash and faster launch, and a private
  account's list no longer claiming "No followers yet."
* ⚠️ **New architect and category tags that are ALREADY live in the catalogue and
  invisible to 1.1.1** — the app does not know the words. This is real value
  sitting in the data that only an app update releases, and it is the item most
  easily forgotten when writing release notes.

⚠️ **Release notes must describe the delta from 1.1.1, not from the last TestFlight
build** — `docs/launch-runbook.md` Step U0. Every release makes that file stale;
rewrite it rather than amending.

**No deadline. Clear this item whenever the answer is no, or after submitting.**
