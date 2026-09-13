# Device-review build 1.1.2 (152) — the App Store candidate

_opened 2026-09-13 · clear with `git rm status/owner/device-review-152.md`_

**Live on TestFlight, owner-confirmed 2026-09-13.** Cut from `main` at `432dca42` —
the first build from `main` rather than a feature branch.

🔴 **Installable is not reviewed, and this is the App Store candidate**, so the
device pass is the gate rather than a formality.

**Most worth your eye: the filter chips.** Three rounds of device review already,
but never alongside everything else on a build from `main`.

Also in it: the breathing splash + faster launch · a link pin that cannot load
says so · the bottom module no longer goes missing · Search counts refresh live ·
the 34-byte version check (open → close → reopen, content still correct) · and
**16 new architect/category names** whose tags are ALREADY live in the catalogue
and invisible to 1.1.1.

⚠️ **Release notes must describe the delta from 1.1.1, not from the last
TestFlight build.** `docs/launch-runbook.md` Step U0.
