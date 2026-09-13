# Cleared a stale owner item: the board named build 152 and the owner is on 157

_2026-09-13 18:18 UTC · branch `filtered-view-lesson`_

🔴 **`device-review-152.md` was wrong twice over.** The owner: *"I'm way past build
152."* Re-derived from the Actions run list: the latest is **157**, cut 16:40 UTC
today — **five builds** on from the one the board was still asking about.

And 152's framing was dead anyway: everything it carried (the filter chips, the
breathing splash, the link-pin error state, the Search count fix, the version
check) has since **merged to `main`**, so "the App Store candidate" stopped
describing it the moment those PRs landed.

🔴 **The underlying mistake is mine and worth not repeating: an owner item must
not hard-code a build number.** `run_number` is shared across branches and moves
several times a day here — this repo's own rule is *read it back, never predict
it*, and a board item that names one has quietly predicted it for as long as it
sits there. A device-review item should name **what to look at**, and let the
build number come from the run list when someone needs it.

No replacement owner item was created: the owner is plainly reviewing builds
already, and 157 belongs to a session still working on its branch.
