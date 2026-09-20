# Press 'Release this version' once Apple approves 1.1.3

_opened 2026-09-20 · clear with `git rm status/owner/release-1-1-3-when-approved.md`_

1.1.3 was submitted on **2026-09-20 22:13 UTC** with build 176 and is
`WAITING_FOR_REVIEW`. Apple usually answers in 24–48 hours.

**Release is MANUAL by design — approval does NOT put it on the store.** When the
email says approved, open App Store Connect → Dozent → 1.1.3 and press
**Release this version**. Phased release is on, so it then rolls out over 7 days.

Clear this with `git rm status/owner/release-1-1-3-when-approved.md`.

Once it is live, a session must bump `MARKETING_VERSION` 1.1.3 → 1.1.4 in
`TRAVEL GUIDED TOUR.xcodeproj/project.pbxproj` as its own PR — a released
version's upload train closes, and the next TestFlight upload is rejected with
90186 *Invalid Pre-Release Train* until it moves.
