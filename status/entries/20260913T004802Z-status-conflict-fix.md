# Restructured the board so parallel sessions stop colliding

_2026-09-13 00:48 UTC · branch `status-conflict-fix`_

`STATUS.md` was one file every session prepended to at the same three line
numbers. 67 commits in a week; #776, #820 and #843 each blocked by a conflict in
it, none a disagreement about code. Live state is now one file per entry under
`status/`, which cannot collide. Proven by simulating two sessions both ways.

## Also from this session, folded in from the superseded #843

**`1.1.2 (152)` is live on TestFlight** (owner-confirmed 2026-09-13) — cut from
`main` at `432dca42`, the first build from `main` rather than a feature branch.
Full detail in `status/builds/152.md`; the device review is owed in
`status/owner/device-review-152.md`.

**[#842](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/842) merged overnight**
— 86 `@blessedarch` link pins (+3 `@__dreamspaces`). ⚠️ **Catalogue counts moved
again; re-derive them, never quote.** That merge is also what knocked
[#843](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/843) into conflict while
it sat open — the third such block in two days, and the reason this restructure
exists.

🔴 **#843 is closed rather than merged, deliberately.** It updated the OLD
single-file board; this PR replaces that file wholesale, so merging both would
have meant one conflicting with the other for no gain. Its substance is here and
in the fragments above — nothing from it is lost.
