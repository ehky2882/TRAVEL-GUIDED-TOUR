# Check what release notes 1.1.2 was submitted with

_opened 2026-09-14 · clear with `git rm status/owner/verify-1-1-2-release-notes.md`_

**Owner submitted 1.1.2 to Apple on 2026-09-14.** One thing could not be checked
from a web session and is worth a look before it goes live.

🔴 **`fastlane/metadata/en-US/release_notes.txt` has not been touched since the
1.1.1 prep** ([#672](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/672), two
weeks ago), and its text is **byte-identical to what the App Store serves for
1.1.1 right now** — *"Pinned posts on the map…"*.

**So it depends how the submission was made:**

* **Typed into App Store Connect by hand** → fine, the file is just stale and
  should be rewritten for tidiness.
* **Submitted via fastlane** → fastlane pushes metadata from these files, so
  **1.1.2 would be listed with 1.1.1's release notes**: the update would describe
  itself as the version people already have.

⚠️ **This cannot be checked from a web session** — a pending version's notes need
the App Store Connect key, which lives on the owner's Mac. `scripts/session-start.sh`
skips that check here by design.

**To check:** App Store Connect → the 1.1.2 version page → *What's New in This
Version*. If it opens with *"Pinned posts on the map"*, it is wrong and can be
edited while the build is still in review.

**What it should say instead:** account deletion · usernames · the rebuilt filter
row · the faster, breathing start · a private account's list saying it is private ·
and the new architect and category tags, which are **already live in the catalogue
and invisible to 1.1.1**.
