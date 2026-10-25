# Release 1.1.4 when Apple approves it (phased, 7 days)

_opened 2026-10-25 · clear with `git rm status/owner/release-1-1-4.md`_

1.1.4 was submitted to App Review on 2026-10-25 (build 190), release type MANUAL. When Apple approves it, release it in App Store Connect; the 7-day phased release is already set and starts then.

After it is released, `MARKETING_VERSION` must be bumped (1.1.4 -> 1.1.5) in its own PR before the next TestFlight upload will be accepted - re-derive the current value from `project.pbxproj` on `origin/main` rather than trusting this note.
