# Restructured the board so parallel sessions stop colliding

_2026-09-13 00:48 UTC · branch `status-conflict-fix`_

`STATUS.md` was one file every session prepended to at the same three line
numbers. 67 commits in a week; #776, #820 and #843 each blocked by a conflict in
it, none a disagreement about code. Live state is now one file per entry under
`status/`, which cannot collide. Proven by simulating two sessions both ways.
